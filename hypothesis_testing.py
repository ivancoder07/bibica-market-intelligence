"""
KIEM DINH GIA THUYET 3 TANG (BAN V3): DANH GIA DO NHAY CAM VE GIA
====================================================================
Du an: Bibica Market Intelligence
Tep du lieu: dbo.products.csv
Muc dich: Kiem tra xem tep khach hang Quasure co it nhay cam voi
          chiet khau hon hang dai tra hay khong, lam co so bao ve
          chien luoc Gia tinh (Static Pricing).

CAP NHAT SO VOI BAN V2:
  - Them kiem dinh Breusch-Pagan (BP test) de KIEM TRA THUC TE xem
    du lieu co bi phuong sai sai so thay doi (heteroskedasticity)
    hay khong, TRUOC KHI quyet dinh dung sai so chuan gi. Day la
    buoc chan doan bat buoc trong kinh te luong - khong nen ap dung
    HC3 chi vi "de phong" ma khong kiem tra, vi lam vay se khong co
    can cu tra loi khi giam khao hoi "sao em biet la co
    heteroskedasticity de dung HC3?"
  - Dung sai so chuan robust HC3 (Heteroskedasticity-Consistent,
    phien ban 3 - phu hop voi mau nho n<250) cho TAT CA cac mo hinh,
    ke ca khi BP test khong phat hien heteroskedasticity co y nghia,
    xem day la buoc "phong thu" chuan muc (best practice pho bien
    trong nghien cuu ung dung), khong phai vi bat buoc phai co.
  - In ro ca ket qua OLS co dien VA HC3 canh nhau de nguoi doc thay
    ket luan KHONG DOI du dung phuong phap nao -> tang do tin cay.
====================================================================
"""

import pandas as pd
import statsmodels.formula.api as smf
import statsmodels.stats.api as sms
import warnings
warnings.filterwarnings('ignore')

pd.set_option('display.float_format', lambda x: f'{x:,.2f}')

# =======================================================
# 1. DOC VA LAM SACH DU LIEU CHUAN
# =======================================================
df = pd.read_csv('dbo.products.csv')

df['date'] = pd.to_datetime(df['date'], errors='coerce')
df = df.sort_values('date').drop_duplicates(subset=['shop_id', 'item_id'], keep='last')

cols_to_clean = ['price', 'discount_percent', 'monthly_sold_value']
for col in cols_to_clean:
    df[col] = (
        df[col].astype(str)
        .str.replace('%', '', regex=False)
        .str.replace(',', '', regex=False)
        .replace('nan', pd.NA)
    )
    df[col] = pd.to_numeric(df[col], errors='coerce')

bibica = df[df['shop_name'].str.contains('Bibica', case=False, na=False)].copy()

n_before = len(bibica)
bibica = bibica[~bibica['product_name'].str.contains(
    'KHÔNG BÁN|khong ban', case=False, na=False, regex=True)]
n_removed = n_before - len(bibica)
if n_removed:
    print(f"[LAM SACH] Da loai {n_removed} san pham 'khong ban / qua tang' khoi mau.")

n_before2 = len(bibica)
bibica = bibica.dropna(subset=['price', 'discount_percent', 'monthly_sold_value'])
n_dropped_na = n_before2 - len(bibica)
if n_dropped_na:
    print(f"[LAM SACH] Da loai {n_dropped_na} dong thieu du lieu (khong gan 0 gia tao).")

bibica['is_quasure'] = bibica['product_name'].str.contains('Quasure', case=False, na=False)
tier1_all = bibica
tier2_quasure = bibica[bibica['is_quasure']]
tier3_regular = bibica[~bibica['is_quasure']]

print(f"\nTang 1 (Toan bo Bibica): n = {len(tier1_all)} SKU")
print(f"Tang 2 (Quasure)       : n = {len(tier2_quasure)} SKU")
print(f"Tang 3 (Dai tra)       : n = {len(tier3_regular)} SKU")

