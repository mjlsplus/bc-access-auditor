codeunit 50578 "BCG User Access Context Mgt"
{
    Permissions =
        tabledata "BCG User Table Data Perm." = m,
        tabledata "BCG User Conflict Result" = m;

    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";

    procedure UpdateAccessContextForRun(RunId: Guid)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG User Access Context Mgt");
        UpdateAccessContextForRun(RunId, true);
    end;

    procedure UpdateAccessContextForRun(RunId: Guid; ShowCompletionMessage: Boolean)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG User Access Context Mgt");
        if IsNullGuid(RunId) then
            Error('Run ID is required. Select a record with a valid Run ID.');

        UpdateSpecialPermissionSummaryForRun(RunId);
        UpdateConflictUserSecurityGroupContextForRun(RunId);

        if ShowCompletionMessage then
            Message('User access context was updated for Run ID %1.', RunId);
    end;

    procedure UpdateSpecialPermissionSummaryForRun(RunId: Guid)
    var
        UserTablePerm: Record "BCG User Table Data Perm.";
        UpdatedCount: Integer;
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG User Access Context Mgt");
        if IsNullGuid(RunId) then
            Error('Run ID is required.');

        UserTablePerm.Reset();
        UserTablePerm.SetRange("Run ID", RunId);
        UserTablePerm.SetRange("Is Special Permission", true);

        if UserTablePerm.FindSet(true) then
            repeat
                UpdateOneSpecialPermissionSummary(UserTablePerm);
                UserTablePerm.Modify(true);
                UpdatedCount += 1;
            until UserTablePerm.Next() = 0;
    end;

    procedure UpdateConflictUserSecurityGroupContextForRun(RunId: Guid)
    var
        ConflictResult: Record "BCG User Conflict Result";
        UpdatedCount: Integer;
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG User Access Context Mgt");
        if IsNullGuid(RunId) then
            Error('Run ID is required.');

        ConflictResult.Reset();
        ConflictResult.SetRange("Run ID", RunId);
        if ConflictResult.FindSet(true) then
            repeat
                UpdateOneConflictUserSecurityGroupContext(ConflictResult);
                ConflictResult.Modify(true);
                UpdatedCount += 1;
            until ConflictResult.Next() = 0;
    end;

    local procedure UpdateOneSpecialPermissionSummary(var UserTablePerm: Record "BCG User Table Data Perm.")
    var
        HasSuper: Boolean;
        HasSuperData: Boolean;
        Summary: Text[250];
    begin
        HasSuper := DetectSuper(UserTablePerm);
        HasSuperData := DetectSuperData(UserTablePerm);

        Summary := BuildSpecialPermissionDisplay(HasSuper, HasSuperData, UserTablePerm);

        UserTablePerm."Has SUPER" := HasSuper;
        UserTablePerm."Has SUPER DATA" := HasSuperData;
        UserTablePerm."Special Permission Summary" := CopyStr(Summary, 1, MaxStrLen(UserTablePerm."Special Permission Summary"));
    end;

    local procedure DetectSuper(UserTablePerm: Record "BCG User Table Data Perm."): Boolean
    var
        SourceSummary: Text;
    begin
        if UserTablePerm."Special Permission Type" = UserTablePerm."Special Permission Type"::SUPER then
            exit(true);

        SourceSummary := UpperCase(UserTablePerm."Special Perm. Source Summary");

        // Expected combined format: SUPER; SUPER (DATA)
        if SourceSummary = 'SUPER' then
            exit(true);

        if StrPos(SourceSummary, 'SUPER;') > 0 then
            exit(true);

        if StrPos(SourceSummary, '; SUPER;') > 0 then
            exit(true);

        // Do not treat a standalone SUPER (DATA) / SUPER DATA as SUPER.
        exit(false);
    end;

    local procedure DetectSuperData(UserTablePerm: Record "BCG User Table Data Perm."): Boolean
    var
        SourceSummary: Text;
    begin
        if UserTablePerm."Special Permission Type" = UserTablePerm."Special Permission Type"::"SUPER DATA" then
            exit(true);

        SourceSummary := UpperCase(UserTablePerm."Special Perm. Source Summary");

        if StrPos(SourceSummary, 'SUPER (DATA)') > 0 then
            exit(true);

        if StrPos(SourceSummary, 'SUPER DATA') > 0 then
            exit(true);

        exit(false);
    end;

    local procedure BuildSpecialPermissionDisplay(HasSuper: Boolean; HasSuperData: Boolean; UserTablePerm: Record "BCG User Table Data Perm."): Text[250]
    begin
        if HasSuper and HasSuperData then
            exit('SUPER + SUPER DATA');

        if HasSuper then
            exit('SUPER');

        if HasSuperData then
            exit('SUPER DATA');

        if UserTablePerm."Special Perm. Source Summary" <> '' then
            exit(CopyStr(UserTablePerm."Special Perm. Source Summary", 1, 250));

        if Format(UserTablePerm."Special Permission Type") <> '' then
            exit(CopyStr(Format(UserTablePerm."Special Permission Type"), 1, 250));

        exit('Special Permission');
    end;

    local procedure UpdateOneConflictUserSecurityGroupContext(var ConflictResult: Record "BCG User Conflict Result")
    var
        SecGrpMember: Record "BCG SecGrp Member Snap";
        GroupSummary: Text[250];
        GroupCount: Integer;
    begin
        GroupSummary := '';
        GroupCount := 0;

        SecGrpMember.Reset();
        SecGrpMember.SetRange("Run ID", ConflictResult."Run ID");
        SecGrpMember.SetRange("User Security ID", ConflictResult."User Security ID");
        if SecGrpMember.FindSet() then
            repeat
                GroupCount += 1;
                AddSecurityGroupToSummary(GroupSummary, GetSecurityGroupDisplayName(SecGrpMember));
            until SecGrpMember.Next() = 0;

        ConflictResult."User Has Security Group" := GroupCount > 0;
        ConflictResult."User Security Group Count" := GroupCount;
        ConflictResult."User Security Group Summary" := CopyStr(GroupSummary, 1, MaxStrLen(ConflictResult."User Security Group Summary"));
    end;

    local procedure GetSecurityGroupDisplayName(SecGrpMember: Record "BCG SecGrp Member Snap"): Text[250]
    begin
        if SecGrpMember."Security Group Name" <> '' then
            exit(SecGrpMember."Security Group Name");

        exit(SecGrpMember."Security Group Code");
    end;

    local procedure AddSecurityGroupToSummary(var GroupSummary: Text[250]; NewText: Text[250])
    begin
        if NewText = '' then
            exit;

        if StrPos(GroupSummary, NewText) > 0 then
            exit;

        if GroupSummary = '' then
            GroupSummary := CopyStr(NewText, 1, MaxStrLen(GroupSummary))
        else
            GroupSummary := CopyStr(GroupSummary + '; ' + NewText, 1, MaxStrLen(GroupSummary));
    end;
}
