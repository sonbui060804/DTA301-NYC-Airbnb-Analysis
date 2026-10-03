# ==============================================================================
# PHASE 4: SENTIMENT ANALYSIS (ĐÁNH GIÁ THÁI ĐỘ KHÁCH HÀNG)
# Yêu cầu: Sử dụng thư viện syuzhet để chấm điểm tích cực/tiêu cực cho bình luận
# ==============================================================================

# 1. Cài đặt và gọi thư viện cần thiết
options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")
if (!require(syuzhet)) install.packages("syuzhet") # Thư viện phân tích cảm xúc

library(dplyr)
library(readr)
library(syuzhet)

cat("Đang đọc dữ liệu reviews đã làm sạch...\n")
# Đọc file nén xz để tiết kiệm bộ nhớ
reviews <- read_csv("../../data/cleaned_reviews.csv.xz", show_col_types = FALSE)

# Lấy ngẫu nhiên 5000 đánh giá để chạy thử (chạy toàn bộ gần 800k dòng sẽ mất rất nhiều thời gian)
cat("Đang trích xuất ngẫu nhiên 5000 bình luận để chạy thử thuật toán...\n")
set.seed(42)
sample_reviews <- reviews %>% 
  filter(!is.na(comments)) %>%
  sample_n(5000)

cat("Đang chấm điểm Sentiment (có thể mất khoảng 1-2 phút)...\n")
# Dùng thuật toán 'syuzhet' (từ điển chuẩn) để lấy ra điểm số tích cực/tiêu cực
# Điểm > 0: Tích cực
# Điểm < 0: Tiêu cực
sentiment_scores <- get_sentiment(sample_reviews$comments, method = "syuzhet")

# Gắn điểm vào bảng dữ liệu
sample_reviews$sentiment_score <- sentiment_scores
sample_reviews <- sample_reviews %>%
  mutate(sentiment_label = case_when(
    sentiment_score > 0 ~ "Positive",
    sentiment_score < 0 ~ "Negative",
    TRUE ~ "Neutral"
  ))

cat("Hoàn thành! Thống kê kết quả:\n")
print(table(sample_reviews$sentiment_label))

# Xuất ra file kết quả để làm bằng chứng báo cáo
output_path <- "../../data/sample_sentiment_results.csv"
write_csv(sample_reviews, output_path)

cat("\nĐã xuất kết quả phân tích cảm xúc ra file:", output_path, "\n")
cat("Thành công! Bạn có thể dùng kết quả này để chụp ảnh cho phần Báo Cáo.\n")