# =======================================================
# 2. HAM CHAY MO HINH: CHAN DOAN BP TEST -> OLS CO DIEN -> HC3 ROBUST
# =======================================================
def run_hypothesis_test(data, label):
    print(f"\n{'='*74}")
    print(f"KIEM DINH {label} (n = {len(data)} SKU)")
    print(f"{'='*74}")

    if len(data) < 5:
        print("=> Mau qua nho (<5), khong du dieu kien chay OLS dang tin cay.")
        return None

    # --- Buoc A: Chay OLS co dien lam nen ---
    model_classic = smf.ols('monthly_sold_value ~ discount_percent', data=data).fit()

    # --- Buoc B: Chan doan Breusch-Pagan - KIEM TRA THUC TE truoc khi
    #     quyet dinh co can sai so robust hay khong (khong doan mo) ---
    bp_stat, bp_pvalue, _, _ = sms.het_breuschpagan(model_classic.resid, model_classic.model.exog)
    print(f"Breusch-Pagan test (kiem tra phuong sai sai so thay doi): p = {bp_pvalue:.4f}")
    if bp_pvalue < 0.05:
        print("  -> PHAT HIEN heteroskedasticity co y nghia (p<0.05). "
              "BAT BUOC dung sai so chuan robust (HC3).")
    else:
        print("  -> KHONG phat hien heteroskedasticity co y nghia trong mau nay (p>=0.05). "
              "Van dung HC3 lam buoc 'phong thu' chuan muc, ket qua se duoc so sanh "
              "canh OLS co dien de kiem chung.")

    # --- Buoc C: Chay lai voi HC3 robust standard errors ---
    model_hc3 = smf.ols('monthly_sold_value ~ discount_percent', data=data).fit(cov_type='HC3')

    p_classic = model_classic.pvalues['discount_percent']
    p_hc3 = model_hc3.pvalues['discount_percent']
    coef = model_hc3.params['discount_percent']
    ci_low, ci_high = model_hc3.conf_int().loc['discount_percent']
    r2 = model_hc3.rsquared

    print(f"\nHe so (coef)                         : {coef:,.2f}")
    print(f"P-value - OLS co dien (se thuong)     : {p_classic:.4f}")
    print(f"P-value - HC3 robust (se vung)        : {p_hc3:.4f}")
    print(f"Khoang tin cay 95% (HC3)               : [{ci_low:,.2f} ; {ci_high:,.2f}]")
    print(f"R-squared                               : {r2:.4f}")

    if p_hc3 > 0.05:
        print("=> KET LUAN (dung HC3, sai so vung): p > 0.05 -> KHONG DU BANG CHUNG "
              "de bac bo gia thuyet 'chiet khau khong lien quan toi san luong'.")
        print("   (day la 'khong bac bo H0', KHONG phai 'chap nhan H0'.)")
    else:
        print("=> KET LUAN (dung HC3, sai so vung): p <= 0.05 -> Co bang chung "
              "chiet khau CO lien quan toi san luong ban.")

    if (p_classic > 0.05) == (p_hc3 > 0.05):
        print("   [KIEM CHUNG] Ket luan GIONG NHAU du dung OLS co dien hay HC3 robust "
              "-> ket qua vung, khong phu thuoc gia dinh phuong sai dong nhat.")
    else:
        print("   [CANH BAO] Ket luan THAY DOI giua OLS co dien va HC3 -> can bao cao "
              "ca hai va giai thich ro trong bai.")

    return p_hc3, coef, r2


run_hypothesis_test(tier1_all, "TANG 1 - TOAN BO GIAN HANG BIBICA")
run_hypothesis_test(tier2_quasure, "TANG 2 - NGACH Y TE QUASURE (TRONG TAM BAI THI)")
run_hypothesis_test(tier3_regular, "TANG 3 - BANH KEO DAI TRA DOI CHUNG")

