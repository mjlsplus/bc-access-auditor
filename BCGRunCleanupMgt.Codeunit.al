codeunit 50575 "BCG Run Cleanup Mgt."
{
    Permissions =
        tabledata "BCG User Snapshot" = d,
        tabledata "BCG User Perm. Assignment" = d,
        tabledata "BCG Perm. Set Object Perm." = d,
        tabledata "BCG User Table Data Perm." = d,
        tabledata "BCG User Conflict Result" = d,
        tabledata "BCG User Conflict Result Line" = d,
        tabledata "BCG Conflict Source Trace" = d,
        tabledata "BCG SecGrp Snap" = d,
        tabledata "BCG SecGrp Member Snap" = d,
        tabledata "BCG SecGrp Perm Assign" = d,
        tabledata "BCG Audit Run" = md;

    SingleInstance = false;

    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";

    procedure DeleteRun(RunId: Guid; DeleteAuditRunHeader: Boolean): Integer
    var
        DeletedCount: Integer;
    begin
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Run Cleanup Mgt.");
        if not DeleteAuditRunHeader then
            Error('Clearing analysis details while retaining the header is unsupported. Run a new Full Analysis instead.');
        if IsNullGuid(RunId) then
            Error('Run ID is required.');

        // Delete detail / child tables first, then headers/snapshots, then audit run header.
        DeletedCount += DeleteConflictResultLines(RunId);
        DeletedCount += DeleteConflictResults(RunId);
        DeletedCount += DeleteConflictSourceTrace(RunId);

        DeletedCount += DeleteSecurityGroupPermissionAssignments(RunId);
        DeletedCount += DeleteSecurityGroupMembers(RunId);
        DeletedCount += DeleteSecurityGroups(RunId);

        DeletedCount += DeleteEffectivePermissions(RunId);
        DeletedCount += DeletePermissionSetObjectPermissions(RunId);
        DeletedCount += DeleteUserPermissionAssignments(RunId);
        DeletedCount += DeleteUserSnapshots(RunId);

        if DeleteAuditRunHeader then
            DeletedCount += DeleteAuditRun(RunId)
        else
            ResetAuditRunCounters(RunId);

        exit(DeletedCount);
    end;

    procedure DeleteRunWithConfirmation(RunId: Guid; RunNo: Code[20]; DeleteAuditRunHeader: Boolean)
    var
        DeletedCount: Integer;
        ConfirmText: Text;
        RunDisplay: Text[50];
    begin
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Run Cleanup Mgt.");
        if not DeleteAuditRunHeader then
            Error('Clearing analysis details while retaining the header is unsupported. Run a new Full Analysis instead.');
        if IsNullGuid(RunId) then
            Error('Run ID is required. Select a record with a valid Run ID.');

        if RunNo <> '' then
            RunDisplay := RunNo
        else
            RunDisplay := Format(RunId);

        if DeleteAuditRunHeader then
            ConfirmText := StrSubstNo('This will delete audit run %1 and all related snapshot, conflict, source trace and Security Group data.\Do you want to continue?', RunDisplay)
        else
            ConfirmText := StrSubstNo('This will delete all detail data for audit run %1 but keep the audit run header.\Do you want to continue?', RunDisplay);

        if not Confirm(ConfirmText, false) then
            exit;

        DeletedCount := DeleteRun(RunId, DeleteAuditRunHeader);
        Message('Cleanup completed for audit run %1. Deleted records: %2.', RunDisplay, DeletedCount);
    end;

    local procedure DeleteConflictResultLines(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG User Conflict Result Line";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeleteConflictResults(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG User Conflict Result";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeleteConflictSourceTrace(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG Conflict Source Trace";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeleteSecurityGroupPermissionAssignments(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG SecGrp Perm Assign";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeleteSecurityGroupMembers(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG SecGrp Member Snap";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeleteSecurityGroups(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG SecGrp Snap";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeleteEffectivePermissions(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG User Table Data Perm.";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeletePermissionSetObjectPermissions(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG Perm. Set Object Perm.";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeleteUserPermissionAssignments(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG User Perm. Assignment";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeleteUserSnapshots(RunId: Guid): Integer
    var
        RecToDelete: Record "BCG User Snapshot";
        DeletedCount: Integer;
    begin
        RecToDelete.SetRange("Run ID", RunId);
        DeletedCount := RecToDelete.Count();
        if DeletedCount > 0 then
            RecToDelete.DeleteAll(false);
        exit(DeletedCount);
    end;

    local procedure DeleteAuditRun(RunId: Guid): Integer
    var
        AuditRun: Record "BCG Audit Run";
    begin
        if AuditRun.Get(RunId) then begin
            AuditRun.Delete(false);
            exit(1);
        end;

        exit(0);
    end;

    local procedure ResetAuditRunCounters(RunId: Guid)
    var
        AuditRun: Record "BCG Audit Run";
    begin
        if not AuditRun.Get(RunId) then
            exit;

        AuditRun."User Count" := 0;
        AuditRun."Assignment Count" := 0;
        AuditRun."Object Permission Count" := 0;
        AuditRun."Effective Permission Count" := 0;
        AuditRun.Modify(false);
    end;
}
