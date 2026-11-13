#if BCG_SOURCE_COUNT_TESTS
codeunit 50973 "BCG Scope Identity Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
        GroupMgt: Codeunit "BCG SecGrp Mgt";
        SpecialMgt: Codeunit "BCG Special Permission Mgt.";
        RunId: Guid;
        UserSid: Guid;
        AppId: Guid;

    [Test]
    procedure DirectSystemAndTenantAreRetained()
    begin
        InitializeFixture();
        AddAssignment('TEST SCOPE', '', 'System');
        AddAssignment('TEST SCOPE', '', 'Tenant');
        AssertAssignment('TEST SCOPE', '', 'System', 'Direct');
        AssertAssignment('TEST SCOPE', '', 'Tenant', 'Direct');
        AssertAssignmentCount(2);
    end;

    [Test]
    procedure SameGroupRetainsBothScopes()
    var
        GroupAssignment: Record "BCG SecGrp Perm Assign";
    begin
        InitializeFixture();
        AddGroupAssignment('GROUP A', 'TEST SCOPE', 'System');
        AddGroupAssignment('GROUP A', 'TEST SCOPE', 'Tenant');
        GroupAssignment.SetRange("Run ID", RunId);
        if GroupAssignment.Count() <> 2 then
            Error('Expected both group assignment scopes.');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        AssertAssignment('TEST SCOPE', '', 'System', 'Security Group');
        AssertAssignment('TEST SCOPE', '', 'Tenant', 'Security Group');
        AssertAssignmentCount(2);
    end;

    [Test]
    procedure DirectAndGroupScopesRemainSeparate()
    begin
        InitializeFixture();
        AddAssignment('TEST SCOPE', '', 'System');
        AddGroupAssignment('GROUP A', 'TEST SCOPE', 'Tenant');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        AssertAssignment('TEST SCOPE', '', 'System', 'Direct');
        AssertAssignment('TEST SCOPE', '', 'Tenant', 'Security Group');
        AssertAssignmentCount(2);
    end;

    [Test]
    procedure SameScopeAcrossRoutesCountsOnce()
    begin
        InitializeFixture();
        AddAssignment('TEST SCOPE', '', 'System');
        AddGroupAssignment('GROUP A', 'TEST SCOPE', 'System');
        AddGroupAssignment('GROUP B', 'TEST SCOPE', 'System');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        AddPermission('TEST SCOPE', 'System', true, false);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        AssertAssignmentCount(1);
        AssertAssignment('TEST SCOPE', '', 'System', 'Direct + Security Group');
        AssertPermission(CopyStr(CompanyName(), 1, 30), 23, true, false, 1);
    end;

    [Test]
    procedure ComplementaryScopesAggregate()
    begin
        InitializeFixture();
        AddAssignment('TEST SCOPE', '', 'System');
        AddAssignment('TEST SCOPE', '', 'Tenant');
        AddPermission('TEST SCOPE', 'System', true, false);
        AddPermission('TEST SCOPE', 'Tenant', false, true);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        AssertPermission(CopyStr(CompanyName(), 1, 30), 23, true, true, 2);
    end;

    [Test]
    procedure OnlyGrantingScopeProducesEvidence()
    var
        Line: Record "BCG User Conflict Result Line";
    begin
        InitializeFixture();
        AddAssignment('TEST SCOPE', '', 'System');
        AddGroupAssignment('GROUP A', 'TEST SCOPE', 'Tenant');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        AddPermission('TEST SCOPE', 'System', false, false);
        AddPermission('TEST SCOPE', 'Tenant', false, true);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        AssertPermission(CopyStr(CompanyName(), 1, 30), 23, false, true, 1);
        CalculateModifyConflict(Line);
        if Line.Count() <> 1 then
            Error('Expected exactly one granting evidence identity.');
        Line.FindFirst();
        if (Line."Scope Text" <> 'Tenant') or
           (Line."Assignment Source Type" <> 'Security Group') or
           not Line."Is From Security Group" or (Line."Security Group Code" <> 'GROUP A')
        then
            Error('Evidence must belong only to the granting Tenant group identity.');
    end;

    [Test]
    procedure GlobalSystemAndCompanyTenantApply()
    var
        TargetCompany: Text[30];
    begin
        InitializeFixture();
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        AddAssignment('TEST SCOPE', '', 'System');
        AddAssignment('TEST SCOPE', TargetCompany, 'Tenant');
        AddAssignment('TEST CONTEXT', 'OTHER SCOPE COMPANY', 'System');
        AddPermission('TEST SCOPE', 'System', true, false);
        AddPermission('TEST SCOPE', 'Tenant', false, true);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        AssertPermission(TargetCompany, 23, true, true, 2);
        AssertNoPermission('');
        AssertNoPermission('OTHER SCOPE COMPANY');
    end;

    [Test]
    procedure GroupEvidenceLookupUsesExactScope()
    var
        SourceMgt: Codeunit "BCG Conflict Source Mgt";
        Line: Record "BCG User Conflict Result Line";
        ScopeText: Text[30];
        Scopes: List of [Text];
    begin
        InitializeFixture();
        AddGroupAssignment('GROUP A', 'TEST SCOPE', 'System');
        AddGroupAssignment('GROUP A', 'TEST SCOPE', 'Tenant');
        Scopes.Add('System');
        Scopes.Add('Tenant');
        foreach ScopeText in Scopes do begin
            Clear(Line);
            Line."Scope Text" := ScopeText;
            SourceMgt.ApplySourceToConflictLine(Line, RunId, UserSid, '', 'TEST SCOPE',
                'Test scope', AppId, 'Security Group', 'GROUP A');
            if not Line."Is From Security Group" or
               (Line."Security Group Name" <> ScopeText) then
                Error('Group lookup returned the wrong scope for %1.', ScopeText);
        end;
    end;

    [Test]
    procedure SuperRolesRetainBothScopeIdentities()
    begin
        CheckSpecialScopes('SUPER');
        CheckSpecialScopes('SUPER (DATA)');
    end;

    [Test]
    procedure HistoricalRestorePreservesBothScopes()
    var
        Assignment: Record "BCG User Perm. Assignment";
        PassNo: Integer;
    begin
        InitializeFixture();
        AddGroupAssignment('GROUP A', 'TEST SCOPE', 'System');
        AddGroupAssignment('GROUP A', 'TEST SCOPE', 'Tenant');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        Assignment.SetRange("Run ID", RunId);
        Assignment.DeleteAll();
        for PassNo := 1 to 2 do begin
            GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
            AssertAssignmentCount(2);
            AssertAssignment('TEST SCOPE', '', 'System', 'Security Group');
            AssertAssignment('TEST SCOPE', '', 'Tenant', 'Security Group');
        end;
    end;

    local procedure CheckSpecialScopes(RoleId: Code[20])
    var
        Line: Record "BCG User Conflict Result Line";
        SpecialSourceMgt: Codeunit "BCG SecGrp Special Src Mgt";
        Permission: Record "BCG User Table Data Perm.";
        PassNo: Integer;
    begin
        InitializeFixture();
        Clear(AppId);
        if RoleId = 'SUPER (DATA)' then
            AppId := '63ca2fa4-4f03-4f2b-a480-172fef340d3f';
        AddAssignment(RoleId, '', 'System');
        AddGroupAssignment('GROUP A', RoleId, 'Tenant');
        GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        // Retain both assignments, but only the genuine System identity is special.
        AssertAssignmentCount(2);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        SpecialMgt.AddSpecialPermissionWildcardsForRun(RunId, false);
        for PassNo := 1 to 2 do begin
            AssertPermission(CopyStr(CompanyName(), 1, 30), 0, true, true, 1);
            Permission.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 0);
            if not Permission."Can Insert" or not Permission."Can Delete" or
               not Permission."Is Special Permission" or not Permission."Applies To All Objects" or
               (Permission."Source Permission Set ID" <> RoleId) then
                Error('Special wildcard metadata or permissions were lost.');
            if RoleId = 'SUPER' then begin
                if Permission."Special Permission Type" <> Permission."Special Permission Type"::SUPER then
                    Error('Expected SUPER type.');
            end else
                if Permission."Special Permission Type" <> Permission."Special Permission Type"::"SUPER DATA" then
                    Error('Expected SUPER DATA type.');
            CalculateModifyConflict(Line);
            SpecialSourceMgt.MarkSpecialPermissionsAssignedThroughSecurityGroups(RunId);
            if Line.Count() <> 1 then
                Error('Only the genuine System identity may produce special evidence.');
            Line.SetRange("Scope Text", 'System');
            Line.FindFirst();
            if (Line."Assignment Source Type" <> 'Direct') or Line."Is From Security Group" or
               not Line."Is Special Permission Source" then
                Error('System special evidence borrowed Tenant group provenance.');
            Line.SetRange("Scope Text", 'Tenant');
            if not Line.IsEmpty() then
                Error('Tenant lookalike contributed special evidence.');
            if PassNo = 1 then
                SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        end;
    end;

    [Test]
    procedure SuperPrefixDoesNotGrantOverride()
    begin
        CheckSpecialLookalike('SUPER-READONLY', '', false, false);
        CheckSpecialLookalike('SUPER-READONLY', '', true, false);
    end;

    [Test]
    procedure SuperDisplayNameDoesNotGrantOverride()
    begin
        CheckSpecialLookalike('ORDINARY ROLE', 'SUPER', false, false);
        CheckSpecialLookalike('ORDINARY ROLE', 'SUPER (DATA)', true, false);
    end;

    [Test]
    procedure SuperLookalikeStillUsesActualGrants()
    begin
        CheckSpecialLookalike('SUPER-READONLY', 'SUPER', false, true);
        CheckSpecialLookalike('SUPER-READONLY', 'SUPER', true, true);
    end;

    [Test]
    procedure WildcardDirectOnlyFromDirectAndGroup()
    begin
        CheckWildcardUnion(false, false, true, false, false, false, true);
        CheckWildcardUnion(true, false, true, false, false, false, true);
    end;

    [Test]
    procedure ComplementaryWildcardAllDirectAndGroup()
    begin
        CheckWildcardUnion(false, true, false, false, false, false, true);
        CheckWildcardUnion(true, true, false, false, false, false, true);
    end;

    [Test]
    procedure ComplementaryWildcardAllDirectOnly()
    begin
        CheckWildcardUnion(false, true, true, false, false, false, true);
        CheckWildcardUnion(true, true, true, false, false, false, true);
    end;

    [Test]
    procedure WildcardIndirectRespectsOperationMode()
    begin
        CheckWildcardUnion(false, true, true, true, false, false, false);
        CheckWildcardUnion(true, true, true, true, false, false, false);
        CheckWildcardUnion(false, true, false, true, false, false, true);
        CheckWildcardUnion(true, true, false, true, false, false, true);
    end;

    [Test]
    procedure WildcardReadOnlyCannotSupplyModify()
    begin
        CheckWildcardUnion(false, true, false, false, true, false, false);
        CheckWildcardUnion(true, false, true, false, true, false, false);
    end;

    [Test]
    procedure WildcardUnionDoesNotCrossCompany()
    begin
        CheckWildcardUnion(false, true, false, false, false, true, false);
        CheckWildcardUnion(false, true, true, false, false, true, false);
    end;

    [Test]
    procedure WildcardAnyAcceptsOneRequiredOperation()
    begin
        // The helper asserts ALL first, then ANY against the same captured grants.
        CheckWildcardUnion(false, true, false, false, true, false, false);
        CheckWildcardUnion(true, true, true, true, false, false, false);
    end;

    [Test]
    procedure EvidenceAllAcrossPermissionSets()
    begin
        CheckEvidenceContributors(1);
    end;

    [Test]
    procedure EvidenceAllAcrossExactAndWildcard()
    begin
        CheckEvidenceContributors(2);
    end;

    [Test]
    procedure EvidenceSecurityGroupContributor()
    begin
        CheckEvidenceContributors(3);
    end;

    [Test]
    procedure EvidenceDirectOnlyRejectsIndirect()
    begin
        CheckEvidenceContributors(4);
    end;

    [Test]
    procedure EvidenceSameRoleMergesExactWildcard()
    begin
        CheckEvidenceContributors(5);
    end;

    [Test]
    procedure EvidenceAnyReportsOnlyMatchedOperation()
    begin
        CheckEvidenceContributors(6);
    end;

    [Test]
    procedure EvidenceExcludesUnrelatedAndOtherCompany()
    begin
        CheckEvidenceContributors(7);
    end;

    [Test]
    procedure EvidenceSuperKeepsOrdinaryContributors()
    begin
        CheckEvidenceContributors(8);
    end;

    [Test]
    procedure EvidenceMissingSourceStaysUnresolved()
    begin
        CheckEvidenceContributors(9);
    end;

    [Test]
    procedure EvidenceUnknownRouteDoesNotBorrowSuper()
    begin
        CheckEvidenceContributors(10);
    end;

    [Test]
    procedure EvidenceAllFourOperationsAreNotClipped()
    begin
        CheckEvidenceContributors(11);
    end;

    local procedure CheckEvidenceContributors(Scenario: Integer)
    var
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
        Permission: Record "BCG Perm. Set Object Perm.";
        Assignment: Record "BCG User Perm. Assignment";
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
        TargetCompany: Text[30];
        ModifyRole: Code[20];
        ExpectedCount: Integer;
        Pass: Integer;
        ReadFound: Boolean;
        ModifyFound: Boolean;
        UnknownFound: Boolean;
        SuperFound: Boolean;
        NullAppId: Guid;
    begin
        InitializeFixture();
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        ModifyRole := 'F07 MODIFY';
        AddAssignment('F07 READ', TargetCompany, 'System');
        AddEvidencePermission('F07 READ', 23, 'Yes', '');
        case Scenario of
            5, 11:
                ModifyRole := 'F07 READ';
            3: begin
                AddGroupAssignment('F07 GROUP', ModifyRole, 'System');
                GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
            end;
            else
                AddAssignment(ModifyRole, '', 'System');
        end;
        if Scenario <> 6 then
            if Scenario in [2, 3, 5, 11] then
                AddEvidencePermission(ModifyRole, 0, '', 'Yes')
            else
                AddEvidencePermission(ModifyRole, 23, '', 'Yes');
        if Scenario = 11 then begin
            Permission.Get(RunId, ModifyRole, AppId, 'System', 'Table Data', 23);
            Permission."Insert Permission" := 'Yes';
            Permission.Modify();
            Permission.Get(RunId, ModifyRole, AppId, 'System', 'Table Data', 0);
            Permission."Delete Permission" := 'Yes';
            Permission.Modify();
        end;

        // Each fixture includes decoys with the same run/user but no applicable operation.
        AddAssignment('F07 UNRELATED', '', 'System');
        AddEvidencePermission('F07 UNRELATED', 288, 'Yes', 'Yes');
        AddAssignment('F07 OTHER COMPANY', 'F07 OTHER COMPANY', 'System');
        AddEvidencePermission('F07 OTHER COMPANY', 23, 'Yes', 'Yes');
        if Scenario = 4 then begin
            AddAssignment('F07 INDIRECT', '', 'System');
            AddEvidencePermission('F07 INDIRECT', 0, '', 'Indirect');
        end;
        if Scenario in [8, 10] then begin
            AddAssignment('SUPER', '', 'System');
            Assignment.Get(RunId, UserSid, '', 'SUPER', AppId, 'System');
            Clear(NullAppId);
            Assignment.Rename(RunId, UserSid, '', 'SUPER', NullAppId, 'System');
        end;
        if Scenario = 10 then begin
            Assignment.Get(RunId, UserSid, TargetCompany, 'F07 READ', AppId, 'System');
            Assignment."Assignment Source Type" := 'UNRESOLVED';
            Assignment.Modify();
        end;

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
        Rule."Rule ID" := 'F07 CONTRIBUTIONS';
        Rule."Object ID" := 23;
        Rule."Object Caption" := 'Vendor';
        Rule."Requires Read" := true;
        Rule."Read Permission Match" := Rule."Read Permission Match"::"Direct or Indirect";
        Rule."Requires Modify" := true;
        Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct or Indirect";
        if Scenario = 4 then
            Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct Only";
        Rule."Permission Match Mode" := Rule."Permission Match Mode"::All;
        if Scenario = 6 then
            Rule."Permission Match Mode" := Rule."Permission Match Mode"::Any;
        if Scenario = 11 then begin
            Rule."Requires Insert" := true;
            Rule."Insert Permission Match" := Rule."Insert Permission Match"::"Direct or Indirect";
            Rule."Requires Delete" := true;
            Rule."Delete Permission Match" := Rule."Delete Permission Match"::"Direct or Indirect";
        end;
        Rule.Insert();
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        SpecialMgt.AddSpecialPermissionWildcardsForRun(RunId, false);
        if Scenario = 9 then begin
            // Aggregated evidence survives, but one source row is unavailable in this snapshot.
            Permission.Get(RunId, ModifyRole, AppId, 'System', 'Table Data', 23);
            Permission.Delete();
        end;

        ExpectedCount := 2;
        if Scenario in [5, 6, 11] then
            ExpectedCount := 1;
        if Scenario in [8, 10] then
            ExpectedCount := 3;
        for Pass := 1 to 2 do begin
            SnapshotMgt.CalculateConflicts(RunId);
            EvidenceMgt.UpdateEvidenceForRun(RunId);
            EvidenceMgt.UpdateEvidenceForRun(RunId);
            Result.SetRange("Run ID", RunId);
            Result.SetRange("User Security ID", UserSid);
            Result.SetRange("Company Name", TargetCompany);
            Result.SetRange("Conflict Code", Header."Conflict ID");
            if Result.Count() <> 1 then
                Error('Expected one detected F07 fixture conflict.');
            Result.FindFirst();
            Line.Reset();
            Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
            if Line.Count() <> ExpectedCount then
                Error('Expected %1 contributor records, found %2.', ExpectedCount, Line.Count());
            Clear(ReadFound);
            Clear(ModifyFound);
            Clear(UnknownFound);
            Clear(SuperFound);
            Line.FindSet();
            repeat
                case Line."Role ID" of
                    'F07 READ': begin
                        ReadFound := true;
                        Line.TestField("App ID", AppId);
                        Line.TestField("Scope Text", 'System');
                        Line.TestField("Is Special Permission Source", false);
                        if Scenario in [5, 11] then begin
                            if not Line."Matched Permission".Split('/').Contains('Read') or
                               not Line."Matched Permission".Split('/').Contains('Modify') then
                                Error('Same-role evidence lost an exact or wildcard operation.');
                            ModifyFound := true;
                            if Scenario = 11 then
                                if not Line."Matched Permission".Split('/').Contains('Insert') or
                                   not Line."Matched Permission".Split('/').Contains('Delete') then
                                    Error('Four-operation evidence was clipped.');
                        end else
                            Line.TestField("Matched Permission", 'Read');
                        if Scenario = 10 then
                            Line.TestField("Permission Source Type", Line."Permission Source Type"::Unknown)
                        else
                            Line.TestField("Permission Source Type", Line."Permission Source Type"::Direct);
                    end;
                    'F07 MODIFY': begin
                        ModifyFound := true;
                        Line.TestField("Matched Permission", 'Modify');
                        Line.TestField("Is Special Permission Source", false);
                        Line.TestField("Is From Security Group", Scenario = 3);
                        if Scenario = 3 then
                            Line.TestField("Security Group Code", 'F07 GROUP');
                    end;
                    'SUPER': begin
                        SuperFound := true;
                        Line.TestField("Is Special Permission Source", true);
                    end;
                    '': begin
                        UnknownFound := true;
                        Line.TestField("Permission Source Type", Line."Permission Source Type"::Unknown);
                        Line.TestField("Matched Permission", 'Unresolved');
                    end;
                    else
                        Error('Evidence attributed an unrelated, indirect-only or foreign-company source.');
                end;
            until Line.Next() = 0;
            if not ReadFound or (ModifyFound <> not (Scenario in [6, 9])) or
               (UnknownFound <> (Scenario = 9)) or (SuperFound <> (Scenario in [8, 10])) then
                Error('Persisted evidence does not explain the captured contributors.');
            if StrPos(Result."Matched Permissions Summary", 'Read') = 0 then
                Error('Customer evidence summary lost Read.');
            if (Scenario = 6) and (StrPos(Result."Matched Permissions Summary", 'Modify') > 0) then
                Error('ANY evidence falsely claimed Modify was matched.');
        end;
    end;

    local procedure AddEvidencePermission(RoleId: Code[30]; ObjectId: Integer; ReadPermission: Text[20]; ModifyPermission: Text[20])
    var
        Permission: Record "BCG Perm. Set Object Perm.";
    begin
        Permission."Run ID" := RunId;
        Permission."Role ID" := RoleId;
        Permission."App ID" := AppId;
        Permission."Scope Text" := 'System';
        Permission."Object Type" := 'Table Data';
        Permission."Object ID" := ObjectId;
        Permission."Read Permission" := ReadPermission;
        Permission."Modify Permission" := ModifyPermission;
        Permission.Insert();
    end;

    local procedure CheckWildcardUnion(ViaGroup: Boolean; RequireRead: Boolean; DirectOnly: Boolean; IndirectModify: Boolean; ReadOnly: Boolean; OtherCompany: Boolean; ExpectedMatch: Boolean)
    var
        Permission: Record "BCG Perm. Set Object Perm.";
        Effective: Record "BCG User Table Data Perm.";
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
        TargetCompany: Text[30];
        Pass: Integer;
    begin
        InitializeFixture();
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        AddAssignment('F01 EXACT', TargetCompany, 'System');
        AddPermission('F01 EXACT', 'System', true, false);
        if ViaGroup then begin
            AddGroupAssignment('F01 GROUP', 'F01 WILDCARD', 'Tenant');
            GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        end else
            if OtherCompany then
                AddAssignment('F01 WILDCARD', 'F01 OTHER COMPANY', 'Tenant')
            else
                AddAssignment('F01 WILDCARD', '', 'Tenant');
        Permission."Run ID" := RunId;
        Permission."Role ID" := 'F01 WILDCARD';
        Permission."App ID" := AppId;
        Permission."Scope Text" := 'Tenant';
        Permission."Object Type" := 'Table Data';
        Permission."Object ID" := 0;
        if ReadOnly then
            Permission."Read Permission" := 'Yes'
        else
            if IndirectModify then
                Permission."Modify Permission" := 'Indirect'
            else
                Permission."Modify Permission" := 'Yes';
        Permission.Insert();

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
        Rule."Rule ID" := 'F01 UNION';
        // No exact row exists for 288: exercise wildcard-only fallback too.
        if RequireRead then
            Rule."Object ID" := 23
        else
            Rule."Object ID" := 288;
        Rule."Requires Read" := RequireRead;
        if RequireRead then
            Rule."Read Permission Match" := Rule."Read Permission Match"::"Direct or Indirect";
        Rule."Requires Modify" := true;
        if DirectOnly then
            Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct Only"
        else
            Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct or Indirect";
        Rule."Permission Match Mode" := Rule."Permission Match Mode"::All;
        Rule.Insert();

        for Pass := 1 to 2 do begin
            SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
            SnapshotMgt.CalculateConflicts(RunId);
            Result.SetRange("Run ID", RunId);
            Result.SetRange("User Security ID", UserSid);
            Result.SetRange("Company Name", TargetCompany);
            Result.SetRange("Conflict Code", Header."Conflict ID");
            if ExpectedMatch then begin
                if Result.Count() <> 1 then
                    Error('Exact/wildcard union must produce one finding.');
            end else
                if not Result.IsEmpty() then
                    Error('Missing or inapplicable wildcard operation produced a finding.');
            Effective.Get(RunId, UserSid, TargetCompany, 23);
            Effective.TestField("Can Read", true);
            // Display booleans include indirect grants, independently of Direct Only rules.
            Effective.TestField("Can Modify", not ReadOnly and not OtherCompany);
            Effective.TestField("Is Special Permission", false);
            if ExpectedMatch and not RequireRead then begin
                Line.SetRange("Run ID", RunId);
                Line.SetRange("Conflict Code", Header."Conflict ID");
                Line.SetRange("Company Name", TargetCompany);
                if Line.Count() <> 1 then
                    Error('Wildcard-only rule must retain its source evidence.');
                Line.FindFirst();
                Line.TestField("Role ID", 'F01 WILDCARD');
                Line.TestField("Is Special Permission Source", false);
                Line.TestField("Is From Security Group", ViaGroup);
            end;
            if (Pass = 1) and RequireRead and not ReadOnly and not OtherCompany then begin
                // Reproduce an older unmerged snapshot without rebuilding it first.
                Effective."Can Modify" := false;
                Effective.Modify();
                SnapshotMgt.CalculateConflicts(RunId);
                if ExpectedMatch <> (Result.Count() = 1) then
                    Error('Rule evaluation must union older exact and wildcard snapshot rows.');
            end;
            Rule."Permission Match Mode" := Rule."Permission Match Mode"::Any;
            Rule.Modify();
            SnapshotMgt.CalculateConflicts(RunId);
            if (RequireRead or ExpectedMatch) <> (Result.Count() = 1) then
                Error('ANY must accept one satisfied operation without requiring the whole ALL rule.');
            Rule."Permission Match Mode" := Rule."Permission Match Mode"::All;
            Rule.Modify();
        end;
    end;

    local procedure CheckSpecialLookalike(RoleId: Code[20]; RoleName: Text[100]; ViaGroup: Boolean; HasModify: Boolean)
    var
        Assignment: Record "BCG User Perm. Assignment";
        Line: Record "BCG User Conflict Result Line";
    begin
        InitializeFixture();
        if ViaGroup then begin
            AddGroupAssignment('GROUP A', RoleId, 'System');
            GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        end else
            AddAssignment(RoleId, '', 'System');
        Assignment.Get(RunId, UserSid, '', RoleId, AppId, 'System');
        Assignment."Role Name" := RoleName;
        Assignment.Modify();
        AddPermission(RoleId, 'System', true, HasModify);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        SpecialMgt.AddSpecialPermissionWildcardsForRun(RunId, false);
        CalculateModifyConflict(Line);
        if not HasModify then begin
            if not Line.IsEmpty() then
                Error('A SUPER-like ID or name granted an unearned Modify finding.');
            exit;
        end;
        if Line.Count() <> 1 then
            Error('A lookalike role must still contribute its actual Modify grant.');
        Line.FindFirst();
        Line.TestField("Is Special Permission Source", false);
        Line.TestField("Is From Security Group", ViaGroup);
    end;

    [Test]
    procedure TenantSuperDataUsesCustomerReadOnly()
    var
        NullAppId: Guid;
    begin
        CheckSpecialIdentity('SUPERDATA', NullAppId, 'Tenant', false, false);
        CheckSpecialIdentity('SUPERDATA', NullAppId, 'Tenant', true, false);
    end;

    [Test]
    procedure GenuineSuperIdentityCreatesOverride()
    var
        NullAppId: Guid;
    begin
        CheckSpecialIdentity('SUPER', NullAppId, 'System', false, true);
        CheckSpecialIdentity('SUPER', NullAppId, 'System', true, true);
    end;

    [Test]
    procedure GenuineSuperDataIdentityCreatesOverride()
    var
        SystemAppId: Guid;
    begin
        SystemAppId := '63ca2fa4-4f03-4f2b-a480-172fef340d3f';
        CheckSpecialIdentity('SUPER (DATA)', SystemAppId, 'System', false, true);
        CheckSpecialIdentity('SUPER (DATA)', SystemAppId, 'System', true, true);
    end;

    [Test]
    procedure LookalikeNamesAppsAndScopesStayOrdinary()
    var
        NullAppId: Guid;
        OtherAppId: Guid;
        SystemAppId: Guid;
        RoleId: Code[20];
        Roles: List of [Code[20]];
    begin
        OtherAppId := CreateGuid();
        SystemAppId := '63ca2fa4-4f03-4f2b-a480-172fef340d3f';
        Roles.Add('SUPER');
        Roles.Add('SUPER (DATA)');
        Roles.Add('SUPERDATA');
        Roles.Add('SUPER(DATA)');
        Roles.Add('SUPER DATA');
        Roles.Add('SUPER-READONLY');
        foreach RoleId in Roles do begin
            CheckSpecialIdentity(RoleId, NullAppId, 'Tenant', false, false);
            CheckSpecialIdentity(RoleId, NullAppId, 'Tenant', true, false);
            CheckSpecialIdentity(RoleId, OtherAppId, 'System', false, false);
            CheckSpecialIdentity(RoleId, OtherAppId, 'System', true, false);
        end;
        CheckSpecialIdentity('SUPER', SystemAppId, 'System', false, false);
        CheckSpecialIdentity('SUPER (DATA)', NullAppId, 'System', true, false);
        CheckSpecialIdentity('SUPERDATA', NullAppId, 'System', false, false);
        CheckSpecialIdentity('SUPER(DATA)', SystemAppId, 'System', true, false);
    end;

    local procedure CheckSpecialIdentity(RoleId: Code[20]; IdentityAppId: Guid; ScopeText: Text[30]; ViaGroup: Boolean; ExpectedSpecial: Boolean)
    var
        TempExpanded: Record "Expanded Permission" temporary;
        Permission: Record "BCG User Table Data Perm.";
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
        Trace: Record "BCG Conflict Source Trace";
        SourceMgt: Codeunit "BCG Conflict Source Mgt";
        SourceSummaryMgt: Codeunit "BCG Conflict Src Summary";
        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
        SpecialSourceMgt: Codeunit "BCG SecGrp Special Src Mgt";
        GroupNo: Integer;
    begin
        InitializeFixture();
        AppId := IdentityAppId;
        if ViaGroup then begin
            AddGroupAssignment('GROUP A', RoleId, ScopeText);
            // Exercise the captured-group wildcard fallback before assignment restoration.
            SpecialMgt.AddSpecialPermissionWildcardsForRun(RunId, false);
            GroupMgt.RestoreAssignmentsFromSnapshot(RunId);
        end else
            AddAssignment(RoleId, '', ScopeText);
        TempExpanded."Role ID" := RoleId;
        TempExpanded."App ID" := AppId;
        if ScopeText = 'Tenant' then
            TempExpanded.Scope := TempExpanded.Scope::Tenant;
        TempExpanded."Object Type" := TempExpanded."Object Type"::"Table Data";
        TempExpanded."Object ID" := 18;
        TempExpanded."Read Permission" := TempExpanded."Read Permission"::Yes;
        TempExpanded."Insert Permission" := TempExpanded."Insert Permission"::" ";
        TempExpanded."Modify Permission" := TempExpanded."Modify Permission"::" ";
        TempExpanded."Delete Permission" := TempExpanded."Delete Permission"::" ";
        TempExpanded."Execute Permission" := TempExpanded."Execute Permission"::" ";
        TempExpanded.Insert();
        SnapshotMgt.TestLoadTableDataObjectPermissions(RunId, TempExpanded);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        SpecialMgt.AddSpecialPermissionWildcardsForRun(RunId, false);
        Permission.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 18);
        Permission.TestField("Can Read", true);
        if not ExpectedSpecial then begin
            Permission.TestField("Can Insert", false);
            Permission.TestField("Can Modify", false);
            Permission.TestField("Can Delete", false);
            Permission.TestField("Is Special Permission", false);
            Permission.TestField("Effective Source Count", 1);
            if Permission.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 0) then
                Error('Lookalike identity created an unearned wildcard.');
        end else begin
            Permission.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 0);
            Permission.TestField("Is Special Permission", true);
            Permission.TestField("Effective Source Count", 1);
        end;

        Header."Conflict ID" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        Header."Is Active" := true;
        Header.Insert();
        for GroupNo := 1 to 2 do begin
            Group.Init();
            Group."Conflict ID" := Header."Conflict ID";
            Group."Group No." := GroupNo;
            Group."Is Active" := true;
            Group.Insert();
            Rule.Init();
            Rule."Conflict ID" := Header."Conflict ID";
            Rule."Group No." := GroupNo;
            Rule."Line No." := 1;
            Rule."Rule ID" := 'IDENTITY TEST';
            Rule."Object ID" := 18;
            Rule."Requires Read" := true;
            Rule."Read Permission Match" := Rule."Read Permission Match"::"Direct Only";
            if GroupNo = 2 then begin
                Rule."Object ID" := 23;
                Rule."Requires Read" := false;
                Rule."Read Permission Match" := Rule."Read Permission Match"::"Not Required";
                Rule."Requires Modify" := true;
                Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct Only";
            end;
            Rule.Insert();
        end;
        SnapshotMgt.CalculateConflicts(RunId);
        Result.SetRange("Run ID", RunId);
        Result.SetRange("Conflict Code", Header."Conflict ID");
        if ExpectedSpecial then begin
            if Result.Count() <> 1 then
                Error('Genuine special identity must satisfy the missing Vendor Modify grant.');
            Result.FindFirst();
            Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
            Line.SetRange("Group No.", 2);
            Line.SetRange("Object ID", 23);
            if Line.Count() <> 1 then
                Error('Vendor Modify must have exactly one special override source.');
            Line.FindFirst();
            Line.TestField("Matched Permission", 'SUPER Override');
            Line.TestField("Role ID", RoleId);
            Line.TestField("App ID", AppId);
            Line.TestField("Scope Text", ScopeText);
            Line.TestField("Is Special Permission Source", true);
            Line.TestField("Is From Security Group", ViaGroup);
            Line.Reset();
        end else
            if not Result.IsEmpty() then
                Error('Lookalike identity satisfied the missing Vendor Modify grant.');

        // Both sides now require the actual Customer Read grant: ordinary evidence must survive.
        Rule."Object ID" := 18;
        Rule."Requires Modify" := false;
        Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Not Required";
        Rule."Requires Read" := true;
        Rule."Read Permission Match" := Rule."Read Permission Match"::"Direct Only";
        Rule.Modify();
        SnapshotMgt.CalculateConflicts(RunId);
        SourceMgt.RebuildSourceTraceForRun(RunId, false);
        SpecialSourceMgt.MarkSpecialPermissionsAssignedThroughSecurityGroups(RunId);
        SourceSummaryMgt.UpdateConflictResultSourcesForRun(RunId, false);
        EvidenceMgt.UpdateEvidenceForRun(RunId);
        if Result.Count() <> 1 then
            Error('Actual Customer Read grant was lost.');
        Result.FindFirst();
        Result.TestField("Has Special Permission Source", ExpectedSpecial);
        Permission.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 18);
        Permission.TestField("Effective Source Count", 1);
        if ExpectedSpecial then begin
            Permission.Get(RunId, UserSid, CopyStr(CompanyName(), 1, 30), 0);
            Permission.TestField("Is Special Permission", true);
            Permission.TestField("Effective Source Count", 1);
        end;
        Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
        if Line.Count() <> 2 then
            Error('Both conflict groups must retain exact source evidence.');
        Line.FindSet();
        repeat
            Line.TestField("Role ID", RoleId);
            Line.TestField("App ID", AppId);
            Line.TestField("Scope Text", ScopeText);
            Line.TestField("Is Special Permission Source", ExpectedSpecial);
            Line.TestField("Is From Security Group", ViaGroup);
            if ViaGroup then begin
                Line.TestField("Assignment Source Type", 'Security Group');
                Line.TestField("Security Group Code", 'GROUP A');
            end else
                Line.TestField("Assignment Source Type", 'Direct');
            Line.TestField("Object ID", 18);
            Line.TestField("Matched Permission", 'Read');
        until Line.Next() = 0;
        Trace.SetRange("Run ID", RunId);
        Trace.SetRange("Permission Source Type", Trace."Permission Source Type"::"Special Permission");
        if Trace.IsEmpty() = ExpectedSpecial then
            Error('Source trace special classification disagrees with the captured identity.');

        // A route label alone must not promote a lookalike into special evidence.
        Clear(Line);
        Line."Scope Text" := ScopeText;
        SourceMgt.ApplySourceToConflictLine(Line, RunId, UserSid, '', RoleId, '', AppId, 'Special Permission', '');
        Line.TestField("Is Special Permission Source", ExpectedSpecial);
    end;

    local procedure InitializeFixture()
    var
        AuditRun: Record "BCG Audit Run";
        UserSnapshot: Record "BCG User Snapshot";
    begin
        // Run with TestIsolation = Function; fixtures never read live assignments.
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

    local procedure AddAssignment(RoleId: Code[30]; TargetCompany: Text[30]; ScopeText: Text[30])
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        Assignment."Run ID" := RunId;
        Assignment."User Security ID" := UserSid;
        Assignment."Company Name" := TargetCompany;
        Assignment."Role ID" := RoleId;
        Assignment."App ID" := AppId;
        Assignment."Scope Text" := ScopeText;
        Assignment."Assignment Source Type" := 'Direct';
        Assignment.Insert();
    end;

    local procedure AddGroupAssignment(GroupCode: Code[20]; RoleId: Code[20]; ScopeText: Text[30])
    var
        Assignment: Record "BCG SecGrp Perm Assign";
    begin
        Assignment."Run ID" := RunId;
        Assignment."Security Group Code" := GroupCode;
        // Distinct captured names expose an incorrectly scoped lookup.
        Assignment."Security Group Name" := ScopeText;
        Assignment."User Security ID" := UserSid;
        Assignment."Role ID" := RoleId;
        Assignment."App ID" := AppId;
        Assignment.Scope := ScopeText;
        Assignment.Insert();
    end;

    local procedure AddPermission(RoleId: Code[30]; ScopeText: Text[30]; CanRead: Boolean; CanModify: Boolean)
    var
        Permission: Record "BCG Perm. Set Object Perm.";
    begin
        Permission."Run ID" := RunId;
        Permission."Role ID" := RoleId;
        Permission."App ID" := AppId;
        Permission."Scope Text" := ScopeText;
        Permission."Object Type" := 'Table Data';
        Permission."Object ID" := 23;
        Permission."Object Name" := 'Vendor';
        if CanRead then
            Permission."Read Permission" := 'Yes';
        if CanModify then
            Permission."Modify Permission" := 'Yes';
        Permission.Insert();
    end;

    local procedure AssertAssignment(RoleId: Code[30]; TargetCompany: Text[30]; ScopeText: Text[30]; ExpectedRoute: Text[30])
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        Assignment.Get(RunId, UserSid, TargetCompany, RoleId, AppId, ScopeText);
        if Assignment."Assignment Source Type" <> ExpectedRoute then
            Error('Wrong provenance for scope %1: expected %2, got %3.',
                ScopeText, ExpectedRoute, Assignment."Assignment Source Type");
    end;

    local procedure AssertAssignmentCount(Expected: Integer)
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        Assignment.SetRange("Run ID", RunId);
        if Assignment.Count() <> Expected then
            Error('Expected %1 resolved assignments, got %2.', Expected, Assignment.Count());
    end;

    local procedure AssertNoPermission(TargetCompany: Text[30])
    var
        Permission: Record "BCG User Table Data Perm.";
    begin
        Permission.SetRange("Run ID", RunId);
        Permission.SetRange("Company Name", TargetCompany);
        if not Permission.IsEmpty() then
            Error('Unexpected effective permissions outside the hosting company.');
    end;

    local procedure AssertPermission(TargetCompany: Text[30]; ObjectId: Integer; CanRead: Boolean; CanModify: Boolean; ExpectedSources: Integer)
    var
        Permission: Record "BCG User Table Data Perm.";
    begin
        Permission.Get(RunId, UserSid, TargetCompany, ObjectId);
        if not Permission."Is Special Permission" then
            if Permission."Effective Source Count" <> SnapshotMgt.CountEffectivePermissionSources(Permission) then
                Error('Cached scope count differs from the public reference implementation.');
        if (Permission."Can Read" <> CanRead) or (Permission."Can Modify" <> CanModify) or
           (Permission."Effective Source Count" <> ExpectedSources) then
            Error('Unexpected grants or source count for company %1, object %2.', TargetCompany, ObjectId);
    end;

    local procedure CalculateModifyConflict(var Line: Record "BCG User Conflict Result Line")
    var
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
        ConflictId: Code[20];
    begin
        ConflictId := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        Header."Conflict ID" := ConflictId;
        Header."Is Active" := true;
        Header.Insert();
        Group."Conflict ID" := ConflictId;
        Group."Group No." := 1;
        Group."Is Active" := true;
        Group.Insert();
        Rule."Conflict ID" := ConflictId;
        Rule."Group No." := 1;
        Rule."Line No." := 1;
        Rule."Rule ID" := 'SCOPE MODIFY';
        Rule."Object ID" := 23;
        Rule."Requires Modify" := true;
        Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct or Indirect";
        Rule.Insert();
        SnapshotMgt.CalculateConflicts(RunId);
        Line.Reset();
        Line.SetRange("Run ID", RunId);
        Line.SetRange("User Security ID", UserSid);
        Line.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
        Line.SetRange("Conflict Code", ConflictId);
        Line.SetRange("Object ID", 23);
    end;
}
#endif
