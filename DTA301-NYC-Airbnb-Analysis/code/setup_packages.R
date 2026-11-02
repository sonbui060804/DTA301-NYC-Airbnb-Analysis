# Cài một lần vào thư mục dự án; không thay đổi thư viện R dùng cho dự án khác.
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

dir.create(local_library, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(local_library, .libPaths()))
packages <- c("dplyr", "readr", "tidyr", "ggplot2", "randomForest", "cluster",
              "tm", "wordcloud", "syuzhet", "cld2", "xml2", "slam", "stringi")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, lib = local_library, repos = "https://cloud.r-project.org")
require_packages(packages)
cat("Đã có đủ thư viện R cần thiết.\n")
