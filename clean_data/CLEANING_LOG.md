# Task 2 – Data Cleaning Log (Power Query)

Workbook: `SupplyChain_PowerQuery_Clean.xlsx` (one Power Query per file, parameter `FolderPath`).
Clean CSV exports: this folder. M code for every query: `power_query_m/`.

## 1. Import
All six CSVs imported with `Csv.Document` (UTF-8, comma), headers promoted, text keys trimmed.

## 2–3. Data types & dates
- IDs and labels → Text; quantities and days → Whole Number; costs, prices, values → Decimal.
- All date columns (Date, OrderDate, ExpectedDeliveryDate, ActualDeliveryDate, SnapshotDate) → Date (locale en-US, ISO format).

## 4. Missing values
Only `PurchaseOrders.ActualDeliveryDate` has blanks: 12 rows, all `Status = Open`. Kept as null (not delivered yet), excluded from delay metrics.

## 5. Duplicate keys
| Table | Key | Rows | Duplicate keys | Duplicate rows |
|---|---|---|---|---|
| Products | ProductID | 150 | 0 | 0 |
| Suppliers | SupplierID | 25 | 0 | 0 |
| DailySales | Date + ProductID | 54,750 | 0 | 0 |
| Inventory | StoreID + ProductID | 1,500 | 0 | 0 |
| PurchaseOrders | POID | 800 | 0 | 0 |
| DeliveryPerformance | POID | 788 | 0 | 0 |

## 6. New inventory columns (Inventory query)
Assumption: `daily_sales_2025` UnitsSold is treated as per-store daily demand (chain-level gives 115–739 days of cover for every product, which does not fit a stockout scenario).

| Column | Formula |
|---|---|
| UnusableUnits | Reserved + Damaged |
| AvailableUnits | max(OnHand − Reserved − Damaged, 0) |
| UnusableExceedsOnHand | Yes when Reserved + Damaged > OnHand (14 rows) |
| InventoryValue / AvailableValue / DamagedValue | units × UnitCost |
| AvgDailySales / StdDevDailySales | from DailySales per product (2025) |
| LeadTimeDays | supplier StandardLeadTimeDays |
| DaysOfCover | AvailableUnits ÷ AvgDailySales |
| SafetyStockUnits | ⌈1.65 × StdDev × √LeadTime⌉ (95% service level) |
| ReorderPointUnits | ⌈AvgDailySales × LeadTime + SafetyStock⌉ |
| TargetStockUnits | ⌈AvgDailySales × TargetStockDays⌉ |
| ExcessUnits / ExcessValue | max(Available − TargetStock, 0); × UnitCost |
| StockStatus | Out of Stock (Available = 0) → Reorder Now (Available ≤ ROP) → Excess (DaysOfCover > TargetStockDays) → Healthy |

Result: Excess 892, Reorder Now 296, Healthy 294, Out of Stock 18 store-product rows. Inventory value 44,479,823.86; excess value 11,484,939.48 (currency not stated).

## 7. Purchase-order inconsistencies (all 800 records kept)
| Column | Meaning |
|---|---|
| PendingQty | OrderQty − ReceivedQty |
| FillRatePct, ReceivedValue | received share and its value |
| PlannedLeadTimeDays / ActualLeadTimeDays / DeliveryDelayDays | date differences (null while open) |
| StatusClean | Received · Open - Partially Received (11) · Open - Fully Received (Not Closed) (1: PO00601) |
| DeliveryStatus | Early 362 · Late 350 · On Time 76 · Open - Not Yet Due 10 · Open - Overdue 2 (PO00368, PO00397) |
| DataIssue / HasDataIssue | text reason + Yes/No flag; 12 POs flagged |

DeliveryPerformance: `DelayMatchesDates` confirms DeliveryDelayDays = Actual − Expected for all 788 rows; added DeliveryStatus, LateDays, ActualLeadTimeDays.

## 8. Export
Loaded every query to its own sheet in the workbook and exported each as `*_clean.csv` (dates as YYYY-MM-DD).
