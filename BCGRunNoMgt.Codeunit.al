codeunit 50507 "BCG Run No. Mgt."
{
    Permissions =
        tabledata "BCG Audit Run" = m,
        tabledata "BCG User Snapshot" = m,
        tabledata "BCG User Perm. Assignment" = m,
        tabledata "BCG Perm. Set Object Perm." = m,
        tabledata "BCG User Table Data Perm." = m,
        tabledata "BCG User Conflict Result" = m,
        tabledata "BCG User Conflict Result Line" = m,
        tabledata "BCG Conflict Source Trace" = m,
        tabledata "BCG SecGrp Snap" = m,
        tabledata "BCG SecGrp Member Snap" = m,
        tabledata "BCG SecGrp Perm Assign" = m;

    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";

    procedure EnsureRunNoAndPropagate(RunId: Guid): Code[20]
    var
        AuditRun: Record "BCG Audit Run";
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Run No. Mgt.");
        if IsNullGuid(RunId) then
            Error('Run ID is required.');

        if not AuditRun.Get(RunId) then
            Error('Audit run was not found for Run ID %1.', RunId);

        EnsureRunNo(AuditRun);
        PropagateRunNo(AuditRun);
        exit(AuditRun."Run No.");
    end;

    procedure TryGetCurrentRunNo(var CurrentRunNo: Code[20]): Boolean
    var
        PresentationMgt: Codeunit "BCG Risk Presentation Mgt.";
    begin
        exit(PresentationMgt.TryGetCurrentRunNo(CurrentRunNo));
    end;

    procedure UpdateAllRunNumbers()
    begin
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Run No. Mgt.");
        Error('Historical analysis maintenance is unsupported. Run a new Full Analysis instead.');
    end;

    procedure EnsureRunNo(var AuditRun: Record "BCG Audit Run")
    begin
        BCGAccessMgt.RequireRunningRun(AuditRun."Run ID", Codeunit::"BCG Run No. Mgt.");
        if AuditRun.IsTemporary() or (AuditRun.CurrentCompany() <> CompanyName()) then
            Error('Run numbering requires a stored run in the current company.');
        AuditRun.Get(AuditRun."Run ID");
        if AuditRun."Run No." = '' then
            AuditRun."Run No." := GetNextRunNo();

        if AuditRun."Run Description" = '' then
            AuditRun."Run Description" := CopyStr(BuildDefaultDescription(AuditRun), 1, MaxStrLen(AuditRun."Run Description"));

        AuditRun.Modify(true);
    end;

    procedure PropagateRunNo(AuditRun: Record "BCG Audit Run")
    begin
        BCGAccessMgt.RequireRunningRun(AuditRun."Run ID", Codeunit::"BCG Run No. Mgt.");
        if AuditRun.IsTemporary() or (AuditRun.CurrentCompany() <> CompanyName()) then
            Error('Run numbering requires a stored run in the current company.');
        AuditRun.Get(AuditRun."Run ID");
        UpdateUserSnapshot(AuditRun."Run ID", AuditRun."Run No.");
        UpdateUserPermAssignment(AuditRun."Run ID", AuditRun."Run No.");
        UpdatePermSetObjectPerm(AuditRun."Run ID", AuditRun."Run No.");
        UpdateUserTableDataPerm(AuditRun."Run ID", AuditRun."Run No.");
        UpdateUserConflictResult(AuditRun."Run ID", AuditRun."Run No.");
        UpdateUserConflictResultLine(AuditRun."Run ID", AuditRun."Run No.");
        UpdateConflictSourceTrace(AuditRun."Run ID", AuditRun."Run No.");
        UpdateSecGrpSnap(AuditRun."Run ID", AuditRun."Run No.");
        UpdateSecGrpMemberSnap(AuditRun."Run ID", AuditRun."Run No.");
        UpdateSecGrpPermAssign(AuditRun."Run ID", AuditRun."Run No.");
    end;

    local procedure GetNextRunNo(): Code[20]
    var
        AuditRun: Record "BCG Audit Run";
        LastRunNo: Code[20];
    begin
        AuditRun.SetCurrentKey("Run No.");
        AuditRun.Ascending(false);
        AuditRun.SetFilter("Run No.", '<>%1', '');
        if AuditRun.FindFirst() then
            LastRunNo := AuditRun."Run No.";

        if LastRunNo = '' then
            exit('RUN-000001');

        exit(IncStr(LastRunNo));
    end;

    local procedure BuildDefaultDescription(AuditRun: Record "BCG Audit Run"): Text[100]
    begin
        if AuditRun."Started At" <> 0DT then
            exit(StrSubstNo('Full analysis %1', AuditRun."Started At"));

        exit(StrSubstNo('Analysis run %1', AuditRun."Run No."));
    end;

    local procedure UpdateUserSnapshot(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG User Snapshot";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;

    local procedure UpdateUserPermAssignment(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG User Perm. Assignment";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;

    local procedure UpdatePermSetObjectPerm(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG Perm. Set Object Perm.";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;

    local procedure UpdateUserTableDataPerm(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG User Table Data Perm.";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;

    local procedure UpdateUserConflictResult(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG User Conflict Result";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;

    local procedure UpdateUserConflictResultLine(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG User Conflict Result Line";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;

    local procedure UpdateConflictSourceTrace(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG Conflict Source Trace";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;

    local procedure UpdateSecGrpSnap(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG SecGrp Snap";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;

    local procedure UpdateSecGrpMemberSnap(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG SecGrp Member Snap";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;

    local procedure UpdateSecGrpPermAssign(RunId: Guid; RunNo: Code[20])
    var
        RecRef: Record "BCG SecGrp Perm Assign";
    begin
        RecRef.SetRange("Run ID", RunId);
        if not RecRef.IsEmpty() then
            RecRef.ModifyAll("Run No.", RunNo, false);
    end;
}
