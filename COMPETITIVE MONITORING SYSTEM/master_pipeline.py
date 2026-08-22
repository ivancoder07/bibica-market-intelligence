import pandas as pd
import numpy as np
import os
from sklearn.tree import DecisionTreeRegressor, plot_tree
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_squared_error
import matplotlib.pyplot as plt

def main():
    print("="*70)
    print("🚀 HỆ THỐNG MARKET INTELLIGENCE - LÕI ĐỘNG CƠ DECISION TREE")
    print("="*70)

    # ---------------------------------------------------------
    # TRẠM 1: DATA PREPARATION (CHUẨN BỊ & LÀM SẠCH DỮ LIỆU)
    # ---------------------------------------------------------
    print("\n[1/3] Đang tải và tiền xử lý dữ liệu (Data Preprocessing)...")
    
    # Cập nhật tên file mới của em
    file_path = os.path.join('data', 'dbo.product.csv')
    
    try:
        df = pd.read_csv(file_path)
    except FileNotFoundError:
        print(f"❌ LỖI: Không tìm thấy file tại đường dẫn: {file_path}")
        return

    # Tên cột đã được cập nhật chuẩn xác theo data thật
    X_COL = 'discount_percent' 
    Y_COL = 'monthly_sold_value'                   

    if X_COL not in df.columns or Y_COL not in df.columns:
        print(f"❌ LỖI: File CSV của em không có cột '{X_COL}' hoặc '{Y_COL}'.")
        return

    # Lọc bỏ Missing Values (Dữ liệu rỗng)
    data_clean = df[[X_COL, Y_COL]].dropna()
    
    # Lọc bỏ Outliers (Giá trị ngoại lệ - Cắt bỏ top 1% dữ liệu ảo/sai số)
    q_x = data_clean[X_COL].quantile(0.99)
    q_y = data_clean[Y_COL].quantile(0.99)
    data_clean = data_clean[(data_clean[X_COL] <= q_x) & (data_clean[Y_COL] <= q_y)]

    X = data_clean[[X_COL]]
    y = data_clean[Y_COL]

    print(f"✔️ Đã làm sạch dữ liệu. Cỡ mẫu (Sample Size) sẵn sàng: {len(data_clean)} dòng.")

    # ---------------------------------------------------------
    # TRẠM 2: MODEL TRAINING (HUẤN LUYỆN & KIỂM ĐỊNH MÔ HÌNH)
    # ---------------------------------------------------------
    print("\n[2/3] Đang huấn luyện AI (Decision Tree)...")
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = DecisionTreeRegressor(max_depth=2, random_state=42)
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    r2 = r2_score(y_test, y_pred)
    mse = mean_squared_error(y_test, y_pred)

    print(f"✔️ Huấn luyện thành công!")
    print(f"   📊 Hệ số tin cậy (R-squared): {r2:.4f}")
    print(f"   📉 Sai số toàn phương (MSE): {mse:.2f}")

    # Rút trích Điểm Đứt Gãy từ não bộ AI
    tipping_point = model.tree_.threshold[0]
    print(f"   🎯 ĐIỂM ĐỨT GÃY TÌM ĐƯỢC: {tipping_point:.2f}%")

    # ---------------------------------------------------------
    # TRẠM 3: XUẤT BÁO CÁO & GIẢ LẬP ĐẦU RA (ACTION TRIGGER)
    # ---------------------------------------------------------
    print("\n[3/3] Trực quan hóa và Giả lập hệ thống cảnh báo...")
    
    plt.figure(figsize=(10, 6), dpi=150)
    plot_tree(model, 
              feature_names=[X_COL], 
              filled=True, 
              rounded=True, 
              fontsize=10)
    
    plt.title(f"Phân tích Ngưỡng đứt gãy Sản lượng (Tipping Point = {tipping_point:.2f}%)", 
              fontsize=12, fontweight='bold')
    
    output_filename = 'Phan_Tich_Diem_Dut_Gay.png'
    plt.tight_layout()
    plt.savefig(output_filename)
    print(f"✔️ Đã lưu ảnh báo cáo Cây quyết định: {output_filename}")

    # Giả lập hệ thống thực thi
    print("\n" + "-"*70)
    print("📡 HỆ THỐNG RADAR THỰC CHIẾN (GIẢ LẬP API)")
    print("-" + "-"*69)
    print(f"[Hệ thống]: Setpoint tháng này được chốt ở mức {tipping_point:.2f}%.")
    
    gia_doi_thu_hom_nay = 15.0 
    print(f"[Radar Shopee]: Sáng nay phát hiện đối thủ giảm giá {gia_doi_thu_hom_nay}%!")
    
    if gia_doi_thu_hom_nay > tipping_point:
        print("\n🚨 [BÁO ĐỘNG ĐỎ] ĐỐI THỦ ĐÃ VƯỢT NGƯỠNG ĐỨT GÃY!")
        print("   >>> Tự động gọi Zalo API: Nhắn tin cho Giám đốc Marketing.")
        print("   >>> Tự động gọi Shopee API: Đẩy 'Combo 3 Hộp' lên trang chủ.")
    else:
        print("\n✅ [AN TOÀN] Vẫn nằm trong ngưỡng chịu đựng. Không cần giảm giá theo.")

    print("="*70)

if __name__ == "__main__":
    main()
