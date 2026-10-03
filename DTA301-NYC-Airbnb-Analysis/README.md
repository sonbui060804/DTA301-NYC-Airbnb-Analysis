# PROJECT ROADMAP: NYC AIRBNB DATA ANALYSIS (R Language)

Dự án này tuân thủ chặt chẽ vòng đời phân tích dữ liệu (Data Analytics Lifecycle) sử dụng ngôn ngữ R. Dưới đây là lộ trình chi tiết từng bước sẽ thực hiện trong dự án.

## BƯỚC 1: DATA PREPARATION & CLEANING (TIỀN XỬ LÝ DỮ LIỆU)
**Mục tiêu:** Chuẩn bị dữ liệu sạch sẽ, không có lỗi trước khi đưa vào mô hình học máy.
* **1.1 Load dữ liệu:** Đọc 2 file `listings.csv` và `reviews.csv` (bản chi tiết của Inside Airbnb, New York City, snapshot 06/2026) bằng thư viện `readr`.
  > **Lưu ý:** `reviews.csv` gốc nặng 310 MB, vượt giới hạn 100 MB/file của GitHub, nên repo lưu bản nén `data/reviews.csv.xz` (73 MB). Đọc trực tiếp bằng `read_csv("../data/reviews.csv.xz")`, không cần giải nén. Nguồn: http://insideairbnb.com/get-the-data/ (New York City).
* **1.2 Xử lý Missing Values:** Loại bỏ các dòng bị khuyết tọa độ (latitude/longitude), điền giá trị 0 cho các phòng chưa từng có đánh giá (reviews_per_month).
* **1.3 Lọc Outliers (Giá trị dị biệt):** Lọc bỏ các phòng có mức giá (`price`) = 0 hoặc quá lớn một cách phi lý. Lọc bỏ số đêm tối thiểu (`minimum_nights`) > 365.
* **1.4 Merge Data:** File listings chi tiết đã có sẵn `first_review`, `last_review` và số lượng review, nên chưa cần join reviews ở bước này. Điểm cảm xúc (sentiment) của từng listing sẽ được join từ reviews sang listings bằng `dplyr` sau Bước 3.

## BƯỚC 2: EXPLORATORY DATA ANALYSIS - EDA (KHÁM PHÁ DỮ LIỆU)
**Mục tiêu:** Hiểu rõ bức tranh toàn cảnh và tìm ra các xu hướng ẩn (Insights).
* **2.1 Phân bố giá:** Vẽ biểu đồ Histogram xem giá phòng tập trung ở mức nào.
* **2.2 So sánh khu vực:** Vẽ Bar chart để so sánh giá thuê trung bình giữa 5 quận (Manhattan, Brooklyn, Queens, Bronx, Staten Island).
* **2.3 Phân tích loại phòng:** Phân tích tỷ lệ 4 loại phòng (Entire home/apt, Private room, Hotel room, Shared room) bằng Pie chart.
*(Thư viện sử dụng: `ggplot2`)*

## BƯỚC 3: TEXT ANALYSIS / NLP (PHÂN TÍCH VĂN BẢN)
**Mục tiêu:** Hiểu được khách hàng thích hay ghét điều gì qua các bình luận.
* **3.1 Tokenization:** Tách các câu bình luận trong `reviews.csv` thành từng từ đơn lẻ.
* **3.2 Stopwords Removal:** Bỏ các từ vô nghĩa (the, a, is, in...). Trước đó: bỏ cột `reviewer_name`, `reviewer_id`; xóa thẻ HTML `<br/>`; bỏ bình luận trống hoặc quá ngắn; lọc bình luận không phải tiếng Anh (gói `cld2`).
* **3.3 Sentiment Analysis:** Phân loại các từ thành Tích cực (Positive) và Tiêu cực (Negative).
* **3.4 Khai phá TF-IDF:** Tìm ra những từ khóa đặc trưng nhất tạo nên một phòng có đánh giá cao: so sánh nhóm `review_scores_rating` = 5.0 với nhóm < 4.5 (trung vị đã là 4.86 nên không chia theo trung vị).
*(Thư viện sử dụng: `tidytext`, `stringr`, `wordcloud`)*

## BƯỚC 4: K-MEANS CLUSTERING (PHÂN CỤM KHÁCH HÀNG/PHÒNG)
**Mục tiêu:** Chia thị trường Airbnb thành các phân khúc khác nhau.
* **4.1 Chọn biến (Feature Selection):** Lấy các cột `price`, `latitude`, `longitude`, `number_of_reviews`.
* **4.2 Chuẩn hóa dữ liệu (Scaling):** Đưa các biến về cùng một thang đo bằng hàm `scale()`.
* **4.3 Chạy K-means:** Thử nghiệm K = 3 hoặc K = 4.
* **4.4 Phân tích Cụm:** Đặt tên cho từng phân khúc (Ví dụ: "Phân khúc siêu sang ở Manhattan", "Phân khúc giá rẻ ở ngoại ô").

## BƯỚC 5: LINEAR REGRESSION (MÔ HÌNH HỒI QUY DỰ ĐOÁN GIÁ)
**Mục tiêu:** Xây dựng phương trình toán học để dự đoán giá thuê phòng.
* **5.1 Split Data:** Chia tập dữ liệu thành Train set (80%) và Test set (20%).
* **5.2 Khởi tạo mô hình:** Dùng hàm `lm()` với biến phụ thuộc là `price` và biến độc lập là `neighbourhood_group`, `room_type`, `accommodates`, `stay_type` (ngắn hạn < 30 đêm / dài hạn >= 30 đêm, theo NYC Local Law 18; tạo trong `code/prepare_airbnb_model.R`).
* **5.3 Đánh giá mô hình:** Kiểm tra các chỉ số R-squared và P-value để xem biến nào tác động mạnh nhất đến giá phòng.

## BƯỚC 6: DATA VISUALIZATION & REPORTING (TRỰC QUAN HÓA & BÁO CÁO)
**Mục tiêu:** Trình bày kết quả trực quan cho các Stakeholders.
* **6.1 Export Kết quả:** Lưu các biểu đồ EDA, biểu đồ Phân cụm và kết quả Dự đoán ra file ảnh/csv.
* **6.2 Hoàn thiện báo cáo:** Đưa toàn bộ code, biểu đồ và insight vào Slide thuyết trình và báo cáo Word cuối cùng.
