# ==============================================================================
# PHASE 3: Khám phá và Trực quan hóa dữ liệu (EDA)
# ==============================================================================
options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")
if (!require(wordcloud)) install.packages("wordcloud")
if (!require(tm)) install.packages("tm")

library(ggplot2)
library(dplyr)
library(readr)

# ------------------------------------------------------------------------------
# 1. Phân bố giá phòng
# ------------------------------------------------------------------------------
listings <- read_csv('../../data/cleaned_listings.csv', show_col_types = FALSE)

p1 <- ggplot(listings, aes(x = price)) +
  geom_histogram(fill = "skyblue", color = "black", bins = 50) +
  coord_cartesian(xlim = c(0, 1000)) +
  theme_minimal() +
  labs(title = "Phân bố giá phòng Airbnb tại NYC (Dưới $1000)",
       x = "Giá (USD)", y = "Số lượng phòng")

# Lưu biểu đồ 1 thành ảnh
dir.create("../../report/images", showWarnings = FALSE, recursive = TRUE)
ggsave("../../report/images/01_Price_Distribution.png", plot = p1, width = 8, height = 5, dpi = 300)
cat("Đã lưu biểu đồ 1 tại: report/images/01_Price_Distribution.png\n")

# ------------------------------------------------------------------------------
# 2. Bản đồ mật độ Airbnb tại New York
# ------------------------------------------------------------------------------
p2 <- ggplot(listings, aes(x = longitude, y = latitude, color = neighbourhood_group)) +
  geom_point(alpha = 0.6, size = 0.5) +
  theme_minimal() +
  guides(color = guide_legend(override.aes = list(size = 3))) +
  labs(title = "Bản đồ Vị trí các phòng Airbnb tại NYC",
       x = "Kinh độ", y = "Vĩ độ", color = "Quận")

# Lưu biểu đồ 2 thành ảnh
ggsave("../../report/images/02_Map_Density.png", plot = p2, width = 10, height = 8, dpi = 300)
cat("Đã lưu biểu đồ 2 tại: report/images/02_Map_Density.png\n")

# ------------------------------------------------------------------------------
# 3. Wordcloud - Từ khóa đánh giá
# ------------------------------------------------------------------------------
library(wordcloud)
library(tm)

reviews <- read_csv('../../data/cleaned_reviews.csv.xz', show_col_types = FALSE)

set.seed(42)
sample_reviews <- reviews %>% 
  filter(!is.na(comments)) %>% 
  sample_n(20000)

corpus <- Corpus(VectorSource(sample_reviews$comments))
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, removeWords, stopwords("english"))

# Lưu Wordcloud thành ảnh
png("../../report/images/03_Wordcloud_Reviews.png", width = 800, height = 600, res = 150)
wordcloud(corpus, max.words = 100, random.order = FALSE, colors = brewer.pal(8, "Dark2"))
dev.off()
cat("Đã lưu biểu đồ 3 tại: report/images/03_Wordcloud_Reviews.png\n")
cat("\nHoàn thành! Bạn hãy vào thư mục report/images/ để xem các hình ảnh nhé.\n")
