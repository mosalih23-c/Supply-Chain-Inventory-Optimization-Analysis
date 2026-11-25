-- =====================================================
-- Supply Chain & Inventory Optimization
-- Sales Analysis Queries
-- =====================================================

-- 1. Top 10 Best-Selling Products
-- Purpose: Identify products with the highest total sales.
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(ds.units_sold) AS total_units_sold
FROM daily_sales ds
JOIN products p
    ON ds.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY total_units_sold DESC
LIMIT 10;


-- 2. Sales vs Inventory Comparison
-- Purpose: Compare product sales against current inventory.
-- Note: Aggregate each table before joining to prevent duplication
-- from the different data grains (product-day vs product-store).
WITH sales_summary AS (
    SELECT
        product_id,
        SUM(units_sold) AS total_sales
    FROM daily_sales
    GROUP BY product_id
),
inventory_summary AS (
    SELECT
        product_id,
        SUM(on_hand_units) AS total_on_hand,
        SUM(available_units) AS total_available,
        SUM(excess_units) AS total_excess
    FROM inventory_snapshot
    GROUP BY product_id
)
SELECT
    p.product_id,
    p.product_name,
    s.total_sales,
    i.total_on_hand,
    i.total_available,
    i.total_excess
FROM products p
JOIN sales_summary s
    ON p.product_id = s.product_id
JOIN inventory_summary i
    ON p.product_id = i.product_id
ORDER BY s.total_sales DESC
LIMIT 10;
