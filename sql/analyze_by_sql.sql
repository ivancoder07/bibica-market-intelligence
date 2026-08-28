/*
===========================================================================
PROJECT: BIBICA MARKET INTELLIGENCE
DESCRIPTION: Hệ thống truy xuất và kiểm chứng dữ liệu, phục vụ phân tích 
             chiến lược giá tĩnh, tối ưu hóa AOV và đo lường rủi ro thị trường.
===========================================================================
*/

-- Thiết lập mốc thời gian phân tích dựa trên dữ liệu mới nhất của thị trường VN
DECLARE @LatestDate DATE = (SELECT MAX([date]) FROM dbo.products WHERE country_code = 'vn');

/*
===========================================================================
PHẦN 1: BỐI CẢNH THỊ TRƯỜNG & VỊ THẾ CẠNH TRANH (SLIDE 4 & 5)
===========================================================================
*/

-- 1.1 Kiểm định quy luật Pareto (80/20): Tương quan đối lập giữa Quasure và phần còn lại của Bibica
WITH Bibica_Latest AS (
    SELECT 
        item_id,
        product_name,
        TRY_CAST(price AS FLOAT) * TRY_CAST(monthly_sold_value AS FLOAT) AS revenue
    FROM dbo.products
    WHERE [date] = @LatestDate
      AND country_code = 'vn'
      AND (shop_name LIKE '%Bibica%' OR brand LIKE '%Bibica%')
)
SELECT
    -- 1. TỔNG QUAN DANH MỤC BIBICA
    COUNT(item_id) AS total_bibica_skus,
    SUM(revenue) AS total_bibica_revenue,

    -- 2. NHÓM SẢN PHẨM CHỦ LỰC (QUASURE)
    SUM(CASE WHEN product_name LIKE '%Quasure%' THEN 1 ELSE 0 END) AS quasure_skus,
    ROUND(SUM(CASE WHEN product_name LIKE '%Quasure%' THEN 1.0 ELSE 0 END) * 100.0 / NULLIF(COUNT(item_id), 0), 1) AS quasure_sku_pct,
    SUM(CASE WHEN product_name LIKE '%Quasure%' THEN revenue ELSE 0 END) AS quasure_revenue,
    ROUND(SUM(CASE WHEN product_name LIKE '%Quasure%' THEN revenue ELSE 0 END) * 100.0 / NULLIF(SUM(revenue), 0), 1) AS quasure_revenue_pct,

    -- 3. NHÓM SẢN PHẨM CÒN LẠI (NON-QUASURE)
    SUM(CASE WHEN product_name NOT LIKE '%Quasure%' THEN 1 ELSE 0 END) AS non_quasure_skus,
    ROUND(SUM(CASE WHEN product_name NOT LIKE '%Quasure%' THEN 1.0 ELSE 0 END) * 100.0 / NULLIF(COUNT(item_id), 0), 1) AS non_quasure_sku_pct,
    SUM(CASE WHEN product_name NOT LIKE '%Quasure%' THEN revenue ELSE 0 END) AS non_quasure_revenue,
    ROUND(SUM(CASE WHEN product_name NOT LIKE '%Quasure%' THEN revenue ELSE 0 END) * 100.0 / NULLIF(SUM(revenue), 0), 1) AS non_quasure_revenue_pct

FROM Bibica_Latest;

-- 1.2 So sánh mức chiết khấu trung bình: Bibica vs Toàn thị trường
SELECT 
    ROUND(AVG(CASE WHEN shop_name LIKE '%Bibica%' THEN TRY_CAST(discount_percent AS FLOAT) END), 1) AS bibica_avg_discount,
    ROUND(AVG(CASE WHEN shop_name NOT LIKE '%Bibica%' THEN TRY_CAST(discount_percent AS FLOAT) END), 1) AS market_avg_discount
FROM dbo.products
WHERE country_code = 'vn'
  AND [date] = @LatestDate;

-- 1.3 Bằng chứng chạy đua chiết khấu: Top 10 sản phẩm bán chạy nhất thị trường (Non-Bibica)
SELECT TOP 10
    product_name AS [Tên Sản Phẩm],
    TRY_CAST(discount_percent AS FLOAT) AS [Mức Chiết Khấu (%)],
    TRY_CAST(monthly_sold_value AS FLOAT) AS [Sản Lượng Bán (hộp/tháng)]
