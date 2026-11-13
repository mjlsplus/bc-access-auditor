codeunit 50586 "BCG Conflict Source Mgt"
{
    Permissions =
        tabledata "BCG Conflict Source Trace" = id;

    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
        SourceRoleIdTooLongErr: Label 'Permission set ID %1 exceeds the supported source identity length of %2 characters. The identity cannot be shortened.', Comment = '%1 = complete permission set ID, %2 = maximum supported length';

    procedure RebuildSourceTraceForRun(RunId: Guid)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Conflict Source Mgt");
        RebuildSourceTraceForRun(RunId, true);
    end;

    procedure RebuildSourceTraceForRun(RunId: Guid; ShowCompletionMessage: Boolean)
    var
        Trace: Record "BCG Conflict Source Trace";
        SecGrpAssign: Record "BCG SecGrp Perm Assign";
        UserTableDataPerm: Record "BCG User Table Data Perm.";
        CountInserted: Integer;
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Conflict Source Mgt");
        if IsNullGuid(RunId) then
            Error('Run ID is required. Select a line with a valid Run ID.');

        Trace.SetRange("Run ID", RunId);
        Trace.DeleteAll(true);

        SecGrpAssign.SetRange("Run ID", RunId);
        if SecGrpAssign.FindSet() then
            repeat
                InsertSecurityGroupTrace(RunId, SecGrpAssign);
                CountInserted += 1;
            until SecGrpAssign.Next() = 0;

        UserTableDataPerm.SetRange("Run ID", RunId);
        UserTableDataPerm.SetRange("Is Special Permission", true);
        UserTableDataPerm.SetRange("Applies To All Objects", true);
        if UserTableDataPerm.FindSet() then
            repeat
                InsertSpecialPermissionTrace(RunId, UserTableDataPerm);
                CountInserted += 1;
            until UserTableDataPerm.Next() = 0;

        if ShowCompletionMessage then
            Message('Permission source trace rebuilt for Run ID %1. Lines created: %2.', RunId, CountInserted);
    end;

    procedure ApplySourceToConflictLine(var ConflictLine: Record "BCG User Conflict Result Line"; RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; RoleId: Code[30]; RoleName: Text[80]; AppId: Guid; AssignmentSourceType: Text[30]; AssignmentSourceCode: Text[100])
    var
        SecGrpAssign: Record "BCG SecGrp Perm Assign";
        SpecialPermissionMgt: Codeunit "BCG Special Permission Mgt.";
        SourceRoleId: Code[20];
        AssignmentSourceTypeUpper: Text;
        HasDirectAssignment: Boolean;
        HasSecurityGroupAssignment: Boolean;
        HasSpecialAssignment: Boolean;
        SecurityGroupFound: Boolean;
    begin
        // This helper should be called by the conflict calculator when it creates a result line
        // and still knows which permission set matched the rule.
        // IMPORTANT: classify the line based on the actual BCAA User Perm. Assignment row.
        // Do not infer Security Group only from Role ID, because the same Role ID can also be assigned directly to the user.
        SourceRoleId := CheckedSourceRoleId(RoleId);
        ConflictLine."Source Permission Set ID" := SourceRoleId;
        ConflictLine."Source Permission Set Name" := RoleName;
        ConflictLine."Source Company Name" := CompanyName;

        AssignmentSourceTypeUpper := UpperCase(AssignmentSourceType);
        HasDirectAssignment := (AssignmentSourceType = '') or (StrPos(AssignmentSourceTypeUpper, 'DIRECT') > 0);
        HasSecurityGroupAssignment := StrPos(AssignmentSourceTypeUpper, 'SECURITY GROUP') > 0;
        HasSpecialAssignment := (StrPos(AssignmentSourceTypeUpper, 'SPECIAL') > 0) and
            SpecialPermissionMgt.IsPlatformSpecialPermission(RoleId, AppId, ConflictLine."Scope Text");

        SecGrpAssign.Reset();
        SecGrpAssign.SetRange("Run ID", RunId);
        SecGrpAssign.SetRange("User Security ID", UserSecurityId);
        SecGrpAssign.SetFilter("Company Name", '%1|%2', CompanyName, '');
        SecGrpAssign.SetRange("Role ID", SourceRoleId);
        SecGrpAssign.SetRange("App ID", AppId);
        SecGrpAssign.SetRange(Scope, ConflictLine."Scope Text");
        if AssignmentSourceCode <> '' then
            SecGrpAssign.SetRange("Security Group Code", CopyStr(AssignmentSourceCode, 1, MaxStrLen(SecGrpAssign."Security Group Code")));
        SecurityGroupFound := SecGrpAssign.FindFirst();

        if HasSecurityGroupAssignment and SecurityGroupFound then begin
            ConflictLine."Is From Security Group" := true;
            ConflictLine."Security Group Code" := SecGrpAssign."Security Group Code";
            ConflictLine."Security Group Name" := SecGrpAssign."Security Group Name";
        end;

        if HasDirectAssignment and HasSecurityGroupAssignment then begin
            ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::Mixed;
            ConflictLine."Permission Source Summary" := CopyStr('Direct + Security Group / Permission Set: ' + RoleId, 1, MaxStrLen(ConflictLine."Permission Source Summary"));
            ConflictLine."Source Notes" := CopyStr('This permission set is assigned directly and also through a BC Security Group.', 1, MaxStrLen(ConflictLine."Source Notes"));
            exit;
        end;

        if HasDirectAssignment then begin
            ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::Direct;
            ConflictLine."Permission Source Summary" := CopyStr('Direct permission set assignment: ' + RoleId, 1, MaxStrLen(ConflictLine."Permission Source Summary"));
            ConflictLine."Source Notes" := CopyStr('Permission set assigned directly to the user in Access Control.', 1, MaxStrLen(ConflictLine."Source Notes"));
            exit;
        end;

        if HasSecurityGroupAssignment then begin
            ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::"Security Group";
            ConflictLine."Is From Security Group" := true;
            if SecurityGroupFound then begin
                ConflictLine."Security Group Code" := SecGrpAssign."Security Group Code";
                ConflictLine."Security Group Name" := SecGrpAssign."Security Group Name";
                ConflictLine."Permission Source Summary" := CopyStr('Security Group: ' + SecGrpAssign."Security Group Name" + ' / Permission Set: ' + RoleId, 1, MaxStrLen(ConflictLine."Permission Source Summary"));
            end else
                ConflictLine."Permission Source Summary" := CopyStr('Security Group / Permission Set: ' + RoleId, 1, MaxStrLen(ConflictLine."Permission Source Summary"));
            ConflictLine."Source Notes" := CopyStr('Permission set assigned through BC Security Group.', 1, MaxStrLen(ConflictLine."Source Notes"));
            exit;
        end;

        if HasSpecialAssignment then begin
            ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::"Special Permission";
            ConflictLine."Is Special Permission Source" := true;
            ConflictLine."Permission Source Summary" := CopyStr('Special permission assignment: ' + RoleId, 1, MaxStrLen(ConflictLine."Permission Source Summary"));
                    ConflictLine."Source Notes" := CopyStr('Permission source marked as special permission in the assignment.', 1, MaxStrLen(ConflictLine."Source Notes"));
            exit;
        end;

        // Fallback for older or incomplete rows where Assignment Source Type was not populated.
        // Keep this after Assignment Source Type checks to avoid hiding Direct assignments.
        if SecurityGroupFound then begin
            ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::"Security Group";
            ConflictLine."Is From Security Group" := true;
            ConflictLine."Security Group Code" := SecGrpAssign."Security Group Code";
            ConflictLine."Security Group Name" := SecGrpAssign."Security Group Name";
            ConflictLine."Permission Source Summary" := CopyStr('Security Group: ' + SecGrpAssign."Security Group Name" + ' / Permission Set: ' + RoleId, 1, MaxStrLen(ConflictLine."Permission Source Summary"));
            ConflictLine."Source Notes" := CopyStr('Permission set assigned through BC Security Group. Source type was inferred as fallback.', 1, MaxStrLen(ConflictLine."Source Notes"));
            exit;
        end;

        ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::Unknown;
        ConflictLine."Permission Source Summary" := CopyStr('Captured permission set found; assignment route unresolved.', 1, MaxStrLen(ConflictLine."Permission Source Summary"));
        ConflictLine."Source Notes" := CopyStr('No matching Security Group or Special Permission source was found.', 1, MaxStrLen(ConflictLine."Source Notes"));
    end;

    local procedure InsertSecurityGroupTrace(RunId: Guid; SecGrpAssign: Record "BCG SecGrp Perm Assign")
    var
        Trace: Record "BCG Conflict Source Trace";
    begin
        Trace.Init();
        Trace."Run ID" := RunId;
        Trace."User Security ID" := SecGrpAssign."User Security ID";
        Trace."User Name" := SecGrpAssign."User Name";
        Trace."User Full Name" := SecGrpAssign."User Full Name";
        Trace."Company Name" := SecGrpAssign."Company Name";
        Trace."Permission Source Type" := Trace."Permission Source Type"::"Security Group";
        Trace."Role ID" := SecGrpAssign."Role ID";
        Trace."Role Name" := SecGrpAssign."Role Name";
        Trace."Security Group Code" := SecGrpAssign."Security Group Code";
        Trace."Security Group Name" := SecGrpAssign."Security Group Name";
        Trace."Source Notes" := CopyStr('User receives this permission set through BC Security Group.', 1, MaxStrLen(Trace."Source Notes"));
        Trace."Captured At" := CurrentDateTime();
        Trace.Insert(true);
    end;

    local procedure InsertSpecialPermissionTrace(RunId: Guid; UserTableDataPerm: Record "BCG User Table Data Perm.")
    var
        Trace: Record "BCG Conflict Source Trace";
    begin
        Trace.Init();
        Trace."Run ID" := RunId;
        Trace."User Security ID" := UserTableDataPerm."User Security ID";
        Trace."Company Name" := UserTableDataPerm."Company Name";
        Trace."Permission Source Type" := Trace."Permission Source Type"::"Special Permission";
        Trace."Role ID" := CheckedSourceRoleId(UserTableDataPerm."Source Permission Set ID");
        // Display only: the full captured name remains on UserTableDataPerm.
        Trace."Role Name" := CopyStr(UserTableDataPerm."Source Permission Set Name", 1, MaxStrLen(Trace."Role Name"));
        Trace."Source Notes" := CopyStr(UserTableDataPerm."Special Permission Notes", 1, MaxStrLen(Trace."Source Notes"));
        Trace."Captured At" := CurrentDateTime();
        Trace.Insert(true);
    end;

    local procedure CheckedSourceRoleId(RoleId: Code[30]): Code[20]
    var
        SourceRoleId: Code[20];
    begin
        if StrLen(RoleId) > MaxStrLen(SourceRoleId) then
            Error(SourceRoleIdTooLongErr, RoleId, MaxStrLen(SourceRoleId));

        // The length check guarantees an exact copy, never an identity prefix.
        exit(CopyStr(RoleId, 1, MaxStrLen(SourceRoleId)));
    end;
}
