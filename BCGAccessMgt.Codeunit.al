codeunit 50615 "BCG Access Mgt."
{
    // No elevated permissions. Check effective grants in the current company,
    // including composed sets and group assignments, never a role-name lookup.
    procedure CanManageCodeunit(CodeunitId: Integer): Boolean
    var
        TempPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        // Mirror RequireCodeunit for UI visibility without raising access errors.
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::"Table Data", Database::"BCG Audit Run");
        if TempPermission."Modify Permission" = TempPermission."Modify Permission"::" " then
            exit(false);
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::Codeunit, CodeunitId);
        exit(TempPermission."Execute Permission" = TempPermission."Execute Permission"::Yes);
    end;

    procedure RequireCodeunit(CodeunitId: Integer)
    var
        TempPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        // Generic Execute from a base login set does not authorize management.
        // Query the user's effective data grant, not this call stack's elevation.
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::"Table Data", Database::"BCG Audit Run");
        if TempPermission."Modify Permission" = TempPermission."Modify Permission"::" " then
            Error(ManagementAccessErr);
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::Codeunit, CodeunitId);
        if TempPermission."Execute Permission" <> TempPermission."Execute Permission"::Yes then
            Error(CodeunitAccessErr, CodeunitId);
    end;

    procedure RequireRunningRun(RunId: Guid; CodeunitId: Integer)
    var
        AuditRun: Record "BCG Audit Run";
    begin
        RequireCodeunit(CodeunitId);
        // Serialize maintenance with finalization; checking never changes the header.
        AuditRun.ReadIsolation := IsolationLevel::UpdLock;
        if not AuditRun.Get(RunId) then
            Error(HistoricalMaintenanceErr);
        if AuditRun.Status <> AuditRun.Status::Running then
            Error(HistoricalMaintenanceErr);
    end;

    procedure RequireAdminPage(PageId: Integer)
    var
        TempPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        // Generic page execution from a base login set must not open admin pages.
        RequireCodeunit(Codeunit::"BCG Snapshot Mgt.");
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::Page, PageId);
        if TempPermission."Execute Permission" <> TempPermission."Execute Permission"::Yes then
            Error(PageAccessErr, PageId);
    end;

    var
        HistoricalMaintenanceErr: Label 'Historical analysis maintenance is unsupported. Only an existing Running run can be updated. Run a new Full Analysis instead.';
        CodeunitAccessErr: Label 'You do not have permission to execute BCAA management codeunit %1 in this company.', Comment = '%1 = codeunit ID';
        ManagementAccessErr: Label 'BCAA management requires audit-run write permission in this company.';
        PageAccessErr: Label 'You do not have permission to open BCAA administration page %1 in this company.', Comment = '%1 = page ID';
}
