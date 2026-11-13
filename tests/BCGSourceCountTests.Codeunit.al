#if BCG_SOURCE_COUNT_TESTS
codeunit 50974 "BCG Source Count Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
        SpecialMgt: Codeunit "BCG Special Permission Mgt.";
        TestRunId: Guid;
        TestUserId: Guid;
        TestAppId: Guid;

    [Test]
    procedure RouteDirectSuperOnly()
    var
        Result: Record "BCG User Conflict Result";
    begin
        CreateSummaryResult(Result);
        AddRouteLine(Result, 'SUPER', 'Direct', true);
        AssertRouteResult(Result, true, false, true, 'Direct: SUPER');
    end;

    [Test]
    procedure RouteDirectSpecialAndOrdinary()
    var
        Result: Record "BCG User Conflict Result";
    begin
        CreateSummaryResult(Result);
        AddRouteLine(Result, 'SUPER', 'Direct', true);
        AddRouteLine(Result, 'D365 BUS PREMIUM', 'Direct', false);
        AssertRouteResult(Result, true, false, true, 'Direct: SUPER, D365 BUS PREMIUM');
    end;

    [Test]
    procedure RouteGroupSpecialAndOrdinary()
    var
        Result: Record "BCG User Conflict Result";
    begin
        CreateSummaryResult(Result);
        AddRouteLine(Result, 'SUPER', 'Security Group', true);
        AddRouteLine(Result, 'D365 FINANCE', 'Security Group', false);
        AssertRouteResult(Result, false, true, true, 'Security Group: SUPER, D365 FINANCE');
    end;

    [Test]
    procedure RouteMixedHasFixedRouteOrder()
    var
        Result: Record "BCG User Conflict Result";
    begin
        CreateSummaryResult(Result);
        AddRouteLine(Result, 'D365 FINANCE', 'Security Group', false);
        AddRouteLine(Result, 'SUPER', 'Direct', true);
        AssertRouteResult(Result, true, true, true, 'Direct: SUPER; Security Group: D365 FINANCE');
    end;

    [Test]
    procedure RouteSameIdentityThroughBothRoutes()
    var
        Result: Record "BCG User Conflict Result";
    begin
        CreateSummaryResult(Result);
        AddRouteLine(Result, 'SUPER', 'Direct + Security Group', true);
        AddRouteLine(Result, 'SUPER', 'Direct', true);
        AddRouteLine(Result, 'SUPER', 'Security Group', true);
        AssertRouteResult(Result, true, true, true, 'Direct: SUPER; Security Group: SUPER');
    end;

    [Test]
    procedure RouteUnknownHistoricalEvidence()
    var
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
    begin
        CreateSummaryResult(Result);
        AddRouteLine(Result, 'SUPER', '', true);
        AddRouteLine(Result, 'OLD SOURCE', '', false);
        Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
        Line.SetRange("Role ID", 'OLD SOURCE');
        Line.FindFirst();
        // Old generation could label unresolved evidence Direct; this is not a reliable route.
        Line."Permission Source Type" := Line."Permission Source Type"::Direct;
        Line.Modify();
        AssertRouteResult(Result, false, false, true, 'Unknown: SUPER, OLD SOURCE');
    end;

    [Test]
    procedure RouteExactIdentityDeduplication()
    var
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
    begin
        CreateSummaryResult(Result);
        AddRouteLine(Result, 'D365 FINANCE', 'Direct', false);
        AddRouteLine(Result, 'D365', 'Direct', false);
        AddRouteLine(Result, 'D365 FINANCE', 'Direct', false);
        AddRouteLine(Result, 'D365 FINANCE', 'Direct', false);
        Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
        Line.FindLast();
        Line."App ID" := CreateGuid();
        Line.Modify();
        AddRouteLine(Result, 'D365 FINANCE', 'Direct', false);
        Line.FindLast();
        Line."Scope Text" := 'Tenant';
        Line.Modify();
        // Equal display names with different App/Scope are distinct identities, not duplicates.
        AssertRouteResult(Result, true, false, false, 'Direct: D365 FINANCE, D365, D365 FINANCE, D365 FINANCE');
    end;

    [Test]
    procedure RouteNoEvidenceDoesNotBorrowUserTrace()
    var
        Result: Record "BCG User Conflict Result";
        Trace: Record "BCG Conflict Source Trace";
    begin
        CreateSummaryResult(Result);
        Result."Has Special Permission Source" := true;
        Result.Modify();
        Trace.Init();
        Trace."Run ID" := Result."Run ID";
        Trace."User Security ID" := Result."User Security ID";
        Trace."Permission Source Type" := Trace."Permission Source Type"::Direct;
        Trace."Role ID" := 'UNRELATED';
        Trace.Insert();
        AssertRouteResult(Result, false, false, true, 'Unknown: source unavailable');
    end;

    local procedure AddRouteLine(Result: Record "BCG User Conflict Result"; RoleId: Code[20]; Route: Text[30]; Special: Boolean)
    var
        Line: Record "BCG User Conflict Result Line";
    begin
        Line.Init();
        Line."Conflict Result Entry No." := Result."Entry No.";
        Line."Run ID" := Result."Run ID";
        Line."Role ID" := RoleId;
        Line."Scope Text" := 'System';
        Line."Assignment Source Type" := Route;
        Line."Is Special Permission Source" := Special;
        if Special then
            Line."Permission Source Type" := Line."Permission Source Type"::"Special Permission";
        Line.Insert();
    end;

    local procedure AssertRouteResult(var Result: Record "BCG User Conflict Result"; ExpectedDirect: Boolean; ExpectedGroup: Boolean; ExpectedSpecial: Boolean; ExpectedSummary: Text)
    var
        SummaryMgt: Codeunit "BCG Conflict Src Summary";
        EnrichmentMgt: Codeunit "BCG SecGrp Special Src Mgt";
        Line: Record "BCG User Conflict Result Line";
        BeforeLine: Record "BCG User Conflict Result Line";
        BeforeCount: Integer;
    begin
        Result."Matched Group Count" := 7;
        Result."Matched Rule Count" := 8;
        Result."Matched Object Count" := 9;
        Result.Modify();
        Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
        BeforeCount := Line.Count();
        if Line.FindFirst() then
            BeforeLine := Line;
        SummaryMgt.UpdateConflictResultSourcesForRun(Result."Run ID", false);
        // The later enrichment/header pass must preserve the same classification.
        EnrichmentMgt.UpdateConflictResultSourcesFromLines(Result."Run ID");
        Result.Get(Result."Entry No.");
        AssertSummaryText(Result."Permission Source Summary", ExpectedSummary);
        if (Result."Has Direct Source" <> ExpectedDirect) or (Result."Has Security Group Source" <> ExpectedGroup) or
           (Result."Has Special Permission Source" <> ExpectedSpecial) then
            Error('Route or special attribute changed.');
        if ExpectedDirect and ExpectedGroup then begin
            if Result."Primary Permission Source" <> Result."Primary Permission Source"::Mixed then
                Error('Expected Mixed routes.');
        end else
            if ExpectedDirect then begin
                if Result."Primary Permission Source" <> Result."Primary Permission Source"::Direct then
                    Error('Expected Direct route.');
            end else
                if ExpectedGroup then begin
                    if Result."Primary Permission Source" <> Result."Primary Permission Source"::"Security Group" then
                        Error('Expected Security Group route.');
                end else
                    if Result."Primary Permission Source" <> Result."Primary Permission Source"::Unknown then
                        Error('Expected Unknown route.');
        if (Result."Matched Group Count" <> 7) or (Result."Matched Rule Count" <> 8) or (Result."Matched Object Count" <> 9) then
            Error('Source refresh modified counters.');
        if Line.Count() <> BeforeCount then
            Error('Source refresh modified evidence count.');
        if Line.FindFirst() then
            if (Line."Assignment Source Type" <> BeforeLine."Assignment Source Type") or
               (Line."Permission Source Type" <> BeforeLine."Permission Source Type") or
               (Line."Is Special Permission Source" <> BeforeLine."Is Special Permission Source") then
                Error('Source refresh modified detailed evidence.');
    end;

    [Test]
    procedure CustomerSummaryGroupsOperationsAndPreservesCounters()
    var
        Result: Record "BCG User Conflict Result";
        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
    begin
        CreateSummaryResult(Result);
        AddSummaryLine(Result, 1, 'Master Data', 23, 'Vendor', 'R1', 'Modify: Direct or Indirect', false);
        AddSummaryLine(Result, 2, 'Payment', 81, 'Gen. Journal Line', 'R3', 'Insert', false);
        AddSummaryLine(Result, 1, 'Master Data', 23, 'Vendor', 'R1', 'Modify: Direct Only', false);
        AddSummaryLine(Result, 1, 'Master Data', 23, 'Vendor', 'R2', 'Read/Modify', false);
        AddSummaryLine(Result, 1, 'Master Data', 288, 'Vendor Bank Account', 'R4', 'Modify', false);
        // The same object in another group remains a separate counted group/object identity.
        AddSummaryLine(Result, 2, 'Payment', 23, 'Vendor', 'R5', 'Read', false);
        EvidenceMgt.UpdateEvidenceForResult(Result);
        AssertSummaryText(Result."Matched Permissions Summary", 'Vendor: Modify, Read; Gen. Journal Line: Insert; Vendor Bank Account: Modify');
        AssertSummaryText(Result."Conflict Evidence Summary", 'Master Data: Vendor, Vendor Bank Account; Payment: Gen. Journal Line, Vendor');
        if (Result."Matched Group Count" <> 2) or (Result."Matched Rule Count" <> 5) or (Result."Matched Object Count" <> 4) then
            Error('Customer display changed evidence identity counters.');
    end;

    [Test]
    procedure CustomerSummaryAnyAllAndHistoricalRefresh()
    var
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
        PassNo: Integer;
    begin
        CreateSummaryResult(Result);
        AddSummaryLine(Result, 1, 'Captured group', 23, 'Captured Vendor', 'NO LIVE RULE', 'Modify: Direct or Indirect', false);
        Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
        Line.FindFirst();
        for PassNo := 1 to 2 do begin
            if PassNo = 1 then begin
                Line."Required Permission" := 'Read/Modify (Any)';
                Line."Evaluation Logic" := 'ANY';
            end else begin
                Line."Required Permission" := 'Modify (All)';
                Line."Evaluation Logic" := 'ALL';
            end;
            Line.Modify();
            // A stored run with no corresponding setup must refresh from its captured evidence alone.
            EvidenceMgt.UpdateEvidenceForRun(Result."Run ID");
            Result.Get(Result."Entry No.");
            AssertSummaryText(Result."Matched Permissions Summary", 'Captured Vendor: Modify');
            AssertSummaryText(Result."Conflict Evidence Summary", 'Captured group: Captured Vendor');
            if (Result."Matched Group Count" <> 1) or (Result."Matched Rule Count" <> 1) or (Result."Matched Object Count" <> 1) then
                Error('Refresh changed counters.');
            Line.Get(Line."Entry No.");
            AssertSummaryText(Line."Matched Permission", 'Modify: Direct or Indirect');
        end;
    end;

    [Test]
    procedure CustomerSummarySpecialEvidenceFallback()
    var
        Result: Record "BCG User Conflict Result";
        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
    begin
        CreateSummaryResult(Result);
        AddSummaryLine(Result, 1, 'Master Data', 23, 'Vendor', 'R1', 'SUPER Override', true);
        AddSummaryLine(Result, 1, 'Master Data', 23, 'Vendor', 'R1', 'SUPER Override', true);
        AddSummaryLine(Result, 1, 'Master Data', 288, 'Vendor Bank Account', 'R2', '', true);
        EvidenceMgt.UpdateEvidenceForResult(Result);
        AssertSummaryText(Result."Matched Permissions Summary", 'Vendor: Special permission; Vendor Bank Account: Special permission');
        AssertSummaryText(Result."Conflict Evidence Summary", 'Master Data: Vendor, Vendor Bank Account');
    end;

    [Test]
    procedure CustomerSummaryTruncatedAndUnknownEvidence()
    var
        Result: Record "BCG User Conflict Result";
        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
    begin
        CreateSummaryResult(Result);
        AddSummaryLine(Result, 1, '', 23, 'Vendor', 'R1', 'Read: Direct Only/Modify', false);
        AddSummaryLine(Result, 1, '', 288, 'Vendor Bank Account', 'R2', 'Modify: Direct or Indi', false);
        AddSummaryLine(Result, 1, '', 81, 'Gen. Journal Line', 'R3', 'Read/Mod', false);
        AddSummaryLine(Result, 1, '', 999, '', 'R4', '', false);
        AddSummaryLine(Result, 1, '', 998, 'Old object', 'R5', 'Unknown old text', false);
        EvidenceMgt.UpdateEvidenceForResult(Result);
        AssertSummaryText(Result."Matched Permissions Summary", 'Vendor: Read, Modify; Vendor Bank Account: Modify; Gen. Journal Line: Read, See detailed evidence; Object 999: See detailed evidence; Old object: See detailed evidence');
        AssertSummaryText(Result."Conflict Evidence Summary", 'Group 1: Vendor, Vendor Bank Account, Gen. Journal Line, Object 999, Old object');
    end;

    [Test]
    procedure EvidenceIdentitiesDoNotMatchAcrossBoundaries()
    var
        Result: Record "BCG User Conflict Result";
        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
    begin
        CreateSummaryResult(Result);
        AddSummaryLine(Result, 1, 'First', 2, 'Object 2', 'A|B', 'Read', false);
        AddSummaryLine(Result, 3, 'Second', 4, 'Object 4', 'C', 'Read', false);
        AddSummaryLine(Result, 2, 'Third', 3, 'Object 3', 'D', 'Read', false);
        AddSummaryLine(Result, 1, 'First', 2, 'Object 2', 'A|B', 'Read', false);
        EvidenceMgt.UpdateEvidenceForResult(Result);
        if (Result."Matched Group Count" <> 3) or (Result."Matched Object Count" <> 3) or
           (Result."Matched Rule Count" <> 3) then
            Error('Evidence identity boundaries or duplicate handling are incorrect.');
    end;

    [Test]
    procedure EvidenceIdentitiesSurviveDisplayTruncation()
    var
        Result: Record "BCG User Conflict Result";
        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
        RuleId: Code[30];
        RuleNo: Integer;
    begin
        CreateSummaryResult(Result);
        for RuleNo := 1 to 200 do begin
            RuleId := CopyStr('LONG-EVIDENCE-RULE-' + Format(RuleNo), 1, MaxStrLen(RuleId));
            AddSummaryLine(Result, 1, 'Group', 23, 'Vendor', RuleId, 'Read', false);
        end;
        // The last identity lies beyond the old 2048-character membership buffer.
        AddSummaryLine(Result, 1, 'Group', 23, 'Vendor', RuleId, 'Read', false);
        EvidenceMgt.UpdateEvidenceForResult(Result);
        if (Result."Matched Group Count" <> 1) or (Result."Matched Object Count" <> 1) or
           (Result."Matched Rule Count" <> 200) then
            Error('Display truncation must not truncate evidence membership.');
        EvidenceMgt.UpdateEvidenceForResult(Result);
        if Result."Matched Rule Count" <> 200 then
            Error('Repeated evidence refresh must preserve exact counts.');
    end;

    local procedure CreateSummaryResult(var Result: Record "BCG User Conflict Result")
    var
        AuditRun: Record "BCG Audit Run";
    begin
        Result.Init();
        Result."Run ID" := CreateGuid();
        AuditRun."Run ID" := Result."Run ID";
        AuditRun.Status := AuditRun.Status::Running;
        AuditRun.Insert();
        Result.Insert();
    end;

    local procedure AddSummaryLine(Result: Record "BCG User Conflict Result"; GroupNo: Integer; GroupName: Text[100]; ObjectId: Integer; ObjectName: Text[249]; RuleId: Code[30]; MatchedText: Text[30]; Special: Boolean)
    var
        Line: Record "BCG User Conflict Result Line";
    begin
        Line.Init();
        Line."Conflict Result Entry No." := Result."Entry No.";
        Line."Run ID" := Result."Run ID";
        Line."Group No." := GroupNo;
        Line."Group Name" := GroupName;
        Line."Object ID" := ObjectId;
        Line."Object Name" := ObjectName;
        Line."Rule ID" := RuleId;
        Line."Required Permission" := 'Read/Insert/Modify/Delete(Any)';
        Line."Matched Permission" := MatchedText;
        Line."Is Special Permission Source" := Special;
        Line.Insert();
    end;

    local procedure AssertSummaryText(Actual: Text; Expected: Text)
    begin
        if Actual <> Expected then
            Error('Expected summary "%1", got "%2".', Expected, Actual);
    end;

    [Test]
    procedure SuperFullAnalysisBuildSequenceAndTwoRebuilds()
    var
        BeforeRebuild: Record "BCG User Table Data Perm.";
        AfterRebuild: Record "BCG User Table Data Perm.";
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        AddAssignment('SUPER', TestAppId, 'System');
        AddObjectPermission('SUPER', TestAppId, 'System', 'Yes');
        // Exercise the initial build -> special marking -> final build sequence of Full Analysis.
        RebuildAndComparePhase1(TestRunId);
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        BeforeRebuild.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
        RebuildAndComparePhase1(TestRunId);
        AssertCount(1);
        RebuildAndComparePhase1(TestRunId);
        AssertCount(1);
        RebuildAndComparePhase1(TestRunId);
        AssertCount(1);
        AfterRebuild.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
        if (AfterRebuild."Object Name" <> BeforeRebuild."Object Name") or
           (AfterRebuild."Is Special Permission" <> BeforeRebuild."Is Special Permission") or
           (AfterRebuild."Applies To All Objects" <> BeforeRebuild."Applies To All Objects") or
           (AfterRebuild."Special Permission Type" <> BeforeRebuild."Special Permission Type") or
           (AfterRebuild."Special Perm. Source Summary" <> BeforeRebuild."Special Perm. Source Summary") or
           (AfterRebuild."Special Permission Notes" <> BeforeRebuild."Special Permission Notes") or
           (AfterRebuild."Source Permission Set ID" <> BeforeRebuild."Source Permission Set ID") or
           (AfterRebuild."Source Permission Set Name" <> BeforeRebuild."Source Permission Set Name") or
           (AfterRebuild."BCG Assignment Source Type" <> BeforeRebuild."BCG Assignment Source Type") or
           (AfterRebuild."Can Read" <> BeforeRebuild."Can Read") or
           (AfterRebuild."Can Insert" <> BeforeRebuild."Can Insert") or
           (AfterRebuild."Can Modify" <> BeforeRebuild."Can Modify") or
           (AfterRebuild."Can Delete" <> BeforeRebuild."Can Delete")
        then
            Error('Rebuild changed special metadata or effective permission flags.');
    end;

    [Test]
    procedure SuperWithoutExpandedWildcardCountsOnce()
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        AddAssignment('SUPER', TestAppId, 'System');
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        AssertCount(1);
        RebuildAndComparePhase1(TestRunId);
        AssertCount(1);
    end;

    [Test]
    procedure TwoDistinctPermissionSetsCountTwice()
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        AddAssignment('SUPER', TestAppId, 'System');
        AddObjectPermission('SUPER', TestAppId, 'System', 'Yes');
        AddAssignment('TEST READ', TestAppId, 'System');
        AddObjectPermission('TEST READ', TestAppId, 'System', 'Indirect');
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        RebuildAndComparePhase1(TestRunId);
        AssertCount(2);
        RebuildAndComparePhase1(TestRunId);
        AssertCount(2);
    end;

    [Test]
    procedure DirectAndTwoGroupsWithSameIdentityCountOnce()
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        AddAssignment('SUPER', TestAppId, 'System');
        AddObjectPermission('SUPER', TestAppId, 'System', 'Yes');
        AddGroupAssignment('GROUP A', 'SUPER', TestAppId, 'System');
        AddGroupAssignment('GROUP B', 'SUPER', TestAppId, 'System');
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        RebuildAndComparePhase1(TestRunId);
        AssertCount(1);
    end;

    [Test]
    procedure SameRoleDifferentAppsCountTwice()
    var
        OtherAppId: Guid;
    begin
        InitializeFixture();
        OtherAppId := CreateGuid();
        AddAssignment('TEST READ', TestAppId, 'System');
        AddObjectPermission('TEST READ', TestAppId, 'System', 'Yes');
        AddAssignment('TEST READ', OtherAppId, 'System');
        AddObjectPermission('TEST READ', OtherAppId, 'System', 'Yes');
        RebuildAndComparePhase1(TestRunId);
        AssertCount(2);
    end;

    [Test]
    procedure SpecialFallbackPreservesDistinctScopes()
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        AddAssignment('SUPER', TestAppId, 'System');
        AddGroupAssignment('GROUP A', 'SUPER', TestAppId, 'Tenant');
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        RebuildAndComparePhase1(TestRunId);
        // The Tenant assignment remains captured but grants no special wildcard.
        AssertCount(1);
    end;

    [Test]
    procedure PermissionEntryWithoutGrantDoesNotCount()
    begin
        InitializeFixture();
        AddAssignment('TEST NONE', TestAppId, 'System');
        AddObjectPermission('TEST NONE', TestAppId, 'System', 'No');
        RebuildAndComparePhase1(TestRunId);
        AssertCount(0);
    end;

    [Test]
    procedure CapturedSuperSurvivesLiveRevocation()
    var
        AccessControl: Record "Access Control";
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        AddLiveAssignment('SUPER');
        AddAssignment('SUPER', TestAppId, 'System');
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        AccessControl.SetRange("User Security ID", TestUserId);
        AccessControl.DeleteAll();
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        RebuildAndComparePhase1(TestRunId);
        AssertCapturedSuper();
    end;

    [Test]
    procedure LaterLiveSuperDataDoesNotEnrichHistory()
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        AddAssignment('SUPER', TestAppId, 'System');
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        AddLiveAssignment('SUPER (DATA)');
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        RebuildAndComparePhase1(TestRunId);
        AssertCapturedSuper();
    end;

    [Test]
    procedure LaterLiveSuperDoesNotCreateHistoricalWildcard()
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
    begin
        InitializeFixture();
        AddLiveAssignment('SUPER');
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        RebuildAndComparePhase1(TestRunId);
        if EffectivePerm.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0) then
            Error('Live SUPER created a historical wildcard.');
    end;

    [Test]
    procedure RunningCalculationRestoresCapturedGroupAssignment()
    var
        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
        Assignment: Record "BCG User Perm. Assignment";
        GroupAssignment: Record "BCG SecGrp Perm Assign";
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        AddGroupAssignment('GROUP A', 'SUPER', TestAppId, 'System');
        // No current group or membership exists for this random user. Calculation must use the capture.
        AddLiveAssignment('SUPER (DATA)');
        SecGrpMgt.RestoreAssignmentsFromSnapshot(TestRunId);
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        Assignment.Get(TestRunId, TestUserId, '', 'SUPER', TestAppId, 'System');
        if (Assignment."Scope Text" <> 'System') or
           (Assignment."Assignment Source Type" <> 'Security Group') or
           (Assignment."Assignment Source Code" <> 'GROUP A') then
            Error('Captured group source was not restored.');
        GroupAssignment.Get(TestRunId, 'GROUP A', TestUserId, '', 'SUPER', TestAppId, 'System');
        AssertCapturedSuper();
        SecGrpMgt.RestoreAssignmentsFromSnapshot(TestRunId);
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        AssertCapturedSuper();
    end;

    [Test]
    procedure CompletedRunRejectsLiveGroupRecapture()
    var
        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
        GroupAssignment: Record "BCG SecGrp Perm Assign";
        AuditRun: Record "BCG Audit Run";
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        AuditRun.Get(TestRunId);
        AuditRun.Status := AuditRun.Status::Finished;
        AuditRun.Modify();
        AddGroupAssignment('GROUP A', 'SUPER', TestAppId, 'System');
        Commit();
        asserterror SecGrpMgt.RunSecurityGroupSnapshot(TestRunId, false);
        if StrPos(GetLastErrorText(), 'Historical analysis maintenance is unsupported') = 0 then
            Error('Expected the completed-run capture guard.');
        GroupAssignment.Get(TestRunId, 'GROUP A', TestUserId, '', 'SUPER', TestAppId, 'System');
    end;

    [Test]
    procedure IncompleteGroupMembershipRejectsPartialRows()
    var
        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
        UserSnapshot: Record "BCG User Snapshot";
        Members: Record "Security Group Member Buffer" temporary;
        MemberSnapshot: Record "BCG SecGrp Member Snap";
        FailedGroups: List of [Code[20]];
    begin
        InitializeFixture();
        // Buffer name fields are FlowFields; seed the captured-user fallback instead.
        UserSnapshot.Get(TestRunId, TestUserId);
        UserSnapshot."User Name" := 'TEST MEMBER';
        UserSnapshot."Full Name" := 'Test Member';
        UserSnapshot.Modify();
        Members."Security Group Code" := 'GROUP OK';
        Members."User Security ID" := TestUserId;
        Members.Insert();
        FailedGroups.Add('GROUP FAILED');

        // Catch without AssertError rollback so a misplaced guard cannot hide partial writes.
        ClearLastError();
        if TryLoadMembershipResult(SecGrpMgt, TestRunId, Members, FailedGroups) then
            Error('Incomplete membership retrieval must stop analysis.');
        if StrPos(GetLastErrorText(), 'Security Group membership retrieval failed for 1 group(s).') = 0 then
            Error('Expected the incomplete membership retrieval error.');
        MemberSnapshot.SetRange("Run ID", TestRunId);
        if not MemberSnapshot.IsEmpty() then
            Error('Partial membership rows were persisted before retrieval was validated.');

        Clear(FailedGroups);
        if SecGrpMgt.TestLoadSecurityGroupMembers(TestRunId, Members, FailedGroups) <> 1 then
            Error('Successful membership retrieval must still capture the member.');
        MemberSnapshot.Get(TestRunId, 'GROUP OK', TestUserId);
        MemberSnapshot.TestField("User Name", 'TEST MEMBER');
    end;

    [TryFunction]
    local procedure TryLoadMembershipResult(var SecGrpMgt: Codeunit "BCG SecGrp Mgt"; RunId: Guid; var Members: Record "Security Group Member Buffer" temporary; FailedGroups: List of [Code[20]])
    begin
        SecGrpMgt.TestLoadSecurityGroupMembers(RunId, Members, FailedGroups);
    end;

    [MessageHandler]
    procedure IgnoreCompletionMessage(MessageText: Text[1024])
    begin
    end;

    local procedure AddLiveAssignment(RoleId: Code[20])
    var
        AccessControl: Record "Access Control";
    begin
        // Synthetic user only; test runner rolls back these records after each test.
        AccessControl.Init();
        AccessControl."User Security ID" := TestUserId;
        AccessControl."Role ID" := RoleId;
        AccessControl."App ID" := TestAppId;
        if RoleId = 'SUPER' then
            Clear(AccessControl."App ID");
        if RoleId = 'SUPER (DATA)' then
            AccessControl."App ID" := '63ca2fa4-4f03-4f2b-a480-172fef340d3f';
        AccessControl.Insert(false);
    end;

    local procedure AssertCapturedSuper()
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
    begin
        AssertCount(1);
        EffectivePerm.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
        if (EffectivePerm."Special Perm. Source Summary" <> 'SUPER') or
           (EffectivePerm."Special Permission Type" <> EffectivePerm."Special Permission Type"::SUPER) or
           (EffectivePerm."Object Name" <> '*ALL TABLE DATA*') or
           not EffectivePerm."Is Special Permission" or not EffectivePerm."Applies To All Objects" or
           not EffectivePerm."Can Read" or not EffectivePerm."Can Insert" or
           not EffectivePerm."Can Modify" or not EffectivePerm."Can Delete" then
            Error('Captured SUPER metadata changed.');
    end;

    [Test]
    procedure NamedCompanyOnlyCountsOnce()
    begin
        CheckCompanyCount(true, false, false, false, 1);
    end;

    [Test]
    procedure BlankCompanyOnlyAppliesToTarget()
    begin
        CheckCompanyCount(false, true, false, false, 1);
    end;

    [Test]
    procedure NamedAndBlankDistinctIdentitiesCountTwice()
    begin
        CheckCompanyCount(true, true, false, false, 2);
    end;

    [Test]
    procedure NamedAndBlankSameIdentityCountsOnce()
    begin
        CheckCompanyCount(true, true, true, false, 1);
    end;

    [Test]
    procedure OtherNamedCompanyDoesNotContribute()
    begin
        CheckCompanyCount(true, false, false, true, 1);
    end;

    local procedure CheckCompanyCount(IncludeNamed: Boolean; IncludeBlank: Boolean; SameIdentity: Boolean; IncludeOther: Boolean; Expected: Integer)
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        Assignment: Record "BCG User Perm. Assignment";
        TargetCompany: Text[30];
        BlankRole: Code[30];
    begin
        InitializeFixture();
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        AddVendorPermission('TEST NAMED');
        if IncludeNamed then
            AddCompanyAssignment('TEST NAMED', TargetCompany);
        if IncludeBlank then begin
            BlankRole := 'TEST GLOBAL';
            if SameIdentity then
                BlankRole := 'TEST NAMED'
            else
                AddVendorPermission(BlankRole);
            AddCompanyAssignment(BlankRole, '');
        end;
        if IncludeOther then begin
            AddVendorPermission('TEST OTHER');
            AddCompanyAssignment('TEST OTHER', 'OTHER-' + CopyStr(Format(CreateGuid()), 2, 20));
        end;
        RebuildAndComparePhase1(TestRunId);
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
        if EffectivePerm."Effective Source Count" <> Expected then
            Error('Expected %1 applicable identities, got %2.', Expected, EffectivePerm."Effective Source Count");
        RebuildAndComparePhase1(TestRunId);
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
        if EffectivePerm."Effective Source Count" <> Expected then
            Error('Company-scoped count changed on rebuild.');
        if IncludeBlank then
            Assignment.Get(TestRunId, TestUserId, '', BlankRole, TestAppId, 'System');
    end;

    [Test]
    procedure BlankGroupIndirectGrantCreatesTargetEvidence()
    begin
        CheckBlankGroupEvidence(false);
    end;

    [Test]
    procedure DuplicateCompanyIdentityProducesOneMixedEvidenceLine()
    begin
        CheckBlankGroupEvidence(true);
    end;

    local procedure CheckBlankGroupEvidence(AddNamedDuplicate: Boolean)
    var
        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
        ConflictHeader: Record "BCG Conflict Header";
        ConflictGroup: Record "BCG Conflict Group";
        GroupRule: Record "BCG Conflict Group Rule";
        ConflictLine: Record "BCG User Conflict Result Line";
        EffectivePerm: Record "BCG User Table Data Perm.";
        ConflictId: Code[20];
        TargetCompany: Text[30];
    begin
        InitializeFixture();
        Clear(TestAppId); // Genuine BC28 SUPER assignment identity.
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        AddGroupAssignment('BCAA_SALES', 'D365 SALES', TestAppId, 'System');
        SecGrpMgt.RestoreAssignmentsFromSnapshot(TestRunId);
        AddVendorPermission('D365 SALES');
        AddCompanyAssignment('SUPER', 'OTHER-' + CopyStr(Format(CreateGuid()), 2, 20));
        AddCompanyAssignment('SUPER', 'OTHER-' + CopyStr(Format(CreateGuid()), 2, 20));
        if AddNamedDuplicate then
            AddCompanyAssignment('D365 SALES', TargetCompany);
        ConflictId := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        ConflictHeader.Init();
        ConflictHeader."Conflict ID" := ConflictId;
        ConflictHeader."Is Active" := true;
        ConflictHeader.Insert();
        ConflictGroup.Init();
        ConflictGroup."Conflict ID" := ConflictId;
        ConflictGroup."Group No." := 1;
        ConflictGroup."Is Active" := true;
        ConflictGroup.Insert();
        GroupRule.Init();
        GroupRule."Conflict ID" := ConflictId;
        GroupRule."Group No." := 1;
        GroupRule."Line No." := 1;
        GroupRule."Rule ID" := 'TEST VENDOR MODIFY';
        GroupRule."Object ID" := 23;
        GroupRule."Object Caption" := 'Vendor';
        GroupRule."Requires Modify" := true;
        GroupRule."Modify Permission Match" := GroupRule."Modify Permission Match"::"Direct or Indirect";
        GroupRule.Insert();
        RebuildAndComparePhase1(TestRunId);
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
        if not EffectivePerm."Can Modify" or (EffectivePerm."Effective Source Count" <> 1) then
            Error('Blank-company group Indirect grant was not applied once.');
        SnapshotMgt.CalculateConflicts(TestRunId);
        ConflictLine.SetRange("Run ID", TestRunId);
        ConflictLine.SetRange("User Security ID", TestUserId);
        ConflictLine.SetRange("Company Name", TargetCompany);
        ConflictLine.SetRange("Conflict Code", ConflictId);
        ConflictLine.SetRange("Object ID", 23);
        ConflictLine.SetRange("Role ID", 'D365 SALES');
        if ConflictLine.Count() <> 1 then
            Error('Expected one target-company SALES evidence line, got %1.', ConflictLine.Count());
        ConflictLine.FindFirst();
        if not ConflictLine."Is From Security Group" or (ConflictLine."Security Group Code" <> 'BCAA_SALES') then
            Error('Blank-company Security Group attribution was lost.');
        if AddNamedDuplicate then
            if ConflictLine."Permission Source Type" <> ConflictLine."Permission Source Type"::Mixed then
                Error('Direct + blank-company group identity should have Mixed attribution.');
        ConflictLine.SetRange("Role ID");
        ConflictLine.SetRange("Is Special Permission Source", true);
        if not ConflictLine.IsEmpty() then
            Error('SUPER from another named company leaked into target-company evidence.');
        ConflictLine.SetRange("Role ID");
        ConflictLine.SetRange("Is Special Permission Source", true);
        if not ConflictLine.IsEmpty() then
            Error('SUPER from another named company leaked into target-company evidence.');
    end;

    local procedure AddCompanyAssignment(RoleId: Code[30]; TargetCompany: Text[30])
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        Assignment.Init();
        Assignment."Run ID" := TestRunId;
        Assignment."User Security ID" := TestUserId;
        Assignment."Company Name" := TargetCompany;
        Assignment."Role ID" := RoleId;
        Assignment."App ID" := TestAppId;
        Assignment."Scope Text" := 'System';
        Assignment."Assignment Source Type" := 'Direct';
        Assignment.Insert();
    end;

    local procedure AddVendorPermission(RoleId: Code[30])
    var
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
    begin
        ObjectPerm.Init();
        ObjectPerm."Run ID" := TestRunId;
        ObjectPerm."Role ID" := RoleId;
        ObjectPerm."App ID" := TestAppId;
        ObjectPerm."Scope Text" := 'System';
        ObjectPerm."Object Type" := 'Table Data';
        ObjectPerm."Object ID" := 23;
        ObjectPerm."Object Name" := 'Vendor';
        ObjectPerm."Read Permission" := 'Yes';
        ObjectPerm."Modify Permission" := 'Indirect';
        ObjectPerm.Insert();
    end;

    [Test]
    procedure ExactGrantCountRemainsOne()
    begin
        CheckWildcardCount(true, false, false, false, false, 1);
    end;

    [Test]
    procedure WildcardOnlyGrantCountsForVendor()
    begin
        CheckWildcardCount(false, true, false, false, false, 1);
    end;

    [Test]
    procedure ExactAndWildcardSameIdentityCountOnce()
    begin
        CheckWildcardCount(true, true, true, false, false, 1);
    end;

    [Test]
    procedure ExactAndWildcardDistinctIdentitiesCountTwice()
    begin
        CheckWildcardCount(true, true, false, false, false, 2);
    end;

    [Test]
    procedure BlankCompanyGroupWildcardCountsForVendor()
    begin
        CheckWildcardCount(false, true, false, true, false, 1);
    end;

    [Test]
    procedure IndirectOnlyWildcardCountsForVendor()
    begin
        CheckWildcardCount(false, true, false, false, true, 1);
    end;

    local procedure CheckWildcardCount(IncludeExact: Boolean; IncludeWildcard: Boolean; SameIdentity: Boolean; GroupSource: Boolean; IndirectOnly: Boolean; Expected: Integer)
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
        WildcardRole: Code[30];
        TargetCompany: Text[30];
    begin
        InitializeFixture();
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        if IncludeExact then begin
            AddCompanyAssignment('TEST EXACT', TargetCompany);
            AddVendorPermission('TEST EXACT');
        end else begin
            // Materialize a Vendor row with no grants; only the wildcard may contribute to its count.
            AddCompanyAssignment('TEST EMPTY', TargetCompany);
            AddVendorPermission('TEST EMPTY');
            ObjectPerm.Get(TestRunId, 'TEST EMPTY', TestAppId, 'System', 'Table Data', 23);
            ObjectPerm."Read Permission" := '';
            ObjectPerm."Modify Permission" := '';
            ObjectPerm.Modify();
        end;
        if IncludeWildcard then begin
            WildcardRole := 'TEST WILD';
            if SameIdentity then
                WildcardRole := 'TEST EXACT'
            else
                if GroupSource then begin
                    AddGroupAssignment('WILD GROUP', CopyStr(WildcardRole, 1, 20), TestAppId, 'System');
                    SecGrpMgt.RestoreAssignmentsFromSnapshot(TestRunId);
                end else
                    AddCompanyAssignment(WildcardRole, TargetCompany);
            AddObjectPermission(WildcardRole, TestAppId, 'System', 'Yes');
            if IndirectOnly then begin
                ObjectPerm.Get(TestRunId, WildcardRole, TestAppId, 'System', 'Table Data', 0);
                ObjectPerm."Read Permission" := '';
                ObjectPerm."Modify Permission" := 'Indirect';
                ObjectPerm.Modify();
            end;
        end;
        RebuildAndComparePhase1(TestRunId);
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
        if (EffectivePerm."Effective Source Count" <> Expected) or
           (SnapshotMgt.CountEffectivePermissionSources(EffectivePerm) <> Expected) then
            Error('Exact/wildcard contributor count should be %1.', Expected);
        RebuildAndComparePhase1(TestRunId);
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
        if EffectivePerm."Effective Source Count" <> Expected then
            Error('Wildcard source count changed after rebuild.');
    end;

    [Test]
    procedure ExactAndWildcardEvidenceAgreeWithSourceCount()
    var
        ConflictHeader: Record "BCG Conflict Header";
        ConflictGroup: Record "BCG Conflict Group";
        GroupRule: Record "BCG Conflict Group Rule";
        ConflictLine: Record "BCG User Conflict Result Line";
        EffectivePerm: Record "BCG User Table Data Perm.";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
        TargetCompany: Text[30];
        ConflictId: Code[20];
    begin
        InitializeFixture();
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        AddCompanyAssignment('TEST EXACT', TargetCompany);
        AddVendorPermission('TEST EXACT');
        AddGroupAssignment('WILD GROUP', 'TEST WILD', TestAppId, 'System');
        SecGrpMgt.RestoreAssignmentsFromSnapshot(TestRunId);
        AddObjectPermission('TEST WILD', TestAppId, 'System', '');
        ObjectPerm.Get(TestRunId, 'TEST WILD', TestAppId, 'System', 'Table Data', 0);
        ObjectPerm."Modify Permission" := 'Indirect';
        ObjectPerm.Modify();
        // A non-Table-Data source with the same numeric object ID must not enter evidence/counting.
        AddCompanyAssignment('TEST PAGE', TargetCompany);
        ObjectPerm.Init();
        ObjectPerm."Run ID" := TestRunId;
        ObjectPerm."Role ID" := 'TEST PAGE';
        ObjectPerm."App ID" := TestAppId;
        ObjectPerm."Scope Text" := 'System';
        ObjectPerm."Object Type" := 'Page';
        ObjectPerm."Object ID" := 23;
        ObjectPerm."Modify Permission" := 'Yes';
        ObjectPerm.Insert();
        ConflictId := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        ConflictHeader.Init();
        ConflictHeader."Conflict ID" := ConflictId;
        ConflictHeader."Is Active" := true;
        ConflictHeader.Insert();
        ConflictGroup.Init();
        ConflictGroup."Conflict ID" := ConflictId;
        ConflictGroup."Group No." := 1;
        ConflictGroup."Is Active" := true;
        ConflictGroup.Insert();
        GroupRule.Init();
        GroupRule."Conflict ID" := ConflictId;
        GroupRule."Group No." := 1;
        GroupRule."Line No." := 1;
        GroupRule."Rule ID" := 'TEST WILDCARD MODIFY';
        GroupRule."Object ID" := 23;
        GroupRule."Object Caption" := 'Vendor';
        GroupRule."Requires Modify" := true;
        GroupRule."Modify Permission Match" := GroupRule."Modify Permission Match"::"Direct or Indirect";
        GroupRule.Insert();
        RebuildAndComparePhase1(TestRunId);
        SnapshotMgt.CalculateConflicts(TestRunId);
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
        ConflictLine.SetRange("Run ID", TestRunId);
        ConflictLine.SetRange("User Security ID", TestUserId);
        ConflictLine.SetRange("Company Name", TargetCompany);
        ConflictLine.SetRange("Conflict Code", ConflictId);
        ConflictLine.SetRange("Object ID", 23);
        if (EffectivePerm."Effective Source Count" <> 2) or (ConflictLine.Count() <> 2) then
            Error('Both exact and wildcard identities must be counted and shown as Modify evidence.');
        ConflictLine.SetRange("Role ID", 'TEST EXACT');
        if ConflictLine.Count() <> 1 then
            Error('Exact contributor missing from evidence.');
        ConflictLine.SetRange("Role ID", 'TEST WILD');
        if ConflictLine.Count() <> 1 then
            Error('Wildcard contributor missing from evidence.');
        ConflictLine.FindFirst();
        if not ConflictLine."Is From Security Group" then
            Error('Wildcard group attribution missing.');
        ComparePhase1ConflictEvidence(TestRunId);
    end;

    [Test]
    procedure GlobalOnlyConflictHasNamedResultOnly()
    begin
        CheckSpecialResultIdentity(true, false, false, false, false, true);
    end;

    [Test]
    procedure GlobalAndNamedConflictHasNoBlankResult()
    begin
        CheckSpecialResultIdentity(true, false, true, false, false, true);
    end;

    [Test]
    procedure OtherCompanyDoesNotCreateSpecialResults()
    begin
        CheckSpecialResultIdentity(true, false, false, true, false, true);
    end;

    [Test]
    procedure DirectSuperDataEvidenceIsOneIdentity()
    begin
        CheckSpecialResultIdentity(true, false, false, false, false, true);
    end;

    [Test]
    procedure GroupSuperDataEvidenceRetainsGroup()
    begin
        CheckSpecialResultIdentity(false, true, false, false, false, true);
    end;

    [Test]
    procedure DirectAndGroupSuperDataEvidenceIsCombined()
    begin
        CheckSpecialResultIdentity(true, true, false, false, false, true);
    end;

    [Test]
    procedure SpecialAndOrdinaryDistinctSourcesRemainVisible()
    begin
        CheckSpecialResultIdentity(true, false, false, false, true, true);
    end;

    [Test]
    procedure SpecialWithoutExpandedGrantStillMatches()
    begin
        CheckSpecialResultIdentity(true, false, false, false, false, false);
    end;

    local procedure CheckSpecialResultIdentity(DirectSource: Boolean; GroupSource: Boolean; NamedDuplicate: Boolean; SecondTarget: Boolean; OrdinarySource: Boolean; ExpandedGrant: Boolean)
    var
        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
        SpecialSourceMgt: Codeunit "BCG SecGrp Special Src Mgt";
        SourceSummaryMgt: Codeunit "BCG Conflict Src Summary";
        ConflictResult: Record "BCG User Conflict Result";
        ConflictLine: Record "BCG User Conflict Result Line";
        EffectivePerm: Record "BCG User Table Data Perm.";
        ConflictHeader: Record "BCG Conflict Header";
        ConflictGroup: Record "BCG Conflict Group";
        GroupRule: Record "BCG Conflict Group Rule";
        TargetCompany: Text[30];
        OtherCompany: Text[30];
        ConflictId: Code[20];
        ExpectedResults: Integer;
        ExpectedSources: Integer;
        PassNo: Integer;
        BeforeCount: Integer;
    begin
        InitializeFixture();
        TestAppId := '63ca2fa4-4f03-4f2b-a480-172fef340d3f';
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        ExpectedResults := 1;
        ExpectedSources := 1;
        if DirectSource then
            AddCompanyAssignment('SUPER (DATA)', '');
        if GroupSource then begin
            AddGroupAssignment('SUPER GROUP', 'SUPER (DATA)', TestAppId, 'System');
            SecGrpMgt.RestoreAssignmentsFromSnapshot(TestRunId);
        end;
        if NamedDuplicate then
            AddCompanyAssignment('SUPER (DATA)', TargetCompany);
        if SecondTarget then begin
            OtherCompany := 'TARGET-' + CopyStr(Format(CreateGuid()), 2, 20);
            AddCompanyAssignment('SUPER (DATA)', OtherCompany);
        end;
        if ExpandedGrant then
            AddVendorPermission('SUPER (DATA)');
        if OrdinarySource then begin
            AddCompanyAssignment('TEST ORDINARY', TargetCompany);
            AddVendorPermission('TEST ORDINARY');
            ExpectedSources := 2;
        end;
        ConflictId := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        ConflictHeader.Init();
        ConflictHeader."Conflict ID" := ConflictId;
        ConflictHeader."Is Active" := true;
        ConflictHeader.Insert();
        ConflictGroup.Init();
        ConflictGroup."Conflict ID" := ConflictId;
        ConflictGroup."Group No." := 1;
        ConflictGroup."Is Active" := true;
        ConflictGroup.Insert();
        GroupRule.Init();
        GroupRule."Conflict ID" := ConflictId;
        GroupRule."Group No." := 1;
        GroupRule."Line No." := 1;
        GroupRule."Rule ID" := 'TEST SPECIAL MODIFY';
        GroupRule."Object ID" := 23;
        GroupRule."Object Caption" := 'Vendor';
        GroupRule."Requires Modify" := true;
        GroupRule."Modify Permission Match" := GroupRule."Modify Permission Match"::"Direct or Indirect";
        GroupRule.Insert();
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        RebuildAndComparePhase1(TestRunId);
        if EffectivePerm.Get(TestRunId, TestUserId, '', 0) then
            Error('A blank-company wildcard must not be generated.');
        AssertCount(1); // The wildcard identity stays distinct from ordinary table-specific sources.
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 0);
        BeforeCount := EffectivePerm."Effective Source Count";
        for PassNo := 1 to 2 do begin
            SnapshotMgt.CalculateConflicts(TestRunId);
            SpecialSourceMgt.MarkSpecialPermissionsAssignedThroughSecurityGroups(TestRunId);
            SourceSummaryMgt.UpdateConflictResultSourcesForRun(TestRunId, false);
            SpecialSourceMgt.UpdateConflictResultSourcesFromLines(TestRunId);
            ConflictResult.Reset();
            ConflictResult.SetRange("Run ID", TestRunId);
            ConflictResult.SetRange("User Security ID", TestUserId);
            ConflictResult.SetRange("Conflict Code", ConflictId);
            if ConflictResult.Count() <> ExpectedResults then
                Error('Expected %1 named results, got %2.', ExpectedResults, ConflictResult.Count());
            ConflictResult.SetRange("Company Name", '');
            if not ConflictResult.IsEmpty() then
                Error('Blank-company business result was generated.');
            ConflictResult.SetRange("Company Name", TargetCompany);
            ConflictResult.FindFirst();
            if not ConflictResult."Has Special Permission Source" then
                Error('Special result attribute was lost.');
            if ConflictResult."Has Direct Source" <> DirectSource then
                Error('Direct result attribute is incorrect.');
            if ConflictResult."Has Security Group Source" <> GroupSource then
                Error('Group result attribute is incorrect.');
            if DirectSource and GroupSource then begin
                if ConflictResult."Primary Permission Source" <> ConflictResult."Primary Permission Source"::Mixed then
                    Error('Expected Mixed for both assignment routes.');
            end else
                if DirectSource then begin
                    if ConflictResult."Primary Permission Source" <> ConflictResult."Primary Permission Source"::Direct then
                        Error('Special Direct evidence must remain Direct.');
                end else
                    if GroupSource then
                        if ConflictResult."Primary Permission Source" <> ConflictResult."Primary Permission Source"::"Security Group" then
                            Error('Special group evidence must remain Security Group.');
            ConflictLine.Reset();
            ConflictLine.SetRange("Conflict Result Entry No.", ConflictResult."Entry No.");
            if ConflictLine.Count() <> ExpectedSources then
                Error('Expected %1 evidence identities, got %2.', ExpectedSources, ConflictLine.Count());
            ConflictLine.SetRange("Role ID", 'SUPER (DATA)');
            if ConflictLine.Count() <> 1 then
                Error('SUPER (DATA) must have exactly one evidence line.');
            ConflictLine.FindFirst();
            if not ConflictLine."Is Special Permission Source" or
               (StrPos(ConflictLine."Source Notes", 'all Table Data') = 0) then
                Error('Special/wildcard attributes were lost.');
            if GroupSource then
                if not ConflictLine."Is From Security Group" or (ConflictLine."Security Group Code" <> 'SUPER GROUP') then
                    Error('Special group attribution was lost.');
            if DirectSource and GroupSource then
                if ConflictLine."Assignment Source Type" <> 'Direct + Security Group' then
                    Error('Combined assignment route was lost.');
            EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 0);
            if EffectivePerm."Effective Source Count" <> BeforeCount then
                Error('Evidence recalculation changed Effective Source Count.');
        end;
        ComparePhase1ConflictEvidence(TestRunId);
    end;

    [Test]
    procedure CachedOrdinaryRoutesScopesAndCompanies()
    var
        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
        EffectivePerm: Record "BCG User Table Data Perm.";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        TargetCompany: Text[30];
    begin
        InitializeFixture();
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        AddAssignment('TEST ROUTES', TestAppId, 'System');
        AddCompanyAssignment('TEST ROUTES', TargetCompany);
        AddGroupAssignment('GROUP A', 'TEST ROUTES', TestAppId, 'System');
        AddGroupAssignment('GROUP B', 'TEST ROUTES', TestAppId, 'System');
        SecGrpMgt.RestoreAssignmentsFromSnapshot(TestRunId);
        AddVendorPermission('TEST ROUTES');
        AddObjectPermission('TEST ROUTES', TestAppId, 'System', 'Indirect');
        AddCompanyAssignment('TEST OTHER', 'UNRELATED COMPANY');
        AddVendorPermission('TEST OTHER');
        RebuildAndComparePhase1(TestRunId);
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
        if EffectivePerm."Effective Source Count" <> 1 then
            Error('Exact/wildcard, global/company and multiple routes must count once.');

        AddAssignment('TEST ROUTES', TestAppId, 'Tenant');
        AddObjectPermission('TEST ROUTES', TestAppId, 'Tenant', 'Indirect');
        RebuildAndComparePhase1(TestRunId);
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
        if EffectivePerm."Effective Source Count" <> 2 then
            Error('Both granting scopes must count.');
        ObjectPerm.Get(TestRunId, 'TEST ROUTES', TestAppId, 'Tenant', 'Table Data', 0);
        ObjectPerm."Read Permission" := 'No';
        ObjectPerm.Modify();
        RebuildAndComparePhase1(TestRunId);
        EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
        if EffectivePerm."Effective Source Count" <> 1 then
            Error('A nongranting scope must not contribute.');
    end;

    [Test]
    procedure TemporaryAggregationPreservesPermissionValues()
    begin
        CheckAggregationValue('', false, 0);
        CheckAggregationValue(' ', false, 0);
        CheckAggregationValue('No', false, 0);
        CheckAggregationValue('0', false, 0);
        CheckAggregationValue('Indirect', true, 1);
        CheckAggregationValue('Direct', true, 1);
        CheckAggregationValue('Yes', true, 1);
    end;

    local procedure CheckAggregationValue(PermissionValue: Text[20]; ExpectedFlag: Boolean; ExpectedCount: Integer)
    var
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        EffectivePerm: Record "BCG User Table Data Perm.";
        PassNo: Integer;
    begin
        InitializeFixture();
        AddAssignment('TEST VALUE', TestAppId, 'System');
        AddVendorPermission('TEST VALUE');
        ObjectPerm.Get(TestRunId, 'TEST VALUE', TestAppId, 'System', 'Table Data', 23);
        ObjectPerm."Read Permission" := PermissionValue;
        ObjectPerm."Insert Permission" := PermissionValue;
        ObjectPerm."Modify Permission" := PermissionValue;
        ObjectPerm."Delete Permission" := PermissionValue;
        ObjectPerm.Modify();
        for PassNo := 1 to 2 do begin
            RebuildAndComparePhase1(TestRunId);
            EffectivePerm.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 23);
            if (EffectivePerm."Can Read" <> ExpectedFlag) or
               (EffectivePerm."Can Insert" <> ExpectedFlag) or
               (EffectivePerm."Can Modify" <> ExpectedFlag) or
               (EffectivePerm."Can Delete" <> ExpectedFlag) or
               (EffectivePerm."Effective Source Count" <> ExpectedCount)
            then
                Error('Aggregation/count semantics changed for permission value "%1".', PermissionValue);
        end;
    end;

    [Test]
    procedure TemporaryAggregationKeepsFirstNonemptyFilter()
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        PassNo: Integer;
    begin
        InitializeFixture();
        // Deliberately insert out of key order. Global A/B precede named-company C.
        AddFilteredContribution('TEST C', CopyStr(CompanyName(), 1, 30), 'C FILTER', 'C NAME', '', '', 'Yes', 'Yes');
        AddFilteredContribution('TEST B', '', 'B FILTER', 'B NAME', '', 'Indirect', '', '');
        AddFilteredContribution('TEST A', '', '', 'A NAME', 'Yes', '', '', '');
        for PassNo := 1 to 2 do begin
            RebuildAndComparePhase1(TestRunId);
            EffectivePerm.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 23);
            if (EffectivePerm."Security Filter" <> 'B FILTER') or (EffectivePerm."Object Name" <> 'A NAME') or
               not EffectivePerm."Can Read" or not EffectivePerm."Can Insert" or
               not EffectivePerm."Can Modify" or not EffectivePerm."Can Delete" or
               (EffectivePerm."Effective Source Count" <> 3)
            then
                Error('Traversal order, first filter/name, or complementary permission aggregation changed.');
            if EffectivePerm.Get(TestRunId, TestUserId, '', 23) then
                Error('A blank-company effective bucket must not be generated.');
        end;
    end;

    local procedure AddFilteredContribution(RoleId: Code[30]; TargetCompany: Text[30]; SecurityFilter: Text[2048]; ObjectName: Text[249]; ReadValue: Text[20]; InsertValue: Text[20]; ModifyValue: Text[20]; DeleteValue: Text[20])
    var
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
    begin
        AddCompanyAssignment(RoleId, TargetCompany);
        AddVendorPermission(RoleId);
        ObjectPerm.Get(TestRunId, RoleId, TestAppId, 'System', 'Table Data', 23);
        ObjectPerm."Object Name" := ObjectName;
        ObjectPerm."Security Filter" := SecurityFilter;
        ObjectPerm."Read Permission" := ReadValue;
        ObjectPerm."Insert Permission" := InsertValue;
        ObjectPerm."Modify Permission" := ModifyValue;
        ObjectPerm."Delete Permission" := DeleteValue;
        ObjectPerm.Modify();
    end;

    [Test]
    procedure TemporaryAggregationRetainsSuperFields()
    begin
        CheckRetainedSpecialFields('SUPER');
    end;

    [Test]
    procedure TemporaryAggregationRetainsSuperDataFields()
    begin
        CheckRetainedSpecialFields('SUPER (DATA)');
    end;

    local procedure CheckRetainedSpecialFields(RoleId: Code[30])
    var
        Expected: Record "BCG User Table Data Perm.";
        Actual: Record "BCG User Table Data Perm.";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        PassNo: Integer;
    begin
        InitializeFixture();
        Clear(TestAppId);
        if RoleId = 'SUPER (DATA)' then
            TestAppId := '63ca2fa4-4f03-4f2b-a480-172fef340d3f';
        AddAssignment(RoleId, TestAppId, 'System');
        AddObjectPermission(RoleId, TestAppId, 'System', 'Yes');
        SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        Expected.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
        Expected."Run No." := 'RETAINED RUN';
        Expected."Special Permission Notes" := 'Retain custom captured notes';
        Expected."Special Permission Summary" := 'Retain extension summary';
        Expected."Has SUPER" := RoleId = 'SUPER';
        Expected."Has SUPER DATA" := RoleId = 'SUPER (DATA)';
        Expected."Can Read" := false;
        Expected."Effective Source Count" := 99;
        Expected.Modify(true);
        ObjectPerm.Get(TestRunId, RoleId, TestAppId, 'System', 'Table Data', 0);
        ObjectPerm."Security Filter" := 'FIRST FILTER';
        ObjectPerm.Modify();
        Expected."Can Read" := true;
        Expected."Security Filter" := 'FIRST FILTER';
        Expected."Effective Source Count" := 1;
        RebuildAndComparePhase1(TestRunId);
        Actual.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
        AssertEffectiveFieldsEqual(Expected, Actual);

        Expected := Actual;
        // A later filter must not replace the retained filter.
        ObjectPerm."Security Filter" := 'LATER FILTER';
        ObjectPerm.Modify();
        for PassNo := 1 to 2 do begin
            RebuildAndComparePhase1(TestRunId);
            Actual.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
            AssertEffectiveFieldsEqual(Expected, Actual);
            if Actual.SystemModifiedAt <> Expected.SystemModifiedAt then
                Error('An unchanged retained special row was modified.');
        end;
        // No source object contribution: retain the row and use captured special fallback.
        ObjectPerm.Delete();
        RebuildAndComparePhase1(TestRunId);
        Actual.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
        AssertEffectiveFieldsEqual(Expected, Actual);
        if Actual.SystemModifiedAt <> Expected.SystemModifiedAt then
            Error('A special row without contributions was unnecessarily modified.');
    end;

    local procedure AssertEffectiveFieldsEqual(Expected: Record "BCG User Table Data Perm."; Actual: Record "BCG User Table Data Perm.")
    var
        ExpectedRef: RecordRef;
        ActualRef: RecordRef;
        ExpectedField: FieldRef;
        ActualField: FieldRef;
        FieldIndex: Integer;
    begin
        ExpectedRef.GetTable(Expected);
        ActualRef.GetTable(Actual);
        for FieldIndex := 1 to ExpectedRef.FieldCount() do begin
            ExpectedField := ExpectedRef.FieldIndex(FieldIndex);
            if (ExpectedField.Number < 2000000000) and (ExpectedField.Class = FieldClass::Normal) then begin
                ActualField := ActualRef.Field(ExpectedField.Number);
                if Format(ExpectedField.Value) <> Format(ActualField.Value) then
                    Error('Retained field %1 changed.', ExpectedField.Name);
            end;
        end;
        if Expected."Is Special Permission" and (Expected.SystemId <> Actual.SystemId) then
            Error('Retained special row identity changed.');
    end;

    [Test]
    procedure TemporaryAggregationDoesNotLeakAcrossContexts()
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        UserSnapshot: Record "BCG User Snapshot";
        FirstRunId: Guid;
        FirstUserId: Guid;
        SecondUserId: Guid;
        PassNo: Integer;
    begin
        InitializeFixture();
        FirstRunId := TestRunId;
        FirstUserId := TestUserId;
        AddFilteredContribution('TEST FIRST', CopyStr(CompanyName(), 1, 30), 'FIRST FILTER', 'FIRST NAME', 'Yes', '', '', '');
        SecondUserId := CreateGuid();
        TestUserId := SecondUserId;
        UserSnapshot.Init();
        UserSnapshot."Run ID" := TestRunId;
        UserSnapshot."User Security ID" := TestUserId;
        UserSnapshot.Insert();
        AddFilteredContribution('TEST SECOND', CopyStr(CompanyName(), 1, 30), '', 'SECOND NAME', '', '', 'Indirect', '');
        AddFilteredContribution('TEST THIRD', 'CONTEXT B', 'THIRD FILTER', 'THIRD NAME', '', '', '', 'Yes');
        for PassNo := 1 to 2 do begin
            RebuildAndComparePhase1(TestRunId);
            EffectivePerm.Reset();
            EffectivePerm.SetRange("Run ID", TestRunId);
            if EffectivePerm.Count() <> 2 then
                Error('Unexpected effective rows across user/company contexts.');
            EffectivePerm.Get(TestRunId, FirstUserId, CopyStr(CompanyName(), 1, 30), 23);
            if not EffectivePerm."Can Read" or EffectivePerm."Can Modify" or
               (EffectivePerm."Security Filter" <> 'FIRST FILTER') then
                Error('First user context changed.');
            EffectivePerm.Get(TestRunId, SecondUserId, CopyStr(CompanyName(), 1, 30), 23);
            if EffectivePerm."Can Read" or not EffectivePerm."Can Modify" or EffectivePerm."Can Delete" or
               (EffectivePerm."Security Filter" <> '') or (EffectivePerm."Effective Source Count" <> 1) then
                Error('First user leaked into second user.');
            if EffectivePerm.Get(TestRunId, SecondUserId, 'CONTEXT B', 23) then
                Error('An unrelated company produced effective permissions.');
        end;
        InitializeFixture();
        TestUserId := FirstUserId;
        UserSnapshot.Init();
        UserSnapshot."Run ID" := TestRunId;
        UserSnapshot."User Security ID" := TestUserId;
        UserSnapshot.Insert();
        AddFilteredContribution('TEST FIRST', CopyStr(CompanyName(), 1, 30), '', 'NEW RUN NAME', '', '', '', '');
        RebuildAndComparePhase1(TestRunId);
        EffectivePerm.Reset();
        EffectivePerm.SetRange("Run ID", TestRunId);
        if EffectivePerm.Count() <> 1 then
            Error('Previous run rows leaked into the new run.');
        EffectivePerm.Get(TestRunId, FirstUserId, CopyStr(CompanyName(), 1, 30), 23);
        if EffectivePerm."Can Read" or EffectivePerm."Can Insert" or EffectivePerm."Can Modify" or
           EffectivePerm."Can Delete" or (EffectivePerm."Security Filter" <> '') or
           (EffectivePerm."Effective Source Count" <> 0) or (EffectivePerm."Object Name" <> 'NEW RUN NAME') then
            Error('Previous run values leaked into the new run.');
        RebuildAndComparePhase1(FirstRunId);
        EffectivePerm.Get(FirstRunId, FirstUserId, CopyStr(CompanyName(), 1, 30), 23);
        if not EffectivePerm."Can Read" or (EffectivePerm."Security Filter" <> 'FIRST FILTER') then
            Error('Successive build changed the original run.');
    end;

    local procedure ComparePhase1ConflictEvidence(RunId: Guid)
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        BaselineResults: List of [Text];
        BaselineLines: List of [Text];
        ActualResults: List of [Text];
        ActualLines: List of [Text];
    begin
        EffectivePerm.SetRange("Run ID", RunId);
        EffectivePerm.SetRange("Is Special Permission", false);
        EffectivePerm.DeleteAll();
        BuildPhase1Baseline(RunId);
        SnapshotMgt.CalculateConflicts(RunId);
        CaptureConflictSignatures(RunId, BaselineResults, BaselineLines);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        SnapshotMgt.CalculateConflicts(RunId);
        CaptureConflictSignatures(RunId, ActualResults, ActualLines);
        AssertSignatureSetsEqual(BaselineResults, ActualResults);
        AssertSignatureSetsEqual(BaselineLines, ActualLines);
    end;

    local procedure CaptureConflictSignatures(RunId: Guid; var Results: List of [Text]; var Lines: List of [Text])
    var
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
        SourceRef: RecordRef;
    begin
        Clear(Results);
        Clear(Lines);
        Result.SetRange("Run ID", RunId);
        if Result.FindSet() then
            repeat
                SourceRef.GetTable(Result);
                Results.Add(BusinessRecordSignature(SourceRef));
            until Result.Next() = 0;
        Line.SetRange("Run ID", RunId);
        if Line.FindSet() then
            repeat
                SourceRef.GetTable(Line);
                Lines.Add(BusinessRecordSignature(SourceRef));
            until Line.Next() = 0;
    end;

    local procedure BusinessRecordSignature(SourceRef: RecordRef): Text
    var
        SourceField: FieldRef;
        Fields: JsonObject;
        Signature: Text;
        FieldIndex: Integer;
    begin
        for FieldIndex := 1 to SourceRef.FieldCount() do begin
            SourceField := SourceRef.FieldIndex(FieldIndex);
            if (SourceField.Number < 2000000000) and (SourceField.Class = FieldClass::Normal) and
               (SourceField.Name <> 'Entry No.') and (SourceField.Name <> 'Conflict Result Entry No.') and
               (SourceField.Name <> 'Run No.') and (SourceField.Name <> 'Detected At') then
                Fields.Add(Format(SourceField.Number), Format(SourceField.Value));
        end;
        Fields.WriteTo(Signature);
        exit(Signature);
    end;

    local procedure AssertSignatureSetsEqual(Expected: List of [Text]; Actual: List of [Text])
    var
        Signature: Text;
    begin
        if Expected.Count() <> Actual.Count() then
            Error('Phase 2 changed conflict/evidence row count.');
        foreach Signature in Expected do
            if not Actual.Remove(Signature) then
                Error('Phase 2 changed conflict identity or evidence/source attribution.');
    end;

    local procedure RebuildAndComparePhase1(RunId: Guid)
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        TempExpected: Record "BCG User Table Data Perm." temporary;
        ExpectedCount: Integer;
    begin
        EffectivePerm.SetRange("Run ID", RunId);
        EffectivePerm.SetRange("Is Special Permission", false);
        EffectivePerm.DeleteAll();
        BuildPhase1Baseline(RunId);
        EffectivePerm.SetRange("Is Special Permission");
        if EffectivePerm.FindSet() then
            repeat
                TempExpected := EffectivePerm;
                TempExpected.Insert(false, true);
            until EffectivePerm.Next() = 0;
        ExpectedCount := TempExpected.Count();

        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
        if EffectivePerm.Count() <> ExpectedCount then
            Error('Phase 2 changed the number of effective rows.');
        if TempExpected.FindSet() then
            repeat
                EffectivePerm.Get(RunId, TempExpected."User Security ID", TempExpected."Company Name", TempExpected."Object ID");
                AssertEffectiveFieldsEqual(TempExpected, EffectivePerm);
                if not EffectivePerm."Is Special Permission" then
                    if EffectivePerm."Effective Source Count" <> SnapshotMgt.CountEffectivePermissionSources(EffectivePerm) then
                        Error('Cached ordinary count differs from the public reference implementation.');
            until TempExpected.Next() = 0;
    end;

    // Phase 1 source-count baseline, aligned to F01 union and F04 recognized grant tokens.
    local procedure BuildPhase1Baseline(RunId: Guid)
    var
        Assignment: Record "BCG User Perm. Assignment";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        EffectivePerm: Record "BCG User Table Data Perm.";
        TempEffectivePerm: Record "BCG User Table Data Perm." temporary;
        TargetCompanies: List of [Text];
        TargetCompany: Text;
    begin
        // Rebuilds retain special rows, including every extension field.
        EffectivePerm.SetRange("Run ID", RunId);
        EffectivePerm.SetRange("Is Special Permission", true);
        if EffectivePerm.FindSet() then
            repeat
                TempEffectivePerm := EffectivePerm;
                TempEffectivePerm.Insert();
            until EffectivePerm.Next() = 0;

        Assignment.SetRange("Run ID", RunId);
        if Assignment.FindSet() then
            repeat
                ObjectPerm.SetRange("Run ID", RunId);
                ObjectPerm.SetRange("Role ID", Assignment."Role ID");
                ObjectPerm.SetRange("App ID", Assignment."App ID");
                ObjectPerm.SetRange("Scope Text", Assignment."Scope Text");
                ObjectPerm.SetRange("Object Type", 'Table Data');
                TargetCompanies := SnapshotMgt.GetPermissionTargetCompanies(RunId, Assignment."User Security ID", Assignment."Company Name");
                if ObjectPerm.FindSet() then
                    repeat
                        foreach TargetCompany in TargetCompanies do
                            UpsertPhase1Baseline(TempEffectivePerm, RunId, Assignment, ObjectPerm, CopyStr(TargetCompany, 1, 30));
                    until ObjectPerm.Next() = 0;
                ObjectPerm.Reset();
            until Assignment.Next() = 0;

        PersistPhase1Baseline(TempEffectivePerm);
    end;

    local procedure PersistPhase1Baseline(var TempEffectivePerm: Record "BCG User Table Data Perm." temporary)
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        TempWildcard: Record "BCG User Table Data Perm." temporary;
    begin
        TempWildcard.Copy(TempEffectivePerm, true);
        TempEffectivePerm.Reset();
        if TempEffectivePerm.FindSet() then
            repeat
                if TempEffectivePerm."Object ID" <> 0 then
                    if TempWildcard.Get(TempEffectivePerm."Run ID", TempEffectivePerm."User Security ID", TempEffectivePerm."Company Name", 0) then begin
                        TempEffectivePerm."Can Read" := TempEffectivePerm."Can Read" or TempWildcard."Can Read";
                        TempEffectivePerm."Can Insert" := TempEffectivePerm."Can Insert" or TempWildcard."Can Insert";
                        TempEffectivePerm."Can Modify" := TempEffectivePerm."Can Modify" or TempWildcard."Can Modify";
                        TempEffectivePerm."Can Delete" := TempEffectivePerm."Can Delete" or TempWildcard."Can Delete";
                    end;
                TempEffectivePerm."Effective Source Count" := SnapshotMgt.CountEffectivePermissionSources(TempEffectivePerm);
                if TempEffectivePerm."Is Special Permission" then begin
                    EffectivePerm.Get(TempEffectivePerm."Run ID", TempEffectivePerm."User Security ID",
                        TempEffectivePerm."Company Name", TempEffectivePerm."Object ID");
                    // Only these fields can change while merging into a retained row.
                    if (EffectivePerm."Can Read" <> TempEffectivePerm."Can Read") or
                       (EffectivePerm."Can Insert" <> TempEffectivePerm."Can Insert") or
                       (EffectivePerm."Can Modify" <> TempEffectivePerm."Can Modify") or
                       (EffectivePerm."Can Delete" <> TempEffectivePerm."Can Delete") or
                       (EffectivePerm."Security Filter" <> TempEffectivePerm."Security Filter") or
                       (EffectivePerm."Effective Source Count" <> TempEffectivePerm."Effective Source Count")
                    then begin
                        EffectivePerm."Can Read" := TempEffectivePerm."Can Read";
                        EffectivePerm."Can Insert" := TempEffectivePerm."Can Insert";
                        EffectivePerm."Can Modify" := TempEffectivePerm."Can Modify";
                        EffectivePerm."Can Delete" := TempEffectivePerm."Can Delete";
                        EffectivePerm."Security Filter" := TempEffectivePerm."Security Filter";
                        EffectivePerm."Effective Source Count" := TempEffectivePerm."Effective Source Count";
                        EffectivePerm.Modify(true);
                    end;
                end else begin
                    EffectivePerm := TempEffectivePerm;
                    EffectivePerm.Insert(true);
                end;
            until TempEffectivePerm.Next() = 0;
    end;

    local procedure UpsertPhase1Baseline(var EffectivePerm: Record "BCG User Table Data Perm." temporary; RunId: Guid; Assignment: Record "BCG User Perm. Assignment"; ObjectPerm: Record "BCG Perm. Set Object Perm."; TargetCompany: Text[30])
    var
        Exists: Boolean;
    begin
        Exists := EffectivePerm.Get(RunId, Assignment."User Security ID", TargetCompany, ObjectPerm."Object ID");
        if not Exists then begin
            EffectivePerm.Init();
            EffectivePerm."Run ID" := RunId;
            EffectivePerm."User Security ID" := Assignment."User Security ID";
            EffectivePerm."Company Name" := TargetCompany;
            EffectivePerm."Object ID" := ObjectPerm."Object ID";
            EffectivePerm."Object Name" := ObjectPerm."Object Name";
            EffectivePerm."Effective Source Count" := 0;
        end;

        EffectivePerm."Can Read" := EffectivePerm."Can Read" or Phase1PermissionGranted(ObjectPerm."Read Permission");
        EffectivePerm."Can Insert" := EffectivePerm."Can Insert" or Phase1PermissionGranted(ObjectPerm."Insert Permission");
        EffectivePerm."Can Modify" := EffectivePerm."Can Modify" or Phase1PermissionGranted(ObjectPerm."Modify Permission");
        EffectivePerm."Can Delete" := EffectivePerm."Can Delete" or Phase1PermissionGranted(ObjectPerm."Delete Permission");

        if EffectivePerm."Security Filter" = '' then
            EffectivePerm."Security Filter" := ObjectPerm."Security Filter";

        if Exists then
            EffectivePerm.Modify()
        else
            EffectivePerm.Insert();
    end;

    local procedure Phase1PermissionGranted(PermissionText: Text): Boolean
    begin
        exit(UpperCase(DelChr(PermissionText, '=', ' ')) in ['YES', 'DIRECT', 'INDIRECT']);
    end;

    [Test]
    procedure DisabledRecalculatePreservesReadableRunNumberTwice()
    var
        AuditRun: Record "BCG Audit Run";
        EffectivePerm: Record "BCG User Table Data Perm.";
        ConflictHeader: Record "BCG Conflict Header";
        ConflictGroup: Record "BCG Conflict Group";
        GroupRule: Record "BCG Conflict Group Rule";
        ConflictResult: Record "BCG User Conflict Result";
        ConflictLine: Record "BCG User Conflict Result Line";
        RunNoMgt: Codeunit "BCG Run No. Mgt.";
        PermissionsPage: TestPage "BCG User Table Data Perms";
        ReadableRunNo: Code[20];
        ConflictId: Code[20];
        TargetCompany: Text[30];
        PassNo: Integer;
    begin
        InitializeFixture();
        ReadableRunNo := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        AuditRun.Get(TestRunId);
        AuditRun."Run No." := ReadableRunNo;
        AuditRun.Modify();
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        AddCompanyAssignment('TEST NUMBER', TargetCompany);
        AddVendorPermission('TEST NUMBER');

        ConflictId := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        ConflictHeader."Conflict ID" := ConflictId;
        ConflictHeader."Is Active" := true;
        ConflictHeader.Insert();
        ConflictGroup."Conflict ID" := ConflictId;
        ConflictGroup."Group No." := 1;
        ConflictGroup."Is Active" := true;
        ConflictGroup.Insert();
        GroupRule."Conflict ID" := ConflictId;
        GroupRule."Group No." := 1;
        GroupRule."Line No." := 1;
        GroupRule."Rule ID" := 'TEST NUMBER MODIFY';
        GroupRule."Object ID" := 23;
        GroupRule."Requires Modify" := true;
        GroupRule."Modify Permission Match" := GroupRule."Modify Permission Match"::"Direct or Indirect";
        GroupRule.Insert();

        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(TestRunId);
        SnapshotMgt.CalculateConflicts(TestRunId);
        RunNoMgt.EnsureRunNoAndPropagate(TestRunId);
        AuditRun.Get(TestRunId);
        AuditRun.Status := AuditRun.Status::Finished;
        AuditRun.Modify();
        PermissionsPage.OpenView();
        PermissionsPage.Filter.SetFilter("Run No.", ReadableRunNo);
        for PassNo := 1 to 2 do begin
            EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
            PermissionsPage.GoToRecord(EffectivePerm);
            if PermissionsPage."Recalculate Conflicts".Enabled() or PermissionsPage."Recalculate Conflicts".Visible() then
                Error('Historical recalculation must be disabled and hidden.');
            ClearLastError();
            if TryRecalculateCompletedRun() then
                Error('Completed-run recalculation must be rejected.');
            if StrPos(GetLastErrorText(), 'Historical analysis maintenance is unsupported') = 0 then
                Error('Expected the completed-run maintenance guard.');

            AuditRun.Get(TestRunId);
            if (AuditRun.Status <> AuditRun.Status::Finished) or (AuditRun."Run No." <> ReadableRunNo) then
                Error('Recalculation changed the completed audit run or its number.');
            EffectivePerm.Get(TestRunId, TestUserId, TargetCompany, 23);
            if EffectivePerm."Is Special Permission" or (EffectivePerm."Run No." <> ReadableRunNo) or
               (EffectivePerm."Effective Source Count" <> 1) or not EffectivePerm."Can Modify" then
                Error('Recalculation lost the ordinary permission number or changed its grants/count.');
            EffectivePerm.SetRange("Run ID", TestRunId);
            EffectivePerm.SetFilter("Run No.", '<>%1', ReadableRunNo);
            if not EffectivePerm.IsEmpty() then
                Error('Rebuilt permissions have inconsistent run numbers.');
            EffectivePerm.Reset();

            ConflictResult.Reset();
            ConflictResult.SetRange("Run ID", TestRunId);
            ConflictResult.SetRange("Conflict Code", ConflictId);
            if ConflictResult.Count() <> 1 then
                Error('Expected one rebuilt fixture conflict.');
            ConflictResult.SetRange("Conflict Code");
            ConflictResult.SetFilter("Run No.", '<>%1', ReadableRunNo);
            if not ConflictResult.IsEmpty() then
                Error('Rebuilt conflict headers lost their run number.');
            ConflictLine.Reset();
            ConflictLine.SetRange("Run ID", TestRunId);
            ConflictLine.SetRange("Conflict Code", ConflictId);
            if ConflictLine.Count() <> 1 then
                Error('Expected one rebuilt fixture evidence line.');
            ConflictLine.SetRange("Conflict Code");
            ConflictLine.SetFilter("Run No.", '<>%1', ReadableRunNo);
            if not ConflictLine.IsEmpty() then
                Error('Rebuilt conflict lines lost their run number.');
            if not PermissionsPage.First() then
                Error('The readable run filter no longer shows the rebuilt permission.');
            PermissionsPage."Run No.".AssertEquals(ReadableRunNo);
        end;
        PermissionsPage.Close();
    end;

    [Test]
    procedure GroupDeletionRejectsChildrenWithoutCascade()
    var
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        EmptyGroup: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
    begin
        CreateGroupDeletionFixture(Header, Group, Rule);
        EmptyGroup := Group;
        EmptyGroup."Group No." := 2;
        EmptyGroup.Insert(true);
        EmptyGroup.Delete(true); // Children of another group must not block deletion.

        ClearLastError();
        if TryDeleteConflictGroup(Group) then
            Error('Deleting a group with child rules must fail.');
        if StrPos(GetLastErrorText(), 'Delete its group rules first') = 0 then
            Error('Expected the child-rule deletion guard.');
        Group.Get(Header."Conflict ID", 1);
        Rule.Get(Header."Conflict ID", 1, 1);
        Rule.Delete(true);
        Group.Delete(true);
        if Group.Get(Header."Conflict ID", 1) then
            Error('An empty group must remain deletable.');
    end;

    [Test]
    procedure HeaderDeletionStillDeletesChildrenFirst()
    var
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
    begin
        CreateGroupDeletionFixture(Header, Group, Rule);
        Header.Delete(true);
        if Group.Get(Header."Conflict ID", 1) or Rule.Get(Header."Conflict ID", 1, 1) then
            Error('Header deletion must still remove its groups and rules.');
    end;

    local procedure CreateGroupDeletionFixture(var Header: Record "BCG Conflict Header"; var Group: Record "BCG Conflict Group"; var Rule: Record "BCG Conflict Group Rule")
    begin
        Header."Conflict ID" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        Header.Insert(true);
        Group."Conflict ID" := Header."Conflict ID";
        Group."Group No." := 1;
        Group.Insert(true);
        Rule."Conflict ID" := Header."Conflict ID";
        Rule."Group No." := 1;
        Rule."Line No." := 1;
        Rule.Insert(true);
    end;

    [TryFunction]
    local procedure TryDeleteConflictGroup(var Group: Record "BCG Conflict Group")
    begin
        Group.Delete(true);
    end;

    [Test]
    procedure WizardAnyThenAllKeepsSelectedModes()
    begin
        CheckWizardModeOrder(false);
    end;

    [Test]
    procedure WizardAllThenAnyKeepsSelectedModes()
    begin
        CheckWizardModeOrder(true);
    end;

    local procedure CheckWizardModeOrder(AllFirst: Boolean)
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
        FirstRule: Record "BCG Rule Dictionary";
        GroupRule: Record "BCG Conflict Group Rule";
        WizardMgt: Codeunit "BCG Wizard Mgt";
        SecondRuleId: Code[30];
    begin
        InitializeWizardFixture(TempWizard);
        if AllFirst then
            TempWizard."Group 1 Permission Match Mode" := TempWizard."Group 1 Permission Match Mode"::All;
        WizardMgt.CreateSimpleConflict(TempWizard, false);
        GroupRule.Get(TempWizard."Conflict ID", 10000, 10000);
        GroupRule.TestField("Permission Match Mode", TempWizard."Group 1 Permission Match Mode");
        FirstRule.Get(GroupRule."Rule ID");

        TempWizard."Conflict ID" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        if AllFirst then
            TempWizard."Group 1 Permission Match Mode" := TempWizard."Group 1 Permission Match Mode"::Any
        else
            TempWizard."Group 1 Permission Match Mode" := TempWizard."Group 1 Permission Match Mode"::All;
        WizardMgt.CreateSimpleConflict(TempWizard, false);
        GroupRule.Get(TempWizard."Conflict ID", 10000, 10000);
        GroupRule.TestField("Permission Match Mode", TempWizard."Group 1 Permission Match Mode");
        SecondRuleId := GroupRule."Rule ID";
        if SecondRuleId = FirstRule."Rule ID" then
            Error('Any and All must use different dictionary identities.');
        FirstRule.Get(FirstRule."Rule ID");
        if FirstRule."Permission Match Mode" = GroupRule."Permission Match Mode" then
            Error('Creating a second mode changed the first dictionary rule.');

        TempWizard."Conflict ID" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        WizardMgt.CreateSimpleConflict(TempWizard, false);
        GroupRule.Get(TempWizard."Conflict ID", 10000, 10000);
        GroupRule.TestField("Rule ID", SecondRuleId);
    end;

    [Test]
    procedure WizardRejectsIncompatibleExistingRules()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
        Rule: Record "BCG Rule Dictionary";
        OriginalRule: Record "BCG Rule Dictionary";
        GroupRule: Record "BCG Conflict Group Rule";
        WizardMgt: Codeunit "BCG Wizard Mgt";
        ChangeNo: Integer;
    begin
        InitializeWizardFixture(TempWizard);
        WizardMgt.CreateSimpleConflict(TempWizard, false);
        GroupRule.Get(TempWizard."Conflict ID", 10000, 10000);
        OriginalRule.Get(GroupRule."Rule ID");
        for ChangeNo := 1 to 6 do begin
            Rule := OriginalRule;
            case ChangeNo of
                1: Rule."Object ID" += 1;
                2: Rule."Requires Delete" := true;
                3: Rule."Read Permission Match" := Rule."Read Permission Match"::"Direct Only";
                4: Rule."Permission Match Mode" := Rule."Permission Match Mode"::All;
                5: Rule."Is Active" := false;
                6: Rule."Object Type" := Rule."Object Type"::Page;
            end;
            Rule.Modify();
            TempWizard."Conflict ID" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
            // Try catches without undoing the fixtures; the test runner rolls back all test writes.
            if TryCreateWizardConflict(TempWizard) then
                Error('Wizard reused an incompatible rule (case %1).', ChangeNo);
            Rule.Get(OriginalRule."Rule ID");
            case ChangeNo of
                1: Rule.TestField("Object ID", OriginalRule."Object ID" + 1);
                2: Rule.TestField("Requires Delete", true);
                3: Rule.TestField("Read Permission Match", Rule."Read Permission Match"::"Direct Only");
                4: Rule.TestField("Permission Match Mode", Rule."Permission Match Mode"::All);
                5: Rule.TestField("Is Active", false);
                6: Rule.TestField("Object Type", Rule."Object Type"::Page);
            end;
        end;
    end;

    [Test]
    procedure WizardLeavesLegacyIdentityUnchanged()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
        Rule: Record "BCG Rule Dictionary";
        GroupRule: Record "BCG Conflict Group Rule";
        WizardMgt: Codeunit "BCG Wizard Mgt";
        LegacyId: Code[30];
    begin
        InitializeWizardFixture(TempWizard);
        LegacyId := CopyStr('TD' + Format(TempWizard."Group 1 Table Data ID") + '-RM-DIDI', 1, 30);
        Rule."Rule ID" := LegacyId;
        Rule."Object ID" := TempWizard."Group 1 Table Data ID";
        Rule."Requires Read" := true;
        Rule."Requires Modify" := true;
        Rule."Read Permission Match" := Rule."Read Permission Match"::"Direct or Indirect";
        Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct or Indirect";
        Rule."Is Active" := true;
        Rule.Notes := 'Existing definition';
        Rule.Insert();
        TempWizard."Group 1 Permission Match Mode" := TempWizard."Group 1 Permission Match Mode"::All;
        WizardMgt.CreateSimpleConflict(TempWizard, false);
        GroupRule.Get(TempWizard."Conflict ID", 10000, 10000);
        GroupRule.TestField("Permission Match Mode", GroupRule."Permission Match Mode"::All);
        if GroupRule."Rule ID" = LegacyId then
            Error('New wizard rule must not reuse the legacy identity.');
        Rule.Get(LegacyId);
        Rule.TestField("Permission Match Mode", Rule."Permission Match Mode"::Any);
        Rule.TestField(Notes, 'Existing definition');
    end;

    [Test]
    procedure WizardG1ReadSynchronizes()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
    begin
        TempWizard.Init();
        TempWizard.TestField("Group 1 Requires Read", false);
        TempWizard.TestField("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Not Required");
        TempWizard.Validate("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Direct Only");
        TempWizard.TestField("Group 1 Requires Read", true);
        TempWizard.Validate("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Not Required");
        TempWizard.TestField("Group 1 Requires Read", false);
        TempWizard.Validate("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Direct or Indirect");
        TempWizard.TestField("Group 1 Requires Read", true);
        TempWizard.Validate("Group 1 Requires Read", false);
        TempWizard.TestField("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Not Required");
        TempWizard.Validate("Group 1 Requires Read", true);
        TempWizard.TestField("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Direct or Indirect");
        TempWizard.Validate("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Direct Only");
        TempWizard.Validate("Group 1 Requires Read", true);
        TempWizard.TestField("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Direct Only");
        TempWizard.Validate("Group 1 Requires Read", false);
        TempWizard.TestField("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Not Required");
    end;

    [Test]
    procedure WizardG1InsertSynchronizes()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
    begin
        TempWizard.Init();
        TempWizard.TestField("Group 1 Requires Insert", false);
        TempWizard.TestField("G1 Insert Perm Match", TempWizard."G1 Insert Perm Match"::"Not Required");
        TempWizard.Validate("G1 Insert Perm Match", TempWizard."G1 Insert Perm Match"::"Direct Only");
        TempWizard.TestField("Group 1 Requires Insert", true);
        TempWizard.Validate("G1 Insert Perm Match", TempWizard."G1 Insert Perm Match"::"Not Required");
        TempWizard.TestField("Group 1 Requires Insert", false);
        TempWizard.Validate("G1 Insert Perm Match", TempWizard."G1 Insert Perm Match"::"Direct or Indirect");
        TempWizard.TestField("Group 1 Requires Insert", true);
        TempWizard.Validate("Group 1 Requires Insert", false);
        TempWizard.TestField("G1 Insert Perm Match", TempWizard."G1 Insert Perm Match"::"Not Required");
        TempWizard.Validate("Group 1 Requires Insert", true);
        TempWizard.TestField("G1 Insert Perm Match", TempWizard."G1 Insert Perm Match"::"Direct or Indirect");
        TempWizard.Validate("G1 Insert Perm Match", TempWizard."G1 Insert Perm Match"::"Direct Only");
        TempWizard.Validate("Group 1 Requires Insert", true);
        TempWizard.TestField("G1 Insert Perm Match", TempWizard."G1 Insert Perm Match"::"Direct Only");
        TempWizard.Validate("Group 1 Requires Insert", false);
        TempWizard.TestField("G1 Insert Perm Match", TempWizard."G1 Insert Perm Match"::"Not Required");
    end;

    [Test]
    procedure WizardG1ModifySynchronizes()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
    begin
        TempWizard.Init();
        TempWizard.TestField("Group 1 Requires Modify", false);
        TempWizard.TestField("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Not Required");
        TempWizard.Validate("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Direct Only");
        TempWizard.TestField("Group 1 Requires Modify", true);
        TempWizard.Validate("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Not Required");
        TempWizard.TestField("Group 1 Requires Modify", false);
        TempWizard.Validate("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Direct or Indirect");
        TempWizard.TestField("Group 1 Requires Modify", true);
        TempWizard.Validate("Group 1 Requires Modify", false);
        TempWizard.TestField("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Not Required");
        TempWizard.Validate("Group 1 Requires Modify", true);
        TempWizard.TestField("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Direct or Indirect");
        TempWizard.Validate("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Direct Only");
        TempWizard.Validate("Group 1 Requires Modify", true);
        TempWizard.TestField("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Direct Only");
        TempWizard.Validate("Group 1 Requires Modify", false);
        TempWizard.TestField("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Not Required");
    end;

    [Test]
    procedure WizardG1DeleteSynchronizes()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
    begin
        TempWizard.Init();
        TempWizard.TestField("Group 1 Requires Delete", false);
        TempWizard.TestField("G1 Delete Perm Match", TempWizard."G1 Delete Perm Match"::"Not Required");
        TempWizard.Validate("G1 Delete Perm Match", TempWizard."G1 Delete Perm Match"::"Direct Only");
        TempWizard.TestField("Group 1 Requires Delete", true);
        TempWizard.Validate("G1 Delete Perm Match", TempWizard."G1 Delete Perm Match"::"Not Required");
        TempWizard.TestField("Group 1 Requires Delete", false);
        TempWizard.Validate("G1 Delete Perm Match", TempWizard."G1 Delete Perm Match"::"Direct or Indirect");
        TempWizard.TestField("Group 1 Requires Delete", true);
        TempWizard.Validate("Group 1 Requires Delete", false);
        TempWizard.TestField("G1 Delete Perm Match", TempWizard."G1 Delete Perm Match"::"Not Required");
        TempWizard.Validate("Group 1 Requires Delete", true);
        TempWizard.TestField("G1 Delete Perm Match", TempWizard."G1 Delete Perm Match"::"Direct or Indirect");
        TempWizard.Validate("G1 Delete Perm Match", TempWizard."G1 Delete Perm Match"::"Direct Only");
        TempWizard.Validate("Group 1 Requires Delete", true);
        TempWizard.TestField("G1 Delete Perm Match", TempWizard."G1 Delete Perm Match"::"Direct Only");
        TempWizard.Validate("Group 1 Requires Delete", false);
        TempWizard.TestField("G1 Delete Perm Match", TempWizard."G1 Delete Perm Match"::"Not Required");
    end;

    [Test]
    procedure WizardG2ReadSynchronizes()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
    begin
        TempWizard.Init();
        TempWizard.TestField("Group 2 Requires Read", false);
        TempWizard.TestField("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Not Required");
        TempWizard.Validate("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Direct Only");
        TempWizard.TestField("Group 2 Requires Read", true);
        TempWizard.Validate("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Not Required");
        TempWizard.TestField("Group 2 Requires Read", false);
        TempWizard.Validate("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Direct or Indirect");
        TempWizard.TestField("Group 2 Requires Read", true);
        TempWizard.Validate("Group 2 Requires Read", false);
        TempWizard.TestField("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Not Required");
        TempWizard.Validate("Group 2 Requires Read", true);
        TempWizard.TestField("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Direct or Indirect");
        TempWizard.Validate("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Direct Only");
        TempWizard.Validate("Group 2 Requires Read", true);
        TempWizard.TestField("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Direct Only");
        TempWizard.Validate("Group 2 Requires Read", false);
        TempWizard.TestField("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Not Required");
    end;

    [Test]
    procedure WizardG2InsertSynchronizes()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
    begin
        TempWizard.Init();
        TempWizard.TestField("Group 2 Requires Insert", false);
        TempWizard.TestField("G2 Insert Perm Match", TempWizard."G2 Insert Perm Match"::"Not Required");
        TempWizard.Validate("G2 Insert Perm Match", TempWizard."G2 Insert Perm Match"::"Direct Only");
        TempWizard.TestField("Group 2 Requires Insert", true);
        TempWizard.Validate("G2 Insert Perm Match", TempWizard."G2 Insert Perm Match"::"Not Required");
        TempWizard.TestField("Group 2 Requires Insert", false);
        TempWizard.Validate("G2 Insert Perm Match", TempWizard."G2 Insert Perm Match"::"Direct or Indirect");
        TempWizard.TestField("Group 2 Requires Insert", true);
        TempWizard.Validate("Group 2 Requires Insert", false);
        TempWizard.TestField("G2 Insert Perm Match", TempWizard."G2 Insert Perm Match"::"Not Required");
        TempWizard.Validate("Group 2 Requires Insert", true);
        TempWizard.TestField("G2 Insert Perm Match", TempWizard."G2 Insert Perm Match"::"Direct or Indirect");
        TempWizard.Validate("G2 Insert Perm Match", TempWizard."G2 Insert Perm Match"::"Direct Only");
        TempWizard.Validate("Group 2 Requires Insert", true);
        TempWizard.TestField("G2 Insert Perm Match", TempWizard."G2 Insert Perm Match"::"Direct Only");
        TempWizard.Validate("Group 2 Requires Insert", false);
        TempWizard.TestField("G2 Insert Perm Match", TempWizard."G2 Insert Perm Match"::"Not Required");
    end;

    [Test]
    procedure WizardG2ModifySynchronizes()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
    begin
        TempWizard.Init();
        TempWizard.TestField("Group 2 Requires Modify", false);
        TempWizard.TestField("G2 Modify Perm Match", TempWizard."G2 Modify Perm Match"::"Not Required");
        TempWizard.Validate("G2 Modify Perm Match", TempWizard."G2 Modify Perm Match"::"Direct Only");
        TempWizard.TestField("Group 2 Requires Modify", true);
        TempWizard.Validate("G2 Modify Perm Match", TempWizard."G2 Modify Perm Match"::"Not Required");
        TempWizard.TestField("Group 2 Requires Modify", false);
        TempWizard.Validate("G2 Modify Perm Match", TempWizard."G2 Modify Perm Match"::"Direct or Indirect");
        TempWizard.TestField("Group 2 Requires Modify", true);
        TempWizard.Validate("Group 2 Requires Modify", false);
        TempWizard.TestField("G2 Modify Perm Match", TempWizard."G2 Modify Perm Match"::"Not Required");
        TempWizard.Validate("Group 2 Requires Modify", true);
        TempWizard.TestField("G2 Modify Perm Match", TempWizard."G2 Modify Perm Match"::"Direct or Indirect");
        TempWizard.Validate("G2 Modify Perm Match", TempWizard."G2 Modify Perm Match"::"Direct Only");
        TempWizard.Validate("Group 2 Requires Modify", true);
        TempWizard.TestField("G2 Modify Perm Match", TempWizard."G2 Modify Perm Match"::"Direct Only");
        TempWizard.Validate("Group 2 Requires Modify", false);
        TempWizard.TestField("G2 Modify Perm Match", TempWizard."G2 Modify Perm Match"::"Not Required");
    end;

    [Test]
    procedure WizardG2DeleteSynchronizes()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
    begin
        TempWizard.Init();
        TempWizard.TestField("Group 2 Requires Delete", false);
        TempWizard.TestField("G2 Delete Perm Match", TempWizard."G2 Delete Perm Match"::"Not Required");
        TempWizard.Validate("G2 Delete Perm Match", TempWizard."G2 Delete Perm Match"::"Direct Only");
        TempWizard.TestField("Group 2 Requires Delete", true);
        TempWizard.Validate("G2 Delete Perm Match", TempWizard."G2 Delete Perm Match"::"Not Required");
        TempWizard.TestField("Group 2 Requires Delete", false);
        TempWizard.Validate("G2 Delete Perm Match", TempWizard."G2 Delete Perm Match"::"Direct or Indirect");
        TempWizard.TestField("Group 2 Requires Delete", true);
        TempWizard.Validate("Group 2 Requires Delete", false);
        TempWizard.TestField("G2 Delete Perm Match", TempWizard."G2 Delete Perm Match"::"Not Required");
        TempWizard.Validate("Group 2 Requires Delete", true);
        TempWizard.TestField("G2 Delete Perm Match", TempWizard."G2 Delete Perm Match"::"Direct or Indirect");
        TempWizard.Validate("G2 Delete Perm Match", TempWizard."G2 Delete Perm Match"::"Direct Only");
        TempWizard.Validate("Group 2 Requires Delete", true);
        TempWizard.TestField("G2 Delete Perm Match", TempWizard."G2 Delete Perm Match"::"Direct Only");
        TempWizard.Validate("Group 2 Requires Delete", false);
        TempWizard.TestField("G2 Delete Perm Match", TempWizard."G2 Delete Perm Match"::"Not Required");
    end;

    [Test]
    [HandlerFunctions('IgnoreCompletionMessage')]
    procedure WizardAnyReviewMatchesSavedRules()
    begin
        CheckWizardReviewAndSavedRules(false, false);
    end;

    [Test]
    [HandlerFunctions('IgnoreCompletionMessage')]
    procedure WizardAllReviewMatchesSavedRules()
    begin
        CheckWizardReviewAndSavedRules(true, false);
    end;

    [Test]
    [HandlerFunctions('IgnoreCompletionMessage')]
    procedure WizardMixedReviewMatchesSavedRules()
    begin
        CheckWizardReviewAndSavedRules(true, true);
    end;

    local procedure CheckWizardReviewAndSavedRules(AllMode: Boolean; DirectRead: Boolean)
    var
        AllObj: Record AllObjWithCaption;
        ExistingRule: Record "BCG Rule Dictionary";
        Rule: Record "BCG Rule Dictionary";
        GroupRule: Record "BCG Conflict Group Rule";
        Wizard: TestPage "BCG Simple Wizard";
        ConflictId: Code[20];
        ExpectedText: Text;
        Separator: Text;
        ModeText: Text;
        GroupNo: Integer;
        ReadMatch: Enum "BCG Table Data Perm Match";
    begin
        // Use a real table for page validation, without reusing installed rule definitions.
        AllObj.SetRange("Object Type", AllObj."Object Type"::TableData);
        AllObj.FindSet();
        repeat
            ExistingRule.SetFilter("Rule ID", 'TD%1-*', Format(AllObj."Object ID"));
            if (AllObj."Object ID" > 0) and ExistingRule.IsEmpty() then
                break;
        until AllObj.Next() = 0;
        if (AllObj."Object ID" = 0) or not ExistingRule.IsEmpty() then
            Error('A table without wizard-generated rules is required for this fixture.');
        ConflictId := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(ConflictId));
        if AllMode then begin
            ModeText := 'All';
            Separator := ' and ';
        end else begin
            ModeText := 'Any';
            Separator := ' or ';
        end;
        ReadMatch := ReadMatch::"Direct or Indirect";
        if DirectRead then
            ReadMatch := ReadMatch::"Direct Only";
        ExpectedText := 'Read: ' + Format(ReadMatch) + Separator +
            'Insert: Direct or Indirect' + Separator +
            'Modify: Direct or Indirect' + Separator + 'Delete: Direct or Indirect';
        if not DirectRead and (StrLen(ExpectedText) <= 100) then
            Error('The fixture must exceed the former review limit.');
        Wizard.OpenView();
        Wizard."Conflict ID".SetValue(ConflictId);
        Wizard."Conflict Name".SetValue('Wizard consistency regression');
        Wizard.Next.Invoke();
        Wizard."Group 1 Name".SetValue('Side 1');
        Wizard."Group 1 Table Data ID".SetValue(AllObj."Object ID");
        Wizard."Group 1 Permission Match Mode".SetValue(ModeText);
        Wizard."G1 Read Perm Match".SetValue(Format(ReadMatch));
        Wizard."Group 1 Requires Read".AssertEquals(true);
        Wizard."G1 Insert Perm Match".SetValue('Direct or Indirect');
        Wizard."Group 1 Requires Insert".AssertEquals(true);
        Wizard."G1 Modify Perm Match".SetValue('Direct or Indirect');
        Wizard."Group 1 Requires Modify".AssertEquals(true);
        Wizard."G1 Delete Perm Match".SetValue('Direct or Indirect');
        Wizard."Group 1 Requires Delete".AssertEquals(true);
        Wizard.Next.Invoke();
        Wizard."Group 2 Name".SetValue('Side 2');
        Wizard."Group 2 Table Data ID".SetValue(AllObj."Object ID");
        Wizard."Group 2 Permission Match Mode".SetValue(ModeText);
        Wizard."G2 Read Perm Match".SetValue(Format(ReadMatch));
        Wizard."Group 2 Requires Read".AssertEquals(true);
        Wizard."G2 Insert Perm Match".SetValue('Direct or Indirect');
        Wizard."Group 2 Requires Insert".AssertEquals(true);
        Wizard."G2 Modify Perm Match".SetValue('Direct or Indirect');
        Wizard."Group 2 Requires Modify".AssertEquals(true);
        Wizard."G2 Delete Perm Match".SetValue('Direct or Indirect');
        Wizard."Group 2 Requires Delete".AssertEquals(true);
        Wizard.Next.Invoke();
        Wizard.ReviewGroup1Permissions.AssertEquals(ExpectedText);
        Wizard.ReviewGroup2Permissions.AssertEquals(ExpectedText);
        Wizard.Back.Invoke();
        Wizard."Group 2 Requires Delete".SetValue(false);
        Wizard."G2 Delete Perm Match".AssertEquals('Not Required');
        Wizard."Group 2 Requires Delete".SetValue(true);
        Wizard."G2 Delete Perm Match".AssertEquals('Direct or Indirect');
        Wizard.Back.Invoke();
        Wizard."G1 Read Perm Match".SetValue('Not Required');
        Wizard."Group 1 Requires Read".AssertEquals(false);
        Wizard."G1 Read Perm Match".SetValue(Format(ReadMatch));
        Wizard."Group 1 Requires Read".AssertEquals(true);
        Wizard.Next.Invoke();
        Wizard.Next.Invoke();
        Wizard.ReviewGroup1Permissions.AssertEquals(ExpectedText);
        Wizard.ReviewGroup2Permissions.AssertEquals(ExpectedText);
        Wizard.Finish.Invoke();
        for GroupNo := 1 to 2 do begin
            GroupRule.Get(ConflictId, GroupNo * 10000, 10000);
            Rule.Get(GroupRule."Rule ID");
            Rule.TestField("Requires Read", true);
            Rule.TestField("Read Permission Match", ReadMatch);
            GroupRule.TestField("Requires Read", true);
            GroupRule.TestField("Read Permission Match", ReadMatch);
            Rule.TestField("Requires Insert", true);
            Rule.TestField("Insert Permission Match", Rule."Insert Permission Match"::"Direct or Indirect");
            GroupRule.TestField("Requires Insert", true);
            GroupRule.TestField("Insert Permission Match", GroupRule."Insert Permission Match"::"Direct or Indirect");
            Rule.TestField("Requires Modify", true);
            Rule.TestField("Modify Permission Match", Rule."Modify Permission Match"::"Direct or Indirect");
            GroupRule.TestField("Requires Modify", true);
            GroupRule.TestField("Modify Permission Match", GroupRule."Modify Permission Match"::"Direct or Indirect");
            Rule.TestField("Requires Delete", true);
            Rule.TestField("Delete Permission Match", Rule."Delete Permission Match"::"Direct or Indirect");
            GroupRule.TestField("Requires Delete", true);
            GroupRule.TestField("Delete Permission Match", GroupRule."Delete Permission Match"::"Direct or Indirect");
            Rule.TestField("Object ID", AllObj."Object ID");
            GroupRule.TestField("Object ID", AllObj."Object ID");
            if AllMode then begin
                Rule.TestField("Permission Match Mode", Rule."Permission Match Mode"::All);
                GroupRule.TestField("Permission Match Mode", GroupRule."Permission Match Mode"::All);
            end else begin
                Rule.TestField("Permission Match Mode", Rule."Permission Match Mode"::Any);
                GroupRule.TestField("Permission Match Mode", GroupRule."Permission Match Mode"::Any);
            end;
        end;
    end;

    [Test]
    procedure WizardRejectsUnselectedGroups()
    var
        TempWizard: Record "BCG Wizard Buffer" temporary;
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        GroupNo: Integer;
        ExpectedErrorLbl: Label 'Select at least one required permission for Group %1.', Locked = true, Comment = '%1 = group number';
    begin
        for GroupNo := 1 to 2 do begin
            Clear(TempWizard);
            InitializeWizardFixture(TempWizard);
            if GroupNo = 1 then begin
                TempWizard.Validate("G1 Read Perm Match", TempWizard."G1 Read Perm Match"::"Not Required");
                TempWizard.Validate("G1 Modify Perm Match", TempWizard."G1 Modify Perm Match"::"Not Required");
            end else
                TempWizard.Validate("G2 Read Perm Match", TempWizard."G2 Read Perm Match"::"Not Required");
            ClearLastError();
            if TryCreateWizardConflict(TempWizard) then
                Error('A group without selected operations must be rejected.');
            if StrPos(GetLastErrorText(), StrSubstNo(ExpectedErrorLbl, GroupNo)) = 0 then
                Error('Expected the unselected-group validation error.');
            if Header.Get(TempWizard."Conflict ID") then
                Error('Rejected wizard input must not create a conflict.');
            Group.SetRange("Conflict ID", TempWizard."Conflict ID");
            if not Group.IsEmpty() then
                Error('Rejected wizard input must not create conflict groups.');
        end;
    end;

    local procedure InitializeWizardFixture(var TempWizard: Record "BCG Wizard Buffer" temporary)
    var
        ExistingRule: Record "BCG Rule Dictionary";
    begin
        TempWizard.Init();
        TempWizard."Conflict ID" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        TempWizard."Conflict Name" := 'Wizard regression';
        TempWizard."Group 1 Name" := 'First';
        TempWizard."Group 2 Name" := 'Second';
        // Synthetic table number keeps generated rule identities separate from installed definitions.
        repeat
            TempWizard."Group 1 Table Data ID" := 2000000000 + Random(1000000);
            ExistingRule.SetFilter("Rule ID", 'TD%1-*', Format(TempWizard."Group 1 Table Data ID"));
        until ExistingRule.IsEmpty();
        TempWizard."Group 2 Table Data ID" := TempWizard."Group 1 Table Data ID";
        TempWizard.Validate("Group 1 Requires Read", true);
        TempWizard.Validate("Group 1 Requires Modify", true);
        TempWizard.Validate("Group 2 Requires Read", true);
    end;

    [TryFunction]
    local procedure TryCreateWizardConflict(var TempWizard: Record "BCG Wizard Buffer" temporary)
    var
        WizardMgt: Codeunit "BCG Wizard Mgt";
    begin
        WizardMgt.CreateSimpleConflict(TempWizard, false);
    end;

    [TryFunction]
    local procedure TryRecalculateCompletedRun()
    begin
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(TestRunId);
    end;

    [Test]
    procedure WizardReviewKeepsMaximumGroupNames()
    var
        Wizard: TestPage "BCG Simple Wizard";
        Group1Name: Text[100];
        Group2Name: Text[100];
        ExpectedText: Text;
    begin
        Group1Name := PadStr('GROUP ONE ', 100, 'A');
        Group2Name := PadStr('GROUP TWO ', 100, 'B');
        ExpectedText := 'A conflict is detected when a user matches both groups: ' + Group1Name + ' and ' + Group2Name + '.';
        if StrLen(ExpectedText) <> 262 then
            Error('The maximum-name fixture must exercise all 262 review characters.');

        Wizard.OpenView();
        Wizard.Next.Invoke();
        Wizard."Group 1 Name".SetValue(Group1Name);
        Wizard.Next.Invoke();
        Wizard."Group 2 Name".SetValue(Group2Name);
        Wizard.Next.Invoke();
        Wizard.ReviewResult.AssertEquals(ExpectedText);
        Wizard.Close();
    end;

    [Test]
    procedure SourceAttributionKeepsExactBoundaryIdentity()
    var
        TempLine: Record "BCG User Conflict Result Line" temporary;
        SourceMgt: Codeunit "BCG Conflict Source Mgt";
        RoleId: Code[20];
        RoleName: Text[80];
    begin
        InitializeFixture();
        RoleId := '12345678901234567890';
        RoleName := PadStr('DISPLAY ', 80, 'N');
        AddGroupAssignment('EXACT GROUP', RoleId, TestAppId, 'System');
        AddGroupAssignment('OTHER APP', RoleId, CreateGuid(), 'System');
        AddGroupAssignment('OTHER SCOPE', RoleId, TestAppId, 'Tenant');
        TempLine."Role ID" := RoleId;
        TempLine."Role Name" := RoleName;
        TempLine."App ID" := TestAppId;
        TempLine."Scope Text" := 'System';
        SourceMgt.ApplySourceToConflictLine(TempLine, TestRunId, TestUserId, '', RoleId, RoleName,
            TestAppId, 'Direct + Security Group', '');
        TempLine.TestField("Role ID", RoleId);
        TempLine.TestField("Source Permission Set ID", RoleId);
        TempLine.TestField("Role Name", RoleName);
        TempLine.TestField("Source Permission Set Name", RoleName);
        TempLine.TestField("App ID", TestAppId);
        TempLine.TestField("Scope Text", 'System');
        TempLine.TestField("Security Group Code", 'EXACT GROUP');
        TempLine.TestField("Is From Security Group", true);
        TempLine.TestField("Permission Source Type", TempLine."Permission Source Type"::Mixed);
    end;

    [Test]
    procedure SourceAttributionRejectsOverlengthIdentity()
    var
        TempLine: Record "BCG User Conflict Result Line" temporary;
        SourceMgt: Codeunit "BCG Conflict Source Mgt";
        RoleId: Code[30];
        LengthToTest: Integer;
    begin
        InitializeFixture();
        AddGroupAssignment('PREFIX GROUP', '12345678901234567890', TestAppId, 'System');
        for LengthToTest := 21 to 30 do begin
            RoleId := CopyStr(PadStr('12345678901234567890', LengthToTest, 'X'), 1, MaxStrLen(RoleId));
            if StrLen(RoleId) <> LengthToTest then
                Error('The overlength fixture identity must be complete.');
            TempLine.Init();
            TempLine."Role ID" := RoleId;
            TempLine."Scope Text" := 'System';
            TempLine."Source Permission Set ID" := 'UNCHANGED';
            TempLine."Source Notes" := 'UNCHANGED';
            asserterror SourceMgt.ApplySourceToConflictLine(TempLine, TestRunId, TestUserId, '', RoleId, '',
                TestAppId, 'Security Group', '');
            AssertSourceIdentityLengthError(RoleId);
            TempLine.TestField("Role ID", RoleId);
            TempLine.TestField("Source Permission Set ID", 'UNCHANGED');
            TempLine.TestField("Source Notes", 'UNCHANGED');
            TempLine.TestField("Security Group Code", '');
            TempLine.TestField("Is From Security Group", false);
            TempLine.TestField("Permission Source Type", TempLine."Permission Source Type"::Unknown);
        end;
    end;

    [Test]
    procedure OrdinaryEvidenceKeepsFullCapturedName()
    begin
        CheckBoundaryEvidence(false, true);
    end;

    [Test]
    procedure SpecialEvidenceKeepsFullCapturedName()
    begin
        CheckBoundaryEvidence(true, false);
    end;

    [Test]
    procedure ExpandedSpecialEvidenceKeepsFullCapturedName()
    begin
        CheckBoundaryEvidence(true, true);
    end;

    local procedure CheckBoundaryEvidence(SpecialSource: Boolean; ExpandedGrant: Boolean)
    var
        Assignment: Record "BCG User Perm. Assignment";
        ConflictHeader: Record "BCG Conflict Header";
        ConflictGroup: Record "BCG Conflict Group";
        GroupRule: Record "BCG Conflict Group Rule";
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
        RoleId: Code[20];
        FullName: Text[100];
        TargetCompany: Text[30];
    begin
        InitializeFixture();
        RoleId := '12345678901234567890';
        if SpecialSource then begin
            RoleId := 'SUPER (DATA)';
            TestAppId := '63ca2fa4-4f03-4f2b-a480-172fef340d3f';
        end;
        FullName := PadStr('CAPTURED DISPLAY ', 100, 'N');
        TargetCompany := CopyStr(CompanyName(), 1, 30);
        AddCompanyAssignment(RoleId, TargetCompany);
        Assignment.Get(TestRunId, TestUserId, TargetCompany, RoleId, TestAppId, 'System');
        Assignment."Role Name" := FullName;
        Assignment.Modify();
        if ExpandedGrant then
            AddVendorPermission(RoleId);

        ConflictHeader."Conflict ID" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        ConflictHeader."Is Active" := true;
        ConflictHeader.Insert();
        ConflictGroup."Conflict ID" := ConflictHeader."Conflict ID";
        ConflictGroup."Group No." := 1;
        ConflictGroup."Is Active" := true;
        ConflictGroup.Insert();
        GroupRule."Conflict ID" := ConflictHeader."Conflict ID";
        GroupRule."Group No." := 1;
        GroupRule."Line No." := 1;
        GroupRule."Rule ID" := 'TEST LENGTH MODIFY';
        GroupRule."Object ID" := 23;
        GroupRule."Requires Modify" := true;
        GroupRule."Modify Permission Match" := GroupRule."Modify Permission Match"::"Direct or Indirect";
        GroupRule.Insert();

        if SpecialSource then
            SpecialMgt.AddSpecialPermissionWildcardsForRun(TestRunId, false);
        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(TestRunId);
        SnapshotMgt.CalculateConflicts(TestRunId);
        Result.SetRange("Run ID", TestRunId);
        Result.SetRange("User Security ID", TestUserId);
        Result.SetRange("Company Name", TargetCompany);
        Result.SetRange("Conflict Code", ConflictHeader."Conflict ID");
        if Result.Count() <> 1 then
            Error('Expected one boundary-fixture finding, got %1.', Result.Count());
        Result.FindFirst();
        Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
        if Line.Count() <> 1 then
            Error('Expected one exact source identity, got %1.', Line.Count());
        Line.FindFirst();
        Line.TestField("Role ID", RoleId);
        Line.TestField("Source Permission Set ID", RoleId);
        Line.TestField("Role Name", FullName);
        Line.TestField("Source Permission Set Name", CopyStr(FullName, 1, 80));
        Line.TestField("App ID", TestAppId);
        Line.TestField("Scope Text", 'System');
        Line.TestField("Source Company Name", TargetCompany);
        Line.TestField("Assignment Source Type", 'Direct');
        Line.TestField("Is Special Permission Source", SpecialSource);
        Assignment.Get(TestRunId, TestUserId, TargetCompany, RoleId, TestAppId, 'System');
        Assignment.TestField("Role Name", FullName);
    end;

    [Test]
    procedure TraceCanonicalSourceKeepsNameBoundaries()
    begin
        CheckTraceSourceBoundary('SUPER (DATA)', 80);
        CheckTraceSourceBoundary('SUPER (DATA)', 81);
        CheckTraceSourceBoundary('SUPER (DATA)', 100);
    end;

    [Test]
    procedure TraceKeepsMaximumSourceIdentity()
    begin
        CheckTraceSourceBoundary('12345678901234567890', 100);
    end;

    local procedure CheckTraceSourceBoundary(RoleId: Code[30]; NameLength: Integer)
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        Trace: Record "BCG Conflict Source Trace";
        SourceMgt: Codeunit "BCG Conflict Source Mgt";
        FullName: Text[100];
    begin
        InitializeFixture();
        FullName := CopyStr(PadStr('CAPTURED DISPLAY ', NameLength, 'N'), 1, MaxStrLen(FullName));
        if StrLen(FullName) <> NameLength then
            Error('The captured-name fixture must be complete.');
        EffectivePerm."Run ID" := TestRunId;
        EffectivePerm."User Security ID" := TestUserId;
        EffectivePerm."Company Name" := CopyStr(CompanyName(), 1, 30);
        EffectivePerm."Is Special Permission" := true;
        EffectivePerm."Applies To All Objects" := true;
        EffectivePerm."Source Permission Set ID" := RoleId;
        EffectivePerm."Source Permission Set Name" := FullName;
        EffectivePerm.Insert();
        SourceMgt.RebuildSourceTraceForRun(TestRunId, false);
        Trace.SetRange("Run ID", TestRunId);
        if Trace.Count() <> 1 then
            Error('Expected one source trace, got %1.', Trace.Count());
        Trace.FindFirst();
        if Trace."Role ID" <> RoleId then
            Error('The complete source identity must be retained.');
        Trace.TestField("Role Name", CopyStr(FullName, 1, 80));
        Trace.TestField("User Security ID", TestUserId);
        Trace.TestField("Permission Source Type", Trace."Permission Source Type"::"Special Permission");
        EffectivePerm.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
        EffectivePerm.TestField("Source Permission Set ID", RoleId);
        EffectivePerm.TestField("Source Permission Set Name", FullName);
    end;

    [Test]
    procedure TraceRejectsOverlengthSourceIdentity()
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        Trace: Record "BCG Conflict Source Trace";
        RoleId: Code[30];
        LengthToTest: Integer;
    begin
        for LengthToTest := 21 to 30 do begin
            InitializeFixture();
            RoleId := CopyStr(PadStr('12345678901234567890', LengthToTest, 'X'), 1, MaxStrLen(RoleId));
            if StrLen(RoleId) <> LengthToTest then
                Error('The overlength fixture identity must be complete.');
            EffectivePerm.Init();
            EffectivePerm."Run ID" := TestRunId;
            EffectivePerm."User Security ID" := TestUserId;
            EffectivePerm."Company Name" := CopyStr(CompanyName(), 1, 30);
            EffectivePerm."Is Special Permission" := true;
            EffectivePerm."Applies To All Objects" := true;
            EffectivePerm."Source Permission Set ID" := RoleId;
            EffectivePerm.Insert();
            // Try catches without undoing the fixture; the test runner rolls back all test writes.
            ClearLastError();
            if TryRebuildSourceTraceForRun(TestRunId) then
                Error('An overlength source identity must be rejected.');
            AssertSourceIdentityLengthError(RoleId);
            Trace.SetRange("Run ID", TestRunId);
            if not Trace.IsEmpty() then
                Error('An overlength identity must not create a prefix trace.');
            EffectivePerm.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
            EffectivePerm.TestField("Source Permission Set ID", RoleId);
        end;
    end;

    [TryFunction]
    local procedure TryRebuildSourceTraceForRun(RunId: Guid)
    var
        SourceMgt: Codeunit "BCG Conflict Source Mgt";
    begin
        SourceMgt.RebuildSourceTraceForRun(RunId, false);
    end;

    local procedure AssertSourceIdentityLengthError(RoleId: Code[30])
    var
        ErrorText: Text;
    begin
        ErrorText := GetLastErrorText();
        if (StrPos(ErrorText, RoleId) = 0) or (StrPos(ErrorText, '20') = 0) then
            Error('Expected the rejected identity and supported length in the error, got: %1', ErrorText);
    end;

    local procedure InitializeFixture()
    var
        AuditRun: Record "BCG Audit Run";
        UserSnapshot: Record "BCG User Snapshot";
    begin
        // Random IDs isolate fixtures from real users and other runs. Test runner must roll back each test.
        TestRunId := CreateGuid();
        TestUserId := CreateGuid();
        TestAppId := CreateGuid();
        AuditRun.Init();
        AuditRun."Run ID" := TestRunId;
        AuditRun."Company Filter" := CopyStr(CompanyName(), 1, MaxStrLen(AuditRun."Company Filter"));
        AuditRun.Status := AuditRun.Status::Running;
        AuditRun.Insert();
        UserSnapshot.Init();
        UserSnapshot."Run ID" := TestRunId;
        UserSnapshot."User Security ID" := TestUserId;
        UserSnapshot.Insert();
    end;

    local procedure AddAssignment(RoleId: Code[30]; AppId: Guid; ScopeText: Text[30])
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        Assignment.Init();
        Assignment."Run ID" := TestRunId;
        Assignment."User Security ID" := TestUserId;
        Assignment."Role ID" := RoleId;
        Assignment."App ID" := AppId;
        Assignment."Scope Text" := ScopeText;
        Assignment."Assignment Source Type" := 'Direct';
        Assignment.Insert();
    end;

    local procedure AddObjectPermission(RoleId: Code[30]; AppId: Guid; ScopeText: Text[30]; ReadPermission: Text[20])
    var
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
    begin
        ObjectPerm.Init();
        ObjectPerm."Run ID" := TestRunId;
        ObjectPerm."Role ID" := RoleId;
        ObjectPerm."App ID" := AppId;
        ObjectPerm."Scope Text" := ScopeText;
        ObjectPerm."Object Type" := 'Table Data';
        ObjectPerm."Object ID" := 0;
        ObjectPerm."Read Permission" := ReadPermission;
        ObjectPerm.Insert();
    end;

    local procedure AddGroupAssignment(GroupCode: Code[20]; RoleId: Code[20]; AppId: Guid; ScopeText: Text[30])
    var
        GroupAssignment: Record "BCG SecGrp Perm Assign";
    begin
        GroupAssignment.Init();
        GroupAssignment."Run ID" := TestRunId;
        GroupAssignment."User Security ID" := TestUserId;
        GroupAssignment."Security Group Code" := GroupCode;
        GroupAssignment."Role ID" := RoleId;
        GroupAssignment."App ID" := AppId;
        GroupAssignment.Scope := ScopeText;
        GroupAssignment.Insert();
    end;

    local procedure AssertCount(Expected: Integer)
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
    begin
        EffectivePerm.Get(TestRunId, TestUserId, CopyStr(CompanyName(), 1, 30), 0);
        if EffectivePerm."Effective Source Count" <> Expected then
            Error('Expected source count %1, got %2.', Expected, EffectivePerm."Effective Source Count");
    end;
}
#endif
