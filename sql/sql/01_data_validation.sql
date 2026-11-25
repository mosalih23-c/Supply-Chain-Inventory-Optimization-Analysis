-- =====================================================
-- Supply Chain & Inventory Optimization
-- Data Validation / Schema Inspection
-- =====================================================

-- 1. Inspect Supplier Delivery Performance table columns
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'supplier_delivery_performance'
ORDER BY ordinal_position;
