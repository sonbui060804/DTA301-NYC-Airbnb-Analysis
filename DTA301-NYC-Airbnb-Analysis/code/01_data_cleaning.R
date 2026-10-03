# ==============================================================================
# BƯỚC 1: DATA PREPARATION & CLEANING (TIỀN XỬ LÝ DỮ LIỆU)
# Mục tiêu: Đọc dữ liệu, xử lý các giá trị khuyết thiếu (Missing Values),
# và loại bỏ các dữ liệu dị biệt (Outliers) để tránh làm sai lệch mô hình học máy.
# ==============================================================================

# 1. TẢI CÁC THƯ VIỆN CẦN THIẾT
# Cài đặt nếu máy chưa có
# Thiết lập Mirror để tải package tự động không bị lỗi
options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")
if (!require(tidyr)) install.packages("tidyr")

library(dplyr)
library(readr)
library(tidyr)

cat("Bắt đầu quá trình Tiền Xử Lý Dữ Liệu...\n")

# 2. ĐỌC DỮ LIỆU TỪ THƯ MỤC DATA
# Sử dụng relative path (đường dẫn tương đối) trỏ ra ngoài thư mục code
cat("Đang đọc file listings.csv...\n")
# id có 19 chữ số, vượt độ chính xác của kiểu số thực -> đọc dạng chuỗi
listings <- read_csv("../data/listings.csv", col_types = cols(id = col_character()), show_col_types = FALSE)

# Xem qua cấu trúc dữ liệu ban đầu
cat("Số lượng dòng ban đầu:", nrow(listings), "\n")

# 3. LÀM SẠCH DỮ LIỆU (DATA CLEANING)
cat("Đang dọn dẹp các giá trị khuyết và dị biệt...\n")
cleaned_listings <- listings %>%
  
  # 3.1: Chỉ giữ các cột dùng cho phân tích (bỏ dữ liệu cá nhân: tên, mô tả, URL của chủ nhà)
  # Giữ id làm khóa để ghép (join) với reviews ở bước sau
  select(
    id,
    neighbourhood_group = neighbourhood_group_cleansed,
    neighbourhood = neighbourhood_cleansed,
    latitude, longitude, room_type, accommodates, price, minimum_nights,
    number_of_reviews, first_review, last_review, reviews_per_month, review_scores_rating,
    calculated_host_listings_count, availability_365, number_of_reviews_ltm
  ) %>%

  # 3.2: Xử lý Missing Values (Giá trị khuyết thiếu)
  # - price trong file chi tiết là chuỗi dạng "$1,234.00" -> chuyển sang số
  # - Nếu số review (reviews_per_month) bị NA (do chưa ai review), điền là 0
  # - Lọc bỏ những phòng bị khuyết giá (price) hoặc khuyết tọa độ
  mutate(
    price = parse_number(price),
    reviews_per_month = replace_na(reviews_per_month, 0),
    first_review = as.Date(first_review),
    last_review = as.Date(last_review)
  ) %>%
  filter(!is.na(price)) %>%
  filter(!is.na(latitude) & !is.na(longitude)) %>%
  
  # 3.3: Lọc bỏ Outliers (Giá trị dị biệt) cực kỳ quan trọng
  # - Price = 0 là vô lý (cho thuê miễn phí). Price > 2000$ thường là nhiễu.
  # - minimum_nights > 365 là không hợp lệ đối với Airbnb (vượt quá 1 năm).
  filter(price > 0 & price <= 2000) %>%
  filter(minimum_nights > 0 & minimum_nights <= 365) %>%
  
  # 3.4: Điền giá trị trung vị (Median) cho các cột bị khuyết ít dữ liệu nếu có
  mutate(
    availability_365 = replace_na(availability_365, median(availability_365, na.rm = TRUE))
  )

# Kiểm tra lại số lượng dữ liệu sau khi làm sạch
cat("Số lượng dòng sau khi làm sạch:", nrow(cleaned_listings), "\n")
cat("Đã loại bỏ được:", nrow(listings) - nrow(cleaned_listings), "dòng dữ liệu lỗi/dị biệt.\n")

# 4. LƯU DỮ LIỆU ĐÃ LÀM SẠCH VÀO FILE MỚI
output_path <- "../data/cleaned_listings.csv"
write_csv(cleaned_listings, output_path)

cat("Tuyệt vời! Dữ liệu sạch đã được lưu tại:", output_path, "\n")
cat("Sẵn sàng cho Bước 2 (Khám phá dữ liệu EDA)!\n")
