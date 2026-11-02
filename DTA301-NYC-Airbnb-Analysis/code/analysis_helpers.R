# Các hàm chung bảo đảm script và notebook áp dụng cùng quy tắc trong báo cáo.
# Không chạy mô hình hoặc ghi dữ liệu khi source file này để có thể kiểm thử riêng.

# Tìm gốc dự án từ thư mục hiện tại hoặc đường dẫn Rscript, kể cả checkout lồng nhau.
find_project_root <- function() {
  script <- grep("^--file=", commandArgs(), value = TRUE)
  origins <- c(getwd(), if (length(script)) dirname(sub("^--file=", "", script[1])))
  for (origin in origins) {
    current <- normalizePath(origin, winslash = "/", mustWork = TRUE)
    repeat {
      candidates <- c(current, file.path(current, "DTA301-NYC-Airbnb-Analysis"))
      for (candidate in candidates) {
        if (file.exists(file.path(candidate, "code", "analysis_helpers.R"))) return(candidate)
      }
      parent <- dirname(current)
      if (parent == current) break
      current <- parent
    }
  }
  stop("Không tìm thấy thư mục dự án có code/analysis_helpers.R.")
}

project_root <- find_project_root()
local_library <- file.path(project_root, ".r-library")
if (dir.exists(local_library)) .libPaths(c(local_library, .libPaths()))

# Kiểm tra phụ thuộc trước khi xử lý; không âm thầm cài package giữa một lần phân tích.
require_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop("Thiếu thư viện: ", paste(missing, collapse = ", "),
                            ". Hãy chạy Rscript code/setup_packages.R trước.")
}

data_path <- function(name) file.path(project_root, "data", name)
table_path <- function(name) {
  folder <- file.path(project_root, "report", "tables")
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  file.path(folder, name)
}
image_path <- function(name) {
  folder <- file.path(project_root, "report", "images")
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  file.path(folder, name)
}

# Khóa 19 chữ số phải là character từ lúc đọc để không làm tròn trước phép join.
read_listings <- function(name = "cleaned_listings.csv") {
  require_packages("readr")
  readr::read_csv(data_path(name), col_types = readr::cols(id = readr::col_character()),
                 show_col_types = FALSE)
}

# Kiểm tra khóa, không xóa theo listing_id vì một listing có nhiều reviews hợp lệ.
assert_unique_id <- function(ids, label) {
  if (anyNA(ids) || any(!nzchar(ids)) || anyDuplicated(ids)) {
    stop(label, ": khóa bị thiếu hoặc trùng. Cần kiểm tra nguồn trước khi phân tích.")
  }
}

# Ghi tỷ lệ thiếu và số khóa trùng làm bằng chứng chất lượng dữ liệu, thay vì chỉ in log.
quality_summary <- function(data, key) {
  data.frame(column = names(data), n = nrow(data),
             missing = vapply(data, function(x) sum(is.na(x)), integer(1)),
             missing_pct = 100 * vapply(data, function(x) mean(is.na(x)), numeric(1)),
             duplicate_ids = sum(duplicated(data[[key]])), row.names = NULL)
}

# Chuẩn hóa HTML và thực thể HTML trước khi đếm ký tự, nhận dạng ngôn ngữ và token hóa.
# Dấu câu vẫn được giữ cho chấm cảm xúc; bộ token NLP sẽ loại chúng ở bước riêng.
normalize_review_text <- function(text) {
  require_packages(c("xml2", "stringi"))
  text <- gsub("<[^>]*>", " ", text)
  entity_rows <- which(!is.na(text) & grepl("&[^ ;]+;", text))
  if (length(entity_rows)) {
    values <- unique(text[entity_rows])
    decoded <- vapply(values, function(x) {
      xml2::xml_text(xml2::read_html(paste0("<html><body>", x, "</body></html>"),
                                   options = c("RECOVER", "NOERROR", "NOWARNING", "NONET")))
    }, character(1), USE.NAMES = FALSE)
    text[entity_rows] <- decoded[match(text[entity_rows], values)]
  }
  text <- stringi::stri_trans_tolower(text)
  trimws(gsub("[[:space:]\u00a0]+", " ", text))
}

# Quy tắc tài liệu: chỉ bỏ nội dung rỗng/NA hoặc tối đa ba ký tự, không đếm số từ.
# Chỉ giữ reviews thuộc listings sạch và có ngày hợp lệ để tránh ghép sai hoặc thiếu ngữ cảnh.
clean_review_rows <- function(reviews, valid_listing_ids) {
  if ("id" %in% names(reviews) && !"review_id" %in% names(reviews)) {
    names(reviews)[names(reviews) == "id"] <- "review_id"
  }
  reviews <- as.data.frame(reviews[, c("listing_id", "review_id", "date", "comments")])
  assert_unique_id(reviews$review_id, "Reviews")
  reviews$comments <- normalize_review_text(reviews$comments)
  keep <- reviews$listing_id %in% valid_listing_ids &
    !is.na(reviews$comments) & nchar(reviews$comments) > 3 &
    reviews$comments != "na" & !is.na(as.Date(reviews$date, format = "%Y-%m-%d")) &
    !grepl("automated posting|canceled this reservation", reviews$comments)
  reviews[keep, , drop = FALSE]
}

