# Supply Chain & Inventory Optimization — SQL Query Collection

This folder organizes the SQL queries collected from the project's SQL EDA and analysis work.

## Files
- `01_data_validation.sql` — schema inspection query captured from the project history.
- `02_sales_analysis.sql` — best-selling products and corrected sales-versus-inventory comparison.
- `03_inventory_analysis.sql` — inventory status, excess inventory, stockouts, days of cover, and allocation candidates.
- `04_supplier_analysis.sql` — supplier late-delivery rate, late-delivery volume, reliability score comparison, and lead-time analysis.
- `05_purchase_orders_analysis.sql` — PO status, open/overdue orders, and supplier partial fulfillment.

## Notes
- Sales and inventory are aggregated separately before joining in the Sales vs Inventory query to avoid row multiplication caused by different data grains.
- Inventory allocation analysis identifies products with excess and shortages across the network; it does not directly calculate store-to-store transfer quantities or source/destination stores.
- Days of cover is a network-level estimate based on historical average daily sales and can hide store-level stock risk.
- The overdue PO query uses `CURRENT_DATE`, so its results depend on the date when it is run.
- This collection contains queries supplied in the conversation. It is not a full database export and does not include every possible validation query.
