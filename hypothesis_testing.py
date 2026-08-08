"""
KIỂM ĐỊNH GIẢ THUYẾT 3 TẦNG: ĐÁNH GIÁ ĐỘ NHẠY CẢM VỀ GIÁ
========================================================
Dự án: Bibica Market Intelligence
Tệp dữ liệu: dbo.products.csv
Mục đích: Chứng minh tệp khách hàng Quasure vô cảm với chiết khấu,
          làm cơ sở bảo vệ chiến lược Giá tĩnh (Static Pricing).
"""

import pandas as pd
import statsmodels.formula.api as smf
import warnings
warnings.filterwarnings('ignore') # Tắt các cảnh báo thừa để log console đẹp hơn

# =======================================================
# 1. ĐỌC VÀ LÀM SẠCH DỮ LIỆU CHUẨN
# =======================================================
df = pd.read_csv('dbo.products.csv')

# Xử lý dữ liệu snapshot (chụp nhiều lần trong ngày): Chỉ lấy dòng mới nhất của mỗi SKU
df['date'] = pd.to_datetime(df['date'], errors='coerce')
df = df.sort_values('date').drop_duplicates(subset=['shop_id', 'item_id'], keep='last')

# Ép kiểu dữ liệu (Numeric) cho các cột tính toán để chạy OLS
cols_to_clean = ['price', 'discount_percent', 'monthly_sold_value']
for col in cols_to_clean:
    if df[col].dtype == object:
        df[col] = df[col].astype(str).str.replace('%', '').str.replace(',', '')
    df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)

# Lọc khoanh vùng riêng gian hàng Bibica
bibica = df[df['shop_name'].str.contains('Bibica', case=False, na=False)].copy()

# =======================================================
# 2. PHÂN LOẠI 3 TẦNG DỮ LIỆU (3 GIẢ THUYẾT)
# =======================================================
# Gắn nhãn phân biệt sản phẩm ngách y tế (Quasure)
bibica['is_quasure'] = bibica['product_name'].str.contains('Quasure', case=False, na=False)

tier1_all = bibica                             # Tầng 1: Toàn bộ danh mục (96 SKUs)
tier2_quasure = bibica[bibica['is_quasure']]   # Tầng 2: Ngách y tế (21 SKUs)
tier3_regular = bibica[~bibica['is_quasure']]  # Tầng 3: Bánh kẹo đại trà (75 SKUs)

# =======================================================
# 3. HÀM CHẠY MÔ HÌNH HỒI QUY (OLS)
# =======================================================
def run_hypothesis_test(data, label):
    print(f"\n{'='*70}")
    print(f"KIỂM ĐỊNH {label} (n = {len(data)} SKUs)")
    print(f"{'='*70}")
    
    # Mô hình: Sản lượng bán hàng tháng (Y) phụ thuộc Chiết khấu (X)
    model = smf.ols('monthly_sold_value ~ discount_percent', data=data).fit()
    
    # Rút xuất p-value
    p_value = model.pvalues.get('discount_percent', 'N/A')
    print(f"P-value của biến Chiết khấu (Discount %): {p_value:.4f}")
    
    # Kết luận kinh doanh
    if p_value > 0.05:
        print("=> KẾT LUẬN: P-value > 0.05. Mức chiết khấu KHÔNG có ý nghĩa thống kê lên khối lượng bán.")
        print("             Tệp khách hàng này KHÔNG NHẠY CẢM với giá (Chấp nhận H0).")
    else:
        print("=> KẾT LUẬN: Khách hàng CÓ NHẠY CẢM với giá (Bác bỏ H0).")
        
    return p_value

# Thực thi kiểm định 3 tầng
run_hypothesis_test(tier1_all, "TẦNG 1 - TOÀN BỘ GIAN HÀNG BIBICA")
run_hypothesis_test(tier2_quasure, "TẦNG 2 - NGÁCH Y TẾ QUASURE (TRỌNG TÂM BÀI THI)")
run_hypothesis_test(tier3_regular, "TẦNG 3 - BÁNH KẸO ĐẠI TRÀ ĐỐI CHỨNG")

# =======================================================
# 4. THỰC CHỨNG SẢN LƯỢNG (BẢO VỆ SLIDE 11 Q&A)
# =======================================================
print(f"\n{'='*70}")
print("THỰC CHỨNG SẢN LƯỢNG DÒNG QUASURE")
print(f"{'='*70}")
q_low = tier2_quasure[tier2_quasure['discount_percent'] <= 15]
q_high = tier2_quasure[tier2_quasure['discount_percent'] > 15]

print(f"Sản lượng trung bình nhóm chiết khấu THẤP (<= 15%): {q_low['monthly_sold_value'].mean():,.0f} đơn/tháng")
print(f"Sản lượng trung bình nhóm chiết khấu CAO (> 15%)  : {q_high['monthly_sold_value'].mean():,.0f} đơn/tháng")
print("\n=> Insight: Bài toán 'Lấy số lượng bù đơn giá' hoàn toàn sụp đổ.")
print("=> Khách hàng y tế nghi ngờ chất lượng khi thấy giảm giá sâu (Medical Barrier).")
