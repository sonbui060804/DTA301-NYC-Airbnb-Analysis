# Đồng bộ phân tích Airbnb với tài liệu Phase 1 và 2

**Mục tiêu:** Sửa các sai lệch đã được người dùng yêu cầu sau bản đối chiếu với `DTA301_Group_4_Phase_1_2_gia_thuyet_don_gian.docx`.

**Cách thực hiện:** Giữ ngôn ngữ R và quy tắc listings hiện có. Dùng các hàm chung có kiểm thử cho làm sạch reviews, so sánh giả thuyết và mã hóa đặc trưng; notebook gọi cùng script để tránh hai phiên bản thuật toán. Không sửa tài liệu Word, không commit.

**Ràng buộc:** UTF-8 không BOM; chú thích tiếng Việt; ID dạng chuỗi; giá trong (0, 2000], số đêm trong (0, 365]; giả thuyết chỉ mô tả trung vị/boxplot; không suy diễn quan hệ nhân quả.

**Giới hạn nguồn:** Thiếu reviews gốc. Cho phép chạy từ reviews đã làm sạch sẵn, nhưng ghi rõ dữ liệu đã bị bộ lọc cũ loại bình luận dưới bốn từ và không thể khôi phục chúng. Không tải snapshot mới thay thế âm thầm.

## Công việc và kiểm chứng

- [x] Kiểm thử trước: giữ review ngắn hợp lệ trên ba ký tự, bỏ HTML/NA, bảo toàn ID dài; nhóm đúng ba giả thuyết; mã hóa neighbourhood chưa thấy ở train mà không dùng thống kê test.
- [x] Chuẩn hóa đường dẫn và kiểm tra dữ liệu đầu vào; xuất thống kê missing/duplicate và nguồn reviews.
- [x] Tạo bảng trung vị và ba boxplot từ toàn bộ listings sạch.
- [x] Regression dùng neighbourhood_group, neighbourhood, room_type, accommodates, stay_type, number_of_reviews, reviews_per_month, availability_365; chia train/test trước khi mã hóa và đánh giá thêm baseline.
- [x] K-means gồm giá, tọa độ, số review và room_type mã hóa; chuẩn hóa, chọn K=2..8 bằng Silhouette trên mẫu cố định, xuất Elbow và bảng mô tả cụm trên toàn bộ dữ liệu.
- [x] Reviews: chuẩn hóa HTML, bỏ tối đa ba ký tự, lọc tiếng Anh bằng cld2; tạo TF-IDF theo listing, so sánh rating=5 và rating<4,5; cảm xúc là kết quả bổ sung trên mẫu có ghi cỡ mẫu.
- [x] Đồng bộ notebook và README; chạy kiểm thử, pipeline với dữ liệu hiện có; kiểm tra ảnh, đầu ra và UTF-8.

## Trọng tâm kiểm tra

- Thiếu reviews gốc: báo hạn chế, không ghi đè dữ liệu nguồn cũ.
- Nhóm rating không đủ văn bản: dừng với thông báo cụ thể.
- Listing ID dài: không chuyển sang double khi join.
- Categorical test chưa thấy: ánh xạ nhóm dự phòng, không làm predict lỗi.
- Dữ liệu quá ít hoặc rỗng: báo rõ trước khi lấy mẫu, chọn K hoặc huấn luyện.

## Kết quả kiểm chứng

- Kiểm thử R đã quan sát fail khi thiếu logic, sau sửa PASS cho reviews, ngày không hợp lệ, giả thuyết, one-hot và TF-IDF.
- Chạy các bước listings, reviews, chuẩn bị đặc trưng, EDA, K-means, Random Forest và NLP thành công trên dữ liệu hiện có.
- Kiểm chứng độc lập từ CSV: 21.350 listings sạch, 701.867 reviews tiếng Anh, 4.270 dự đoán holdout; MAE 99,11097 USD so với baseline 147,61092 USD; K=6.
- Review độc lập không phát hiện lỗi correctness/leakage quan trọng; đã sửa chú thích phân biệt số nhóm rating gốc và sạch.
- Số rating 6.606/2.868 thuộc listings gốc; sạch là 4.171/2.079; mẫu NLP là 4.007/1.998.
- Kiểm tra trực quan 11 biểu đồ, UTF-8 không BOM, cú pháp R và git diff --check đều đạt.
- Notebook đã bỏ output cũ và dùng script chung đã chạy; không khởi chạy Jupyter/R kernel riêng.
- Giới hạn còn lại: thiếu reviews gốc cùng snapshot nên không khôi phục được các bình luận ngắn nguồn cũ đã loại. Đã công bố trong README và provenance.
- Không commit, không sửa tài liệu Word hoặc dữ liệu reviews nguồn.

## Sự cố Rscript và cách ngăn lặp lại

- Lệnh kiểm tra cuối từng gọi `tests/test_analysis.R` từ checkout ngoài, nơi không có file này. Đây là lỗi đường dẫn khi thực thi.
- Tái hiện có tắt hộp thoại lỗi chỉ trong tiến trình chẩn đoán: cả launcher và binary x64 của Rscript đều trả -1073741819 (0xC0000005) khi script không tồn tại. Chạy đúng đường dẫn kiểm thử PASS.
- Thêm `run_analysis.ps1` ở gốc để xác nhận mọi đường dẫn trước khi gọi R, chọn đúng thư mục dự án và khôi phục locale sau khi chạy.
- Đã chạy wrapper Checks thành công và kiểm tra fixture thiếu script bị chặn trước khi gọi Rscript.
