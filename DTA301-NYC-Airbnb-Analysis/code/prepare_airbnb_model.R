
# ==============================================================================
# CHUẨN BỊ DỮ LIỆU CHO MÔ HÌNH (MODEL-READY DATA)
# Đầu vào: cleaned_listings.csv (kết quả của 01_data_cleaning.R)
# Chạy 01_data_cleaning.R trước, với thư mục làm việc là thư mục code.
# ==============================================================================

# Cài đặt và tải các thư viện cần thiết
options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")
if (!require(tidyr)) install.packages("tidyr")

library(dplyr)
library(readr)
library(tidyr)

# 1. Đọc dữ liệu (dùng dữ liệu đã làm sạch để thống nhất bộ lọc outliers)
cat("Đang đọc dữ liệu...\n")
listings <- read_csv("../data/cleaned_listings.csv", col_types = cols(id = col_character()), show_col_types = FALSE)

# Ngày chốt dữ liệu = ngày review mới nhất -> kết quả không đổi theo ngày chạy code
snapshot_date <- max(listings$last_review, na.rm = TRUE)
cat("Ngày chốt dữ liệu (snapshot):", format(snapshot_date), "\n")

# 2. Tạo đặc trưng cho mô hình
# File listings chi tiết đã có first_review, last_review và số review, nên không cần gộp reviews.csv ở bước này.
# Điểm cảm xúc (sentiment) từ reviews sẽ được gộp vào sau Bước 3 (NLP).
cat("Đang tạo đặc trưng cho mô hình...\n")
model_data <- listings %>%
  mutate(
    # NYC Local Law 18 (09/2023): phần lớn listing chỉ cho thuê từ 30 đêm trở lên
    stay_type = if_else(minimum_nights >= 30, "long_stay", "short_stay"),

    # Listing chưa có review: đánh dấu bằng has_reviews = 0 và điền trung vị cho các cột số ngày
    has_reviews = as.integer(number_of_reviews > 0),
    days_since_last_review = as.numeric(snapshot_date - last_review),
    days_since_first_review = as.numeric(snapshot_date - first_review),
    days_since_last_review = replace_na(days_since_last_review, median(days_since_last_review, na.rm = TRUE)),
    days_since_first_review = replace_na(days_since_first_review, median(days_since_first_review, na.rm = TRUE))
  ) %>%
  select(-id, -first_review, -last_review) # Bỏ khóa và các cột ngày tháng sau khi đã chuyển thành số

# 3. Lưu dữ liệu đã làm sạch
output_path <- "../data/airbnb_model_ready.csv"
write_csv(model_data, output_path)
cat("Dữ liệu sẵn sàng cho mô hình. Số dòng:", nrow(model_data), "- Lưu tại:", output_path, "\n")
