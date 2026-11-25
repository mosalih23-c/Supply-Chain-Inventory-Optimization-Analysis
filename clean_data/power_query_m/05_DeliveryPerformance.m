let
    Source = Csv.Document(File.Contents(FolderPath & "supplier_delivery_performance.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    TrimmedText = Table.TransformColumns(PromotedHeaders, {{"POID", Text.Trim}, {"SupplierID", Text.Trim}}),
    ChangedTypes = Table.TransformColumnTypes(TrimmedText, {{"POID", type text}, {"SupplierID", type text}, {"OrderDate", type date}, {"ExpectedDeliveryDate", type date}, {"ActualDeliveryDate", type date}, {"DeliveryDelayDays", Int64.Type}, {"OrderQty", Int64.Type}, {"ReceivedQty", Int64.Type}}, "en-US"),
    AddedDelayCheck = Table.AddColumn(ChangedTypes, "DelayMatchesDates", each if Duration.Days([ActualDeliveryDate] - [ExpectedDeliveryDate]) = [DeliveryDelayDays] then "Yes" else "No", type text),
    AddedDeliveryStatus = Table.AddColumn(AddedDelayCheck, "DeliveryStatus", each if [DeliveryDelayDays] > 0 then "Late" else if [DeliveryDelayDays] = 0 then "On Time" else "Early", type text),
    AddedLateDays = Table.AddColumn(AddedDeliveryStatus, "LateDays", each List.Max({[DeliveryDelayDays], 0}), Int64.Type),
    AddedActualLeadTime = Table.AddColumn(AddedLateDays, "ActualLeadTimeDays", each Duration.Days([ActualDeliveryDate] - [OrderDate]), Int64.Type)
in
    AddedActualLeadTime
