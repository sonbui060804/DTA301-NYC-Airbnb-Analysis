# PHASE 4: Modeling (Regression & Clustering)
# Xuất số liệu thật từ cùng lần chạy; không dùng kết luận viết sẵn trong notebook.
# Tìm hàm chung khi chạy từ notebook, thư mục dự án hoặc đường dẫn Rscript tuyệt đối.
script_arg <- grep("^--file=", commandArgs(), value = TRUE)
origins <- c(getwd(), if (length(script_arg)) dirname(sub("^--file=", "", script_arg[1])))
helper <- NULL
for (origin in origins) {
  current <- normalizePath(origin, winslash = "/", mustWork = TRUE)
  repeat {
    candidates <- c(file.path(current, "code", "analysis_helpers.R"),
                    file.path(current, "DTA301-NYC-Airbnb-Analysis", "code", "analysis_helpers.R"))
    found <- candidates[file.exists(candidates)]
    if (length(found)) { helper <- found[1]; break }
    if (dirname(current) == current) break
    current <- dirname(current)
  }
  if (!is.null(helper)) break
}
if (is.null(helper)) stop("Không tìm thấy code/analysis_helpers.R.")
source(helper, encoding = "UTF-8")

require_packages(c("dplyr", "readr", "ggplot2", "randomForest", "cluster"))
library(dplyr)
library(ggplot2)
model_data <- read_listings("airbnb_model_ready.csv")
assert_unique_id(model_data$id, "Dữ liệu mô hình")
if (nrow(model_data) < 20) stop("Cần ít nhất 20 listings để chia train/test và chọn cụm.")

# 1. Phân khúc thị trường: gồm cả room_type theo phần mô tả của báo cáo.
# One-hot các loại phòng trước khi chuẩn hóa để không gán thứ tự giả cho nhãn.
cluster_columns <- c("price", "latitude", "longitude", "number_of_reviews", "room_type")
cluster_data <- as.data.frame(model_data[, cluster_columns])
if (anyNA(cluster_data)) stop("Đặc trưng phân cụm còn thiếu giá trị; cần kiểm tra bước làm sạch.")
encoded_cluster <- encode_train_test(cluster_data, cluster_data[FALSE, ], "room_type")$train
varying <- apply(encoded_cluster, 2, sd) > 0
scaled_features <- scale(encoded_cluster[, varying, drop = FALSE])
set.seed(42)
# Silhouette cần khoảng cách từng cặp O(n^2), nên chọn K trên mẫu cố định tối đa 2.000.
# Sau đó khớp K đã chọn trên toàn bộ listings, không gọi mẫu là kết quả toàn bộ dữ liệu.
selection_idx <- sample(seq_len(nrow(scaled_features)), min(2000, nrow(scaled_features)))
selection_data <- scaled_features[selection_idx, , drop = FALSE]
max_k <- min(8, nrow(unique(selection_data)) - 1)
if (max_k < 2) stop("Không đủ quan sát khác nhau để đánh giá số cụm.")
distances <- dist(selection_data)
k_metrics <- do.call(rbind, lapply(2:max_k, function(k) {
  set.seed(42)
  fit <- kmeans(selection_data, centers = k, nstart = 20, iter.max = 100)
  data.frame(k = k, total_withinss = fit$tot.withinss,
             silhouette = mean(cluster::silhouette(fit$cluster, distances)[, "sil_width"]),
             selection_sample_n = nrow(selection_data))
}))
best_k <- k_metrics$k[which.max(k_metrics$silhouette)]
readr::write_csv(k_metrics, table_path("kmeans_k_selection.csv"))
for (metric in c("total_withinss", "silhouette")) {
  p <- ggplot(k_metrics, aes(x = k, y = .data[[metric]])) + geom_line() + geom_point() +
    theme_minimal() + scale_x_continuous(breaks = k_metrics$k) +
    labs(title = if (metric == "silhouette") "Chọn K bằng Silhouette" else "Elbow Method", x = "Số cụm K", y = metric)
  ggsave(image_path(paste0("KMeans_", metric, ".png")), p, width = 8, height = 5, dpi = 150)
}
set.seed(42)
kmeans_result <- kmeans(scaled_features, centers = best_k, nstart = 25, iter.max = 100)
clustered <- model_data %>% mutate(cluster = factor(kmeans_result$cluster))
readr::write_csv(clustered %>% select(id, cluster), table_path("listing_clusters.csv"))
profile <- clustered %>% group_by(cluster) %>% summarise(
  n = n(), median_price = median(price), median_reviews = median(number_of_reviews),
  mean_latitude = mean(latitude), mean_longitude = mean(longitude), .groups = "drop")
