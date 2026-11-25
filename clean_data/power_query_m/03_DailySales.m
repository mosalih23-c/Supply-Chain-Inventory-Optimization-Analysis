let
    Source = Csv.Document(File.Contents(FolderPath & "daily_sales_2025.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    TrimmedText = Table.TransformColumns(PromotedHeaders, {{"ProductID", Text.Trim}}),
    ChangedTypes = Table.TransformColumnTypes(TrimmedText, {{"Date", type date}, {"ProductID", type text}, {"UnitsSold", Int64.Type}}, "en-US"),
    AddedMonth = Table.AddColumn(ChangedTypes, "MonthNumber", each Date.Month([Date]), Int64.Type),
    AddedMonthName = Table.AddColumn(AddedMonth, "MonthName", each Date.ToText([Date], "MMM", "en-US"), type text),
    AddedWeekday = Table.AddColumn(AddedMonthName, "Weekday", each Date.ToText([Date], "ddd", "en-US"), type text),
    AddedZeroSaleFlag = Table.AddColumn(AddedWeekday, "IsZeroSaleDay", each if [UnitsSold] = 0 then "Yes" else "No", type text)
in
    AddedZeroSaleFlag
