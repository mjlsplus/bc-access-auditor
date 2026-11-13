codeunit 50611 "BCG Affected User Mgt."
{
    procedure ResolveCueRun(RunNo: Code[20]): Guid
    var
        AuditRun: Record "BCG Audit Run";
    begin
        if RunNo = '' then
            Error(RunScopeUnavailableLbl);
        AuditRun.SetRange(Status, AuditRun.Status::Finished);
        AuditRun.SetRange("Run No.", RunNo);
        if AuditRun.Count() <> 1 then
            Error(RunScopeUnavailableLbl);
        AuditRun.FindFirst();

        // Compatibility lookup only. Results are always retrieved by this Run ID.
        exit(AuditRun."Run ID");
    end;

    procedure BuildSummary(RunId: Guid; RunNo: Code[20]; var Findings: Record "BCG User Conflict Result"; var Buffer: Record "BCG Affected User Buffer")
    var
        SeenCompanies: Dictionary of [Text, Boolean];
        SeenConflicts: Dictionary of [Code[50], Boolean];
        HasUser: Boolean;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();
        if IsNullGuid(RunId) then
            exit;

        Findings.SetRange("Run ID", RunId);
        Findings.SetRange(Status, Findings.Status::Open);
        Findings.SetCurrentKey("Run ID", "User Security ID");
        Findings.Ascending(true);
        if Findings.FindSet(false) then
            repeat
                if (not HasUser) or (Buffer."User Security ID" <> Findings."User Security ID") then begin
                    if HasUser then
                        Buffer.Insert();
                    Buffer.Init();
                    Buffer."Run ID" := RunId;
                    Buffer."Run No." := RunNo;
                    Buffer."User Security ID" := Findings."User Security ID";
                    Buffer."User Name" := GetUserName(Findings);
                    Clear(SeenCompanies);
                    Clear(SeenConflicts);
                    HasUser := true;
                end;

                Buffer."Finding Count" += 1;
                if Findings.Severity = Findings.Severity::High then
                    Buffer."High Severity Finding Count" += 1;
                if not SeenCompanies.ContainsKey(Findings."Company Name") then begin
                    SeenCompanies.Add(Findings."Company Name", true);
                    Buffer."Company Count" += 1;
                end;
                if not SeenConflicts.ContainsKey(Findings."Conflict Code") then begin
                    SeenConflicts.Add(Findings."Conflict Code", true);
                    Buffer."Detected Conflict Count" += 1;
                end;
                Buffer."Has Special Permissions" := Buffer."Has Special Permissions" or Findings."Has Special Permission Source";
                Buffer."Has Security Group Findings" := Buffer."Has Security Group Findings" or Findings."Has Security Group Source";
                Buffer."Has Direct Assignments" := Buffer."Has Direct Assignments" or Findings."Has Direct Source";
            until Findings.Next() = 0;

        if HasUser then
            Buffer.Insert();
    end;

    local procedure GetUserName(var Finding: Record "BCG User Conflict Result"): Text[50]
    var
        UserSnapshot: Record "BCG User Snapshot";
    begin
        if UserSnapshot.Get(Finding."Run ID", Finding."User Security ID") then
            if UserSnapshot."User Name" <> '' then
                exit(UserSnapshot."User Name");

        // Same display fallback as User Conflict Results; never used as a grouping key.
        Finding.CalcFields("BCG User Name");
        exit(Finding."BCG User Name");
    end;

    var
        RunScopeUnavailableLbl: Label 'The Run No. does not identify one completed run. Open Affected Users using a Run ID. No audit data was changed.';
}
