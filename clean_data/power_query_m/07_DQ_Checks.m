let
    Check = (tableName as text, t as table, keyCols as list, sourceCols as list) =>
        let
            src = Table.SelectColumns(t, sourceCols),
            missingByCol = List.Transform(sourceCols, (c) => [Col = c, N = List.Count(List.Select(Table.Column(src, c), each _ = null))]),
            distinctKeys = Table.RowCount(Table.Distinct(Table.SelectColumns(t, keyCols)))
        in
            [
                Table = tableName,
                Rows = Table.RowCount(t),
                SourceColumns = List.Count(sourceCols),
                ColumnsAfterCleaning = Table.ColumnCount(t),
                KeyColumns = Text.Combine(keyCols, " + "),
                DistinctKeys = distinctKeys,
                DuplicateKeys = Table.RowCount(t) - distinctKeys,
                DuplicateRows = Table.RowCount(src) - Table.RowCount(Table.Distinct(src)),
                MissingValues = List.Sum(List.Transform(missingByCol, each [N])),
                MissingDetail = Text.Combine(List.Transform(List.Select(missingByCol, each [N] > 0), each [Col] & " (" & Text.From([N]) & ")"), ", ")
            ],
    Results = {
        Check("Products", Products, {"ProductID"}, {"ProductID", "ProductName", "Category", "SupplierID", "UnitCost", "UnitPrice", "MinOrderQty", "TargetStockDays"}),
        Check("Suppliers", Suppliers, {"SupplierID"}, {"SupplierID", "SupplierName", "Region", "ReliabilityScore", "StandardLeadTimeDays", "PaymentTermsDays", "SupplierCategory"}),
        Check("DailySales", DailySales, {"Date", "ProductID"}, {"Date", "ProductID", "UnitsSold"}),
        Check("Inventory", Inventory, {"StoreID", "ProductID"}, {"StoreID", "ProductID", "OnHandUnits", "ReservedUnits", "DamagedUnits", "SnapshotDate"}),
        Check("PurchaseOrders", PurchaseOrders, {"POID"}, {"POID", "ProductID", "SupplierID", "OrderDate", "ExpectedDeliveryDate", "ActualDeliveryDate", "OrderQty", "ReceivedQty", "OrderValue", "Status"}),
        Check("DeliveryPerformance", DeliveryPerformance, {"POID"}, {"POID", "SupplierID", "OrderDate", "ExpectedDeliveryDate", "ActualDeliveryDate", "DeliveryDelayDays", "OrderQty", "ReceivedQty"})
    },
    AsTable = Table.FromRecords(Results),
    ChangedTypes = Table.TransformColumnTypes(AsTable, {{"Table", type text}, {"Rows", Int64.Type}, {"SourceColumns", Int64.Type}, {"ColumnsAfterCleaning", Int64.Type}, {"KeyColumns", type text}, {"DistinctKeys", Int64.Type}, {"DuplicateKeys", Int64.Type}, {"DuplicateRows", Int64.Type}, {"MissingValues", Int64.Type}, {"MissingDetail", type text}})
in
    ChangedTypes
