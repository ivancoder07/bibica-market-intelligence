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
