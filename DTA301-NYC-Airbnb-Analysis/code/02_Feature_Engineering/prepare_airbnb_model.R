# CHUẨN BỊ DỮ LIỆU CHO MÔ HÌNH (MODEL-READY DATA)
# Các giá trị NA dành cho đặc trưng dự đoán được xử lý sau khi chia train/test.
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

require_packages(c("dplyr", "readr"))
library(dplyr)
listings <- read_listings()
assert_unique_id(listings$id, "Listings sạch")
if (!any(!is.na(listings$last_review))) stop("Không có last_review để xác định ngày chốt.")
snapshot_date <- max(as.Date(listings$last_review), na.rm = TRUE)
model_data <- listings %>%
  mutate(
    # Ranh giới 30 đêm đúng định nghĩa nhóm lưu trú của báo cáo.
    stay_type = if_else(minimum_nights >= 30, "long_stay", "short_stay"),
    has_reviews = as.integer(number_of_reviews > 0),
    days_since_last_review = as.numeric(snapshot_date - as.Date(last_review)),
    days_since_first_review = as.numeric(snapshot_date - as.Date(first_review))
  )
# Giữ id để xuất dự đoán và mô tả cụm có thể truy vết; không đưa id vào mô hình.
readr::write_csv(model_data, data_path("airbnb_model_ready.csv"))
cat("Ngày chốt dữ liệu (snapshot):", format(snapshot_date), "\n")
cat("Dữ liệu sẵn sàng cho mô hình. Số dòng:", nrow(model_data), "\n")
cat("\n--- BẢNG THỐNG KÊ ĐẶC TRƯNG MỚI (stay_type & has_reviews) ---\n")
print(model_data %>% group_by(stay_type, has_reviews) %>%
        summarise(n = n(), median_price = median(price), mean_price = mean(price), .groups = "drop"))
