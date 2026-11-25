let
    Source = Csv.Document(File.Contents(FolderPath & "suppliers.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    TrimmedText = Table.TransformColumns(PromotedHeaders, {{"SupplierID", Text.Trim}, {"SupplierName", Text.Trim}, {"Region", Text.Trim}, {"SupplierCategory", Text.Trim}}),
    ChangedTypes = Table.TransformColumnTypes(TrimmedText, {{"SupplierID", type text}, {"SupplierName", type text}, {"Region", type text}, {"ReliabilityScore", type number}, {"StandardLeadTimeDays", Int64.Type}, {"PaymentTermsDays", Int64.Type}, {"SupplierCategory", type text}}, "en-US")
in
    ChangedTypes
