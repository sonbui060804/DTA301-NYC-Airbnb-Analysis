# Kiểm thử quy tắc nghiệp vụ bằng dữ liệu nhỏ có kết quả tính tay.
# Chạy từ thư mục dự án: Rscript tests/test_analysis.R.
helper <- file.path("code", "analysis_helpers.R")
if (!file.exists(helper)) stop("Chưa có hàm phân tích chung để kiểm thử.")
source(helper, encoding = "UTF-8")

# Phản hồi bốn ký tự vẫn hợp lệ, kể cả chỉ có một từ; ID phải giữ đủ chữ số.
reviews <- data.frame(
  listing_id = rep("1234567890123456789", 6),
  review_id = as.character(1:6),
  date = rep("2026-06-14", 6),
  comments = c("Nice", "OK!", " NA ", "<br/>Great &amp; clean!", "   ", NA),
  stringsAsFactors = FALSE
)
clean <- clean_review_rows(reviews, "1234567890123456789")
stopifnot(identical(clean$review_id, c("1", "4")))
stopifnot(identical(clean$comments, c("nice", "great & clean!")))
stopifnot(all(clean$listing_id == "1234567890123456789"))

# Ngày đầu tiên bị lỗi cũng phải được loại, không làm toàn bộ quy trình dừng.
reviews$date[1] <- "bad-date"
clean_invalid_date <- clean_review_rows(reviews, "1234567890123456789")
stopifnot(identical(clean_invalid_date$review_id, "4"))

# Trung vị được tính trên đúng nhóm; hotel room không thuộc so sánh loại phòng.
listings <- data.frame(
  price = c(300, 500, 100, 200, 900),
  neighbourhood_group = c("Manhattan", "Manhattan", "Queens", "Queens", "Queens"),
  room_type = c("Entire home/apt", "Entire home/apt", "Private room", "Private room", "Hotel room"),
  minimum_nights = c(1, 29, 30, 60, 30)
)
h <- hypothesis_summary(listings)
stopifnot(h$median_price[h$hypothesis == "H1" & h$group == "Manhattan"] == 400)
stopifnot(h$median_price[h$hypothesis == "H2" & h$group == "Private room"] == 150)
stopifnot(sum(h$n[h$hypothesis == "H2"]) == 4)
stopifnot(h$median_price[h$hypothesis == "H3" & h$group == ">=30"] == 200)

# Mức neighbourhood mới chỉ xuất hiện trong test phải dự đoán được;
# trung vị điền NA phải học từ train, không lấy giá trị 1000 trong test.
train <- data.frame(neighbourhood = c("A", "B", "A"), accommodates = c(2, 4, NA))
test <- data.frame(neighbourhood = "NEW", accommodates = 1000)
encoded <- encode_train_test(train, test, "neighbourhood")
stopifnot(identical(colnames(encoded$train), colnames(encoded$test)))
stopifnot(all(is.finite(encoded$test)), encoded$train[3, "accommodates"] == 3)
stopifnot(encoded$test[1, "neighbourhood__OTHER"] == 1)

# Ma trận TF-IDF phải giảm trọng số từ xuất hiện trong mọi listing;
# 'clean' chỉ xuất hiện trong một tài liệu nên có trọng số dương.
tokens <- list(c("great", "clean"), c("great", "host"))
tfidf <- build_tfidf(tokens)
stopifnot(all(as.matrix(tfidf)[, "great"] == 0))
stopifnot(as.matrix(tfidf)[1, "clean"] > 0)
terms <- tfidf_term_summary(tfidf, 1:2, "Both")
stopifnot(abs(terms$mean_tfidf[terms$term == "clean"] - log(2) / 4) < 1e-12)
stopifnot(terms$document_frequency[terms$term == "clean"] == 1)
cat("PASS: quy tắc reviews, giả thuyết, mã hóa train/test và TF-IDF.\n")
