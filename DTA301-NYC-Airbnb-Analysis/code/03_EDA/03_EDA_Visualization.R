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
print(p1)

# ------------------------------------------------------------------------------
# 2. Bản đồ mật độ Airbnb tại New York
# ------------------------------------------------------------------------------
p2 <- ggplot(listings, aes(x = longitude, y = latitude, color = neighbourhood_group)) +
  geom_point(alpha = 0.6, size = 0.5) +
  theme_minimal() +
  guides(color = guide_legend(override.aes = list(size = 3))) +
  labs(title = "Bản đồ Vị trí các phòng Airbnb tại NYC",
       x = "Kinh độ", y = "Vĩ độ", color = "Quận")
print(p2)

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

wordcloud(corpus, max.words = 100, random.order = FALSE, colors = brewer.pal(8, "Dark2"))
