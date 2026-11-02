# DTA301 NYC Airbnb Data Analysis

Dự án phân tích Airbnb tại New York theo tài liệu `DTA301_Group_4_Phase_1_2_gia_thuyet_don_gian.docx`: định giá, phân khúc thị trường và phân tích phản hồi. Dữ liệu listings thuộc snapshot tháng 06/2026, scrape từ 14–23/06/2026.

## Cấu trúc thư mục

- `code/01_Data_Cleaning/`: Làm sạch listings và reviews, xuất thống kê chất lượng.
- `code/02_Feature_Engineering/`: Tạo `stay_type`, `has_reviews` và đặc trưng ngày.
- `code/03_EDA/`: Phân bố giá, bản đồ và ba giả thuyết đơn giản.
- `code/04_Modeling/`: Random Forest, K-means, TF-IDF và cảm xúc bổ sung.
- `code/analysis_helpers.R`: Quy tắc chung được dùng bởi cả script và kiểm thử.
- `data/`: Dữ liệu đầu vào và dữ liệu đã chuẩn bị.
- `report/tables/`: Bảng kết quả, chỉ số đánh giá, nguồn và giới hạn dữ liệu.
- `report/images/`: Biểu đồ từ lần chạy thực tế.
- `tests/test_analysis.R`: Kiểm thử quy tắc reviews, giả thuyết, mã hóa và TF-IDF.

## Chạy quy trình

Từ thư mục checkout ngoài cùng, có thể dùng PowerShell 7 để tự kiểm tra đường dẫn và locale trước khi gọi R:

```powershell
pwsh -File .\run_analysis.ps1
pwsh -File .\run_analysis.ps1 -Stage All
```

Lệnh đầu chỉ chạy kiểm thử; lệnh thứ hai chạy lại toàn bộ pipeline và ghi lại các đầu ra. Cài thư viện ở bước setup bên dưới trước nếu máy chưa có. Wrapper kiểm tra file tồn tại trước khi gọi R vì bản Rscript trên máy đã được xác nhận crash với mã `0xC0000005` khi đường dẫn script không tồn tại.

Các lệnh dưới đây chạy từ thư mục dự án bên trong, nơi có `code/`, `data/`, `report/`. Dùng R hỗ trợ UTF-8 và có `Rscript` trong PATH; nếu chưa có, gọi đường dẫn đầy đủ tới Rscript. Script cũng hỗ trợ chạy bằng đường dẫn tuyệt đối từ thư mục khác.

```powershell
Rscript code/setup_packages.R
Rscript tests/test_analysis.R
Rscript code/01_Data_Cleaning/01_data_cleaning.R
Rscript code/01_Data_Cleaning/01b_clean_reviews.R
Rscript code/02_Feature_Engineering/prepare_airbnb_model.R
Rscript code/03_EDA/03_EDA_Visualization.R
Rscript code/04_Modeling/04_Modeling.R
Rscript code/04_Modeling/04_Sentiment_Analysis.R
```

`setup_packages.R` cài những gói còn thiếu vào `.r-library/` của dự án; cần kết nối mạng ở bước này. Các bước phân tích không tự cài gói. Thư viện gồm `dplyr`, `readr`, `tidyr`, `ggplot2`, `randomForest`, `cluster`, `tm`, `wordcloud`, `syuzhet`, `cld2`, `xml2`, `slam`, `stringi`. Không đặt locale ASCII `C` cho quá trình đọc code tiếng Việt.

Hai notebook dùng R kernel và gọi cùng script R; không còn chứa thuật toán sao chép hoặc output cũ. Nếu cần dùng Jupyter, cài và đăng ký `IRkernel` trong môi trường Jupyter của bạn trước. Các bảng/ảnh mới được xuất khi chạy cell, thay vì giữ kết luận viết sẵn.

## Nguồn reviews và giới hạn tái tạo

**Checkout hiện tại thiếu `reviews.csv` và `reviews.csv.xz` gốc.** `01b_clean_reviews.R` ưu tiên `data/reviews.csv.xz`, `data/reviews.csv`, rồi `data/reviews.csv.gz`. Nếu đều thiếu, script dùng `cleaned_reviews.csv.xz` hiện có và ghi `source_status=legacy_precleaned` vào `reviews_preparation.csv`.

Nguồn dự phòng đã bị code cũ loại bình luận dưới bốn từ. Không thể khôi phục những dòng đó từ file hiện có. Muốn tái tạo hoàn toàn bước chuẩn bị reviews từ tài liệu, bổ sung **reviews gốc đúng snapshot tháng 06/2026** rồi chạy lại từ bước 01b; không thay bằng snapshot mới khác thời điểm.

