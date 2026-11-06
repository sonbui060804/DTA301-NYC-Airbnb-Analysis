# BƯỚC 1b: DATA PREPARATION & CLEANING CHO REVIEWS
# Ưu tiên nguồn gốc; bản đã làm sạch cũ chỉ là nguồn thay thế có ghi giới hạn.
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

require_packages(c("readr", "cld2", "xml2", "stringi"))
listings <- read_listings()
raw_candidates <- data_path(c("reviews.csv.xz", "reviews.csv", "reviews.csv.gz"))
available <- raw_candidates[file.exists(raw_candidates)]
legacy_source <- !length(available)
if (legacy_source) {
  available <- data_path("cleaned_reviews.csv.xz")
  if (!file.exists(available)) stop("Thiếu reviews.csv/reviews.csv.xz và cả reviews sạch dự phòng.")
  warning("Đang dùng reviews sạch cũ: không khôi phục được bình luận dưới bốn từ đã bị loại. ",
          "Hãy bổ sung reviews gốc cùng snapshot để tái tạo đầy đủ.")
}
source_file <- available[1]
cat("Đang đọc file reviews:", basename(source_file), "\n")
reviews <- readr::read_csv(source_file,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE)
key <- if ("review_id" %in% names(reviews)) "review_id" else "id"
rev_quality <- quality_summary(reviews, key)
readr::write_csv(rev_quality, table_path("reviews_quality_source.csv"))
cat("\n--- BẢNG CHẤT LƯỢNG REVIEWS GỐC (reviews_quality_source.csv) ---\n")
print(rev_quality)
cleaned_reviews <- clean_review_rows(reviews, listings$id)

# Từ điển cảm xúc và stop words dùng tiếng Anh, nên lọc ngôn ngữ trước khi phân tích.
# Kết quả NA của cld2 là không xác định, không tự coi là tiếng Anh.
cat("Đang nhận dạng ngôn ngữ bằng cld2...\n")
language <- cld2::detect_language(cleaned_reviews$comments, plain_text = TRUE)
keep <- !is.na(language) & language == "en"
english_reviews <- cleaned_reviews[keep, , drop = FALSE]
if (!nrow(english_reviews)) stop("Không còn review tiếng Anh sau khi làm sạch.")
# Giữ nguyên cleaned_reviews.csv.xz cũ để không làm mất nguồn dự phòng.
readr::write_csv(english_reviews, data_path("prepared_reviews.csv.xz"))
prep_summary <- data.frame(
  source_file = basename(source_file),
  source_status = if (legacy_source) "legacy_precleaned" else "raw_snapshot",
  input_reviews = nrow(reviews), after_text_rules = nrow(cleaned_reviews),
  english_reviews = nrow(english_reviews),
  non_english_or_unknown = sum(!keep),
  limitation = if (legacy_source) "Nguồn cũ đã loại review dưới bốn từ; không thể khôi phục." else ""
)
readr::write_csv(prep_summary, table_path("reviews_preparation.csv"))
lang_table <- as.data.frame(table(language, useNA = "ifany"))
lang_table <- lang_table[order(-lang_table$Freq), ]
readr::write_csv(lang_table, table_path("review_languages.csv"))
cat("\n--- BẢNG THỐNG KÊ LÀM SẠCH REVIEWS (reviews_preparation.csv) ---\n")
print(prep_summary)
cat("\n--- TOP 10 NGÔN NGỮ TRONG REVIEWS (review_languages.csv) ---\n")
print(head(lang_table, 10))
cat("Số lượng dòng sau khi làm sạch:", nrow(english_reviews), "\n")
