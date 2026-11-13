#if BCG_AFFECTED_USER_TESTS
codeunit 50613 "BCG Affected User Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DistinctUsersCompaniesConflictsAndHighOnly()
    var
        Findings: Record "BCG User Conflict Result" temporary;
        Buffer: Record "BCG Affected User Buffer";
        AffectedUserMgt: Codeunit "BCG Affected User Mgt.";
        RunId: Guid;
        UserA: Guid;
        UserB: Guid;
        FindingSum: Integer;
    begin
        RunId := CreateGuid();
        UserA := CreateGuid();
        UserB := CreateGuid();
        AddFinding(Findings, 1, RunId, UserA, 'Company A', 'C1');
        Findings.Severity := Findings.Severity::High;
        Findings."Has Special Permission Source" := true;
        Findings.Modify();
        AddFinding(Findings, 2, RunId, UserA, 'Company B', 'C1');
        Findings.Severity := Findings.Severity::Critical;
        Findings."Has Security Group Source" := true;
        Findings.Modify();
        AddFinding(Findings, 3, RunId, UserA, 'Company A', 'C2');
        Findings.Severity := Findings.Severity::High;
        Findings."Has Direct Source" := true;
        Findings.Modify();
        AddFinding(Findings, 4, RunId, UserA, 'Company A', 'C1');
        AddFinding(Findings, 5, RunId, UserB, 'Company A', 'C1');

        // Closed-only users and findings in other runs must not create summary rows.
        AddFinding(Findings, 6, RunId, CreateGuid(), 'Company C', 'C3');
        Findings.Status := Findings.Status::Resolved;
        Findings.Modify();
        AddFinding(Findings, 7, CreateGuid(), CreateGuid(), 'Company D', 'C4');
        AffectedUserMgt.BuildSummary(RunId, 'TEST-RUN', Findings, Buffer);

        AssertEqual(2, Buffer.Count(), 'distinct affected users');
        Buffer.Get(RunId, UserA);
        AssertEqual(2, Buffer."Company Count", 'distinct companies');
        AssertEqual(2, Buffer."Detected Conflict Count", 'distinct conflict codes');
        AssertEqual(4, Buffer."Finding Count", 'finding records');
        AssertEqual(2, Buffer."High Severity Finding Count", 'High excludes Critical');
        if not (Buffer."Has Special Permissions" and Buffer."Has Security Group Findings" and Buffer."Has Direct Assignments") then
            Error('Stored source flags were not combined across findings.');
        Buffer.Get(RunId, UserB);
        AssertEqual(1, Buffer."Company Count", 'second user companies');
        AssertEqual(1, Buffer."Detected Conflict Count", 'second user conflicts');
        AssertEqual(1, Buffer."Finding Count", 'second user findings');
        AssertEqual(0, Buffer."High Severity Finding Count", 'second user High findings');
        if Buffer."Has Special Permissions" or Buffer."Has Security Group Findings" or Buffer."Has Direct Assignments" then
            Error('Source flags leaked between users.');
        if Buffer.FindSet() then
            repeat
                FindingSum += Buffer."Finding Count";
            until Buffer.Next() = 0;
        AssertEqual(5, FindingSum, 'sum of Open findings');

        // Rebuilding replaces the temporary summary rather than accumulating it.
        AffectedUserMgt.BuildSummary(RunId, 'TEST-RUN', Findings, Buffer);
        AssertEqual(2, Buffer.Count(), 'rebuilt distinct affected users');
    end;

    [Test]
    procedure NonOpenFindingsDoNotAffectCountsOrFlags()
    var
        Findings: Record "BCG User Conflict Result" temporary;
        Buffer: Record "BCG Affected User Buffer";
        AffectedUserMgt: Codeunit "BCG Affected User Mgt.";
        RunId: Guid;
        UserId: Guid;
        EntryNo: Integer;
    begin
        RunId := CreateGuid();
        UserId := CreateGuid();
        AddFinding(Findings, 1, RunId, UserId, '', 'C1');
        for EntryNo := 2 to 4 do begin
            AddFinding(Findings, EntryNo, RunId, UserId, 'Excluded Company', 'EXCLUDED');
            Findings.Status := EntryNo - 1;
            Findings.Severity := Findings.Severity::High;
            Findings."Has Special Permission Source" := true;
            Findings."Has Security Group Source" := true;
            Findings."Has Direct Source" := true;
            Findings.Modify();
        end;
        AffectedUserMgt.BuildSummary(RunId, 'TEST-RUN', Findings, Buffer);
        AssertEqual(1, Buffer.Count(), 'one Open user');
        Buffer.Get(RunId, UserId);
        AssertEqual(1, Buffer."Company Count", 'blank stored company is one distinct value');
        AssertEqual(1, Buffer."Detected Conflict Count", 'Open conflicts only');
        AssertEqual(1, Buffer."Finding Count", 'Open findings only');
        AssertEqual(0, Buffer."High Severity Finding Count", 'non-Open High findings excluded');
        if Buffer."Has Special Permissions" or Buffer."Has Security Group Findings" or Buffer."Has Direct Assignments" then
            Error('Non-Open source flags affected the summary.');

        Findings.Reset();
        Findings.DeleteAll();
        AffectedUserMgt.BuildSummary(RunId, 'TEST-RUN', Findings, Buffer);
        AssertEqual(0, Buffer.Count(), 'empty scope clears previous summary');
    end;

    [Test]
    procedure CapturedNameDoesNotRequireLiveUser()
    var
        Findings: Record "BCG User Conflict Result" temporary;
        Buffer: Record "BCG Affected User Buffer";
        UserSnapshot: Record "BCG User Snapshot";
        AffectedUserMgt: Codeunit "BCG Affected User Mgt.";
        RunId: Guid;
        UserId: Guid;
    begin
        RunId := CreateGuid();
        UserId := CreateGuid();
        // Test-runner transaction rolls back this fixture; production browsing is read-only.
        UserSnapshot.Init();
        UserSnapshot."Run ID" := RunId;
        UserSnapshot."User Security ID" := UserId;
        UserSnapshot."User Name" := 'CAPTURED USER';
        UserSnapshot.Insert();
        AddFinding(Findings, 1, RunId, UserId, 'Company A', 'C1');
        AffectedUserMgt.BuildSummary(RunId, 'TEST-RUN', Findings, Buffer);
        Buffer.Get(RunId, UserId);
        if Buffer."User Name" <> 'CAPTURED USER' then
            Error('Expected captured user name without a live User record.');
        if Buffer."Run No." <> 'TEST-RUN' then
            Error('Expected selected readable run number.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DuplicateRunNumbersSelectNewestIdentity()
    var
        Presentation: Codeunit "BCG Risk Presentation Mgt.";
        RunId: Guid;
        RunNo: Code[20];
    begin
        CreateNavigationFixture();
        if not Presentation.TryGetCurrentRun(RunId, RunNo) then
            Error('Expected a completed run.');
        if RunId <> NavigationRunId then
            Error('Latest run selection lost its identity.');
        if RunNo <> 'TEST-05A-DUPLICATE' then
            Error('Readable run number changed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DuplicateRunNumbersKeepCueCountsIsolated()
    var
        Cues: TestPage "BCG Conflict Cues";
    begin
        CreateNavigationFixture();
        Cues.OpenView();
        Cues."Active Conflicts".AssertEquals(2);
        Cues."Users with Conflicts".AssertEquals(2);
        Cues."High Severity".AssertEquals(2);
        Cues."Privileged Access Risks".AssertEquals(2);
        Cues."Group-Based Risks".AssertEquals(2);
        Cues.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CheckDetectedDrillDown,CheckDetailedDrillDown')]
    procedure DuplicateRunNumbersKeepFindingDrillDownsIsolated()
    var
        Cues: TestPage "BCG Conflict Cues";
    begin
        CreateNavigationFixture();
        ExpectedNavigationCount := 2;
        Cues.OpenView();
        Cues."Active Conflicts".DrillDown();
        Cues."High Severity".DrillDown();
        Cues."Privileged Access Risks".DrillDown();
        Cues."Group-Based Risks".DrillDown();
        Cues.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CheckAffectedDrillDown,CheckDetailedDrillDown')]
    procedure DuplicateRunNumbersKeepAffectedUserDrillDownIsolated()
    var
        Cues: TestPage "BCG Conflict Cues";
    begin
        CreateNavigationFixture();
        ExpectedNavigationCount := 1;
        Cues.OpenView();
        Cues."Users with Conflicts".DrillDown();
        Cues.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CheckDetailedDrillDown')]
    procedure AmbiguousHistoricalRunCanBeOpenedByIdentity()
    var
        Detected: Page "BCG Detected Conflicts";
        DetectedTest: TestPage "BCG Detected Conflicts";
    begin
        CreateNavigationFixture();
        NavigationRunId := HistoricalRunId;
        ExpectedNavigationCount := 3;
        Detected.InitializeOpenScope(NavigationRunId);
        DetectedTest.Trap();
        Detected.Run();
        DetectedTest.First();
        DetectedTest."Finding Count".AssertEquals(3);
        DetectedTest."Finding Count".DrillDown();
        DetectedTest.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AmbiguousLegacyNumberLookupFailsClosed()
    var
        AffectedMgt: Codeunit "BCG Affected User Mgt.";
    begin
        CreateNavigationFixture();
        asserterror AffectedMgt.ResolveCueRun('TEST-05A-DUPLICATE');
        if StrPos(GetLastErrorText(), 'does not identify one completed run') = 0 then
            Error('Expected ambiguous legacy number lookup to fail closed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CheckDetailedDrillDown')]
    procedure DefaultDetectedConflictsUsesSelectedRunId()
    var
        Detected: TestPage "BCG Detected Conflicts";
    begin
        CreateNavigationFixture();
        ExpectedNavigationCount := 3;
        Detected.OpenView();
        if not Detected.First() then
            Error('Duplicate display numbers must not prevent default selection.');
        Detected."Finding Count".AssertEquals(3);
        Detected."Finding Count".DrillDown();
        Detected.Close();
    end;

    [PageHandler]
    procedure CheckDetectedDrillDown(var Detected: TestPage "BCG Detected Conflicts")
    begin
        if not Detected.First() then
            Error('Expected selected-run findings.');
        Detected."Finding Count".AssertEquals(ExpectedNavigationCount);
        if Detected.Next() then
            Error('Unexpected second conflict summary.');
        Detected.First();
        Detected."Finding Count".DrillDown();
        Detected.Close();
    end;

    [PageHandler]
    procedure CheckAffectedDrillDown(var Affected: TestPage "BCG Affected Users")
    var
        UserCount: Integer;
    begin
        if Affected.First() then
            repeat
                UserCount += 1;
                Affected."Finding Count".AssertEquals(1);
                Affected."Finding Count".DrillDown();
            until not Affected.Next();
        AssertEqual(2, UserCount, 'selected-run affected users');
        Affected.Close();
    end;

    [PageHandler]
    procedure CheckDetailedDrillDown(var Findings: TestPage "BCG User Conflict Results")
    var
        FindingCount: Integer;
    begin
        if Findings.First() then
            repeat
                Findings."Result Description".AssertEquals('TEST-05A-RUN:' + Format(NavigationRunId));
                FindingCount += 1;
            until not Findings.Next();
        AssertEqual(ExpectedNavigationCount, FindingCount, 'selected-run detailed findings');
        Findings.Close();
    end;

    local procedure CreateNavigationFixture()
    var
        Audit: Record "BCG Audit Run";
        Finding: Record "BCG User Conflict Result";
        UserSnapshot: Record "BCG User Snapshot";
        LatestStartedAt: DateTime;
        FixtureStartedAt: DateTime;
        RunIndex: Integer;
        FindingIndex: Integer;
    begin
        // AutoRollback owns these synthetic records. Existing audit data is
        // retained and may include fixtures from earlier test executions.
        LatestStartedAt := CurrentDateTime();
        Audit.SetRange(Status, Audit.Status::Finished);
        Audit.SetFilter("Run No.", '<>%1', '');
        if Audit.FindSet() then
            repeat
                if Audit."Started At" > LatestStartedAt then
                    LatestStartedAt := Audit."Started At";
            until Audit.Next() = 0;
        Audit.Reset();

        // Leave conservative headroom before the final supported date, including
        // time-zone conversion. Check BEFORE rounding or adding milliseconds.
        if LatestStartedAt > CreateDateTime(99991230D, 235957T) then
            Error('Cannot create newer navigation fixtures safely: eligible audit timestamps are too close to the DateTime limit. Existing data was not changed.');
        FixtureStartedAt := RoundDateTime(LatestStartedAt, 1000, '>');
        for RunIndex := 1 to 2 do begin
            Audit.Init();
            Audit."Run ID" := CreateGuid();
            Audit."Run No." := 'TEST-05A-DUPLICATE';
            Audit.Status := Audit.Status::Finished;
            Audit."Started At" := FixtureStartedAt + (RunIndex * 1000);
            Audit.Insert();
            if RunIndex = 1 then
                HistoricalRunId := Audit."Run ID"
            else
                NavigationRunId := Audit."Run ID";
            for FindingIndex := 1 to 3 do begin
                UserSnapshot.Init();
                UserSnapshot."Run ID" := Audit."Run ID";
                UserSnapshot."User Security ID" := CreateGuid();
                UserSnapshot."User Name" := 'TEST-05A';
                UserSnapshot.Insert();
                Finding.Init();
                Finding."Entry No." := 0;
                Finding."Run ID" := Audit."Run ID";
                Finding."Result Description" := 'TEST-05A-RUN:' + Format(Finding."Run ID");
                Finding."Run No." := Audit."Run No.";
                Finding."User Security ID" := UserSnapshot."User Security ID";
                Finding."Conflict Code" := 'TEST-05A';
                Finding."Conflict Name" := 'Run identity test';
                Finding.Status := Finding.Status::Open;
                Finding.Severity := Finding.Severity::High;
                Finding."Has Special Permission Source" := true;
                Finding."Has Security Group Source" := true;
                if RunIndex = 2 then
                    case FindingIndex of
                        1: Finding."Run No." := 'HISTORICAL-LABEL';
                        2: Finding.Status := Finding.Status::Resolved;
                        3:
                            begin
                                Finding.Severity := Finding.Severity::Critical;
                                Finding."Has Special Permission Source" := false;
                                Finding."Has Security Group Source" := false;
                            end;
                    end;
                Finding.Insert();
            end;
        end;
        AssertNavigationFixtureSelected();
    end;

    local procedure AssertNavigationFixtureSelected()
    var
        Presentation: Codeunit "BCG Risk Presentation Mgt.";
        SelectedRunId: Guid;
        SelectedRunNo: Code[20];
    begin
        // Fail at setup, before any default page navigation can select another run.
        if not Presentation.TryGetCurrentRun(SelectedRunId, SelectedRunNo) then
            Error('Navigation fixture setup did not produce an eligible completed run.');
        if SelectedRunId <> NavigationRunId then
            Error('Navigation fixture setup selected Run ID %1 instead of expected Run ID %2.', SelectedRunId, NavigationRunId);
    end;

    var
        NavigationRunId: Guid;
        HistoricalRunId: Guid;
        ExpectedNavigationCount: Integer;

    local procedure AddFinding(var Findings: Record "BCG User Conflict Result" temporary; EntryNo: Integer; RunId: Guid; UserId: Guid; CompanyName: Text[30]; ConflictCode: Code[50])
    begin
        Findings.Init();
        Findings."Entry No." := EntryNo;
        Findings."Run ID" := RunId;
        Findings."User Security ID" := UserId;
        Findings."Company Name" := CompanyName;
        Findings."Conflict Code" := ConflictCode;
        Findings.Status := Findings.Status::Open;
        Findings.Insert();
    end;

    local procedure AssertEqual(Expected: Integer; Actual: Integer; Context: Text)
    begin
        if Expected <> Actual then
            Error('%1: expected %2, got %3.', Context, Expected, Actual);
    end;
}
#endif
