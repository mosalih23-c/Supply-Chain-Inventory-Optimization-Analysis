let
    Source = Csv.Document(File.Contents(FolderPath & "products.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    TrimmedText = Table.TransformColumns(PromotedHeaders, {{"ProductID", Text.Trim}, {"ProductName", Text.Trim}, {"Category", Text.Trim}, {"SupplierID", Text.Trim}}),
    ChangedTypes = Table.TransformColumnTypes(TrimmedText, {{"ProductID", type text}, {"ProductName", type text}, {"Category", type text}, {"SupplierID", type text}, {"UnitCost", type number}, {"UnitPrice", type number}, {"MinOrderQty", Int64.Type}, {"TargetStockDays", Int64.Type}}, "en-US"),
    AddedUnitMargin = Table.AddColumn(ChangedTypes, "UnitMargin", each [UnitPrice] - [UnitCost], type number),
    AddedMarginPct = Table.AddColumn(AddedUnitMargin, "MarginPct", each Number.Round([UnitMargin] / [UnitPrice], 4), Percentage.Type)
in
    AddedMarginPct
