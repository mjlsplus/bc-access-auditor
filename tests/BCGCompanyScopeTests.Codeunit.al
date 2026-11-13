#if BCG_SOURCE_COUNT_TESTS
codeunit 50976 "BCG Company Scope Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TempUsers: Record User temporary;
        TempAccess: Record "Access Control" temporary;
        SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
        GroupMgt: Codeunit "BCG SecGrp Mgt";
        SpecialMgt: Codeunit "BCG Special Permission Mgt.";
        RunId: Guid;
        UserSid: Guid;
        GroupSid: Guid;
        ConflictId: Code[20];

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GlobalAssignmentsApplyToCurrentCompany()
    begin
        InitializeFixture(false, false);
        CaptureAssignments('', 'F02 MODIFY');
        AssertAssignmentEvidence('');
        AssertCurrentCompanyFinding('');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CurrentCompanyAssignmentsApplyOnlyHere()
    begin
        InitializeFixture(false, false);
        CaptureAssignments(CopyStr(CompanyName(), 1, 30), 'F02 MODIFY');
        AssertAssignmentEvidence(CopyStr(CompanyName(), 1, 30));
        AssertCurrentCompanyFinding(CopyStr(CompanyName(), 1, 30));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OtherCompanyAssignmentsCannotCreateFindings()
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        InitializeFixture(false, false);
        CaptureAssignments(OtherCompany(), 'F02 MODIFY');
        AssertNoAssignments();
        // Also protect aggregation/evaluation when a captured input contains an out-of-scope row.
        Assignment."Run ID" := RunId;
        Assignment."User Security ID" := UserSid;
        Assignment."Company Name" := OtherCompany();
        Assignment."Role ID" := 'F02 MODIFY';
        Assignment."Scope Text" := 'System';
        Assignment.Insert();
        AddRawGroupAssignment('SUPER', OtherCompany());
        AssertNoPermissionsOrFindings();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisabledUsersExcludedFromBothRoutes()
    begin
        InitializeFixture(true, false);
        CaptureAssignments('', 'F02 MODIFY');
        AssertNoAssignments();
        AddRawGroupAssignment('F02 MODIFY', '');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        AssertNoDirectAssignments();
        AssertNoPermissionsOrFindings();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonFullUsersExcludedFromBothRoutes()
    begin
        InitializeFixture(false, true);
        CaptureAssignments('', 'F02 MODIFY');
        AssertNoAssignments();
        AddRawGroupAssignment('F02 MODIFY', '');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        AssertNoDirectAssignments();
        AssertNoPermissionsOrFindings();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GroupSuperCannotBypassDisabledEligibility()
    begin
        CheckExcludedSuper(true, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GroupSuperCannotBypassLicenseEligibility()
    begin
        CheckExcludedSuper(false, true);
    end;

    local procedure CheckExcludedSuper(Disabled: Boolean; NonFull: Boolean)
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        InitializeFixture(Disabled, NonFull);
        CaptureAssignments('', 'SUPER');
        AssertNoAssignments();
        // Exercise the group-only special fallback before any merged assignment exists.
        AddRawGroupAssignment('SUPER', '');
        AssertNoPermissionsOrFindings();
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        AssertNoDirectAssignments();
        // A stale direct SUPER snapshot must use the same captured eligible population.
        Assignment."Run ID" := RunId;
        Assignment."User Security ID" := UserSid;
        Assignment."Role ID" := 'SUPER';
        Assignment."Scope Text" := 'System';
        Assignment.Insert();
        AssertNoPermissionsOrFindings();
    end;

    local procedure InitializeFixture(Disabled: Boolean; NonFull: Boolean)
    var
        Audit: Record "BCG Audit Run";
        Group: Record "BCG SecGrp Snap";
        Member: Record "BCG SecGrp Member Snap";
        Permission: Record "BCG Perm. Set Object Perm.";
        Header: Record "BCG Conflict Header";
        ConflictGroup: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
    begin
        TempUsers.Reset();
        TempUsers.DeleteAll();
        TempAccess.Reset();
        TempAccess.DeleteAll();
        RunId := CreateGuid();
        UserSid := CreateGuid();
        GroupSid := CreateGuid();
        Audit."Run ID" := RunId;
        Audit.Status := Audit.Status::Running;
        Audit."Company Filter" := CopyStr(CompanyName(), 1, MaxStrLen(Audit."Company Filter"));
        Audit.Insert();
        TempUsers.Init();
        TempUsers."User Security ID" := UserSid;
        TempUsers."User Name" := 'F02 ELIGIBILITY';
        TempUsers.State := TempUsers.State::Enabled;
        if Disabled then
            TempUsers.State := TempUsers.State::Disabled;
        TempUsers."License Type" := TempUsers."License Type"::"Full User";
        if NonFull then
            TempUsers."License Type" := TempUsers."License Type"::"External User";
        TempUsers.Insert();
        Group."Run ID" := RunId;
        Group."Security Group Code" := 'F02 GROUP';
        Group."Group User SID" := GroupSid;
        Group."Group Name" := 'F02 source group';
        Group.Insert();
        Member."Run ID" := RunId;
        Member."Security Group Code" := Group."Security Group Code";
        Member."User Security ID" := UserSid;
        Member.Insert();
        Permission."Run ID" := RunId;
        Permission."Role ID" := 'F02 MODIFY';
        Permission."Scope Text" := 'System';
        Permission."Object Type" := 'Table Data';
        Permission."Object ID" := 23;
        Permission."Modify Permission" := 'Yes';
        Permission.Insert();
        ConflictId := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        Header."Conflict ID" := ConflictId;
        Header."Is Active" := true;
        Header.Insert();
        ConflictGroup."Conflict ID" := ConflictId;
        ConflictGroup."Group No." := 1;
        ConflictGroup."Is Active" := true;
        ConflictGroup.Insert();
        Rule."Conflict ID" := ConflictId;
        Rule."Group No." := 1;
        Rule."Line No." := 1;
        Rule."Rule ID" := 'F02 MODIFY';
        Rule."Object ID" := 23;
        Rule."Requires Modify" := true;
        Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct Only";
        Rule.Insert();
    end;

    local procedure CaptureAssignments(AssignmentCompany: Text[30]; RoleId: Code[20])
    begin
        TempAccess.Init();
        TempAccess."User Security ID" := UserSid;
        TempAccess."Role ID" := RoleId;
        TempAccess."Company Name" := AssignmentCompany;
        TempAccess.Scope := TempAccess.Scope::System;
        TempAccess.Insert();
        TempAccess."User Security ID" := GroupSid;
        TempAccess.Insert();
        SnapshotMgt.TestCaptureUsersAndAssignments(RunId, TempUsers, TempAccess);
        GroupMgt.TestBuildGroupAssignments(RunId, TempAccess);
    end;

    local procedure AddRawGroupAssignment(RoleId: Code[20]; AssignmentCompany: Text[30])
    var
        Assignment: Record "BCG SecGrp Perm Assign";
    begin
        Assignment."Run ID" := RunId;
        Assignment."User Security ID" := UserSid;
        Assignment."Security Group Code" := 'F02 GROUP';
        Assignment."Company Name" := AssignmentCompany;
        Assignment."Role ID" := RoleId;
        Assignment.Scope := 'System';
        Assignment.Insert();
    end;

    local procedure AssertAssignmentEvidence(AssignmentCompany: Text[30])
    var
        Assignment: Record "BCG User Perm. Assignment";
        GroupAssignment: Record "BCG SecGrp Perm Assign";
        EmptyAppId: Guid;
    begin
        Assignment.Get(RunId, UserSid, AssignmentCompany, 'F02 MODIFY', EmptyAppId, 'System');
        Assignment.TestField("Assignment Source Type", 'Direct + Security Group');
        Assignment.TestField("Assignment Source Code", 'F02 GROUP');
        GroupAssignment.SetRange("Run ID", RunId);
        if GroupAssignment.Count() <> 1 then
            Error('Expected exactly one captured group assignment.');
        GroupAssignment.FindFirst();
        GroupAssignment.TestField("Company Name", AssignmentCompany);
        GroupAssignment.TestField("Role ID", 'F02 MODIFY');
        GroupAssignment.TestField(Scope, 'System');
        GroupAssignment.TestField("App ID", EmptyAppId);
    end;

    local procedure AssertCurrentCompanyFinding(AssignmentCompany: Text[30])
    var
        Permission: Record "BCG User Table Data Perm.";
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
    begin
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        Permission.SetRange("Run ID", RunId);
        if Permission.Count() <> 1 then
            Error('Expected one hosting-company permission, without a global bucket.');
        Permission.FindFirst();
        Permission.TestField("Company Name", CompanyName());
        Permission.TestField("Can Modify", true);
        Permission.TestField("Effective Source Count", 1);
        SnapshotMgt.CalculateConflicts(RunId);
        Result.SetRange("Run ID", RunId);
        Result.SetRange("Conflict Code", ConflictId);
        if Result.Count() <> 1 then
            Error('Expected exactly one hosting-company finding.');
        Result.FindFirst();
        Result.TestField("Company Name", CompanyName());
        Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
        if Line.Count() <> 1 then
            Error('Expected exactly one permission identity in evidence.');
        Line.FindFirst();
        Line.TestField("Source Company Name", AssignmentCompany);
        Line.TestField("Role ID", 'F02 MODIFY');
        Line.TestField("Scope Text", 'System');
        Line.TestField("Assignment Source Type", 'Direct + Security Group');
        Line.TestField("Is From Security Group", true);
        Line.TestField("Security Group Code", 'F02 GROUP');
    end;

    local procedure AssertNoDirectAssignments()
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        Assignment.SetRange("Run ID", RunId);
        if not Assignment.IsEmpty() then
            Error('An excluded user/company acquired a merged assignment.');
    end;

    local procedure AssertNoAssignments()
    var
        Assignment: Record "BCG SecGrp Perm Assign";
    begin
        AssertNoDirectAssignments();
        Assignment.SetRange("Run ID", RunId);
        if not Assignment.IsEmpty() then
            Error('An excluded user/company acquired a group assignment.');
    end;

    local procedure AssertNoPermissionsOrFindings()
    var
        Permission: Record "BCG User Table Data Perm.";
        Result: Record "BCG User Conflict Result";
    begin
        SpecialMgt.AddSpecialPermissionWildcardsForRun(RunId, false);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        Permission.SetRange("Run ID", RunId);
        if not Permission.IsEmpty() then
            Error('An excluded user/company acquired effective permissions.');
        SnapshotMgt.CalculateConflicts(RunId);
        Result.SetRange("Run ID", RunId);
        if not Result.IsEmpty() then
            Error('An excluded user/company acquired findings.');
    end;

    local procedure OtherCompany(): Text[30]
    begin
        if CompanyName() <> 'F02 OTHER COMPANY' then
            exit('F02 OTHER COMPANY');
        exit('F02 ANOTHER COMPANY');
    end;
}
#endif
