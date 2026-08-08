# bibica-market-intelligence
# 📊 BIBICA MARKET INTELLIGENCE 
**Tối ưu hóa Biên lợi nhuận thông qua Chiến lược Cạnh tranh Bất xứng (Asymmetric Strategy)**

Kho lưu trữ này chứa toàn bộ Truy vấn SQL, Mã nguồn Python, Dữ liệu gốc (Raw Data) và Kế hoạch Thực thi (Go-to-market) được đội thi sử dụng để bóc tách thị trường và thiết lập chiến lược.

---

## 📂 1. Cấu Trúc Dữ Liệu (Data Schema)
Dữ liệu được trích xuất dưới dạng Cơ sở dữ liệu quan hệ (Relational DB) để đảm bảo tính toàn vẹn:
* `dbo.products.csv`: Bảng sự kiện lõi chứa thông tin giao dịch, sản lượng, giá bán và chiết khấu.
* `dbo.shop_info.csv`: Bảng chiều (Dimension table) chứa metadata của các gian hàng.
* Các file `category`: Hệ thống sơ đồ cây danh mục chuẩn.

---

## 🔍 2. Truy Vết Chỉ Số (SQL Data Validation)
**File thực thi:** `analyze_by_sql.sql`
Toàn bộ các chỉ số trọng yếu trên Slide báo cáo đều được truy vấn trực tiếp bằng SQL:
* **Quy luật Pareto (80/20):** Dòng Quasure (ngách y tế) chỉ chiếm **21.9%** số lượng SKU nhưng gánh tới **71.9%** tổng doanh thu toàn gian hàng Bibica.
* **Sự sụp đổ của Bẫy khối lượng (Volume Trap):** Nhóm giảm giá sâu (>40%) chỉ mang lại doanh thu trung bình **89.6M/tháng**, trong khi nhóm giữ giá tốt (<=40%) mang về **648M/tháng** (Gấp 7 lần).

---

## 🧪 3. Kiểm Định Giả Thuyết (OLS Regression)
**File thực thi:** `hypothesis_testing.py`
Hệ thống sử dụng Hồi quy OLS (thư viện `Statsmodels` - Python) để đánh giá độ nhạy cảm về giá (Price Elasticity):
* **🎯 TẦNG 2 (Ngách y tế Quasure - Trọng tâm): p-value = 0.3216 (> 0.05)**
* **Kết luận Toán học:** Không có cơ sở để bác bỏ Giả thuyết Không (Fail to reject H0). Khách hàng mua Quasure vì niềm tin sức khỏe, hoàn toàn **vô cảm với giá (Inelastic Demand)**.

---

## 💡 4. Giải Pháp Chiến Lược (Strategic Formulation)
Rút toàn bộ nguồn lực khỏi cuộc đua Flash Sale vô nghĩa của đại dương đỏ, dồn hỏa lực chiếm lĩnh phân khúc chi tiêu phòng thủ thông qua 3 hành động:

1. **Cơ chế Giá tĩnh (Static Pricing):** Thiết lập trần chiết khấu tối đa 20% cho dòng Hero SKUs (Quasure). Từ chối tham gia cuộc chiến phá giá để giữ nguyên vị thế cao cấp của sản phẩm dinh dưỡng y học.
2. **Cấu trúc Bundle (Gộp gói sản phẩm):** Thuật toán tối ưu AOV (Giá trị đơn hàng). Không giảm giá bán lẻ, tập trung đóng gói Combo (2-3 hộp) để đánh trúng tâm lý mua tích trữ/biếu tặng.
3. **Dịch chuyển Ngân sách (Budget Shift) & Social Proof:** Tái phân bổ 100% ngân sách khuyến mãi sang xây dựng Bằng chứng xã hội. Cụ thể: Đóng dấu mộc "Chứng nhận Viện Dinh Dưỡng" lên mọi Thumbnail, tạo rào cản chất lượng vô hình mà bánh kẹo đại trà nhiều đường không thể sao chép.

---

## 🚀 5. Lộ Trình Triển Khai (Go-to-Market)
* **Giai đoạn 1 (Tháng 1):** Tái cấu trúc nhận diện. Áp dụng chuẩn Thumbnail y tế & Khóa trần chiết khấu 20%.
* **Giai đoạn 2 (Tháng 2):** Đẩy mạnh Combo. Dồn ngân sách hiển thị vào các mã Bundle (Giỏ quà biếu, Combo 3).
* **Giai đoạn 3 (Tháng 3):** Đo lường & Phân phối. Tập trung phủ kênh Siêu thị (MT) và Nhà thuốc; thu hẹp kênh tạp hóa lẻ (GT).
