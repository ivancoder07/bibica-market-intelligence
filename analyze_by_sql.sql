/* 
===========================================================================
BIBICA MARKET INTELLIGENCE - SQL DATA VALIDATION (VER 2.0 - AUDITED)
Mục đích: Truy xuất và đối soát các chỉ số (Metrics) xuất hiện trên Slide.
Tệp dữ liệu gốc: dbo.products.csv
===========================================================================
*/

-- ========================================================================
-- SLIDE 3: QUY LUẬT 80/20 & VỊ THẾ BẤT XỨNG
-- ========================================================================

-- Q1: Dòng Quasure chiếm bao nhiêu phần trăm trong tổng số lượng SKU của Bibica? 
WITH Bibica_SKU AS (
    SELECT 
        COUNT(item_id) AS total_bibica_skus,
        SUM(CASE WHEN product_name LIKE '%Quasure%' THEN 1 ELSE 0 END) AS quasure_skus
    FROM products
    WHERE brand LIKE '%Bibica%' OR shop_name LIKE '%Bibica%'
)
SELECT 
    total_bibica_skus,
    quasure_skus,
    ROUND((quasure_skus * 100.0 / total_bibica_skus), 1) AS quasure_sku_percentage -- Result: 21.9%
FROM Bibica_SKU;

-- Q2: Doanh thu của dòng Quasure gánh bao nhiêu phần trăm tổng doanh thu Bibica?
WITH Bibica_Revenue AS (
    SELECT 
        SUM(price * monthly_sold_value) AS total_revenue,
        SUM(CASE WHEN product_name LIKE '%Quasure%' THEN price * monthly_sold_value ELSE 0 END) AS quasure_revenue
    FROM products
    WHERE brand LIKE '%Bibica%' OR shop_name LIKE '%Bibica%'
)
SELECT 
    ROUND((quasure_revenue * 100.0 / total_revenue), 1) AS quasure_revenue_percentage -- Result: 71.9%
FROM Bibica_Revenue;

-- Q3: Mức chiết khấu trung bình của Bibica so với đối thủ cạnh tranh trực tiếp (Richy)
SELECT 
    'Bibica' AS segment,
    ROUND(AVG(CAST(REPLACE(discount_percent, '%', '') AS FLOAT)), 1) AS avg_discount_percent -- Result: 16.0%
FROM products
WHERE (brand LIKE '%Bibica%' OR shop_name LIKE '%Bibica%') 
  AND discount_percent IS NOT NULL
UNION ALL
SELECT 
    'Richy (Benchmark)' AS segment,
    ROUND(AVG(CAST(REPLACE(discount_percent, '%', '') AS FLOAT)), 1) AS avg_discount_percent -- Result: ~28.1% - 29.1%
FROM products
WHERE brand LIKE '%Richy%' AND discount_percent IS NOT NULL;


-- ========================================================================
-- SLIDE 4: SỰ SỤP ĐỔ CỦA BẪY KHỐI LƯỢNG (VOLUME TRAP)
-- ========================================================================

-- Q4: Doanh thu trung bình nhóm giảm giá sâu (>40%) vs nhóm giữ giá (<=40%)?
-- Lưu ý: Đã loại bỏ Nestlé Health Science để tránh nhiễu Outlier ngành y tế.
WITH Discount_Categorization AS (
    SELECT 
        item_id,
        (price * monthly_sold_value) AS monthly_revenue,
        CAST(REPLACE(discount_percent, '%', '') AS FLOAT) AS discount_val
    FROM products
    WHERE shop_name NOT LIKE '%Nestlé%' AND brand NOT LIKE '%Nestlé%' -- Data Cleaning
)
SELECT 
    CASE 
        WHEN discount_val > 40 THEN 'Deep Discount (>40%)'
        ELSE 'Normal/Static Price (<=40%)' 
    END AS discount_strategy,
    COUNT(item_id) AS total_skus,
    ROUND(AVG(monthly_revenue), 0) AS avg_monthly_revenue -- Result: 89.6M vs 648M
FROM Discount_Categorization
GROUP BY 
    CASE 
        WHEN discount_val > 40 THEN 'Deep Discount (>40%)'
        ELSE 'Normal/Static Price (<=40%)' 
    END;


-- ========================================================================
-- SLIDE 6: CHIẾN LƯỢC TỐI ƯU AOV QUA BUNDLING (GỘP GÓI)
-- ========================================================================

-- Q5: So sánh AOV và Tổng doanh thu giữa Bán lẻ và Combo (Dòng Quasure)
WITH Quasure_Bundling AS (
    SELECT 
        item_id,
        price,
        (price * monthly_sold_value) AS monthly_revenue,
        CASE 
            WHEN product_name LIKE '%Combo%' OR product_name LIKE '%Hộp%' OR product_name LIKE '%Lốc%' THEN 'Bundle/Combo'
            ELSE 'Retail/Single' 
        END AS product_type
    FROM products
    WHERE product_name LIKE '%Quasure%'
)
SELECT 
    product_type,
    ROUND(AVG(price), 0) AS AOV, -- Result: 113k vs 143k
    SUM(monthly_revenue) AS total_revenue
FROM Quasure_Bundling
GROUP BY product_type;


-- ========================================================================
-- SLIDE 11: DATA VALIDATION & PRICE ELASTICITY
-- ========================================================================

-- Q6: Sản lượng bán dòng Quasure theo mốc chiết khấu 15%
WITH Quasure_Volume AS (
    SELECT 
        item_id,
        monthly_sold_value,
        CAST(REPLACE(discount_percent, '%', '') AS FLOAT) AS discount_val
    FROM products
    WHERE product_name LIKE '%Quasure%'
)
SELECT 
    CASE 
        WHEN discount_val <= 15 THEN 'Low Discount (<= 15%)'
        ELSE 'High Discount (> 15%)' 
    END AS discount_tier,
    COUNT(item_id) AS sku_count,
    ROUND(AVG(monthly_sold_value), 0) AS avg_monthly_sold_volume -- Result: 2527 vs 1387
FROM Quasure_Volume
GROUP BY 
    CASE 
        WHEN discount_val <= 15 THEN 'Low Discount (<= 15%)'
        ELSE 'High Discount (> 15%)' 
    END;
