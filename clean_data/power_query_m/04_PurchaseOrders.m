let
    SnapshotDate = #date(2025, 12, 31),
    Source = Csv.Document(File.Contents(FolderPath & "purchase_orders.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    TrimmedText = Table.TransformColumns(PromotedHeaders, {{"POID", Text.Trim}, {"ProductID", Text.Trim}, {"SupplierID", Text.Trim}, {"Status", Text.Trim}, {"ActualDeliveryDate", Text.Trim}}),
    BlankToNull = Table.ReplaceValue(TrimmedText, "", null, Replacer.ReplaceValue, {"ActualDeliveryDate"}),
    ChangedTypes = Table.TransformColumnTypes(BlankToNull, {{"POID", type text}, {"ProductID", type text}, {"SupplierID", type text}, {"OrderDate", type date}, {"ExpectedDeliveryDate", type date}, {"ActualDeliveryDate", type date}, {"OrderQty", Int64.Type}, {"ReceivedQty", Int64.Type}, {"OrderValue", type number}, {"Status", type text}}, "en-US"),
    AddedPendingQty = Table.AddColumn(ChangedTypes, "PendingQty", each [OrderQty] - [ReceivedQty], Int64.Type),
    AddedFillRate = Table.AddColumn(AddedPendingQty, "FillRatePct", each Number.Round([ReceivedQty] / [OrderQty], 4), Percentage.Type),
    AddedReceivedValue = Table.AddColumn(AddedFillRate, "ReceivedValue", each Number.Round([OrderValue] * [ReceivedQty] / [OrderQty], 2), type number),
    AddedPlannedLeadTime = Table.AddColumn(AddedReceivedValue, "PlannedLeadTimeDays", each Duration.Days([ExpectedDeliveryDate] - [OrderDate]), Int64.Type),
    AddedActualLeadTime = Table.AddColumn(AddedPlannedLeadTime, "ActualLeadTimeDays", each if [ActualDeliveryDate] = null then null else Duration.Days([ActualDeliveryDate] - [OrderDate]), Int64.Type),
    AddedDelay = Table.AddColumn(AddedActualLeadTime, "DeliveryDelayDays", each if [ActualDeliveryDate] = null then null else Duration.Days([ActualDeliveryDate] - [ExpectedDeliveryDate]), Int64.Type),
    AddedStatusClean = Table.AddColumn(AddedDelay, "StatusClean", each
        if [Status] = "Received" then "Received"
        else if [ReceivedQty] >= [OrderQty] then "Open - Fully Received (Not Closed)"
        else if [ReceivedQty] > 0 then "Open - Partially Received"
        else "Open - Not Received", type text),
    AddedDeliveryStatus = Table.AddColumn(AddedStatusClean, "DeliveryStatus", each
        if [Status] = "Open" then (if [ExpectedDeliveryDate] < SnapshotDate then "Open - Overdue" else "Open - Not Yet Due")
        else if [DeliveryDelayDays] > 0 then "Late"
        else if [DeliveryDelayDays] = 0 then "On Time"
        else "Early", type text),
    AddedDataIssue = Table.AddColumn(AddedDeliveryStatus, "DataIssue", each
        Text.Combine(List.RemoveNulls({
            if [Status] = "Open" and [ReceivedQty] > 0 and [ActualDeliveryDate] = null then "Open PO has received units but no delivery date" else null,
            if [Status] = "Open" and [ReceivedQty] >= [OrderQty] then "Fully received but status still Open" else null,
            if [Status] = "Open" and [ExpectedDeliveryDate] < SnapshotDate then "Past expected date and still open" else null,
            if [Status] = "Received" and [ActualDeliveryDate] = null then "Received PO missing delivery date" else null,
            if [ReceivedQty] > [OrderQty] then "Received more than ordered" else null
        }), "; "), type text),
    DataIssueBlankToNull = Table.ReplaceValue(AddedDataIssue, "", null, Replacer.ReplaceValue, {"DataIssue"}),
    AddedIssueFlag = Table.AddColumn(DataIssueBlankToNull, "HasDataIssue", each if [DataIssue] = null then "No" else "Yes", type text)
in
    AddedIssueFlag
