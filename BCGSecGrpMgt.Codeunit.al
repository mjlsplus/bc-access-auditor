codeunit 50595 "BCG SecGrp Mgt"
{
    Permissions =
        tabledata "BCG SecGrp Snap" = id,
        tabledata "BCG SecGrp Member Snap" = imd,
        tabledata "BCG SecGrp Perm Assign" = id,
        tabledata "BCG User Perm. Assignment" = im;

    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";

    procedure RunSecurityGroupSnapshot(RunId: Guid)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG SecGrp Mgt");
        RunSecurityGroupSnapshot(RunId, true);
    end;

    procedure RunSecurityGroupSnapshot(RunId: Guid; ShowCompletionMessage: Boolean)
    var
        AuditRun: Record "BCG Audit Run";
        GroupCount: Integer;
        MemberCount: Integer;
        AssignmentCount: Integer;
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG SecGrp Mgt");
        if IsNullGuid(RunId) then
            Error('Run ID is required. Open User Table Data Permissions and select a line with a valid Run ID.');

        AuditRun.Get(RunId);
        if AuditRun.Status <> AuditRun.Status::Running then
            Error('Permission capture is closed for this run. Run a new Full Analysis to capture current permissions.');

        DeleteExistingRunData(RunId);
        GroupCount := LoadSecurityGroups(RunId);
        MemberCount := LoadSecurityGroupMembers(RunId);
        AssignmentCount := BuildGroupPermissionAssignments(RunId);

        if ShowCompletionMessage then
            Message('Security Group snapshot completed for Run ID %1. Groups: %2. Members: %3. Permission assignments: %4.',
                RunId, GroupCount, MemberCount, AssignmentCount);
    end;

    procedure RestoreAssignmentsFromSnapshot(RunId: Guid)
    var
        SecGrpPermAssign: Record "BCG SecGrp Perm Assign";
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG SecGrp Mgt");
        if IsNullGuid(RunId) then
            Error('Run ID is required.');

        // Restore derived assignments without recapturing or changing the source snapshots.
        SecGrpPermAssign.SetRange("Run ID", RunId);
        if SecGrpPermAssign.FindSet() then
            repeat
                UpsertUserPermissionAssignmentFromSecurityGroup(SecGrpPermAssign);
            until SecGrpPermAssign.Next() = 0;
    end;

    local procedure DeleteExistingRunData(RunId: Guid)
    var
        SecGrpSnap: Record "BCG SecGrp Snap";
        SecGrpMemberSnap: Record "BCG SecGrp Member Snap";
        SecGrpPermAssign: Record "BCG SecGrp Perm Assign";
    begin
        SecGrpPermAssign.SetRange("Run ID", RunId);
        SecGrpPermAssign.DeleteAll(true);

        SecGrpMemberSnap.SetRange("Run ID", RunId);
        SecGrpMemberSnap.DeleteAll(true);

        SecGrpSnap.SetRange("Run ID", RunId);
        SecGrpSnap.DeleteAll(true);
    end;

    local procedure LoadSecurityGroups(RunId: Guid): Integer
    var
        SecGroupMgt: Codeunit "Security Group";
        SecGroupBuffer: Record "Security Group Buffer" temporary;
        SecGrpSnap: Record "BCG SecGrp Snap";
        CountInserted: Integer;
    begin
        SecGroupMgt.GetGroups(SecGroupBuffer, true);

        if SecGroupBuffer.FindSet() then
            repeat
                SecGrpSnap.Init();
                SecGrpSnap."Run ID" := RunId;
                SecGrpSnap."Security Group Code" := SecGroupBuffer.Code;
                SecGrpSnap."Group User SID" := SecGroupBuffer."Group User SID";
                SecGrpSnap."Group ID" := SecGroupBuffer."Group ID";
                SecGrpSnap."Group Name" := SecGroupBuffer."Group Name";
                SecGrpSnap."Retrieved Successfully" := SecGroupBuffer."Retrieved Successfully";
                SecGrpSnap."Captured At" := CurrentDateTime();
                if SecGrpSnap.Insert(true) then;
                CountInserted += 1;
            until SecGroupBuffer.Next() = 0;

        exit(CountInserted);
    end;

    local procedure LoadSecurityGroupMembers(RunId: Guid): Integer
    var
        SecGroupMgt: Codeunit "Security Group";
        SecGroupMemberBuffer: Record "Security Group Member Buffer" temporary;
        SecGrpMemberSnap: Record "BCG SecGrp Member Snap";
        NotRetrievedGroups: List of [Code[20]];
        UserName: Code[50];
        UserFullName: Text[80];
        CountInserted: Integer;
    begin
#if BCG_SOURCE_COUNT_TESTS
        if TestMembershipResultPending then begin
            TestMembershipResultPending := false;
            SecGroupMemberBuffer.Copy(TestMemberBuffer, true);
            NotRetrievedGroups := TestNotRetrievedGroups;
        end else
#endif
        NotRetrievedGroups := SecGroupMgt.GetMembers(SecGroupMemberBuffer);

        if NotRetrievedGroups.Count() > 0 then
            Error(IncompleteMembershipErr, NotRetrievedGroups.Count());

        if SecGroupMemberBuffer.FindSet() then
            repeat
                UserName := SecGroupMemberBuffer."User Name";
                UserFullName := SecGroupMemberBuffer."User Full Name";
                ResolveUserDisplayInfo(RunId, SecGroupMemberBuffer."User Security ID", UserName, UserFullName);

                SecGrpMemberSnap.Init();
                SecGrpMemberSnap."Run ID" := RunId;
                SecGrpMemberSnap."Security Group Code" := SecGroupMemberBuffer."Security Group Code";
                SecGrpMemberSnap."User Security ID" := SecGroupMemberBuffer."User Security ID";
                SecGrpMemberSnap."Security Group Name" := SecGroupMemberBuffer."Security Group Name";
                SecGrpMemberSnap."User Name" := UserName;
                SecGrpMemberSnap."User Full Name" := UserFullName;
                SecGrpMemberSnap."Captured At" := CurrentDateTime();
                if SecGrpMemberSnap.Insert(true) then;
                CountInserted += 1;
            until SecGroupMemberBuffer.Next() = 0;

        exit(CountInserted);
    end;

#if BCG_SOURCE_COUNT_TESTS
    internal procedure TestLoadSecurityGroupMembers(RunId: Guid; var Members: Record "Security Group Member Buffer" temporary; FailedGroups: List of [Code[20]]): Integer
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG SecGrp Mgt");
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Source Count Tests");
        TestMemberBuffer.Copy(Members, true);
        TestNotRetrievedGroups := FailedGroups;
        TestMembershipResultPending := true;
        exit(LoadSecurityGroupMembers(RunId));
    end;

    var
        TestMemberBuffer: Record "Security Group Member Buffer" temporary;
        TestNotRetrievedGroups: List of [Code[20]];
        TestMembershipResultPending: Boolean;
#endif

    var
        IncompleteMembershipErr: Label 'Security Group membership retrieval failed for %1 group(s). Analysis stopped because permission data is incomplete. Run a new Full Analysis after resolving the retrieval failure.', Comment = '%1 = number of security groups whose membership could not be retrieved.';

    local procedure BuildGroupPermissionAssignments(RunId: Guid): Integer
    var
        AccessControl: Record "Access Control";
    begin
        exit(BuildGroupPermissionAssignmentsFrom(RunId, AccessControl));
    end;

#if BCG_SOURCE_COUNT_TESTS
    internal procedure TestBuildGroupAssignments(RunId: Guid; var AccessControl: Record "Access Control" temporary): Integer
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG SecGrp Mgt");
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Company Scope Tests");
        exit(BuildGroupPermissionAssignmentsFrom(RunId, AccessControl));
    end;
#endif

    local procedure BuildGroupPermissionAssignmentsFrom(RunId: Guid; var AccessControl: Record "Access Control"): Integer
    var
        SecGrpSnap: Record "BCG SecGrp Snap";
        SecGrpMemberSnap: Record "BCG SecGrp Member Snap";
        SecGrpPermAssign: Record "BCG SecGrp Perm Assign";
        SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
        UserName: Code[50];
        UserFullName: Text[80];
        CountInserted: Integer;
    begin
        SecGrpSnap.SetRange("Run ID", RunId);
        if SecGrpSnap.FindSet() then
            repeat
                AccessControl.Reset();
                AccessControl.SetAutoCalcFields("Role Name", "App Name");
                AccessControl.SetRange("User Security ID", SecGrpSnap."Group User SID");

                if AccessControl.FindSet() then
                    repeat
                        SecGrpMemberSnap.Reset();
                        SecGrpMemberSnap.SetRange("Run ID", RunId);
                        SecGrpMemberSnap.SetRange("Security Group Code", SecGrpSnap."Security Group Code");

                        if SecGrpMemberSnap.FindSet() then
                            repeat
                                if SnapshotMgt.IsAssignmentInScope(RunId, SecGrpMemberSnap."User Security ID", AccessControl."Company Name") then begin
                                    UserName := SecGrpMemberSnap."User Name";
                                    UserFullName := SecGrpMemberSnap."User Full Name";
                                    ResolveUserDisplayInfo(RunId, SecGrpMemberSnap."User Security ID", UserName, UserFullName);

                                    if (SecGrpMemberSnap."User Name" <> UserName) or (SecGrpMemberSnap."User Full Name" <> UserFullName) then begin
                                        SecGrpMemberSnap."User Name" := UserName;
                                        SecGrpMemberSnap."User Full Name" := UserFullName;
                                        SecGrpMemberSnap.Modify(true);
                                    end;

                                    SecGrpPermAssign.Init();
                                    SecGrpPermAssign."Run ID" := RunId;
                                    SecGrpPermAssign."Security Group Code" := SecGrpSnap."Security Group Code";
                                    SecGrpPermAssign."Security Group Name" := SecGrpSnap."Group Name";
                                    SecGrpPermAssign."User Security ID" := SecGrpMemberSnap."User Security ID";
                                    SecGrpPermAssign."User Name" := UserName;
                                    SecGrpPermAssign."User Full Name" := UserFullName;
                                    SecGrpPermAssign."Company Name" := AccessControl."Company Name";
                                    SecGrpPermAssign."Role ID" := AccessControl."Role ID";
                                    SecGrpPermAssign."Role Name" := CopyStr(AccessControl."Role Name", 1, MaxStrLen(SecGrpPermAssign."Role Name"));
                                    case AccessControl.Scope of
                                        AccessControl.Scope::System: SecGrpPermAssign.Scope := 'System';
                                        AccessControl.Scope::Tenant: SecGrpPermAssign.Scope := 'Tenant';
                                    end;
                                    SecGrpPermAssign."App ID" := AccessControl."App ID";
                                    SecGrpPermAssign."App Name" := CopyStr(AccessControl."App Name", 1, MaxStrLen(SecGrpPermAssign."App Name"));
                                    SecGrpPermAssign."Assignment Source Type" := 'Security Group';
                                    SecGrpPermAssign."Captured At" := CurrentDateTime();

                                    if SecGrpPermAssign.Insert(true) then begin
                                        UpsertUserPermissionAssignmentFromSecurityGroup(SecGrpPermAssign);
                                        CountInserted += 1;
                                    end;
                                end;
                            until SecGrpMemberSnap.Next() = 0;
                    until AccessControl.Next() = 0;
            until SecGrpSnap.Next() = 0;

        exit(CountInserted);
    end;

    local procedure ResolveUserDisplayInfo(RunId: Guid; UserSecurityId: Guid; var UserName: Code[50]; var UserFullName: Text[80])
    var
        UserSnapshot: Record "BCG User Snapshot";
        UserRec: Record User;
    begin
        // Prefer BCAA snapshot because it belongs to the same Run ID.
        if UserSnapshot.Get(RunId, UserSecurityId) then begin
            if UserName = '' then
                UserName := UserSnapshot."User Name";

            if UserFullName = '' then
                UserFullName := UserSnapshot."Full Name";
        end;

        // Fallback to the standard BC User table when the Security Group buffer does not return names
        // and the BCAA user snapshot is not available for this Run ID.
        if (UserName = '') or (UserFullName = '') then
            if UserRec.Get(UserSecurityId) then begin
                if UserName = '' then
                    UserName := UserRec."User Name";

                if UserFullName = '' then
                    UserFullName := UserRec."Full Name";
            end;
    end;

    local procedure UpsertUserPermissionAssignmentFromSecurityGroup(SecGrpPermAssign: Record "BCG SecGrp Perm Assign")
    var
        Assignment: Record "BCG User Perm. Assignment";
        SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
    begin
        if not SnapshotMgt.IsAssignmentInScope(SecGrpPermAssign."Run ID", SecGrpPermAssign."User Security ID", SecGrpPermAssign."Company Name") then
            exit;

        if Assignment.Get(
            SecGrpPermAssign."Run ID",
            SecGrpPermAssign."User Security ID",
            SecGrpPermAssign."Company Name",
            SecGrpPermAssign."Role ID",
            SecGrpPermAssign."App ID",
            SecGrpPermAssign.Scope)
        then begin
            if Assignment."Assignment Source Type" = '' then
                Assignment."Assignment Source Type" := 'Security Group'
            else
                if StrPos(Assignment."Assignment Source Type", 'Security Group') = 0 then
                    Assignment."Assignment Source Type" := CopyStr(Assignment."Assignment Source Type" + ' + Security Group', 1, MaxStrLen(Assignment."Assignment Source Type"));

            if Assignment."Assignment Source Code" = '' then
                Assignment."Assignment Source Code" := SecGrpPermAssign."Security Group Code";

            Assignment.Modify(true);
            exit;
        end;

        Assignment.Init();
        Assignment."Run ID" := SecGrpPermAssign."Run ID";
        Assignment."User Security ID" := SecGrpPermAssign."User Security ID";
        Assignment."Company Name" := SecGrpPermAssign."Company Name";
        Assignment."Role ID" := SecGrpPermAssign."Role ID";
        Assignment."Role Name" := SecGrpPermAssign."Role Name";
        Assignment."Scope Text" := SecGrpPermAssign."Scope";
        Assignment."App ID" := SecGrpPermAssign."App ID";
        Assignment."App Name" := SecGrpPermAssign."App Name";
        Assignment."Assignment Source Type" := 'Security Group';
        Assignment."Assignment Source Code" := SecGrpPermAssign."Security Group Code";
        Assignment.Insert(true);
    end;
}
