#if BCG_SOURCE_COUNT_TESTS
codeunit 50972 "BCG Permission Loader Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
        GroupMgt: Codeunit "BCG SecGrp Mgt";
        Expanded: Record "Expanded Permission" temporary;
        RunId: Guid;
        UserSid: Guid;
        AppId: Guid;

    [Test]
    procedure DirectOnlySetRetained()
    begin
        InitializeFixture();
        AddAssignment('DIRECT', '', AppId, 'System');
        AddExpanded('DIRECT', AppId, false, 23);
        LoadAndAssertCount(1);
        AssertRow('DIRECT', AppId, 'System', 23);
    end;

    [Test]
    procedure SecurityGroupOnlySetRetained()
    begin
        InitializeFixture();
        AddGroupAssignment('GROUP A', 'GROUP ONLY');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        AddExpanded('GROUP ONLY', AppId, false, 23);
        LoadAndAssertCount(1);
        AssertRow('GROUP ONLY', AppId, 'System', 23);
    end;

    [Test]
    procedure UnassignedAndOtherRunSetsExcluded()
    var
        CurrentRunId: Guid;
    begin
        InitializeFixture();
        CurrentRunId := RunId;
        RunId := CreateGuid();
        AddAssignment('OTHER RUN', '', AppId, 'System');
        RunId := CurrentRunId;
        AddExpanded('UNASSIGNED', AppId, false, 23);
        AddExpanded('OTHER RUN', AppId, false, 23);
        LoadAndAssertCount(0);
    end;

    [Test]
    procedure AppAndScopeIdentitiesAreIndependent()
    var
        OtherAppId: Guid;
    begin
        InitializeFixture();
        OtherAppId := CreateGuid();
        AddAssignment('SAME ROLE', '', AppId, 'System');
        AddAssignment('SAME ROLE', '', OtherAppId, 'Tenant');
        AddExpanded('SAME ROLE', AppId, false, 23);
        AddExpanded('SAME ROLE', AppId, true, 18);
        AddExpanded('SAME ROLE', OtherAppId, false, 23);
        AddExpanded('SAME ROLE', OtherAppId, true, 18);
        LoadAndAssertCount(2);
        AssertRow('SAME ROLE', AppId, 'System', 23);
        AssertRow('SAME ROLE', OtherAppId, 'Tenant', 18);
    end;

    [Test]
    procedure GlobalAndCompanyAssignmentsRetained()
    begin
        InitializeFixture();
        AddAssignment('GLOBAL', '', AppId, 'System');
        AddAssignment('COMPANY', CopyStr(CompanyName(), 1, 30), AppId, 'System');
        AddAssignment('OTHER COMPANY', 'OTHER LOADER COMPANY', AppId, 'System');
        AddExpanded('GLOBAL', AppId, false, 23);
        AddExpanded('COMPANY', AppId, false, 23);
        AddExpanded('OTHER COMPANY', AppId, false, 23);
        LoadAndAssertCount(3);
        AssertRow('GLOBAL', AppId, 'System', 23);
        AssertRow('COMPANY', AppId, 'System', 23);
        AssertRow('OTHER COMPANY', AppId, 'System', 23);
    end;

    [Test]
    procedure DuplicateRoutesProduceOneSnapshotRow()
    begin
        InitializeFixture();
        AddAssignment('DUPLICATE', '', AppId, 'System');
        AddAssignment('DUPLICATE', CopyStr(CompanyName(), 1, 30), AppId, 'System');
        AddGroupAssignment('GROUP A', 'DUPLICATE');
        AddGroupAssignment('GROUP B', 'DUPLICATE');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        UserSid := CreateGuid();
        AddAssignment('DUPLICATE', '', AppId, 'System');
        AddExpanded('DUPLICATE', AppId, false, 23);
        LoadAndAssertCount(1);
        AssertRow('DUPLICATE', AppId, 'System', 23);
    end;

    [Test]
    procedure ApplicableRowsPreserveAllPermissionValues()
    var
        Permission: Record "BCG Perm. Set Object Perm.";
    begin
        InitializeFixture();
        AddAssignment('ALL ROWS', '', AppId, 'System');
        AddExpanded('ALL ROWS', AppId, false, 0);
        AddExpanded('ALL ROWS', AppId, false, 23);
        Expanded."Read Permission" := Expanded."Read Permission"::Indirect;
        Expanded."Insert Permission" := Expanded."Insert Permission"::Indirect;
        Expanded."Modify Permission" := Expanded."Modify Permission"::Indirect;
        Expanded."Delete Permission" := Expanded."Delete Permission"::Indirect;
        Expanded."Execute Permission" := Expanded."Execute Permission"::Indirect;
        Evaluate(Expanded."Security Filter", 'Vendor: No.=10000');
        Expanded.Modify();
        AddExpanded('ALL ROWS', AppId, false, 18);
        Expanded."Read Permission" := Expanded."Read Permission"::" ";
        Expanded."Insert Permission" := Expanded."Insert Permission"::" ";
        Expanded."Modify Permission" := Expanded."Modify Permission"::" ";
        Expanded."Delete Permission" := Expanded."Delete Permission"::" ";
        Expanded."Execute Permission" := Expanded."Execute Permission"::" ";
        Expanded.Modify();
        // A non-Table Data row of the same identity must still be excluded.
        Expanded."Object Type" := Expanded."Object Type"::Table;
        Expanded.Insert();
        LoadAndAssertCount(3);
        AssertRow('ALL ROWS', AppId, 'System', 0);
        Permission.Get(RunId, 'ALL ROWS', AppId, 'System', 'Table Data', 0);
        if Permission."Object Name" <> '' then
            Error('Loader changed the unnamed wildcard display name.');
        AssertRow('ALL ROWS', AppId, 'System', 23);
        AssertRow('ALL ROWS', AppId, 'System', 18);
    end;

    [Test]
    procedure SpecialRolesWithoutExpandedRowsStillWork()
    var
        SpecialMgt: Codeunit "BCG Special Permission Mgt.";
        Permission: Record "BCG User Table Data Perm.";
        RoleId: Code[30];
        Roles: List of [Code[30]];
    begin
        Roles.Add('SUPER');
        Roles.Add('SUPER (DATA)');
        foreach RoleId in Roles do begin
            InitializeFixture();
            Clear(AppId);
            if RoleId = 'SUPER (DATA)' then
                AppId := '63ca2fa4-4f03-4f2b-a480-172fef340d3f';
            AddAssignment(RoleId, '', AppId, 'System');
            LoadAndAssertCount(0);
            SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
            SpecialMgt.AddSpecialPermissionWildcardsForRun(RunId, false);
            Permission.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 0);
            if not Permission."Can Read" or not Permission."Can Insert" or
               not Permission."Can Modify" or not Permission."Can Delete" or
               not Permission."Is Special Permission" or not Permission."Applies To All Objects" or
               (Permission."Source Permission Set ID" <> RoleId) or
               (Permission."Effective Source Count" <> 1) then
                Error('Special role %1 did not produce its wildcard.', RoleId);
        end;
    end;

    [Test]
    procedure CanonicalCaptureEvaluationAndEvidenceEnglish()
    begin
        CheckCaptureLanguage(1033);
    end;

    [Test]
    procedure CanonicalCaptureEvaluationAndEvidencePolish()
    begin
        CheckCaptureLanguage(1045);
    end;

    [Test]
    procedure HistoricalEnglishPermissionTokensRemainUsable()
    var
        Permission: Record "BCG Perm. Set Object Perm.";
        Effective: Record "BCG User Table Data Perm.";
    begin
        InitializeFixture();
        AddAssignment('F04 LEGACY', '', AppId, 'System');
        AddExpanded('F04 LEGACY', AppId, false, 23);
        LoadAndAssertCount(1);
        Permission.Get(RunId, 'F04 LEGACY', AppId, 'System', 'Table Data', 23);
        Permission."Read Permission" := ' yEs ';
        Permission."Insert Permission" := 'Direct';
        Permission."Modify Permission" := 'Indirect';
        Permission."Delete Permission" := 'No';
        Permission."Execute Permission" := '0';
        Permission.Modify();
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        Effective.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 23);
        Effective.TestField("Can Read", true);
        Effective.TestField("Can Insert", true);
        Effective.TestField("Can Modify", true);
        Effective.TestField("Can Delete", false);
        Effective.TestField("Effective Source Count", 1);
        SnapshotMgt.CalculateConflicts(RunId);
    end;

    [Test]
    procedure LocalizedPermissionTokenIsRejected()
    begin
        CheckRejectedSnapshotToken(1, 'Tak');
        CheckRejectedSnapshotToken(1, 'Nein');
    end;

    [Test]
    procedure HistoricalDeniedTokensCannotCreateFindings()
    var
        Permission: Record "BCG Perm. Set Object Perm.";
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
        Result: Record "BCG User Conflict Result";
        Tokens: List of [Text];
        Token: Text;
    begin
        InitializeFixture();
        AddAssignment('F04 DENIED', '', AppId, 'System');
        AddExpanded('F04 DENIED', AppId, false, 23);
        LoadAndAssertCount(1);
        Header."Conflict ID" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        Header."Is Active" := true;
        Header.Insert();
        Group."Conflict ID" := Header."Conflict ID";
        Group."Group No." := 1;
        Group."Is Active" := true;
        Group.Insert();
        Rule."Conflict ID" := Header."Conflict ID";
        Rule."Group No." := 1;
        Rule."Line No." := 1;
        Rule."Rule ID" := 'F04 DENIED';
        Rule."Object ID" := 23;
        Rule."Requires Read" := true;
        Rule."Read Permission Match" := Rule."Read Permission Match"::"Direct or Indirect";
        Rule.Insert();
        Tokens.Add('No');
        Tokens.Add('0');
        Tokens.Add(' ');
        Tokens.Add('');
        foreach Token in Tokens do begin
            Permission.Get(RunId, 'F04 DENIED', AppId, 'System', 'Table Data', 23);
            Permission."Read Permission" := CopyStr(Token, 1, 20);
            Permission.Modify();
            SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
            SnapshotMgt.CalculateConflicts(RunId);
            Result.SetRange("Run ID", RunId);
            Result.SetRange("Conflict Code", Header."Conflict ID");
            if not Result.IsEmpty() then
                Error('Denied historical permission token created a false positive.');
        end;
    end;

    [Test]
    procedure UnknownPermissionTokenIsRejected()
    begin
        CheckRejectedSnapshotToken(1, 'UNRECOGNIZED');
        CheckRejectedSnapshotToken(1, 'true');
    end;

    [Test]
    procedure LocalizedObjectTypeIsRejected()
    begin
        CheckRejectedSnapshotToken(2, 'Dane tabeli');
    end;

    [Test]
    procedure LocalizedScopeIsRejected()
    begin
        CheckRejectedSnapshotToken(3, 'Mandant');
    end;

    local procedure CheckCaptureLanguage(LanguageId: Integer)
    var
        PreviousLanguage: Integer;
        FailureText: Text;
        Succeeded: Boolean;
    begin
        PreviousLanguage := GlobalLanguage();
        ClearLastError();
        Succeeded := TryCaptureLanguage(LanguageId);
        FailureText := GetLastErrorText();
        GlobalLanguage(PreviousLanguage);
        if not Succeeded then
            Error('%1', FailureText);
    end;

    [TryFunction]
    local procedure TryCaptureLanguage(LanguageId: Integer)
    var
        Permission: Record "BCG Perm. Set Object Perm.";
        Effective: Record "BCG User Table Data Perm.";
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
    begin
        GlobalLanguage(LanguageId);
        InitializeFixture();
        AddAssignment('F04 READ', '', AppId, 'System');
        AddGroupAssignment('F04 GROUP', 'F04 MODIFY');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        AddExpanded('F04 READ', AppId, false, 23);
        // Expanded Permission initializes every operation to Yes; this fixture grants only Read.
        Expanded."Read Permission" := Expanded."Read Permission"::Yes;
        Expanded."Insert Permission" := Expanded."Insert Permission"::" ";
        Expanded."Modify Permission" := Expanded."Modify Permission"::" ";
        Expanded."Delete Permission" := Expanded."Delete Permission"::" ";
        Expanded."Execute Permission" := Expanded."Execute Permission"::" ";
        Expanded.Modify();
        AddExpanded('F04 MODIFY', AppId, false, 0);
        Expanded."Read Permission" := Expanded."Read Permission"::" ";
        Expanded."Insert Permission" := Expanded."Insert Permission"::" ";
        Expanded."Modify Permission" := Expanded."Modify Permission"::Indirect;
        Expanded."Delete Permission" := Expanded."Delete Permission"::" ";
        Expanded."Execute Permission" := Expanded."Execute Permission"::Yes;
        Expanded.Modify();
        AddAssignment('F04 TENANT', '', AppId, 'Tenant');
        AddExpanded('F04 TENANT', AppId, true, 18);
        LoadAndAssertCount(3);
        Permission.Get(RunId, 'F04 READ', AppId, 'System', 'Table Data', 23);
        Permission.TestField("Read Permission", 'Yes');
        Permission.TestField("Delete Permission", '');
        Permission.Get(RunId, 'F04 MODIFY', AppId, 'System', 'Table Data', 0);
        Permission.TestField("Modify Permission", 'Indirect');
        Permission.TestField("Execute Permission", 'Yes');
        Permission.Get(RunId, 'F04 TENANT', AppId, 'Tenant', 'Table Data', 18);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        Effective.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 23);
        Effective.TestField("Can Read", true);
        Effective.TestField("Can Modify", true);

        Header."Conflict ID" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        Header."Is Active" := true;
        Header.Severity := Header.Severity::Critical;
        Header.Insert();
        Group."Conflict ID" := Header."Conflict ID";
        Group."Group No." := 1;
        Group."Is Active" := true;
        Group."Evaluation Logic" := Group."Evaluation Logic"::ALL;
        Group.Insert();
        Rule."Conflict ID" := Header."Conflict ID";
        Rule."Group No." := 1;
        Rule."Line No." := 1;
        Rule."Rule ID" := 'F04 RULE';
        Rule."Object ID" := 23;
        Rule."Requires Read" := true;
        Rule."Requires Modify" := true;
        Rule."Read Permission Match" := Rule."Read Permission Match"::"Direct or Indirect";
        Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct Only";
        Rule."Permission Match Mode" := Rule."Permission Match Mode"::All;
        Rule.Insert();
        Result.SetRange("Run ID", RunId);
        Result.SetRange("User Security ID", UserSid);
        Result.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
        Result.SetRange("Conflict Code", Header."Conflict ID");
        SnapshotMgt.CalculateConflicts(RunId);
        if not Result.IsEmpty() then
            Error('Indirect wildcard must not satisfy Direct Only.');
        Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct or Indirect";
        Rule.Modify();
        SnapshotMgt.CalculateConflicts(RunId);
        if Result.Count() <> 1 then
            Error('Expected complementary ALL finding in either language.');
        Result.FindFirst();
        Result.TestField(Severity, Result.Severity::Critical);
        Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
        if Line.Count() <> 2 then
            Error('Language change lost complementary source evidence.');
        Line.SetRange("Role ID", 'F04 MODIFY');
        Line.FindFirst();
        Line.TestField("Matched Permission", 'Modify');
        Line.TestField("Is From Security Group", true);
        Line.TestField("Security Group Code", 'F04 GROUP');

        // A legacy rule uses the typed operation, independently of its caption.
        Rule."Requires Read" := false;
        Rule."Requires Modify" := false;
        Rule."Read Permission Match" := Rule."Read Permission Match"::"Not Required";
        Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Not Required";
        Rule."Required Permission" := Rule."Required Permission"::Modify;
        Rule.Modify();
        SnapshotMgt.CalculateConflicts(RunId);
        if Result.Count() <> 1 then
            Error('Legacy Modify rule changed with language.');
        Rule."Line No." := 2;
        Rule."Rule ID" := 'F04 MISSING DELETE';
        Rule."Required Permission" := Rule."Required Permission"::Delete;
        Rule.Insert();
        SnapshotMgt.CalculateConflicts(RunId);
        if not Result.IsEmpty() then
            Error('ALL group must require the unmatched Delete rule.');
        Group."Evaluation Logic" := Group."Evaluation Logic"::ANY;
        Group.Modify();
        SnapshotMgt.CalculateConflicts(RunId);
        if Result.Count() <> 1 then
            Error('ANY group must accept its matched Modify rule.');
    end;

    local procedure CheckRejectedSnapshotToken(Kind: Integer; BadToken: Text[30])
    var
        Permission: Record "BCG Perm. Set Object Perm.";
        Effective: Record "BCG User Table Data Perm.";
    begin
        InitializeFixture();
        AddAssignment('F04 INVALID', '', AppId, 'System');
        AddExpanded('F04 INVALID', AppId, false, 23);
        Expanded."Read Permission" := Expanded."Read Permission"::Yes;
        Expanded.Modify();
        LoadAndAssertCount(1);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        Permission.Get(RunId, 'F04 INVALID', AppId, 'System', 'Table Data', 23);
        Effective.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 23);
        Effective.TestField("Can Read", true);
        case Kind of
            1: begin
                Permission."Read Permission" := CopyStr(BadToken, 1, 20);
                Permission.Modify();
            end;
            2: Permission.Rename(RunId, 'F04 INVALID', AppId, 'System', BadToken, 23);
            3: Permission.Rename(RunId, 'F04 INVALID', AppId, BadToken, 'Table Data', 23);
        end;
        // Catch without asserterror's rollback so the preservation assertion checks the actual fixture.
        ClearLastError();
        if TryRebuildRejectedSnapshot() then
            Error('Rebuild must reject unsupported snapshot tokens.');
        if StrPos(GetLastErrorText(), 'Run a new Full Analysis') = 0 then
            Error('Expected explicit unsupported historical value error.');
        Effective.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 23);
        Effective.TestField("Can Read", true);
        ClearLastError();
        if TryCalculateRejectedSnapshot() then
            Error('Recalculation must reject unsupported snapshot tokens.');
        if StrPos(GetLastErrorText(), 'Run a new Full Analysis') = 0 then
            Error('Recalculation must not silently accept unknown snapshot tokens.');
        Effective.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 23);
        Effective.TestField("Can Read", true);
    end;

    [TryFunction]
    local procedure TryRebuildRejectedSnapshot()
    begin
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
    end;

    [TryFunction]
    local procedure TryCalculateRejectedSnapshot()
    begin
        SnapshotMgt.CalculateConflicts(RunId);
    end;

    local procedure InitializeFixture()
    var
        AuditRun: Record "BCG Audit Run";
        UserSnapshot: Record "BCG User Snapshot";
    begin
        // Execute with TestIsolation = Function in a Business Central sandbox.
        Expanded.Reset();
        Expanded.DeleteAll();
        RunId := CreateGuid();
        UserSid := CreateGuid();
        AppId := CreateGuid();
        AuditRun."Run ID" := RunId;
        AuditRun.Status := AuditRun.Status::Running;
        AuditRun."Company Filter" := CopyStr(CompanyName(), 1, MaxStrLen(AuditRun."Company Filter"));
        AuditRun.Insert();
        UserSnapshot."Run ID" := RunId;
        UserSnapshot."User Security ID" := UserSid;
        UserSnapshot.Insert();
    end;

    local procedure AddAssignment(RoleId: Code[30]; TargetCompany: Text[30]; PermissionAppId: Guid; ScopeText: Text[30])
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        Assignment."Run ID" := RunId;
        Assignment."User Security ID" := UserSid;
        Assignment."Company Name" := TargetCompany;
        Assignment."Role ID" := RoleId;
        Assignment."App ID" := PermissionAppId;
        Assignment."Scope Text" := ScopeText;
        Assignment."Assignment Source Type" := 'Direct';
        Assignment.Insert();
    end;

    local procedure AddGroupAssignment(GroupCode: Code[20]; RoleId: Code[20])
    var
        Assignment: Record "BCG SecGrp Perm Assign";
    begin
        Assignment."Run ID" := RunId;
        Assignment."User Security ID" := UserSid;
        Assignment."Security Group Code" := GroupCode;
        Assignment."Role ID" := RoleId;
        Assignment."App ID" := AppId;
        Assignment.Scope := 'System';
        Assignment.Insert();
    end;

    local procedure AddExpanded(RoleId: Code[30]; PermissionAppId: Guid; TenantScope: Boolean; ObjectId: Integer)
    begin
        Expanded.Init();
        Expanded."App ID" := PermissionAppId;
        Expanded."Role ID" := RoleId;
        if TenantScope then
            Expanded.Scope := Expanded.Scope::Tenant
        else
            Expanded.Scope := Expanded.Scope::System;
        Expanded."Object Type" := Expanded."Object Type"::"Table Data";
        Expanded."Object ID" := ObjectId;
        Expanded.Insert();
    end;

    local procedure LoadAndAssertCount(ExpectedCount: Integer)
    var
        Permission: Record "BCG Perm. Set Object Perm.";
    begin
        SnapshotMgt.TestLoadTableDataObjectPermissions(RunId, Expanded);
        Permission.SetRange("Run ID", RunId);
        if Permission.Count() <> ExpectedCount then
            Error('Expected %1 snapshot rows, got %2.', ExpectedCount, Permission.Count());
    end;

    local procedure AssertRow(RoleId: Code[30]; PermissionAppId: Guid; ScopeText: Text[30]; ObjectId: Integer)
    var
        Permission: Record "BCG Perm. Set Object Perm.";
    begin
        Expanded.Get(PermissionAppId, RoleId, Expanded."Object Type"::"Table Data", ObjectId);
        Permission.Get(RunId, RoleId, PermissionAppId, ScopeText, 'Table Data', ObjectId);
        if (Permission."Role Name" <> Expanded."Role Name") or
           (Permission."Read Permission" <> ExpectedPermissionToken(Expanded."Read Permission")) or
           (Permission."Insert Permission" <> ExpectedPermissionToken(Expanded."Insert Permission")) or
           (Permission."Modify Permission" <> ExpectedPermissionToken(Expanded."Modify Permission")) or
           (Permission."Delete Permission" <> ExpectedPermissionToken(Expanded."Delete Permission")) or
           (Permission."Execute Permission" <> ExpectedPermissionToken(Expanded."Execute Permission")) or
           (Permission."Security Filter" <> Format(Expanded."Security Filter")) then
            Error('Loader changed copied metadata or permission values for %1, object %2.', RoleId, ObjectId);
    end;

    local procedure ExpectedPermissionToken(Value: Option " ",Yes,Indirect): Text
    begin
        case Value of
            Value::" ": exit('');
            Value::Yes: exit('Yes');
            Value::Indirect: exit('Indirect');
        end;
        Error('Unexpected option in loader fixture.');
    end;
}
#endif
