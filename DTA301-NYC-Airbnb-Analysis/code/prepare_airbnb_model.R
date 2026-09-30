
# Cài d?t và t?i các thu vi?n c?n thi?t
if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")
if (!require(lubridate)) install.packages("lubridate")

library(dplyr)
library(readr)
library(lubridate)

# 1. Ð?c d? li?u
cat("Ðang d?c d? li?u...\n")
listings <- read_csv("D:/dta/reviews.csv~1/listings.csv")
reviews <- read_csv("D:/dta/reviews.csv~1/reviews.csv")

# 2. Ti?n x? lý d? li?u reviews (T?o các d?c trung m?i)
cat("Ðang x? lý d? li?u nh?n xét...\n")
# Tính toán m?t s? d?c trung t? reviews d? làm phong phú d? li?u d? doán
# Ví d?: S? lu?ng review g?n dây (trong 1 nam qua)
reviews_summary <- reviews %>%
  mutate(date = as.Date(date)) %>%
  group_by(listing_id) %>%
  summarise(
    total_reviews_text = n(),
    latest_review_date = max(date, na.rm = TRUE),
    .groups = "drop"
  )

# 3. G?p d? li?u (Merge)
cat("Ðang g?p d? li?u...\n")
merged_data <- listings %>%
  left_join(reviews_summary, by = c("id" = "listing_id"))

# 4. Ti?n x? lý cho Mô hình H?c máy (Machine Learning)
cat("Ðang làm s?ch d? li?u cho mô hình...\n")
model_data <- merged_data %>%
  # Lo?i b? các c?t không có giá tr? d? doán (nhu ID, Tên, License)
  select(-id, -name, -host_id, -host_profile_id, -host_name, -license) %>%
  
  # X? lý missing values co b?n
  mutate(
    reviews_per_month = replace_na(reviews_per_month, 0),
    total_reviews_text = replace_na(total_reviews_text, 0),
    
    # Bi?n d?i ngày tháng thành s? ngày k? t? l?n dánh giá cu?i cùng
    days_since_last_review = as.numeric(Sys.Date() - as.Date(last_review)),
    days_since_last_review = replace_na(days_since_last_review, 9999) # 9999 cho nh?ng phòng chua có review
  ) %>%
  select(-last_review, -latest_review_date) # B? các c?t ngày tháng sau khi dã chuy?n thành s?

# L?c các dòng b? thi?u giá tr? ? các bi?n quan tr?ng (ví d?: price)
model_data <- model_data %>% filter(!is.na(price) & price > 0)

# 5. Luu d? li?u dã g?p và làm s?ch
output_path <- "D:/dta/airbnb_model_ready.csv"
write_csv(model_data, output_path)
cat("Tuy?t v?i! D? li?u dã du?c g?p và làm s?ch. Luu t?i:", output_path, "\n")

