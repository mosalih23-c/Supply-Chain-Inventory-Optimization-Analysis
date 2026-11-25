-- =====================================================
-- Supply Chain & Inventory Optimization
-- Supplier Analysis Queries
-- =====================================================

-- 1. Supplier Late Delivery Performance
-- Purpose: Evaluate supplier punctuality and late delivery rates.
SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(*) AS total_deliveries,
    ROUND(AVG(sp.late_days), 2) AS avg_late_days,
    SUM(CASE WHEN sp.late_days > 0 THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(
        SUM(CASE WHEN sp.late_days > 0 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS late_delivery_pct
FROM supplier_delivery_performance sp
JOIN suppliers s
    ON sp.supplier_id = s.supplier_id
GROUP BY
    s.supplier_id,
    s.supplier_name
ORDER BY late_delivery_pct DESC;


-- 2. Top 10 Suppliers by Late Deliveries
-- Purpose: Identify suppliers with the highest number of late deliveries.
SELECT
    s.supplier_name,
    COUNT(*) AS total_deliveries,
    SUM(CASE WHEN sp.late_days > 0 THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(
        SUM(CASE WHEN sp.late_days > 0 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS late_pct
FROM supplier_delivery_performance sp
JOIN suppliers s
    ON sp.supplier_id = s.supplier_id
GROUP BY s.supplier_name
ORDER BY late_deliveries DESC
LIMIT 10;


-- 3. Supplier Reliability Score vs Delivery Performance
-- Purpose: Compare supplier reliability scores with actual delivery performance.
SELECT
    s.supplier_name,
    s.reliability_score,
    COUNT(*) AS total_deliveries,
    ROUND(AVG(sp.late_days), 2) AS avg_late_days,
    ROUND(
        SUM(CASE WHEN sp.late_days > 0 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS late_delivery_pct
FROM suppliers s
JOIN supplier_delivery_performance sp
    ON s.supplier_id = sp.supplier_id
GROUP BY
    s.supplier_id,
    s.supplier_name,
    s.reliability_score
ORDER BY s.reliability_score DESC;


-- 4. Supplier Lead Time Analysis
-- Purpose: Compare actual vs expected supplier lead times.
SELECT
    s.supplier_name,
    COUNT(*) AS completed_deliveries,
    ROUND(AVG(sp.actual_lead_time_days), 2) AS avg_actual_lead_time,
    ROUND(AVG(sp.expected_delivery_date - sp.order_date), 2) AS avg_expected_lead_time,
    ROUND(AVG(sp.late_days), 2) AS avg_late_days,
    ROUND(
        SUM(CASE WHEN sp.late_days > 0 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    ) AS late_delivery_pct
FROM supplier_delivery_performance sp
JOIN suppliers s
    ON sp.supplier_id = s.supplier_id
WHERE sp.actual_delivery_date IS NOT NULL
GROUP BY s.supplier_id, s.supplier_name
ORDER BY avg_actual_lead_time DESC;
