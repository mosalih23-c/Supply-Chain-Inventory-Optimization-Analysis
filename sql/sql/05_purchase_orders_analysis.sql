-- =====================================================
-- Supply Chain & Inventory Optimization
-- Purchase Order Analysis Queries
-- =====================================================

-- 1. Purchase Order Status Summary
-- Purpose: Analyze purchase orders by status.
SELECT
    status_clean,
    COUNT(*) AS total_pos,
    SUM(order_qty) AS total_ordered_units,
    SUM(received_qty) AS total_received_units,
    SUM(order_qty - received_qty) AS remaining_units
FROM purchase_orders
GROUP BY status_clean
ORDER BY total_pos DESC;


-- 2. Open & Overdue Purchase Orders
-- Purpose: Identify outstanding and overdue purchase orders.
-- Note: Overdue status depends on CURRENT_DATE at query execution.
SELECT
    po.po_id,
    s.supplier_name,
    p.product_name,
    po.order_date,
    po.expected_delivery_date,
    po.order_qty,
    po.received_qty,
    (po.order_qty - po.received_qty) AS remaining_units,
    po.status_clean,
    CASE
        WHEN po.expected_delivery_date < CURRENT_DATE
             AND po.received_qty < po.order_qty
        THEN 'Overdue'
        ELSE 'Not Overdue'
    END AS delivery_status
FROM purchase_orders po
JOIN suppliers s
    ON po.supplier_id = s.supplier_id
JOIN products p
    ON po.product_id = p.product_id
WHERE po.received_qty < po.order_qty
   OR po.status_clean LIKE 'Open%'
ORDER BY po.expected_delivery_date;


-- 3. Partial Orders by Supplier
-- Purpose: Measure supplier fulfillment for incomplete purchase orders.
SELECT
    s.supplier_name,
    COUNT(*) AS partial_orders,
    SUM(po.order_qty) AS total_ordered,
    SUM(po.received_qty) AS total_received,
    SUM(po.order_qty - po.received_qty) AS remaining_units,
    ROUND(
        SUM(po.received_qty) * 100.0
        / NULLIF(SUM(po.order_qty), 0),
        2
    ) AS fulfillment_rate_pct
FROM purchase_orders po
JOIN suppliers s
    ON po.supplier_id = s.supplier_id
WHERE po.order_qty > po.received_qty
GROUP BY s.supplier_name
ORDER BY remaining_units DESC;
