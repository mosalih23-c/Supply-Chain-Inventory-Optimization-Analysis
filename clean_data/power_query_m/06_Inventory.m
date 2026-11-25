let
    ServiceLevelZ = 1.65,
    Source = Csv.Document(File.Contents(FolderPath & "inventory_snapshot.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    TrimmedText = Table.TransformColumns(PromotedHeaders, {{"StoreID", Text.Trim}, {"ProductID", Text.Trim}}),
    ChangedTypes = Table.TransformColumnTypes(TrimmedText, {{"StoreID", type text}, {"ProductID", type text}, {"OnHandUnits", Int64.Type}, {"ReservedUnits", Int64.Type}, {"DamagedUnits", Int64.Type}, {"SnapshotDate", type date}}, "en-US"),
    SalesStats = Table.Group(DailySales, {"ProductID"}, {{"AvgDailySales", each Number.Round(List.Average([UnitsSold]), 4), type number}, {"StdDevDailySales", each Number.Round(List.StandardDeviation([UnitsSold]), 4), type number}}),
    ProductInfo = Table.SelectColumns(Products, {"ProductID", "Category", "SupplierID", "UnitCost", "MinOrderQty", "TargetStockDays"}),
    SupplierInfo = Table.SelectColumns(Suppliers, {"SupplierID", "StandardLeadTimeDays"}),
    MergedProducts = Table.NestedJoin(ChangedTypes, {"ProductID"}, ProductInfo, {"ProductID"}, "P", JoinKind.LeftOuter),
    ExpandedProducts = Table.ExpandTableColumn(MergedProducts, "P", {"Category", "SupplierID", "UnitCost", "MinOrderQty", "TargetStockDays"}),
    MergedSuppliers = Table.NestedJoin(ExpandedProducts, {"SupplierID"}, SupplierInfo, {"SupplierID"}, "S", JoinKind.LeftOuter),
    ExpandedSuppliers = Table.ExpandTableColumn(MergedSuppliers, "S", {"StandardLeadTimeDays"}, {"LeadTimeDays"}),
    MergedSales = Table.NestedJoin(ExpandedSuppliers, {"ProductID"}, SalesStats, {"ProductID"}, "D", JoinKind.LeftOuter),
    ExpandedSales = Table.ExpandTableColumn(MergedSales, "D", {"AvgDailySales", "StdDevDailySales"}),
    AddedUnusable = Table.AddColumn(ExpandedSales, "UnusableUnits", each [ReservedUnits] + [DamagedUnits], Int64.Type),
    AddedAvailable = Table.AddColumn(AddedUnusable, "AvailableUnits", each List.Max({[OnHandUnits] - [ReservedUnits] - [DamagedUnits], 0}), Int64.Type),
    AddedNegativeFlag = Table.AddColumn(AddedAvailable, "UnusableExceedsOnHand", each if [UnusableUnits] > [OnHandUnits] then "Yes" else "No", type text),
    AddedInventoryValue = Table.AddColumn(AddedNegativeFlag, "InventoryValue", each Number.Round([OnHandUnits] * [UnitCost], 2), type number),
    AddedAvailableValue = Table.AddColumn(AddedInventoryValue, "AvailableValue", each Number.Round([AvailableUnits] * [UnitCost], 2), type number),
    AddedDamagedValue = Table.AddColumn(AddedAvailableValue, "DamagedValue", each Number.Round([DamagedUnits] * [UnitCost], 2), type number),
    AddedDaysOfCover = Table.AddColumn(AddedDamagedValue, "DaysOfCover", each if [AvgDailySales] = 0 then null else Number.Round([AvailableUnits] / [AvgDailySales], 1), type number),
    AddedSafetyStock = Table.AddColumn(AddedDaysOfCover, "SafetyStockUnits", each Number.RoundUp(ServiceLevelZ * [StdDevDailySales] * Number.Sqrt([LeadTimeDays])), Int64.Type),
    AddedReorderPoint = Table.AddColumn(AddedSafetyStock, "ReorderPointUnits", each Number.RoundUp([AvgDailySales] * [LeadTimeDays] + [SafetyStockUnits]), Int64.Type),
    AddedTargetStock = Table.AddColumn(AddedReorderPoint, "TargetStockUnits", each Number.RoundUp([AvgDailySales] * [TargetStockDays]), Int64.Type),
    AddedExcessUnits = Table.AddColumn(AddedTargetStock, "ExcessUnits", each List.Max({[AvailableUnits] - [TargetStockUnits], 0}), Int64.Type),
    AddedExcessValue = Table.AddColumn(AddedExcessUnits, "ExcessValue", each Number.Round([ExcessUnits] * [UnitCost], 2), type number),
    AddedStockStatus = Table.AddColumn(AddedExcessValue, "StockStatus", each
        if [AvailableUnits] = 0 then "Out of Stock"
        else if [AvailableUnits] <= [ReorderPointUnits] then "Reorder Now"
        else if [DaysOfCover] > [TargetStockDays] then "Excess"
        else "Healthy", type text),
    Reordered = Table.ReorderColumns(AddedStockStatus, {"StoreID", "ProductID", "Category", "SupplierID", "SnapshotDate", "OnHandUnits", "ReservedUnits", "DamagedUnits", "UnusableUnits", "AvailableUnits", "UnusableExceedsOnHand", "UnitCost", "InventoryValue", "AvailableValue", "DamagedValue", "AvgDailySales", "StdDevDailySales", "LeadTimeDays", "TargetStockDays", "MinOrderQty", "DaysOfCover", "SafetyStockUnits", "ReorderPointUnits", "TargetStockUnits", "ExcessUnits", "ExcessValue", "StockStatus"}),
    Sorted = Table.Sort(Reordered, {{"StoreID", Order.Ascending}, {"ProductID", Order.Ascending}})
in
    Sorted
