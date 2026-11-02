# PHASE 4: SENTIMENT ANALYSIS (ĐÁNH GIÁ THÁI ĐỘ KHÁCH HÀNG)
# TF-IDF và so sánh hai nhóm rating là đầu ra chính; cảm xúc là phân tích bổ sung.
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

require_packages(c("dplyr", "readr", "ggplot2", "wordcloud", "syuzhet", "slam", "tm", "stringi"))
library(dplyr)
library(ggplot2)
if (!file.exists(data_path("prepared_reviews.csv.xz"))) {
  stop("Cần chạy code/01_Data_Cleaning/01b_clean_reviews.R trước để lọc tiếng Anh và HTML.")
}
reviews <- readr::read_csv(data_path("prepared_reviews.csv.xz"),
  col_types = readr::cols(listing_id = readr::col_character(), review_id = readr::col_character()),
  show_col_types = FALSE)
listings <- read_listings()
assert_unique_id(listings$id, "Listings sạch")
if (!nrow(reviews)) stop("Không có reviews đã chuẩn hóa để phân tích.")

# Một tài liệu TF-IDF là toàn bộ reviews tiếng Anh của một listing.
# Nhờ vậy mỗi listing có trọng số bằng nhau khi so sánh rating, tránh listing nhiều
# reviews lấn át các listing khác. Không chọn hai nhóm theo trung vị điểm.
documents <- reviews %>% group_by(listing_id) %>%
  summarise(text = paste(comments, collapse = " "), review_count = n(), .groups = "drop") %>%
  left_join(listings %>% select(id, review_scores_rating), by = c("listing_id" = "id"))
tokens <- tokenize_english(documents$text)
nonempty <- lengths(tokens) > 0
documents <- documents[nonempty, ]
tokens <- tokens[nonempty]
tfidf <- build_tfidf(tokens)
# Lưu ma trận thưa kèm thứ tự listing_id và từ vựng để có thể kiểm tra lại phép tính.
saveRDS(list(matrix = tfidf, listing_id = documents$listing_id,
             formula = "TF=count/total tokens per listing; IDF=log(N/df)"),
        file.path(project_root, "report", "tables", "listing_tfidf.rds"))

# Gộp trọng số thưa trực tiếp, không chuyển toàn ma trận sang dense.
# Tổng/mean đều tính theo mọi listing trong nhóm, kể cả listing không có từ đó.
high <- which(documents$review_scores_rating == 5 & !is.na(documents$review_scores_rating))
low <- which(documents$review_scores_rating < 4.5 & !is.na(documents$review_scores_rating))
terms_all <- tfidf_term_summary(tfidf, seq_len(nrow(documents)), "All English-review listings")
terms_high <- tfidf_term_summary(tfidf, high, "Rating = 5.0")
terms_low <- tfidf_term_summary(tfidf, low, "Rating < 4.5")
readr::write_csv(head(terms_all, 100), table_path("tfidf_top_terms.csv"))
readr::write_csv(rbind(head(terms_high, 100), head(terms_low, 100)), table_path("tfidf_rating_top_terms.csv"))
contrast <- merge(terms_high[, c("term", "mean_tfidf")], terms_low[, c("term", "mean_tfidf")],
                  by = "term", all = TRUE, suffixes = c("_high", "_low"))
contrast[is.na(contrast)] <- 0
contrast$high_minus_low <- contrast$mean_tfidf_high - contrast$mean_tfidf_low
readr::write_csv(contrast[order(-abs(contrast$high_minus_low)), ], table_path("tfidf_rating_contrast.csv"))
# Số nhóm nêu trong tài liệu được tính trên listings gốc, trước khi lọc giá.
# Xuất cả ba phạm vi để không nhầm số gốc với số sạch hoặc số có review tiếng Anh.
raw_ratings <- readr::read_csv(data_path("listings.csv"),
  col_select = "review_scores_rating", show_col_types = FALSE)$review_scores_rating
readr::write_csv(data.frame(
  group = c("Rating = 5.0", "Rating < 4.5"),
  raw_listings = c(sum(raw_ratings == 5, na.rm = TRUE), sum(raw_ratings < 4.5, na.rm = TRUE)),
  eligible_clean_listings = c(sum(listings$review_scores_rating == 5, na.rm = TRUE),
                             sum(listings$review_scores_rating < 4.5, na.rm = TRUE)),
  english_review_listings = c(length(high), length(low)),
  english_reviews = c(sum(documents$review_count[high]), sum(documents$review_count[low]))
), table_path("tfidf_group_sizes.csv"))

plot_terms <- rbind(head(terms_high, 15), head(terms_low, 15))
plot_terms$key <- paste(plot_terms$group, plot_terms$term, sep = ": ")
p <- ggplot(plot_terms, aes(x = reorder(key, mean_tfidf), y = mean_tfidf, fill = group)) +
  geom_col(show.legend = FALSE) + coord_flip() + facet_wrap(~group, scales = "free_y") +
  theme_minimal() + labs(title = "Từ khóa TF-IDF theo nhóm điểm đánh giá", x = NULL, y = "TF-IDF trung bình mỗi listing")
ggsave(image_path("TFIDF_Rating_Comparison.png"), p, width = 13, height = 7, dpi = 150)

# Wordcloud minh họa tần suất, không thay thế TF-IDF; dùng cùng corpus tiếng Anh.
frequency <- table(unlist(tokens, use.names = FALSE))
frequency <- sort(frequency, decreasing = TRUE)
png(image_path("03_Wordcloud_Reviews.png"), width = 1200, height = 800, res = 150)
set.seed(42)
wordcloud::wordcloud(names(frequency), as.numeric(frequency), max.words = 100,
                     random.order = FALSE, colors = RColorBrewer::brewer.pal(8, "Dark2"))
dev.off()

# Chấm cảm xúc trên mẫu tối đa 5.000 reviews; không suy rộng thành chất lượng toàn thị trường.
set.seed(42)
sample_reviews <- reviews[sample(seq_len(nrow(reviews)), min(5000, nrow(reviews))), ]
sample_reviews$sentiment_score <- syuzhet::get_sentiment(sample_reviews$comments, method = "syuzhet")
sample_reviews <- sample_reviews %>% mutate(sentiment_label = case_when(
  sentiment_score > 0 ~ "Positive", sentiment_score < 0 ~ "Negative", TRUE ~ "Neutral"))
readr::write_csv(sample_reviews, data_path("sample_sentiment_results.csv"))
sentiment_summary <- sample_reviews %>% count(sentiment_label) %>% mutate(proportion = n / sum(n))
readr::write_csv(sentiment_summary, table_path("sentiment_summary.csv"))
p <- ggplot(sample_reviews, aes(sentiment_label, fill = sentiment_label)) + geom_bar(color = "black") +
  theme_minimal() + scale_fill_manual(values = c(Negative = "tomato", Neutral = "gray", Positive = "palegreen")) +
  labs(title = "Phân bố cảm xúc của khách hàng (Sentiment Analysis)",
       subtitle = paste("Mẫu", nrow(sample_reviews), "reviews tiếng Anh; điểm từ điển có thể sai ngữ cảnh"),
       x = "Cảm xúc", y = "Số lượng bình luận")
ggsave(image_path("Sentiment_Distribution.png"), p, width = 9, height = 5, dpi = 150)
cat("Hoàn thành! Thống kê kết quả:\n")
print(sentiment_summary)
cat("Đã xuất TF-IDF, đối chiếu hai nhóm rating và kết quả cảm xúc bổ sung.\n")