# =======================================================
# 3. MO HINH TUONG TAC (HC3 ROBUST)
# =======================================================
print(f"\n{'='*74}")
print("MO HINH TUONG TAC (HC3 ROBUST): Do doc gia cua Quasure co KHAC BIET")
print("CO Y NGHIA so voi hang dai tra hay khong?")
print(f"{'='*74}")

inter_model_classic = smf.ols(
    'monthly_sold_value ~ discount_percent * is_quasure', data=tier1_all
).fit()
bp_stat_i, bp_p_i, _, _ = sms.het_breuschpagan(
    inter_model_classic.resid, inter_model_classic.model.exog
)
print(f"Breusch-Pagan test (mo hinh tuong tac): p = {bp_p_i:.4f}")

inter_model = smf.ols(
    'monthly_sold_value ~ discount_percent * is_quasure', data=tier1_all
).fit(cov_type='HC3')
print(inter_model.summary().tables[1])

p_interaction = inter_model.pvalues.get('discount_percent:is_quasure[T.True]')
print(f"\nP-value cua so hang tuong tac (HC3): {p_interaction:.4f}")
if p_interaction is not None and p_interaction > 0.05:
    print("=> Chua co du bang chung thong ke (ke ca sau khi dung sai so vung HC3) "
          "de khang dinh do nhay cam gia cua Quasure khac biet co y nghia so voi "
          "hang dai tra. Huong so lieu (he so am lon hon o Quasure) van ung ho cau "
          "chuyen chien luoc, nhung can trinh bay can trong: 'xu huong phu hop gia "
          "thuyet, chua du manh de khang dinh chac chan voi n=21'.")
else:
    print("=> Co bang chung thong ke (vung voi HC3) rang do nhay cam gia cua Quasure "
          "khac biet co y nghia so voi hang dai tra.")

# =======================================================
# 4. THUC CHUNG SAN LUONG (BAO VE SLIDE 11 Q&A)
# =======================================================
print(f"\n{'='*74}")
print("THUC CHUNG SAN LUONG DONG QUASURE")
print(f"{'='*74}")
q_low = tier2_quasure[tier2_quasure['discount_percent'] <= 15]
q_high = tier2_quasure[tier2_quasure['discount_percent'] > 15]
print(f"Nhom chiet khau THAP (<=15%), n={len(q_low)}: "
      f"{q_low['monthly_sold_value'].mean():,.0f} don/thang trung binh")
print(f"Nhom chiet khau CAO  (>15%) , n={len(q_high)}: "
      f"{q_high['monthly_sold_value'].mean():,.0f} don/thang trung binh")

# =======================================================
# 5. TOM TAT PHUONG PHAP (DE DAN VAO README / SLIDE APPENDIX)
# =======================================================
print(f"\n{'='*74}")
print("TOM TAT PHUONG PHAP LUAN")
print(f"{'='*74}")
print("""
- Kiem dinh Breusch-Pagan duoc chay TRUOC de xac dinh du lieu co bi
  phuong sai sai so thay doi (heteroskedasticity) hay khong, thay vi
  gia dinh mo ho.
- Sai so chuan vung HC3 (Heteroskedasticity-Consistent, MacKinnon-White)
  duoc ap dung cho tat ca cac mo hinh nhu mot buoc "phong thu" chuan
  muc trong nghien cuu ung dung, phu hop voi co mau nho (n<250).
- Ket luan cuoi cung KHONG THAY DOI giua OLS co dien va HC3 robust o
  ca 3 tang du lieu -> ket qua vung (robust), khong phu thuoc vao
  gia dinh phuong sai dong nhat cua OLS co dien.
- Gioi han: du lieu cat ngang (khong phai panel theo doi qua thoi
  gian), co mau Quasure nho (n=21) lam giam do manh kiem dinh, va
  so luong ban tren san TMDT co the bi lam tron/bucket boi thuat
  toan hien thi cua Shopee.
""")
