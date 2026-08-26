/*
===========================================================================
BIBICA MARKET INTELLIGENCE - SQL DATA VALIDATION

===========================================================================
*/


DECLARE @LatestDate DATE = (SELECT MAX([date]) FROM dbo.products WHERE country_code = 'vn');


-- ========================================================================
-- SLIDE 3: BUSINESS CONTEXT (The Data Paradox)
-- ========================================================================

-- Q1 + Q2: Ty le SKU va doanh thu cua Quasure trong danh muc Bibica (Pareto donut)
WITH Bibica_Latest AS (
    SELECT *
    FROM dbo.products
    WHERE [date] = @LatestDate
      AND country_code = 'vn'
      AND shop_name LIKE '%Bibica%'
)
SELECT
    COUNT(*)                                                            AS total_bibica_skus,
    SUM(CASE WHEN product_name LIKE '%Quasure%' THEN 1 ELSE 0 END)      AS quasure_skus,
    ROUND(SUM(CASE WHEN product_name LIKE '%Quasure%' THEN 1.0 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                        AS quasure_sku_pct,          -- Expect: 21.9
    ROUND(SUM(CASE WHEN product_name LIKE '%Quasure%'
                    THEN price * TRY_CAST(monthly_sold_value AS FLOAT) ELSE 0 END)
          * 100.0 / SUM(price * TRY_CAST(monthly_sold_value AS FLOAT)), 1)                 AS quasure_revenue_pct        -- Expect: 71.9
FROM Bibica_Latest;

-- Q3: Chiet khau Quasure vs. doi thu truc tiep (Nestle Boost Glucose Control)
SELECT
    ROUND(AVG(CASE WHEN product_name LIKE '%Quasure%'      THEN TRY_CAST(discount_percent AS FLOAT) END), 1) AS quasure_avg_discount,        -- Expect: 20.0
    ROUND(AVG(CASE WHEN product_name LIKE '%BOOST GLUCOSE%' THEN TRY_CAST(discount_percent AS FLOAT) END), 1) AS boost_glucose_avg_discount  -- Expect: 33.5
FROM dbo.products
WHERE [date] = @LatestDate
  AND country_code = 'vn'
  AND (product_name LIKE '%Quasure%' OR product_name LIKE '%BOOST GLUCOSE%');


-- ========================================================================
-- SLIDE 4: COMPETITIVE MONITORING SYSTEM
-- Q7 (SUPPORTING, v5): Top-5 SKU doi thu THAT SU cung phan khuc dinh duong
-- y te (Boost Glucose Control) voi Quasure, sap theo chiet khau hien tai
SELECT TOP 5
    p.shop_name       AS competitor_name,
    p.product_name    AS competitor_sku,
    p.price,
    TRY_CAST(p.discount_percent AS FLOAT) AS current_discount
FROM dbo.products p
WHERE p.[date] = @LatestDate
  AND p.country_code = 'vn'
  AND p.shop_name NOT LIKE '%Bibica%'
  AND p.product_name LIKE '%GLUCOSE%'
ORDER BY TRY_CAST(p.discount_percent AS FLOAT) DESC;
-- Expect: 4 dong, toan bo la "Boost Glucose Control" (Nestlé Health Science),
-- discount 35.0 / 33.0 / 33.0 / 33.0

-- Q8 (SUPPORTING, v5): so SKU doi thu THAT SU cung phan khuc dinh duong y te
-- dang giam gia >30% - nuoi logic "Action Threshold" (chenh lech >10 diem %
-- thi kich hoat review gia)
SELECT
    N'Medical Nutrition Segment (Boost Glucose Control)' AS target_segment,
    COUNT(DISTINCT p.item_id)                             AS competitor_skus_over_30pct,
    ROUND(AVG(TRY_CAST(p.discount_percent AS FLOAT)), 1)  AS avg_aggressive_discount
FROM dbo.products p
WHERE p.[date] = @LatestDate
  AND p.country_code = 'vn'
  AND p.shop_name NOT LIKE '%Bibica%'
  AND p.product_name LIKE '%GLUCOSE%'
  AND TRY_CAST(p.discount_percent AS FLOAT) > 30;
-- Expect: competitor_skus_over_30pct = 4, avg_aggressive_discount = 33.5
-- (ca 4/4 SKU doi thu that trong phan khuc nay deu dang giam >30% - cang
-- cung co luan diem "doi thu buoc phai giam sau, Bibica thi khong")


-- ========================================================================
-- SLIDE 5: PRODUCT MATCHING MATRIX (Bubble Chart)
-- ========================================================================

SELECT
    CASE WHEN product_name LIKE '%Quasure%'       THEN 'Quasure'
         WHEN product_name LIKE '%BOOST GLUCOSE%' THEN 'Boost Glucose Control'
         WHEN product_name LIKE '%BOOST OPTIMUM%' THEN 'Boost Optimum' END AS product_line,
    COUNT(*)                              AS n_sku,               -- Expect: 21 / 4 / 7
    ROUND(AVG(TRY_CAST(discount_percent AS FLOAT)), 1)       AS avg_discount_pct,    -- Expect: 20.0 / 33.5 / 32.1
    SUM(TRY_CAST(monthly_sold_value AS FLOAT))               AS total_monthly_volume,-- Expect: 32,539 / 814 / 2,580
    ROUND(SUM(price * TRY_CAST(monthly_sold_value AS FLOAT)), 0) AS total_monthly_revenue, -- Expect: 3,937,541,281 / 357,247,680 / 1,240,676,936
    SUM(rating_count)                     AS total_reviews        -- Expect: 12,547 / 90 / 894
FROM dbo.products
WHERE [date] = @LatestDate
  AND country_code = 'vn'
  AND (product_name LIKE '%Quasure%' OR product_name LIKE '%BOOST GLUCOSE%' OR product_name LIKE '%BOOST OPTIMUM%')
GROUP BY CASE WHEN product_name LIKE '%Quasure%'       THEN 'Quasure'
              WHEN product_name LIKE '%BOOST GLUCOSE%' THEN 'Boost Glucose Control'
              WHEN product_name LIKE '%BOOST OPTIMUM%' THEN 'Boost Optimum' END;



-- ========================================================================
-- SLIDE 6: DATA INSIGHTS (The Collapse of the Volume Trap)
-- ========================================================================

-- Q4: Doanh thu TB nhom giam gia sau (>40%) vs giu gia ky luat (<=40%),
-- loai Nestle Health Science (outlier) VA loai ca Bibica (slide mo ta hanh
-- vi THI TRUONG can phan ung, khong phai chinh Bibica)
SELECT
    CASE WHEN TRY_CAST(discount_percent AS FLOAT) > 40 THEN 'Deep Discount (>40%)'
         ELSE 'Disciplined Pricing (<=40%)' END        AS discount_strategy,
    COUNT(*)                                            AS total_skus,       -- Expect: 26 / 436
    ROUND(AVG(price * TRY_CAST(monthly_sold_value AS FLOAT)), 0)           AS avg_monthly_revenue -- Expect: 89,658,938 / 648,334,417
FROM dbo.products
WHERE [date] = @LatestDate
  AND country_code = 'vn'
  AND shop_name NOT LIKE '%Nestlé Health Science%'
  AND shop_name NOT LIKE '%Bibica%'
  AND TRY_CAST(discount_percent AS FLOAT) IS NOT NULL
GROUP BY CASE WHEN TRY_CAST(discount_percent AS FLOAT) > 40 THEN 'Deep Discount (>40%)'
              ELSE 'Disciplined Pricing (<=40%)' END;


-- ========================================================================
-- SLIDE 8: STRATEGIC SOLUTIONS I & II (Static Pricing & Bundling)
-- ========================================================================

-- Q5: Retail vs. Combo AOV va doanh thu TB/SKU, chi dong Quasure. Chi khop
-- tu khoa "Combo" (KHONG dung "Hop"/"Loc" vi de nham hop qua tang don le
-- thanh combo). Loai SKU qua tang khong ban.
SELECT
    CASE WHEN product_name LIKE '%Combo%' THEN 'Bundle/Combo' ELSE 'Retail/Single' END AS product_type,
    COUNT(*)                                    AS n_sku,           -- Expect: 16 / 5
    ROUND(AVG(price), 0)                        AS aov,             -- Expect: 143,742 / 113,739
    ROUND(AVG(price * TRY_CAST(monthly_sold_value AS FLOAT)), 0)   AS avg_revenue_per_sku -- Expect: 214,826,719 / 100,062,756
FROM dbo.products
WHERE [date] = @LatestDate
  AND country_code = 'vn'
  AND product_name LIKE '%Quasure%'
  AND product_name NOT LIKE '%không bán%'
  AND product_name NOT LIKE '%khong ban%'
GROUP BY CASE WHEN product_name LIKE '%Combo%' THEN 'Bundle/Combo' ELSE 'Retail/Single' END;
-- TRUY VẤN TÌM ĐIỂM ĐỨT GÃY SẢN LƯỢNG (TIPPING POINT ANALYSIS)
SELECT 
    CASE 
        -- Ép cột discount_percent thành FLOAT trước khi so sánh
        WHEN CAST(discount_percent AS FLOAT) BETWEEN 0 AND 5 THEN '1. 0% - 5%'
        WHEN CAST(discount_percent AS FLOAT) > 5 AND CAST(discount_percent AS FLOAT) <= 10 THEN '2. 6% - 10%'
        WHEN CAST(discount_percent AS FLOAT) > 10 AND CAST(discount_percent AS FLOAT) <= 15 THEN '3. 11% - 15%'
        WHEN CAST(discount_percent AS FLOAT) > 15 AND CAST(discount_percent AS FLOAT) <= 20 THEN '4. 16% - 20%'
        WHEN CAST(discount_percent AS FLOAT) > 20 AND CAST(discount_percent AS FLOAT) <= 25 THEN '5. 21% - 25%'
        WHEN CAST(discount_percent AS FLOAT) > 25 AND CAST(discount_percent AS FLOAT) <= 30 THEN '6. 26% - 30%'
        WHEN CAST(discount_percent AS FLOAT) > 30 THEN '7. > 30%'
        ELSE 'Không xác định'
    END AS discount_range,
    
    COUNT(item_id) AS total_products, 
    -- Ép cột monthly_sold_value thành FLOAT để tính tổng
    SUM(CAST(monthly_sold_value AS FLOAT)) AS total_sales_volume, 
    -- Ép cột price thành FLOAT để tính trung bình
    ROUND(AVG(CAST(price AS FLOAT)), 0) AS average_price 
    
FROM 
    dbo.products 
WHERE 
    product_name LIKE '%Bibica%' OR product_name LIKE '%Quasure%' 
GROUP BY 
    CASE 
        WHEN CAST(discount_percent AS FLOAT) BETWEEN 0 AND 5 THEN '1. 0% - 5%'
        WHEN CAST(discount_percent AS FLOAT) > 5 AND CAST(discount_percent AS FLOAT) <= 10 THEN '2. 6% - 10%'
        WHEN CAST(discount_percent AS FLOAT) > 10 AND CAST(discount_percent AS FLOAT) <= 15 THEN '3. 11% - 15%'
        WHEN CAST(discount_percent AS FLOAT) > 15 AND CAST(discount_percent AS FLOAT) <= 20 THEN '4. 16% - 20%'
        WHEN CAST(discount_percent AS FLOAT) > 20 AND CAST(discount_percent AS FLOAT) <= 25 THEN '5. 21% - 25%'
        WHEN CAST(discount_percent AS FLOAT) > 25 AND CAST(discount_percent AS FLOAT) <= 30 THEN '6. 26% - 30%'
        WHEN CAST(discount_percent AS FLOAT) > 30 THEN '7. > 30%'
        ELSE 'Không xác định'
    END
ORDER BY 
    discount_range ASC;




-- ========================================================================
-- SLIDE 4: BUSINESS CONTEXT (So sánh độ sâu chiết khấu)
-- ========================================================================
SELECT 
    ROUND(AVG(CASE WHEN shop_name LIKE '%Bibica%' THEN TRY_CAST(discount_percent AS FLOAT) END), 1) AS bibica_avg_discount,
    ROUND(AVG(CASE WHEN shop_name NOT LIKE '%Bibica%' THEN TRY_CAST(discount_percent AS FLOAT) END), 1) AS market_avg_discount
FROM dbo.products
WHERE country_code = 'vn'
  AND [date] = @LatestDate;


-- ========================================================================
-- SLIDE 17 (APPENDIX 1): Tác động của chiết khấu đến sản lượng bán Quasure
-- ========================================================================
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