# Bảng mô tả ba giả thuyết: không tính p-value và không tự tuyên bố bác bỏ H0.
hypothesis_summary <- function(listings) {
  groups <- list(
    H1 = ifelse(listings$neighbourhood_group == "Manhattan", "Manhattan", "Outside Manhattan"),
    H2 = ifelse(listings$room_type %in% c("Entire home/apt", "Private room"),
                listings$room_type, NA_character_),
    H3 = ifelse(listings$minimum_nights >= 30, ">=30", "<30")
  )
  do.call(rbind, lapply(names(groups), function(h) {
    labels <- groups[[h]]
    do.call(rbind, lapply(sort(unique(labels[!is.na(labels)])), function(g) {
      values <- listings$price[which(labels == g)]
      data.frame(hypothesis = h, group = g, n = length(values),
                 median_price = median(values), mean_price = mean(values))
    }))
  }))
}

# Chỉ học mức phân loại và trung vị từ train; test chưa thấy được đưa vào OTHER.
# One-hot cho neighbourhood tránh giới hạn 53 mức của randomForest với factor.
encode_train_test <- function(train, test, categorical) {
  train <- as.data.frame(train)
  test <- as.data.frame(test)
  result_train <- list()
  result_test <- list()
  for (name in names(train)) {
    if (name %in% categorical) {
      levels_train <- sort(unique(as.character(train[[name]][!is.na(train[[name]])])))
      levels_train <- unique(c(levels_train, "OTHER"))
      tr <- as.character(train[[name]])
      te <- as.character(test[[name]])
      tr[is.na(tr)] <- "OTHER"
      te[is.na(te) | !te %in% levels_train] <- "OTHER"
      for (level in levels_train) {
        column <- paste(name, level, sep = "__")
        result_train[[column]] <- as.numeric(tr == level)
        result_test[[column]] <- as.numeric(te == level)
      }
    } else {
      replacement <- median(train[[name]], na.rm = TRUE)
      if (!is.finite(replacement)) stop("Biến train không có giá trị số hợp lệ: ", name)
      result_train[[name]] <- ifelse(is.na(train[[name]]), replacement, train[[name]])
      result_test[[name]] <- ifelse(is.na(test[[name]]), replacement, test[[name]])
    }
  }
  list(train = as.matrix(as.data.frame(result_train, check.names = FALSE)),
       test = as.matrix(as.data.frame(result_test, check.names = FALSE)))
}

# Mỗi phần tử là token của một listing. Dùng ma trận thưa để không cấp phát
# listing x toàn bộ từ vựng dưới dạng ma trận đặc; TF là tỷ lệ từ, IDF=log(N/df).
build_tfidf <- function(tokens) {
  require_packages("slam")
  counts <- lapply(tokens, table)
  terms <- sort(unique(unlist(lapply(counts, names), use.names = FALSE)))
  if (!length(terms)) stop("Không còn token để xây dựng TF-IDF.")
  i <- rep(seq_along(counts), lengths(counts))
  j <- match(unlist(lapply(counts, names), use.names = FALSE), terms)
  v <- as.numeric(unlist(counts, use.names = FALSE))
  doc_size <- vapply(tokens, length, integer(1))
  df <- tabulate(j, nbins = length(terms))
  weights <- v / doc_size[i] * log(length(tokens) / df[j])
  slam::simple_triplet_matrix(i, j, weights, nrow = length(tokens), ncol = length(terms),
                             dimnames = list(NULL, terms))
}

# Tính trung bình theo toàn bộ listing của nhóm, gồm cả listing không chứa từ.
# rowsum cộng trọng số thực; tabulate chỉ dùng đếm số tài liệu, không nhận weights.
tfidf_term_summary <- function(tfidf, rows, group) {
  if (!length(rows)) stop("Không có listing tiếng Anh trong nhóm rating: ", group)
  use <- tfidf$i %in% rows
  sums <- numeric(tfidf$ncol)
  if (any(use)) {
    grouped <- rowsum(tfidf$v[use], tfidf$j[use], reorder = FALSE)
    sums[as.integer(rownames(grouped))] <- grouped[, 1]
  }
  doc_frequency <- tabulate(tfidf$j[use], nbins = tfidf$ncol)
  out <- data.frame(group = group, term = tfidf$dimnames[[2]],
                    mean_tfidf = sums / length(rows), document_frequency = doc_frequency,
                    n_listings = length(rows))
  out <- out[out$mean_tfidf > 0, ]
  out[order(-out$mean_tfidf), ]
}

# Loại số, dấu câu và stop words tiếng Anh sau khi đã lọc ngôn ngữ.
tokenize_english <- function(text) {
  require_packages(c("stringi", "tm"))
  words <- stringi::stri_extract_all_regex(text, "[a-z]+", omit_no_match = TRUE)
  stop_words <- tm::stopwords("english")
  lapply(words, function(x) x[nchar(x) > 1 & !x %in% stop_words])
}
