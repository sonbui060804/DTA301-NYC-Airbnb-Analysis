# BƯỚC 1: DATA PREPARATION & CLEANING (TIỀN XỬ LÝ DỮ LIỆU)
# Giữ nguyên các ngưỡng kinh doanh của báo cáo, đồng thời lưu bằng chứng chất lượng.
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

require_packages(c("dplyr", "readr", "tidyr"))
library(dplyr)
library(readr)
library(tidyr)
cat("Bắt đầu quá trình Tiền Xử Lý Dữ Liệu...\n")
listings <- read_listings("listings.csv")
write_csv(quality_summary(listings, "id"), table_path("listings_quality_raw.csv"))
assert_unique_id(listings$id, "Listings")

# Bỏ dữ liệu cá nhân; giữ id dạng chuỗi để ghép chính xác với reviews.
cleaned_listings <- listings %>%
  select(id, neighbourhood_group = neighbourhood_group_cleansed,
         neighbourhood = neighbourhood_cleansed, latitude, longitude, room_type,
         accommodates, price, minimum_nights, number_of_reviews, first_review,
         last_review, reviews_per_month, review_scores_rating,
         calculated_host_listings_count, availability_365, number_of_reviews_ltm) %>%
  mutate(price = parse_number(price), reviews_per_month = replace_na(reviews_per_month, 0),
         first_review = as.Date(first_review), last_review = as.Date(last_review)) %>%
  # Tọa độ và giá cần có để phân tích; giới hạn giá giữ được phần lớn phân khúc cao cấp.
  filter(!is.na(price), !is.na(latitude), !is.na(longitude),
         price > 0, price <= 2000, minimum_nights > 0, minimum_nights <= 365)

# Dataset hiện tại không thiếu availability; chỉ điền trung vị nếu thực sự có NA.
# first_review, last_review, review_scores_rating vẫn giữ NA cho listing chưa có review.
if (anyNA(cleaned_listings$availability_365)) {
  replacement <- median(cleaned_listings$availability_365, na.rm = TRUE)
  if (!is.finite(replacement)) stop("availability_365 không có dữ liệu hợp lệ để điền trung vị.")
  cleaned_listings$availability_365 <- replace_na(cleaned_listings$availability_365, replacement)
}
write_csv(cleaned_listings, data_path("cleaned_listings.csv"))
write_csv(quality_summary(cleaned_listings, "id"), table_path("listings_quality_clean.csv"))
cat("Số lượng dòng ban đầu:", nrow(listings), "\n")
cat("Số lượng dòng sau khi làm sạch:", nrow(cleaned_listings), "\n")
cat("Đã loại bỏ được:", nrow(listings) - nrow(cleaned_listings), "dòng dữ liệu lỗi/dị biệt.\n")
