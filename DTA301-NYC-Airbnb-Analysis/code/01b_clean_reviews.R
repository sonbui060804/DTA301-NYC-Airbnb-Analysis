# ==============================================================================
# BƯỚC 1b: DATA PREPARATION & CLEANING CHO REVIEWS
# Mục tiêu: Đọc dữ liệu reviews, loại bỏ các bình luận rỗng, 
# giữ lại các cột cần thiết cho Sentiment Analysis, và CHỈ lấy reviews 
# của những listing_id đã được làm sạch trong cleaned_listings.csv
# ==============================================================================

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")

library(dplyr)
library(readr)

cat("Bắt đầu quá trình Tiền Xử Lý file Reviews...\n")

# Đọc file cleaned_listings để lấy danh sách các id hợp lệ
cat("Đang đọc cleaned_listings.csv...\n")
cleaned_listings <- read_csv("../data/cleaned_listings.csv", col_types = cols(id = col_character()), show_col_types = FALSE)

valid_listing_ids <- cleaned_listings$id

# Đọc file reviews
cat("Đang đọc reviews.csv (file gốc)...\n")
reviews <- read_csv("../data/reviews.csv", col_types = cols(
  listing_id = col_character(),
  id = col_character(),
  date = col_date(format = ""),
  reviewer_id = col_character(),
  reviewer_name = col_character(),
  comments = col_character()
), show_col_types = FALSE)

cat("Số lượng dòng ban đầu của reviews:", nrow(reviews), "\n")

# Làm sạch
cat("Đang lọc và dọn dẹp reviews...\n")
cleaned_reviews <- reviews %>%
  # 1. Chỉ giữ lại những review thuộc về các listing_id hợp lệ
  filter(listing_id %in% valid_listing_ids) %>%
  # 2. Bỏ qua các review không có nội dung comment
  filter(!is.na(comments) & comments != "") %>%
  # 3. Chỉ giữ các cột cần cho Sentiment Analysis (Bỏ tên reviewer để bảo mật và giảm dung lượng)
  select(listing_id, review_id = id, date, comments)

cat("Số lượng dòng sau khi làm sạch:", nrow(cleaned_reviews), "\n")
cat("Đã loại bỏ được:", nrow(reviews) - nrow(cleaned_reviews), "dòng dữ liệu dư thừa/khuyết thiếu.\n")

# Lưu ra file mới
output_path <- "../data/cleaned_reviews.csv"
write_csv(cleaned_reviews, output_path)

cat("Tuyệt vời! Dữ liệu reviews gọn nhẹ đã được lưu tại:", output_path, "\n")
