# Bibica Market Intelligence - Core Decision Engine

![Python](https://img.shields.io/badge/Python-3.12-blue)
![Scikit-Learn](https://img.shields.io/badge/Machine%20Learning-Scikit--Learn-orange)
![Status](https://img.shields.io/badge/Status-Production%20Ready-success)

## 1. Tổng quan Dự án
Đây là Lõi Trí tuệ (Core AI Engine) thuộc hệ thống Market Intelligence của doanh nghiệp Bibica. 
Hệ thống này sử dụng thuật toán học máy Decision Tree (White-box AI) để tự động phân tích dữ liệu thị trường, tìm ra Điểm Đứt Gãy (Tipping Point) về giá, từ đó kích hoạt các luồng phòng thủ phi giá cả nhằm bảo vệ biên lợi nhuận, thay vì cuốn vào cuộc chiến giảm giá (Price War).

## 2. Cấu trúc Kho lưu trữ
Toàn bộ mã nguồn cốt lõi được đặt trong thư mục `COMPETITIVE MONITORING SYSTEM`.
- `data/dbo.product.csv`: Dữ liệu đầu vào (đóng vai trò như tín hiệu cảm biến thu thập từ sàn thương mại điện tử).
- `master_pipeline.py`: Mã nguồn chính chứa bộ điều khiển trung tâm (bao gồm khâu tiền xử lý dữ liệu, huấn luyện mô hình và rơ-le kích hoạt hành động).
- `requirement.txt`: Danh sách các thư viện phụ thuộc cần thiết để vận hành hệ thống.

## 3. Hướng dẫn Cài đặt (Dành cho Người Đánh giá)
Để hệ thống vận hành trơn tru mà không gặp lỗi đường dẫn (Path Error), vui lòng thực hiện tuần tự các bước sau:

**Bước 1: Tải dự án về máy**
Mở Terminal (hoặc Command Prompt) và chạy lệnh sau để tải toàn bộ mã nguồn về:
```bash
git clone https://github.com/ivancoder07/bibica-market-intelligence.git
```
**Bước 2: Di chuyển vào phân hệ Code AI**
```bash
cd "bibica-market-intelligence/COMPETITIVE MONITORING SYSTEM"
```
**Bước 3: Cài đặt thư viện phụ thuộc**
``` bash
pip install -r requirement.txt
```
**Bước 4: Thực hiện chạy code hệ thống**
``` bash
python master_pipeline.py
```
Kết quả đẩu ra:
4. Kết quả Đầu ra
Khi hệ thống thực thi thành công, Terminal sẽ tự động kết xuất các thông số sau:

Model Diagnostics: Báo cáo số lượng bản ghi dữ liệu đã được làm sạch, hệ số tin cậy (R-Squared) và sai số toàn phương trung bình (MSE).

Dynamic Action Threshold: Tự động trích xuất Điểm Đứt Gãy (%) chính xác từ bộ dữ liệu.

Visual Report: Tự động kết xuất sơ đồ Cây Quyết Định và lưu thành file ảnh Phan_Tich_Diem_Dut_Gay.png tại thư mục hiện tại.

System Simulation: Giả lập hệ thống cảnh báo (gọi API Zalo nội bộ / đẩy sản phẩm trên API sàn thương mại điện tử) khi phát hiện đối thủ vi phạm ngưỡng giá.


