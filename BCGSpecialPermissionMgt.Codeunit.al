codeunit 50540 "BCG Special Permission Mgt."
{
    Permissions =
        tabledata "BCG User Table Data Perm." = im;

    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";

    internal procedure IsPlatformSpecialPermission(RoleId: Code[30]; AppId: Guid; ScopeText: Text[30]): Boolean
    var
        SystemApplicationId: Guid;
    begin
        // BC28 User Permissions Impl. identifies SUPER with System scope and a null App ID.
        // SUPER (DATA), permission set 7368, belongs to Microsoft System Application.
        if ScopeText <> 'System' then
            exit(false);
        case RoleId of
            'SUPER':
                exit(IsNullGuid(AppId));
            'SUPER (DATA)': begin
                SystemApplicationId := '63ca2fa4-4f03-4f2b-a480-172fef340d3f';
                exit(AppId = SystemApplicationId);
            end;
        end;
        exit(false);
    end;

    procedure AddSpecialPermissionWildcardsForRun(RunId: Guid)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Special Permission Mgt.");
        AddSpecialPermissionWildcardsForRun(RunId, true);
    end;

    procedure AddSpecialPermissionWildcardsForRun(RunId: Guid; ShowCompletionMessage: Boolean)
    var
        Assignment: Record "BCG User Perm. Assignment";
        SecGrpPermAssign: Record "BCG SecGrp Perm Assign";
        UpdatedCount: Integer;
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Special Permission Mgt.");
        if IsNullGuid(RunId) then
            Error('Run ID is required. Open User Table Data Permissions and select a line with a valid Run ID.');

        // Captured direct assignments and effective assignments already resolved to users.
        // This covers User -> Security Group -> SUPER / SUPER (DATA), provided Run Security Group Snapshot was executed first.
        Assignment.Reset();
        Assignment.SetRange("Run ID", RunId);
        Assignment.SetFilter("Role ID", '%1|%2', 'SUPER', 'SUPER (DATA)');
        if Assignment.FindSet() then
            repeat
                if InsertOrUpdateWildcardPermission(
                    RunId,
                    Assignment."User Security ID",
                    Assignment."Company Name",
                    Assignment."Role ID",
                    Assignment."App ID",
                    Assignment."Scope Text",
                    Assignment."Role Name",
                    Assignment."Assignment Source Type",
                    Assignment."Assignment Source Code")
                then
                    UpdatedCount += 1;
            until Assignment.Next() = 0;

        // Safety fallback: read the Security Group permission assignment buffer directly.
        // This protects analysis even if the upsert into BCAA User Perm. Assignment was not executed for some reason.
        SecGrpPermAssign.Reset();
        SecGrpPermAssign.SetRange("Run ID", RunId);
        SecGrpPermAssign.SetFilter("Role ID", '%1|%2', 'SUPER', 'SUPER (DATA)');
        if SecGrpPermAssign.FindSet() then
            repeat
                if InsertOrUpdateWildcardPermission(
                    RunId,
                    SecGrpPermAssign."User Security ID",
                    SecGrpPermAssign."Company Name",
                    SecGrpPermAssign."Role ID",
                    SecGrpPermAssign."App ID",
                    SecGrpPermAssign.Scope,
                    SecGrpPermAssign."Role Name",
                    'Security Group',
                    SecGrpPermAssign."Security Group Code")
                then
                    UpdatedCount += 1;
            until SecGrpPermAssign.Next() = 0;

        if ShowCompletionMessage then
            Message('%1 SUPER / SUPER DATA wildcard permission records were created or updated for Run ID %2.', UpdatedCount, RunId);
    end;

    procedure UserHasSpecialTableDataPermission(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]): Boolean
    var
        UserTableDataPerm: Record "BCG User Table Data Perm.";
    begin
        UserTableDataPerm.Reset();
        UserTableDataPerm.SetRange("Run ID", RunId);
        UserTableDataPerm.SetRange("User Security ID", UserSecurityId);
        UserTableDataPerm.SetRange("Applies To All Objects", true);
        UserTableDataPerm.SetRange("Is Special Permission", true);
        UserTableDataPerm.SetFilter("Company Name", '%1|%2', CompanyName, '');

        exit(not UserTableDataPerm.IsEmpty());
    end;

    procedure SpecialPermissionSatisfiesObjectRule(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; RequiredRead: Boolean; RequiredInsert: Boolean; RequiredModify: Boolean; RequiredDelete: Boolean): Boolean
    var
        UserTableDataPerm: Record "BCG User Table Data Perm.";
    begin
        UserTableDataPerm.Reset();
        UserTableDataPerm.SetRange("Run ID", RunId);
        UserTableDataPerm.SetRange("User Security ID", UserSecurityId);
        UserTableDataPerm.SetRange("Applies To All Objects", true);
        UserTableDataPerm.SetRange("Is Special Permission", true);
        UserTableDataPerm.SetFilter("Company Name", '%1|%2', CompanyName, '');

        if UserTableDataPerm.FindSet() then
            repeat
                if ((not RequiredRead) or UserTableDataPerm."Can Read") and
                   ((not RequiredInsert) or UserTableDataPerm."Can Insert") and
                   ((not RequiredModify) or UserTableDataPerm."Can Modify") and
                   ((not RequiredDelete) or UserTableDataPerm."Can Delete") then
                    exit(true);
            until UserTableDataPerm.Next() = 0;

        exit(false);
    end;

    local procedure InsertOrUpdateWildcardPermission(RunId: Guid; UserSecurityId: Guid; CompanyNameParam: Text[30]; RoleId: Code[30]; AppId: Guid; ScopeText: Text[30]; RoleName: Text[100]; AssignmentSourceType: Text[50]; AssignmentSourceCode: Text[100]): Boolean
    var
        SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
        TargetCompanies: List of [Text];
        TargetCompany: Text;
        Updated: Boolean;
    begin
        if not IsPlatformSpecialPermission(RoleId, AppId, ScopeText) then
            exit(false);
        TargetCompanies := SnapshotMgt.GetPermissionTargetCompanies(RunId, UserSecurityId, CompanyNameParam);
        foreach TargetCompany in TargetCompanies do
            if InsertOrUpdateWildcardForCompany(RunId, UserSecurityId, CopyStr(TargetCompany, 1, 30), RoleId, RoleName, AssignmentSourceType, AssignmentSourceCode) then
                Updated := true;
        exit(Updated);
    end;

    local procedure InsertOrUpdateWildcardForCompany(RunId: Guid; UserSecurityId: Guid; CompanyNameParam: Text[30]; RoleId: Code[30]; RoleName: Text[100]; AssignmentSourceType: Text[50]; AssignmentSourceCode: Text[100]): Boolean
    var
        UserTableDataPerm: Record "BCG User Table Data Perm.";
        SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
        CompanyName: Text[30];
        SourceSummary: Text[250];
        IsNew: Boolean;
    begin
        if not IsSuperRoleId(RoleId) then
            exit(false);

        CompanyName := CopyStr(CompanyNameParam, 1, MaxStrLen(CompanyName));

        UserTableDataPerm.Reset();
        UserTableDataPerm.SetRange("Run ID", RunId);
        UserTableDataPerm.SetRange("User Security ID", UserSecurityId);
        UserTableDataPerm.SetRange("Company Name", CompanyName);
        UserTableDataPerm.SetRange("Object ID", 0);

        IsNew := not UserTableDataPerm.FindFirst();

        if IsNew then begin
            UserTableDataPerm.Init();
            UserTableDataPerm."Run ID" := RunId;
            UserTableDataPerm."User Security ID" := UserSecurityId;
            UserTableDataPerm."Company Name" := CompanyName;
            UserTableDataPerm."Object ID" := 0;
            UserTableDataPerm."Effective Source Count" := 0;
        end;

        UserTableDataPerm."Object Name" := '*ALL TABLE DATA*';
        UserTableDataPerm."Can Read" := true;
        UserTableDataPerm."Can Insert" := true;
        UserTableDataPerm."Can Modify" := true;
        UserTableDataPerm."Can Delete" := true;
        UserTableDataPerm."Is Special Permission" := true;
        UserTableDataPerm."Applies To All Objects" := true;

        if StrPos(UpperCase(AssignmentSourceType), 'SECURITY GROUP') > 0 then
            UserTableDataPerm."BCG Assignment Source Type" := UserTableDataPerm."BCG Assignment Source Type"::"Security Group"
        else
            if UserTableDataPerm."BCG Assignment Source Type" <> UserTableDataPerm."BCG Assignment Source Type"::"Security Group" then
                UserTableDataPerm."BCG Assignment Source Type" := UserTableDataPerm."BCG Assignment Source Type"::"Special Permission Set";

        SourceSummary := UserTableDataPerm."Special Perm. Source Summary";
        AddRoleToSourceSummary(SourceSummary, RoleId);
        UserTableDataPerm."Special Perm. Source Summary" := SourceSummary;

        if IsSuperDataRoleId(RoleId) then
            UserTableDataPerm."Special Permission Type" := UserTableDataPerm."Special Permission Type"::"SUPER DATA"
        else
            if UserTableDataPerm."Special Permission Type" <> UserTableDataPerm."Special Permission Type"::"SUPER DATA" then
                UserTableDataPerm."Special Permission Type" := UserTableDataPerm."Special Permission Type"::SUPER;

        UserTableDataPerm."Source Permission Set ID" := GetPrimarySourcePermissionSetId(SourceSummary);
        UserTableDataPerm."Source Permission Set Name" := GetPrimarySourcePermissionSetName(SourceSummary, RoleName);
        UserTableDataPerm."Special Permission Notes" :=
            CopyStr(BuildSpecialPermissionNotes(SourceSummary, AssignmentSourceType, AssignmentSourceCode),
                1, MaxStrLen(UserTableDataPerm."Special Permission Notes"));

        UserTableDataPerm."Effective Source Count" := SnapshotMgt.CountEffectivePermissionSources(UserTableDataPerm);

        if IsNew then
            UserTableDataPerm.Insert(true)
        else
            UserTableDataPerm.Modify(true);

        exit(true);
    end;

    local procedure AddRoleToSourceSummary(var SourceSummary: Text[250]; RoleId: Code[30])
    var
        RoleText: Text[30];
    begin
        RoleText := NormalizeRoleDisplay(RoleId);

        if SourceSummary = '' then begin
            SourceSummary := CopyStr(RoleText, 1, MaxStrLen(SourceSummary));
            exit;
        end;

        if StrPos(UpperCase(SourceSummary), UpperCase(RoleText)) = 0 then
            SourceSummary := CopyStr(SourceSummary + '; ' + RoleText, 1, MaxStrLen(SourceSummary));
    end;

    local procedure NormalizeRoleDisplay(RoleId: Code[30]): Text[30]
    begin
        if IsSuperDataRoleId(RoleId) then
            exit('SUPER (DATA)');

        if IsSuperRoleId(RoleId) then
            exit('SUPER');

        exit(Format(RoleId));
    end;

    local procedure IsSuperRoleId(RoleId: Code[30]): Boolean
    begin
        // Display helpers only receive identities checked before wildcard creation.
        exit(RoleId in ['SUPER', 'SUPER (DATA)']);
    end;

    local procedure IsSuperDataRoleId(RoleId: Code[30]): Boolean
    begin
        exit(RoleId = 'SUPER (DATA)');
    end;

    local procedure GetPrimarySourcePermissionSetId(SourceSummary: Text[250]): Code[30]
    begin
        if StrPos(UpperCase(SourceSummary), 'SUPER (DATA)') > 0 then
            exit('SUPER (DATA)');

        if StrPos(UpperCase(SourceSummary), 'SUPER') > 0 then
            exit('SUPER');

        exit('');
    end;

    local procedure GetPrimarySourcePermissionSetName(SourceSummary: Text[250]; FallbackRoleName: Text[100]): Text[100]
    begin
        if StrPos(UpperCase(SourceSummary), 'SUPER (DATA)') > 0 then
            exit('SUPER (DATA)');

        if StrPos(UpperCase(SourceSummary), 'SUPER') > 0 then
            exit('SUPER');

        exit(CopyStr(FallbackRoleName, 1, 100));
    end;

    local procedure BuildSpecialPermissionNotes(SourceSummary: Text[250]; AssignmentSourceType: Text[50]; AssignmentSourceCode: Text[100]): Text[250]
    var
        Notes: Text[250];
    begin
        Notes := CopyStr('Wildcard: user has ' + SourceSummary + ', so all Table Data permissions are treated as granted.', 1, MaxStrLen(Notes));

        if StrPos(UpperCase(AssignmentSourceType), 'SECURITY GROUP') > 0 then
            Notes := CopyStr(Notes + ' Source: Security Group ' + AssignmentSourceCode + '.', 1, MaxStrLen(Notes));

        exit(Notes);
    end;
}
