/* 
===========================================================================
BIBICA MARKET INTELLIGENCE - SQL DATA VALIDATION
Mục đích: Truy xuất và đối soát các chỉ số (Metrics) xuất hiện trên Slide.
Tệp dữ liệu gốc: dbo.products.csv, dbo.shop_info.csv
===========================================================================
*/

-- ========================================================================
-- SLIDE 3: QUY LUẬT 80/20 & VỊ THẾ BẤT XỨNG
-- ========================================================================

-- Q1: Dòng Quasure chiếm bao nhiêu phần trăm trong tổng số lượng SKU của Bibica? (Số liệu slide: 21.9% / 22%)
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
    ROUND((quasure_skus * 100.0 / total_bibica_skus), 1) AS quasure_sku_percentage
FROM Bibica_SKU;


-- Q2: Doanh thu của dòng Quasure gánh bao nhiêu phần trăm tổng doanh thu Bibica? (Số liệu slide: 12.2 Tỷ VNĐ / 71.9%)
WITH Bibica_Revenue AS (
    SELECT 
        SUM(price * monthly_sold_value) AS total_revenue,
        SUM(CASE WHEN product_name LIKE '%Quasure%' THEN price * monthly_sold_value ELSE 0 END) AS quasure_revenue
    FROM products
    WHERE brand LIKE '%Bibica%' OR shop_name LIKE '%Bibica%'
)
SELECT 
    total_revenue,
    quasure_revenue,
    ROUND((quasure_revenue * 100.0 / total_revenue), 1) AS quasure_revenue_percentage
FROM Bibica_Revenue;


-- Q3: Mức chiết khấu an toàn của Bibica so với mức cắt máu của thị trường là bao nhiêu? (Số liệu slide: 15.8% vs 28.4%)
SELECT 
    'Bibica' AS segment,
    ROUND(AVG(CAST(REPLACE(discount_percent, '%', '') AS FLOAT)), 1) AS avg_discount_percent
FROM products
WHERE brand LIKE '%Bibica%' OR shop_name LIKE '%Bibica%'
UNION ALL
SELECT 
    'Market Average' AS segment,
    ROUND(AVG(CAST(REPLACE(discount_percent, '%', '') AS FLOAT)), 1) AS avg_discount_percent
FROM products
WHERE brand NOT LIKE '%Bibica%';


-- ========================================================================
-- SLIDE 4: SỰ SỤP ĐỔ CỦA BẪY KHỐI LƯỢNG (VOLUME TRAP)
-- ========================================================================

-- Q4: Doanh thu trung bình của nhóm giảm giá sâu (>40%) vs nhóm giữ giá (<=40%) là bao nhiêu? (Số liệu slide: 89.6M vs 648M)
WITH Discount_Categorization AS (
    SELECT 
        item_id,
        (price * monthly_sold_value) AS monthly_revenue,
        CAST(REPLACE(discount_percent, '%', '') AS FLOAT) AS discount_val
    FROM products
)
SELECT 
    CASE 
        WHEN discount_val > 40 THEN 'Deep Discount (>40%)'
        ELSE 'Normal/Static Price (<=40%)' 
    END AS discount_strategy,
    COUNT(item_id) AS total_skus,
    ROUND(AVG(monthly_revenue), 0) AS avg_monthly_revenue
FROM Discount_Categorization
GROUP BY 
    CASE 
        WHEN discount_val > 40 THEN 'Deep Discount (>40%)'
        ELSE 'Normal/Static Price (<=40%)' 
    END;


-- ========================================================================
-- SLIDE 6: CHIẾN LƯỢC TỐI ƯU AOV QUA BUNDLING (GỘP GÓI)
-- ========================================================================

-- Q5: So sánh Giá trị đơn hàng trung bình (AOV) và Tổng doanh thu giữa Bán lẻ và Combo? (Số liệu slide: 113k vs 143k)
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
    ROUND(AVG(price), 0) AS average_order_value_AOV,
    SUM(monthly_revenue) AS total_revenue
FROM Quasure_Bundling
GROUP BY product_type;


-- ========================================================================
-- SLIDE 11: DATA VALIDATION & PRICE ELASTICITY (APPENDIX)
-- ========================================================================

-- Q6: Sản lượng bán trung bình mỗi tháng của dòng Quasure chia theo mốc chiết khấu 15% là bao nhiêu? (Số liệu slide: 2,527 đơn vs 1,387 đơn)
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
    ROUND(AVG(monthly_sold_value), 0) AS avg_monthly_sold_volume
FROM Quasure_Volume
GROUP BY 
    CASE 
        WHEN discount_val <= 15 THEN 'Low Discount (<= 15%)'
        ELSE 'High Discount (> 15%)' 
    END;