FROM dbo.products
WHERE country_code = 'vn'
  AND (brand IS NULL OR brand NOT LIKE '%Bibica%') 
  AND (product_name IS NULL OR product_name NOT LIKE '%Bibica%')
  AND [date] = @LatestDate
ORDER BY TRY_CAST(monthly_sold_value AS FLOAT) DESC;

-- 1.4 Dữ liệu Ma trận định vị cạnh tranh (Product Matching Matrix / Bubble Chart)
SELECT
    CASE WHEN product_name LIKE '%Quasure%'       THEN 'Quasure'
         WHEN product_name LIKE '%BOOST GLUCOSE%' THEN 'Boost Glucose Control'
         WHEN product_name LIKE '%BOOST OPTIMUM%' THEN 'Boost Optimum' END AS product_line,
    COUNT(*) AS n_sku,               
    ROUND(AVG(TRY_CAST(discount_percent AS FLOAT)), 1) AS avg_discount_pct,    
    SUM(TRY_CAST(monthly_sold_value AS FLOAT)) AS total_monthly_volume,
    ROUND(SUM(price * TRY_CAST(monthly_sold_value AS FLOAT)), 0) AS total_monthly_revenue, 
    SUM(rating_count) AS total_reviews
FROM dbo.products
WHERE [date] = @LatestDate
  AND country_code = 'vn'
  AND (product_name LIKE '%Quasure%' OR product_name LIKE '%BOOST GLUCOSE%' OR product_name LIKE '%BOOST OPTIMUM%')
GROUP BY CASE WHEN product_name LIKE '%Quasure%'       THEN 'Quasure'
              WHEN product_name LIKE '%BOOST GLUCOSE%' THEN 'Boost Glucose Control'
              WHEN product_name LIKE '%BOOST OPTIMUM%' THEN 'Boost Optimum' END;


/*
===========================================================================
PHẦN 2: PHÂN TÍCH ĐỘ NHẠY VỀ GIÁ & XÁC ĐỊNH NGƯỠNG CHIẾT KHẤU (SLIDE 9)
===========================================================================
*/

-- 2.1 Phân phối sản lượng theo các phân khúc chiết khấu (Xác định mốc tối ưu 20%)
SELECT 
    CASE 
        WHEN TRY_CAST(discount_percent AS FLOAT) BETWEEN 0 AND 5 THEN '1. 0% - 5%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 5 AND TRY_CAST(discount_percent AS FLOAT) <= 10 THEN '2. 6% - 10%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 10 AND TRY_CAST(discount_percent AS FLOAT) <= 15 THEN '3. 11% - 15%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 15 AND TRY_CAST(discount_percent AS FLOAT) <= 20 THEN '4. 16% - 20%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 20 AND TRY_CAST(discount_percent AS FLOAT) <= 25 THEN '5. 21% - 25%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 25 AND TRY_CAST(discount_percent AS FLOAT) <= 30 THEN '6. 26% - 30%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 30 THEN '7. > 30%'
        ELSE 'Không xác định'
    END AS discount_range,
    COUNT(item_id) AS total_products, 
    SUM(TRY_CAST(monthly_sold_value AS FLOAT)) AS total_sales_volume, 
    ROUND(AVG(TRY_CAST(price AS FLOAT)), 0) AS average_price 
FROM dbo.products 
WHERE [date] = @LatestDate
  AND (product_name LIKE '%Bibica%' OR product_name LIKE '%Quasure%')
GROUP BY 
    CASE 
        WHEN TRY_CAST(discount_percent AS FLOAT) BETWEEN 0 AND 5 THEN '1. 0% - 5%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 5 AND TRY_CAST(discount_percent AS FLOAT) <= 10 THEN '2. 6% - 10%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 10 AND TRY_CAST(discount_percent AS FLOAT) <= 15 THEN '3. 11% - 15%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 15 AND TRY_CAST(discount_percent AS FLOAT) <= 20 THEN '4. 16% - 20%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 20 AND TRY_CAST(discount_percent AS FLOAT) <= 25 THEN '5. 21% - 25%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 25 AND TRY_CAST(discount_percent AS FLOAT) <= 30 THEN '6. 26% - 30%'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 30 THEN '7. > 30%'
        ELSE 'Không xác định'
    END
ORDER BY discount_range ASC;