readr::write_csv(profile, table_path("cluster_profiles.csv"))
readr::write_csv(clustered %>% count(cluster, room_type), table_path("cluster_room_types.csv"))
readr::write_csv(data.frame(selected_k = best_k, fitted_n = nrow(clustered), seed = 42),
                 table_path("kmeans_run.csv"))
p3 <- ggplot(clustered, aes(longitude, latitude, color = cluster)) +
  geom_point(alpha = 0.5, size = 0.5) + theme_minimal() +
  labs(title = "Phân khúc phòng Airbnb (K-Means Clustering)",
       subtitle = paste("K =", best_k, "được chọn bằng Silhouette trên mẫu", nrow(selection_data)),
       x = "Kinh độ", y = "Vĩ độ", color = "Cụm")
ggsave(image_path("04_KMeans_Clustering.png"), p3, width = 10, height = 8, dpi = 150)
cat("K được chọn:", best_k, "\n")
print(profile)

# 2. Định giá: dùng stay_type THAY minimum_nights, đúng danh sách đặc trưng tài liệu.
# Chia trước khi học mã hóa/điền thiếu để thông tin của tập test không ảnh hưởng train.
predictor_columns <- c("neighbourhood_group", "neighbourhood", "room_type", "accommodates",
                       "stay_type", "number_of_reviews", "reviews_per_month", "availability_365")
categorical <- c("neighbourhood_group", "neighbourhood", "room_type", "stay_type")
set.seed(42)
train_idx <- sample(seq_len(nrow(model_data)), floor(0.8 * nrow(model_data)))
train_data <- model_data[train_idx, ]
test_data <- model_data[-train_idx, ]
encoded <- encode_train_test(train_data[, predictor_columns], test_data[, predictor_columns], categorical)
set.seed(42)
rf_model <- randomForest::randomForest(x = encoded$train, y = train_data$price,
  ntree = 150, mtry = max(1, floor(sqrt(ncol(encoded$train)))), importance = TRUE)
predictions <- predict(rf_model, encoded$test)
baseline <- rep(median(train_data$price), nrow(test_data))
# Baseline dùng trung vị train giúp đánh giá MAE có thực sự tốt hơn dự đoán đơn giản.
score <- function(pred, name) {
  residuals <- test_data$price - pred
  data.frame(model = name, n_train = nrow(train_data), n_test = nrow(test_data),
             MAE = mean(abs(residuals)), RMSE = sqrt(mean(residuals^2)),
             R2 = 1 - sum(residuals^2) / sum((test_data$price - mean(test_data$price))^2), seed = 42)
}
metrics <- rbind(score(predictions, "Random Forest"), score(baseline, "Train median baseline"))
readr::write_csv(metrics, table_path("regression_metrics.csv"))
readr::write_csv(data.frame(id = test_data$id, actual_price = test_data$price,
                           predicted_price = as.numeric(predictions), baseline_price = baseline),
                 table_path("regression_predictions.csv"))
importance <- randomForest::importance(rf_model)
readr::write_csv(data.frame(feature = rownames(importance), importance, check.names = FALSE),
                 table_path("regression_importance.csv"))
cat("KẾT QUẢ DỰ ĐOÁN GIÁ:\n")
print(metrics)
cat("Kết quả holdout mô tả khả năng dự đoán giá niêm yết; chưa chứng minh giá tối ưu hay doanh thu.\n")
