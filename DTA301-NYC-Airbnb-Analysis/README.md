# DTA301 NYC Airbnb Data Analysis

Dự án phân tích dữ liệu Airbnb tại New York (NYC), tập trung giải quyết 3 bài toán kinh doanh lõi (Pricing Strategy, Market Positioning, Customer Satisfaction).

## Cấu trúc thư mục (Directory Structure)
Dự án áp dụng chặt chẽ 6 giai đoạn của **Data Analytics Lifecycle**, với mã nguồn (code) được chia thành các thư mục tương ứng với từng giai đoạn (Phase) để dễ quản lý:

* 📁 **`code/`**: Chứa toàn bộ kịch bản và mã nguồn phân tích
  * `01_Data_Cleaning/`: Xử lý dị biệt (Outliers) và giá trị khuyết (Missing Values) cho dữ liệu Listings và Reviews.
  * `02_Feature_Engineering/`: Chuyển đổi dữ liệu và chuẩn bị ma trận đặc trưng cho các mô hình Machine Learning.
  * `03_EDA/`: Khám phá và trực quan hóa dữ liệu (Các biểu đồ vẽ bằng Jupyter Notebook `.ipynb`).
  * `04_Modeling/`: Triển khai các thuật toán học máy (Regression, K-Means Clustering, NLP Sentiment Analysis).

* 📁 **`data/`**: Chứa các tệp dữ liệu thô và dữ liệu đã làm sạch (`listings.csv`, `reviews.csv`, `cleaned_listings.csv`, `cleaned_reviews.csv.xz`, `airbnb_model_ready.csv`).
* 📁 **`report/`**: Chứa tài liệu báo cáo phân tích tổng quan cho các giai đoạn (Phase 1 & 2).

## Hướng dẫn sử dụng (How to use)

### 1. Tiền xử lý dữ liệu (Data Cleaning & Feature Engineering)
Chạy lần lượt các script R trong môi trường làm việc `code/`:
```bash
# Di chuyển vào thư mục code
cd code/01_Data_Cleaning
Rscript 01_data_cleaning.R
Rscript 01b_clean_reviews.R

cd ../02_Feature_Engineering
Rscript prepare_airbnb_model.R
```

### 2. Trực quan hoá dữ liệu (EDA) và Máy học (Modeling)
Phần biểu đồ và Máy học được thực hiện trên **Jupyter Notebook (`.ipynb`)** với ngôn ngữ **R**.

Mở các file sau bằng VSCode, Jupyter Lab hoặc Google Colab (với R Kernel) và chạy từng ô (Run All):
* `code/03_EDA/03_EDA_Visualization.ipynb`: Xem bản đồ mật độ, biểu đồ giá phòng, và Wordcloud của các lượt đánh giá.
* `code/04_Modeling/04_Modeling.ipynb`: Mô hình Hồi quy dự đoán giá, Phân cụm nhóm khách hàng, và Xử lý ngôn ngữ tự nhiên.

## Phụ thuộc (Dependencies)
Tất cả code đều sử dụng 100% ngôn ngữ R.
* **Tiền xử lý:** `dplyr`, `readr`, `tidyr`.
* **Trực quan hoá (EDA):** `ggplot2`, `wordcloud`, `tm`.
* **Máy học (Modeling):** `randomForest`, `caret`.