-- 2.2 Đánh giá rủi ro từ chiến lược chiết khấu sâu của thị trường (Bẫy sản lượng >40%)
SELECT
    CASE WHEN TRY_CAST(discount_percent AS FLOAT) > 40 THEN 'Deep Discount (>40%)'
         ELSE 'Disciplined Pricing (<=40%)' END AS discount_strategy,
    COUNT(*) AS total_skus,       
    ROUND(AVG(price * TRY_CAST(monthly_sold_value AS FLOAT)), 0) AS avg_monthly_revenue
FROM dbo.products
WHERE [date] = @LatestDate
  AND country_code = 'vn'
  AND shop_name NOT LIKE '%Nestlé Health Science%'
  AND shop_name NOT LIKE '%Bibica%'
  AND TRY_CAST(discount_percent AS FLOAT) IS NOT NULL
GROUP BY CASE WHEN TRY_CAST(discount_percent AS FLOAT) > 40 THEN 'Deep Discount (>40%)'
              ELSE 'Disciplined Pricing (<=40%)' END;


/*
===========================================================================
PHẦN 3: GIẢI PHÁP CHIẾN LƯỢC - TỐI ƯU HÓA AOV (SLIDE 12)
===========================================================================
*/

-- 3.1 Hiệu suất mô hình Gộp gói (Bundling) so với Bán lẻ (Retail)
SELECT
    CASE WHEN product_name LIKE '%Combo%' THEN 'Bundle/Combo' ELSE 'Retail/Single' END AS product_type,
    COUNT(*) AS n_sku,           
    ROUND(AVG(price), 0) AS avg_order_value,
    ROUND(AVG(price * TRY_CAST(monthly_sold_value AS FLOAT)), 0) AS avg_revenue_per_sku
FROM dbo.products
WHERE [date] = @LatestDate
  AND country_code = 'vn'
  AND product_name LIKE '%Quasure%'
  AND product_name NOT LIKE '%không bán%'
  AND product_name NOT LIKE '%khong ban%'
GROUP BY CASE WHEN product_name LIKE '%Combo%' THEN 'Bundle/Combo' ELSE 'Retail/Single' END;


/*
===========================================================================
PHẦN 4: DỮ LIỆU ĐỐI CHỨNG DÀNH CHO BÁO CÁO PHỤ LỤC (APPENDIX 1)
===========================================================================
*/

-- 4.1 Đánh giá độ co giãn của tệp khách hàng mục tiêu Quasure (Mốc tham chiếu 15%)
SELECT 
    CASE WHEN TRY_CAST(discount_percent AS FLOAT) <= 15 THEN '<= 15%' 
         ELSE '> 15%' END AS discount_group,
    COUNT(item_id) AS total_skus,
    ROUND(AVG(TRY_CAST(monthly_sold_value AS FLOAT)), 0) AS avg_monthly_sold
FROM dbo.products
WHERE country_code = 'vn'
  AND product_name LIKE '%Quasure%'
  AND [date] = @LatestDate
GROUP BY CASE WHEN TRY_CAST(discount_percent AS FLOAT) <= 15 THEN '<= 15%' 
              ELSE '> 15%' END;

-- 4.2 Tần suất sử dụng chiết khấu sâu của các nhãn hàng đối thủ trên thị trường
SELECT 
    CASE 
        WHEN TRY_CAST(discount_percent AS FLOAT) <= 15 THEN '1. Nhom Can Bang (<=15%)'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 15 AND TRY_CAST(discount_percent AS FLOAT) <= 45 THEN '2. Nhom Chiet Khau Sau (16% - 45%)'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 45 THEN '3. Nhom Ruy Ro Cao (>45%)'
        ELSE '4. Khong Xac Dinh (Thieu Data)' 
    END AS Market_Zone,
    COUNT(item_id) AS total_skus
FROM dbo.products
WHERE country_code = 'vn'
  AND (brand IS NULL OR brand NOT LIKE '%Bibica%') 
  AND [date] = @LatestDate
GROUP BY 
    CASE 
        WHEN TRY_CAST(discount_percent AS FLOAT) <= 15 THEN '1. Nhom Can Bang (<=15%)'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 15 AND TRY_CAST(discount_percent AS FLOAT) <= 45 THEN '2. Nhom Chiet Khau Sau (16% - 45%)'
        WHEN TRY_CAST(discount_percent AS FLOAT) > 45 THEN '3. Nhom Ruy Ro Cao (>45%)'
        ELSE '4. Khong Xac Dinh (Thieu Data)'
    END
ORDER BY Market_Zone ASC;
