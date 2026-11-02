# PHASE 3: Khám phá và Trực quan hóa dữ liệu (EDA)
# Ba giả thuyết dùng toàn bộ listings sạch, không lấy mẫu hoặc cắt bớt giá hợp lệ.
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

require_packages(c("ggplot2", "readr"))
library(ggplot2)
listings <- read_listings()
summary <- hypothesis_summary(listings)
readr::write_csv(summary, table_path("hypothesis_price_summary.csv"))
print(summary)
p1 <- ggplot(listings, aes(x = price)) +
  geom_histogram(fill = "skyblue", color = "black", bins = 50) +
  coord_cartesian(xlim = c(0, 1000)) + theme_minimal() +
  labs(title = "Phân bố giá phòng Airbnb tại NYC (Dưới $1000)",
       subtitle = "Chỉ giới hạn vùng hiển thị; dữ liệu sạch vẫn giữ giá đến 2.000 USD",
       x = "Giá (USD)", y = "Số lượng phòng")
ggsave(image_path("01_Price_Distribution.png"), p1, width = 8, height = 5, dpi = 150)
p2 <- ggplot(listings, aes(longitude, latitude, color = neighbourhood_group)) +
  geom_point(alpha = 0.6, size = 0.5) + theme_minimal() +
  guides(color = guide_legend(override.aes = list(size = 3))) +
  labs(title = "Bản đồ Vị trí các phòng Airbnb tại NYC", x = "Kinh độ", y = "Vĩ độ", color = "Quận")
ggsave(image_path("02_Map_Density.png"), p2, width = 10, height = 8, dpi = 150)

# Cùng quy tắc nhóm với bảng; H2 loại Hotel room và Shared room theo tài liệu.
comparisons <- list(
  H1 = data.frame(group = ifelse(listings$neighbourhood_group == "Manhattan", "Manhattan", "Outside Manhattan"), price = listings$price),
  H2 = data.frame(group = listings$room_type, price = listings$price)[listings$room_type %in% c("Entire home/apt", "Private room"), ],
  H3 = data.frame(group = ifelse(listings$minimum_nights >= 30, ">=30", "<30"), price = listings$price)
)
titles <- c(H1 = "Giá niêm yết theo vị trí", H2 = "Giá niêm yết theo loại phòng", H3 = "Giá niêm yết theo số đêm tối thiểu")
for (h in names(comparisons)) {
  p <- ggplot(comparisons[[h]], aes(group, price, fill = group)) +
    geom_boxplot(outlier.alpha = 0.15, show.legend = FALSE) + theme_minimal() +
    labs(title = titles[[h]], subtitle = "So sánh mô tả; chưa chứng minh quan hệ nhân quả",
         x = NULL, y = "Giá mỗi đêm (USD)")
  ggsave(image_path(paste0("Hypothesis_", h, "_Boxplot.png")), p, width = 9, height = 5, dpi = 150)
}
cat("Đã xuất bảng trung vị và ba biểu đồ hộp; không suy diễn bác bỏ H0.\n")
