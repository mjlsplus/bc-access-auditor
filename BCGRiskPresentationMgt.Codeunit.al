codeunit 50606 "BCG Risk Presentation Mgt."
{
    procedure TryGetCurrentRunNo(var CurrentRunNo: Code[20]): Boolean
    var
        CurrentRunId: Guid;
    begin
        exit(TryGetCurrentRun(CurrentRunId, CurrentRunNo));
    end;

    procedure TryGetCurrentRun(var CurrentRunId: Guid; var CurrentRunNo: Code[20]): Boolean
    var
        AuditRun: Record "BCG Audit Run";
        LatestStartedAt: DateTime;
    begin
        Clear(CurrentRunId);
        Clear(CurrentRunNo);
        AuditRun.SetRange(Status, AuditRun.Status::Finished);
        AuditRun.SetFilter("Run No.", '<>%1', '');

        if AuditRun.FindSet() then
            repeat
                if (AuditRun."Started At" > LatestStartedAt) or
                   ((AuditRun."Started At" = LatestStartedAt) and (AuditRun."Run No." > CurrentRunNo))
                then begin
                    LatestStartedAt := AuditRun."Started At";
                    CurrentRunNo := AuditRun."Run No.";
                    CurrentRunId := AuditRun."Run ID";
                end;
            until AuditRun.Next() = 0;

        exit(not IsNullGuid(CurrentRunId));
    end;

    procedure BuildSummary(RunId: Guid; var Findings: Record "BCG User Conflict Result"; var Buffer: Record "BCG Detected Conflict Buffer")
    var
        SeenUsers: Dictionary of [Guid, Boolean];
        SeenCompanies: Dictionary of [Text, Boolean];
        HasConflict: Boolean;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();
        if IsNullGuid(RunId) then
            exit;

        // Preserve the caller's finding filters. Only the run identity and scan order are fixed here.
        Findings.SetRange("Run ID", RunId);
        Findings.SetCurrentKey("Run ID", "Conflict Code");
        Findings.Ascending(true);
        Findings.SetLoadFields("Run ID", "Conflict Code", "Conflict Name", Severity,
            "User Security ID", "Company Name", "Has Special Permission Source", "Has Security Group Source", "Has Direct Source");

        if Findings.FindSet(false) then
            repeat
                if (not HasConflict) or (Buffer."Conflict Code" <> Findings."Conflict Code") then begin
                    if HasConflict then
                        SaveSummary(Buffer);
                    Buffer.Init();
                    Buffer."Run ID" := RunId;
                    Buffer."Conflict Code" := Findings."Conflict Code";
                    Buffer."Conflict Name" := Findings."Conflict Name";
                    Buffer.Severity := Findings.Severity;
                    Buffer."Representative Entry No." := Findings."Entry No.";
                    Clear(SeenUsers);
                    Clear(SeenCompanies);
                    HasConflict := true;
                end;

                if (Buffer."Conflict Name" <> Findings."Conflict Name") or (Buffer.Severity <> Findings.Severity) then
                    Buffer."Inconsistent Stored Values" := true;
                // Keep one row: use an actual stored name and the highest stored severity.
                if Findings."Entry No." < Buffer."Representative Entry No." then begin
                    Buffer."Conflict Name" := Findings."Conflict Name";
                    Buffer."Representative Entry No." := Findings."Entry No.";
                end;
                if Findings.Severity > Buffer.Severity then
                    Buffer.Severity := Findings.Severity;

                Buffer."Finding Count" += 1;
                if not SeenUsers.ContainsKey(Findings."User Security ID") then begin
                    SeenUsers.Add(Findings."User Security ID", true);
                    Buffer."Affected User Count" += 1;
                end;
                if not SeenCompanies.ContainsKey(Findings."Company Name") then begin
                    SeenCompanies.Add(Findings."Company Name", true);
                    Buffer."Company Count" += 1;
                end;
                Buffer."Has Special Permissions" := Buffer."Has Special Permissions" or Findings."Has Special Permission Source";
                Buffer."Has Direct Assignments" := Buffer."Has Direct Assignments" or Findings."Has Direct Source";
                Buffer."Has Group Based Findings" := Buffer."Has Group Based Findings" or Findings."Has Security Group Source";
            until Findings.Next() = 0;

        if HasConflict then
            SaveSummary(Buffer);
    end;

    local procedure SaveSummary(var Buffer: Record "BCG Detected Conflict Buffer")
    begin
        if Buffer."Inconsistent Stored Values" then
            Buffer."Summary Note" := InconsistentValuesLbl;
        Buffer.Insert();
    end;

    var
        InconsistentValuesLbl: Label 'Stored names or severities differ. Name is from the lowest finding entry; severity is the highest included value. Review Detailed Findings.';
}
