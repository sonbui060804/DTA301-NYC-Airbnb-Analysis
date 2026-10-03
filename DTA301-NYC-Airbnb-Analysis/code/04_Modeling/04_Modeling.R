# ==============================================================================
# PHASE 4: Modeling (Regression & Clustering)
# ==============================================================================
options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(randomForest)) install.packages("randomForest")

library(dplyr)
library(readr)
library(ggplot2)

# ------------------------------------------------------------------------------
# 1. Bài toán Định vị (Clustering - K-Means)
# ------------------------------------------------------------------------------
model_data <- read_csv('../../data/airbnb_model_ready.csv', show_col_types = FALSE)

features <- model_data %>% select(price, latitude, longitude, number_of_reviews) %>% na.omit()
scaled_features <- scale(features)

set.seed(42)
kmeans_result <- kmeans(scaled_features, centers = 4, nstart = 10)
features$cluster <- as.factor(kmeans_result$cluster)

p3 <- ggplot(features, aes(x = longitude, y = latitude, color = cluster)) +
  geom_point(alpha = 0.5, size = 0.5) +
  theme_minimal() +
  labs(title = "Phân khúc phòng Airbnb (K-Means Clustering)")

# Lưu biểu đồ phân cụm thành ảnh
dir.create("../../report/images", showWarnings = FALSE, recursive = TRUE)
ggsave("../../report/images/04_KMeans_Clustering.png", plot = p3, width = 10, height = 8, dpi = 300)
cat("Đã lưu biểu đồ phân cụm tại: report/images/04_KMeans_Clustering.png\n")

# ------------------------------------------------------------------------------
# 2. Bài toán Định giá (Regression - Random Forest)
# ------------------------------------------------------------------------------
library(randomForest)

set.seed(42)
df_reg <- model_data %>% 
  select(price, room_type, neighbourhood_group, accommodates, minimum_nights, has_reviews) %>%
  mutate(across(c(room_type, neighbourhood_group), as.factor)) %>%
  sample_n(10000)

train_idx <- sample(1:nrow(df_reg), 0.8 * nrow(df_reg))
train_data <- df_reg[train_idx, ]
test_data <- df_reg[-train_idx, ]

rf_model <- randomForest(price ~ ., data = train_data, ntree = 50, importance = TRUE)
predictions <- predict(rf_model, test_data)

mae <- mean(abs(test_data$price - predictions))
cat("\n==================================\n")
cat("KẾT QUẢ DỰ ĐOÁN GIÁ:\n")
cat("Mean Absolute Error (MAE):", mae, "\n")

rss <- sum((predictions - test_data$price) ^ 2)
tss <- sum((test_data$price - mean(test_data$price)) ^ 2)
rsq <- 1 - rss/tss
cat("R-squared (R2):", rsq, "\n")
cat("==================================\n")
