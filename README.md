BIBICA MARKET INTELLIGENCE 

Kho lưu trữ này tổng hợp dữ liệu gốc (Raw Data), mã nguồn truy vấn (SQL), kịch bản kiểm định (Python) và kế hoạch thực thi nhằm chứng minh tính khả thi cho các đề xuất chiến lược.

1. CẤU TRÚC DỮ LIỆU
Dữ liệu được tổ chức theo mô hình cơ sở dữ liệu quan hệ nhằm đảm bảo tính toàn vẹn:
- dbo.products.csv: Bảng dữ liệu chính chứa thông tin giao dịch, sản lượng, giá bán và mức chiết khấu.
- dbo.shop_info.csv: Bảng chứa thông tin phụ trợ (metadata) của các gian hàng.
- Các file category: Hệ thống phân loại danh mục sản phẩm của nền tảng.

2. TRUY VẾT CHỈ SỐ BẰNG SQL
File thực thi: analyze_by_sql.sql
Các chỉ số kinh doanh cốt lõi được trích xuất và đối soát trực tiếp từ dữ liệu gốc:
- Tỷ trọng doanh thu (Pareto 80/20): Dòng sản phẩm Quasure (ngách y tế) chiếm 21.9% tổng số lượng SKU nhưng đóng góp 71.9% tổng doanh thu của gian hàng Bibica.
- Phân tích hiệu quả giảm giá: Phân tích trên toàn thị trường cho thấy, nhóm sản phẩm giảm giá sâu (>40%) mang lại doanh thu trung bình 89.6 triệu/tháng. Trong khi đó, nhóm giữ giá tốt (chiết khấu <=40%) mang về 648 triệu/tháng (gấp 7.2 lần).

3. KIỂM ĐỊNH THỐNG KÊ (OLS REGRESSION)
File thực thi: hypothesis_testing.py
Sử dụng mô hình Hồi quy OLS (thư viện Statsmodels - Python) để đo lường độ nhạy cảm về giá (Price Elasticity).
- Kết quả kiểm định nhóm Quasure: p-value = 0.3216 (> 0.05).
- Kết luận: Mức chiết khấu không có tác động có ý nghĩa thống kê đến sản lượng bán ra. Khách hàng ngách y tế có độ cầu không co giãn (Inelastic Demand) với yếu tố giá.

4. ĐỀ XUẤT CHIẾN LƯỢC
Dựa trên kết quả kiểm định dữ liệu, nhóm đề xuất tập trung tối ưu lợi nhuận từ tệp khách hàng ngách thông qua 3 hành động:
- Chính sách Giá tĩnh (Static Pricing): Giới hạn trần chiết khấu tối đa cho dòng Quasure ở mức 20%. Từ chối tham gia các chiến dịch giảm giá sâu nhằm bảo vệ biên lợi nhuận và định vị sản phẩm.
- Tối ưu Giá trị đơn hàng (AOV): Dữ liệu cho thấy khách hàng có xu hướng mua tích trữ. Bibica cần tập trung đóng gói và truyền thông các mã Combo (2-3 hộp) thay vì giảm giá bán lẻ từng sản phẩm.
- Chuyển dịch ngân sách (Budget Shift): Cắt giảm chi phí khuyến mãi để tái đầu tư vào việc xây dựng bằng chứng xã hội (Social Proof). Cụ thể: Đồng bộ hình ảnh sản phẩm (Thumbnail) gắn logo Chứng nhận Viện Dinh Dưỡng, tạo rào cản chất lượng so với sản phẩm đại trà.

5. LỘ TRÌNH TRIỂN KHAI
- Tháng 1: Tái cấu trúc nhận diện hình ảnh. Cập nhật hệ thống Thumbnail y tế và thiết lập trần chiết khấu 20%.
- Tháng 2: Dồn ngân sách hiển thị vào các mã sản phẩm gộp (Giỏ quà biếu, Combo 3).
- Tháng 3: Đo lường hiệu quả. Phủ sóng kênh Siêu thị (MT) và Nhà thuốc; giảm dần sự phụ thuộc vào kênh tạp hóa lẻ (GT).