Code mới bỏ nội dung trống/NA hoặc tối đa ba **ký tự**, loại thông báo tự động và ngày không hợp lệ, bỏ HTML, giải mã thực thể HTML, chuyển chữ thường và lọc tiếng Anh bằng `cld2`. Ngôn ngữ không xác định cũng bị loại. Đầu ra là `prepared_reviews.csv.xz`; không ghi đè nguồn reviews sạch cũ. Các bước lọc bổ sung được ghi trong code và số lượng được xuất trong `reviews_preparation.csv`.

## Cách đối chiếu với tài liệu

### Ba giả thuyết nghiên cứu

`hypothesis_price_summary.csv` và ba ảnh `Hypothesis_H*_Boxplot.png` sử dụng toàn bộ listings sạch:

1. Manhattan so với ngoài Manhattan.
2. Entire home/apt so với Private room; không đưa Hotel room/Shared room vào phép so sánh này.
3. `minimum_nights >= 30` so với `< 30`.

Đây là so sánh số lượng, trung vị và biểu đồ hộp. Không tự bác bỏ H0, không diễn giải thành quan hệ nhân quả. Histogram chỉ thu hẹp vùng hiển thị dưới 1.000 USD, không loại những giá hợp lệ 1.000–2.000 USD khỏi giả thuyết hoặc mô hình.

### Regression

Random Forest dùng `neighbourhood_group`, `neighbourhood`, `room_type`, `accommodates`, `stay_type`, `number_of_reviews`, `reviews_per_month`, `availability_365`. `stay_type` thay `minimum_nights` đúng tài liệu. Không đưa `id`, giá mục tiêu hoặc điểm cảm xúc vào đầu vào mô hình.

Chia ngẫu nhiên 80/20 với seed 42 trên toàn bộ listings sạch, học mức phân loại và trung vị điền NA chỉ từ train. Mã hóa one-hot tránh giới hạn factor nhiều mức của Random Forest; mức mới trong test được ánh xạ `OTHER`. Mô hình dùng 150 cây. `regression_metrics.csv` ghi MAE, RMSE, R² và baseline trung vị train; `regression_predictions.csv` giữ ID để truy vết. Kết quả holdout chưa phải xác nhận trên snapshot tương lai và chưa chứng minh mức giá tối ưu doanh thu.

### K-means

Dùng giá, tọa độ, số lượng reviews và loại phòng đã one-hot; loại cột hằng rồi chuẩn hóa. Thử K=2..8, chọn Silhouette cao nhất trên mẫu cố định tối đa 2.000 listing để giới hạn chi phí khoảng cách từng cặp. Xuất cả Elbow/Silhouette, sau đó khớp K đã chọn trên toàn bộ dữ liệu.

Xem `kmeans_k_selection.csv`, `kmeans_run.csv`, `cluster_profiles.csv`, `cluster_room_types.csv`, `listing_clusters.csv`. Diễn giải cụm dựa trên bảng thống kê thực tế; số thứ tự cụm không tự mang ý nghĩa “giá rẻ” hoặc “cao cấp”.

### NLP và TF-IDF

Gộp reviews tiếng Anh theo listing thành tài liệu, token hóa và bỏ stop words, số, dấu câu. Công thức: `TF = số lần xuất hiện / tổng token của listing`, `IDF = log(số listing / số listing chứa từ)`. Lưu ma trận thưa vào `listing_tfidf.rds` cùng thứ tự ID và từ vựng.

So sánh TF-IDF trung bình theo listing giữa nhóm `review_scores_rating = 5.0` và `< 4.5`; không chia theo trung vị rating. `tfidf_group_sizes.csv` ghi cả số listing đủ điều kiện trong dữ liệu sạch và số thực sự có reviews tiếng Anh, vì hai số này có thể khác nhau. `tfidf_rating_top_terms.csv` và `tfidf_rating_contrast.csv` hỗ trợ tìm chủ đề đáng khảo sát, không tự chứng minh nguyên nhân hài lòng.

Wordcloud minh họa tần suất từ; không thay thế TF-IDF. `syuzhet` chấm cảm xúc trên mẫu tối đa 5.000 reviews tiếng Anh với seed 42, xuất `sample_sentiment_results.csv` và `sentiment_summary.csv`. Điểm từ điển có thể sai khi gặp phủ định, mỉa mai hoặc ngữ cảnh; không suy rộng từ mẫu thành chất lượng toàn thị trường.
