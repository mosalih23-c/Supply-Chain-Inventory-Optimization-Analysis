# Supply Chain & Inventory Optimization

![Excel Power Query](https://img.shields.io/badge/Excel%20Power%20Query-Data%20Cleaning-217346?logo=microsoftexcel&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-SQL%20Analysis-336791?logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi&logoColor=black)

An end-to-end data analysis project for a retail company with **10 stores, 150 products and 25 suppliers** that suffers from stockouts, excess inventory and late supplier deliveries.

The project follows a full analyst workflow:

**Raw data → Data audit → Cleaning & feature engineering in Excel Power Query → SQL analysis in PostgreSQL → Findings & recommendations → Power BI dashboard**

> Synthetic portfolio dataset — no real company or customer data. Monetary values have no currency because the source does not state one.

---

## Business Problem

The company faces stockouts in some stores, excess stock in others, high storage costs and unreliable supplier delivery times. The analysis answers five business questions:

1. **Stockout risk** — which products and stores are out of stock or need reordering?
2. **Excess inventory** — where is excess stock concentrated?
3. **Supplier delays** — which suppliers deliver late, and how often?
4. **Tied-up capital** — how much money is locked in excess inventory?
5. **Reorder list** — what should be reordered, and what can be covered by moving stock between stores?

---

## Workflow

### 1. Data Understanding & Audit
Six raw CSV files ([`data/`](data/)) were reviewed for structure, keys, grain and relationships. A dedicated **data-quality query** (`07_DQ_Checks.m`) checks every table for row counts, duplicate keys, duplicate rows and missing values.

| Table | Grain | Rows | Duplicate keys | Missing values |
|---|---|---|---|---|
| Products | ProductID | 150 | 0 | 0 |
| Suppliers | SupplierID | 25 | 0 | 0 |
| Daily Sales | Date + ProductID | 54,750 | 0 | 0 |
| Inventory Snapshot | StoreID + ProductID | 1,500 | 0 | 0 |
| Purchase Orders | POID | 800 | 0 | 12 (`ActualDeliveryDate`, all open POs) |
| Delivery Performance | POID | 788 | 0 | 0 |

### 2. Data Cleaning & Feature Engineering — Excel Power Query
All cleaning was done in **Excel Power Query** in the workbook [`data/SupplyChain_PowerQuery_Clean.xlsx`](data/SupplyChain_PowerQuery_Clean.xlsx), with one query per table and a `FolderPath` parameter. The M code for every query is in [`clean_data/power_query_m/`](clean_data/power_query_m/), every step is documented in [`clean_data/CLEANING_LOG.md`](clean_data/CLEANING_LOG.md), and the cleaned tables are exported as `*_clean.csv` in [`clean_data/`](clean_data/).

**Cleaning**
- Trimmed text keys, set correct data types (text IDs, whole-number quantities, decimal costs, dates).
- Kept the 12 blank delivery dates as null — they belong to open POs that have not been delivered yet.
- Kept all 800 purchase orders and **flagged** inconsistencies instead of deleting them (`DataIssue`, `HasDataIssue`), e.g. a PO that is fully received but still open (PO00601) and two overdue POs (PO00368, PO00397).
- Validated that the delivery delay equals actual − expected date for all 788 deliveries (`DelayMatchesDates`).

**New calculated columns**

| Table | Columns added |
|---|---|
| Products | `UnitMargin`, `MarginPct` |
| Daily Sales | `MonthNumber`, `MonthName`, `Weekday`, `IsZeroSaleDay` |
| Purchase Orders | `PendingQty`, `FillRatePct`, `ReceivedValue`, `PlannedLeadTimeDays`, `ActualLeadTimeDays`, `DeliveryDelayDays`, `StatusClean`, `DeliveryStatus` |
| Delivery Performance | `DeliveryStatus` (Early / On Time / Late), `LateDays`, `ActualLeadTimeDays` |
| Inventory | Inventory-planning metrics below |

**Inventory planning metrics** (merged from sales, products and suppliers):

| Metric | Formula |
|---|---|
| Available Units | max(On Hand − Reserved − Damaged, 0) |
| Days of Cover | Available Units ÷ Avg Daily Sales |
| Safety Stock | ⌈1.65 × StdDev Daily Sales × √Lead Time⌉ (95% service level) |
| Reorder Point | ⌈Avg Daily Sales × Lead Time + Safety Stock⌉ |
| Target Stock | ⌈Avg Daily Sales × Target Stock Days⌉ |
| Excess Units / Value | max(Available − Target Stock, 0) × Unit Cost |
| **Stock Status** | Out of Stock → Reorder Now (≤ reorder point) → Excess (cover > target days) → Healthy |

Result: **892 Excess, 296 Reorder Now, 294 Healthy, 18 Out of Stock** store-product records.

### 3. SQL Analysis — PostgreSQL
The cleaned tables were loaded into PostgreSQL and analysed with the queries in [`sql/sql/`](sql/sql/):

| File | Analysis |
|---|---|
| `01_data_validation.sql` | Schema inspection |
| `02_sales_analysis.sql` | Top 10 best-selling products; sales vs inventory (each table aggregated **before** joining to avoid row duplication from different grains) |
| `03_inventory_analysis.sql` | Stock status summary; excess value by category (window function for % of total); stockouts by category; network days of cover; **allocation opportunities** (products with excess in some stores and shortages in others) |
| `04_supplier_analysis.sql` | Late-delivery rate by supplier; top suppliers by late deliveries; reliability score vs actual performance; actual vs expected lead time |
| `05_purchase_orders_analysis.sql` | PO status summary; open & overdue POs; partial orders and fulfilment rate by supplier |

### 4. Findings & Recommendations
The SQL results were turned into business findings and an action plan in [`reborts/Supply_Chain_Tasks_5_6_Findings_Recommendations.docx`](reborts/Supply_Chain_Tasks_5_6_Findings_Recommendations.docx) (summarised below).

### 5. Power BI Dashboard
The cleaned CSVs feed a four-page interactive dashboard, saved as a **Power BI Project (`.pbip`)** so the data model, DAX measures and report layout are stored as readable text files in [`powerbi/`](powerbi/).

---

## Key Findings

1. **Capital tied up in excess stock** — 892 store-product records are in excess, holding **11,394,554** in excess value.
2. **Electronics drives the excess** — Electronics alone accounts for **58.06%** of excess value (6,615,576). Electronics, Home & Kitchen (15.16%) and Sports (12.68%) together account for **85.9%**.
3. **Inventory is imbalanced across stores** — the same product can be in excess in some stores and out of stock in others. For example, PRD0014 is in excess in 7 stores and out of stock in 1 (933 excess units), and PRD0020 is in excess in 8 stores and out of stock in 1 (879 excess units).
4. **Supplier delays** — 44.4% of 788 deliveries arrived late. The highest late rates are Summit Wholesale (69.23%, 13 deliveries), Riyadh Wholesale (63.16%, 38) and Global Link (60.00%, 50 — the highest number of late deliveries, 30).
5. **Outstanding purchase orders** — 11 partially received open POs still have **723 units** outstanding, led by Urban Trade (216) and Global Link (153). One fully received PO is still open.
6. **Seasonal demand** — sales peaked in March (15,545 units) and fell to September (10,520 units, about −32.3%) before recovering in Q4.
7. **Network averages hide store risk** — every product shows about 115+ days of cover across the network, yet store-level Reorder Now and Out-of-Stock cases remain.

## Recommendations

| Priority | Recommendation | Objective |
|---|---|---|
| 1 | Optimise Electronics inventory — review overstock, pause replenishment for overstocked items | Release tied-up capital |
| 2 | Store-to-store transfers before raising new POs | Reduce stockouts and new purchases |
| 3 | Supplier performance management — scorecards, delivery targets, lead-time variability in safety stock | Improve delivery reliability |
| 4 | Purchase-order monitoring — track open POs, follow up overdue ones, close fully received POs | Reduce replenishment uncertainty |
| 5 | Demand-based planning — use monthly trends and store-level demand, not annual averages | Align stock with demand |
| 6 | Inventory health dashboard — track stock status, excess, supplier delays and open POs | Improve monitoring and decisions |

---

## Power BI Dashboard

### Executive Overview
![Executive Overview](images/Screenshot%202026-11-24%20193223.png)

### Inventory Analysis
![Inventory Analysis](images/Screenshot%202026-11-24%20193248.png)

### Supplier Performance
![Supplier Performance](images/Screenshot%202026-11-24%20193331.png)

### Purchase Orders
![Purchase Orders](images/Screenshot%202026-11-24%20193347.png)

| Page | KPIs | Main visuals | Slicers |
|---|---|---|---|
| **Executive Overview** | Total Sales Units, Total Inventory Units, Available Units, Excess Inventory Value, Stockout Records, Late Delivery % | Monthly sales trend, inventory status donut, excess value by category, stockouts by category | Category, Product, Store |
| **Inventory Analysis** | On-Hand Units, Available Units, Excess Units, Excess Value, Records Requiring Reorder | Status by store, excess vs reorder by category, inventory by store, allocation opportunities table, detailed inventory table | Category, Store, Product, Stock Status |
| **Supplier Performance** | Total Suppliers, Deliveries, Late Deliveries, Late %, Avg Actual Lead Time | Late % by supplier, late vs on-time, actual vs expected lead time, reliability vs late % scatter, supplier ranking | Supplier, Order Date, Delivery Status |
| **Purchase Orders** | Total POs, Ordered Units, Received Units, Outstanding Units, Fulfillment Rate % | PO status donut, outstanding units by supplier, ordered vs received by category, overdue & open POs, PO detail table | Supplier, PO Status, Order Date, Product |

**Data model:** star schema — `Products`, `Suppliers`, `Stores` and `DimDate` filter the four fact tables (`Sales`, `Inventory`, `PurchaseOrders`, `Deliveries`). Fact tables are never joined to each other, so measures are not duplicated across different grains.

**Interactivity:** page navigation, cross-filtering, drill-down from category to product, tooltips and status colours (green = healthy, amber = warning, red = critical).

### How to open
1. Download or clone this repository.
2. Open `powerbi/SupplyChain_Dashboard.pbip` in a recent version of Power BI Desktop.
3. **Home → Transform data → Edit parameters** → set `FolderPath` to your local `clean_data` folder, ending with `\` (e.g. `C:\Projects\Supply-Chain\clean_data\`).
4. Click **Refresh**.

---

## Repository Structure

```
├── data/                  Raw CSVs + Excel Power Query cleaning workbook
├── clean_data/            Cleaned CSVs, CLEANING_LOG.md, power_query_m/ (M code)
├── sql/                   PostgreSQL analysis queries
├── reborts/               Findings & recommendations report (Word)
├── powerbi/               Power BI project (.pbip)
├── images/                Dashboard screenshots
├── docs/                  Dataset description
└── README.md
```

## Assumptions & Limitations

- Daily sales are treated as **per-store daily demand** when calculating cover, safety stock and reorder points (chain-level demand gives 115–739 days of cover for every product, which does not fit a stockout scenario).
- The inventory snapshot (31 Dec 2025) and the sales history (2025) cover different periods; days of cover is based on historical averages, not a forecast.
- Sales and purchase orders are not recorded per store, so store-level analysis applies to inventory only.
- Some suppliers have small delivery samples (e.g. 13 deliveries), so late rates should be read together with volume.
- The allocation analysis identifies candidate products for transfers; it does not assign source and destination stores.

## Tools

Excel Power Query (M) · PostgreSQL · Power BI · DAX

## Author

**Mohamed Salih** — Data Analyst, Riyadh, Saudi Arabia
[LinkedIn](https://www.linkedin.com/in/mohamed-salih-341bb0368/) · [GitHub](https://github.com/mosalih23-c) · [Portfolio](https://mosalih23-c.github.io/mohamed-salih-portfolio/)
