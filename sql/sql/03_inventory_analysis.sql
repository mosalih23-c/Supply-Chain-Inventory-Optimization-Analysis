-- =====================================================
-- Supply Chain & Inventory Optimization
-- Inventory Analysis Queries
-- =====================================================

-- 1. Inventory Status Analysis
-- Purpose: Analyze inventory distribution by stock status.
SELECT
    stock_status,
    COUNT(*) AS product_store_count,
    SUM(on_hand_units) AS total_on_hand,
    SUM(available_units) AS total_available,
    SUM(excess_value) AS total_excess_value
FROM inventory_snapshot
GROUP BY stock_status
ORDER BY product_store_count DESC;


-- 2. Excess Inventory Analysis by Category
-- Purpose: Analyze excess stock value and its contribution
-- to total excess inventory value.
SELECT
    category,
    COUNT(*) AS excess_records,
    SUM(excess_units) AS excess_units,
    ROUND(SUM(excess_value), 2) AS excess_inventory_value,
    ROUND(
        SUM(excess_value) * 100.0
        / SUM(SUM(excess_value)) OVER (),
        2
    ) AS pct_of_total_excess_value
FROM inventory_snapshot
WHERE stock_status = 'Excess'
GROUP BY category
ORDER BY excess_inventory_value DESC;


-- 3. Stockout Analysis by Category
-- Purpose: Identify stockout distribution across categories.
SELECT
    category,
    COUNT(*) AS stockout_records,
    SUM(on_hand_units) AS on_hand_units,
    SUM(reserved_units) AS reserved_units,
    SUM(damaged_units) AS damaged_units
FROM inventory_snapshot
WHERE stock_status = 'Out of Stock'
GROUP BY category
ORDER BY stockout_records DESC;


-- 4. Days of Inventory Cover
-- Purpose: Estimate inventory coverage based on historical demand.
-- Note: Network-level cover can hide store-level shortages.
WITH sales_summary AS (
    SELECT
        product_id,
        SUM(units_sold) AS total_sales,
        SUM(units_sold) / 365.0 AS avg_daily_sales
    FROM daily_sales
    GROUP BY product_id
),
inventory_summary AS (
    SELECT
        product_id,
        SUM(available_units) AS total_available
    FROM inventory_snapshot
    GROUP BY product_id
)
SELECT
    p.product_id,
    p.product_name,
    p.category,
    s.total_sales,
    ROUND(s.avg_daily_sales::numeric, 2) AS avg_daily_sales,
    i.total_available,
    ROUND(
        i.total_available / NULLIF(s.avg_daily_sales, 0),
        2
    ) AS days_of_cover
FROM products p
JOIN sales_summary s ON p.product_id = s.product_id
JOIN inventory_summary i ON p.product_id = i.product_id
ORDER BY days_of_cover ASC;


-- 5. Inventory Allocation Opportunities
-- Purpose: Identify products with excess stock in some stores
-- and shortages (reorder/out-of-stock) in other stores.
-- Note: This identifies candidate products; it does not directly
-- specify transfer source and destination stores.
SELECT
    i.product_id,
    p.product_name,
    i.category,
    COUNT(*) AS total_stores,
    SUM(CASE WHEN i.stock_status = 'Excess' THEN 1 ELSE 0 END) AS excess_stores,
    SUM(CASE WHEN i.stock_status = 'Reorder Now' THEN 1 ELSE 0 END) AS reorder_stores,
    SUM(CASE WHEN i.stock_status = 'Out of Stock' THEN 1 ELSE 0 END) AS out_of_stock_stores,
    SUM(i.excess_units) AS total_excess_units
FROM inventory_snapshot i
JOIN products p
    ON i.product_id = p.product_id
GROUP BY
    i.product_id,
    p.product_name,
    i.category
HAVING
    SUM(CASE WHEN i.stock_status = 'Excess' THEN 1 ELSE 0 END) > 0
    AND
    SUM(CASE WHEN i.stock_status IN ('Reorder Now', 'Out of Stock') THEN 1 ELSE 0 END) > 0
ORDER BY
    out_of_stock_stores DESC,
    reorder_stores DESC,
    total_excess_units DESC;
