# Supply Chain & Inventory Optimization — Project Dataset

## Scenario
You are a Data Analyst supporting a retail company with 10 stores. The business experiences stockouts, excess inventory, high storage costs, and supplier delivery variability. Your task is to diagnose the issues and propose data-driven replenishment actions.

## Dataset files
- `products.csv`: product master data, category, supplier, cost/price, minimum order quantity, target stock days.
- `suppliers.csv`: supplier attributes, reliability score, standard lead time, payment terms.
- `daily_sales_2025.csv`: daily units sold per product during 2025.
- `inventory_snapshot.csv`: store-level inventory as of 2025-12-31, including reserved and damaged units.
- `purchase_orders.csv`: purchase-order history, quantities, expected/actual dates, order value and status.
- `supplier_delivery_performance.csv`: received PO delivery timing and delay.

## Keys
- `ProductID` links products to sales, inventory, and purchase orders.
- `SupplierID` links products and purchase orders to suppliers.
- `POID` links purchase orders to supplier delivery performance.
- `StoreID` identifies store locations (STR01–STR10).

## Notes
- Synthetic portfolio dataset; no real company or customer data.
- Sales are demand proxies; inventory snapshot is a point-in-time observation.
- Some POs may still be open as of year-end.
- Validate business assumptions and document formulas before making recommendations.
