#if BCG_SOURCE_COUNT_TESTS
codeunit 50975 "BCG Full Analysis Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // Run with AL Test Tool runner 130450 (Codeunit isolation), never a non-isolated runner.
    EventSubscriberInstance = Manual;

    var
        FailureStage: Integer;
        CapturedRunId: Guid;
        ConflictId: Code[20];
        InjectedFailureLbl: Label 'F05 injected failure at stage %1', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailureAfterSnapshotRollsBack()
    begin
        CheckFailure(1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailureAfterFindingAndEvidenceRollsBack()
    begin
        CheckFailure(2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailureAfterEvidenceSummaryRollsBack()
    begin
        CheckFailure(3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailureDuringFinalizationRollsBack()
    begin
        CheckFailure(4);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SuccessfulFullAnalysisPersistsCompleteRun()
    var
        Probe: Codeunit "BCG Full Analysis Tests";
        Snapshot: Codeunit "BCG Snapshot Mgt.";
        RunId: Guid;
    begin
        GuardSandbox();
        Probe.Configure(0);
        BindSubscription(Probe);
        RunId := Snapshot.RunFullSnapshot();
        UnbindSubscription(Probe);
        // A later error must not undo the successful worker's Finished status or data.
        asserterror Error('F05 post-success rollback probe');
        AssertCompleteRun(RunId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure UnauthorizedWorkerEntryCreatesNoRun()
    var
        Audit: Record "BCG Audit Run";
        Snapshot: Codeunit "BCG Snapshot Mgt.";
        CountBefore: Integer;
        FailureText: Text;
    begin
        GuardSandbox();
        CountBefore := Audit.Count();
        Audit.Init();
        Audit."Run ID" := CreateGuid();
        Commit();
        ClearLastError();
        if Snapshot.Run(Audit) then
            Error('An unarmed worker entry must be rejected.');
        FailureText := GetLastErrorText();
        if StrPos(FailureText, 'must be started through RunFullSnapshot') = 0 then
            Error('Unexpected worker-entry diagnostic: %1', FailureText);
        if Audit.Count() <> CountBefore then
            Error('Rejected worker entry created an audit run.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure HistoricalRunCannotBeReusedByWorker()
    var
        Audit: Record "BCG Audit Run";
        Probe: Codeunit "BCG Full Analysis Tests";
        Snapshot: Codeunit "BCG Snapshot Mgt.";
        RunId: Guid;
    begin
        GuardSandbox();
        Probe.Configure(0);
        BindSubscription(Probe);
        RunId := Snapshot.RunFullSnapshot();
        UnbindSubscription(Probe);
        Audit.Get(RunId);
        Commit();
        if Snapshot.Run(Audit) then
            Error('The consumed worker entry must not reopen a historical run.');
        AssertCompleteRun(RunId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CompletedRunsRejectMaintenanceWithoutMutation()
    begin
        CheckMaintenanceStates(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CreatedErrorAndMissingRunsRejectMaintenance()
    begin
        CheckMaintenanceStates(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ClearDetailsRejectsRunningRunBeforeDeletion()
    var
        Audit: Record "BCG Audit Run";
        BeforeState: Text;
    begin
        Audit.Get(CreateCompletedFixture());
        Audit.Status := Audit.Status::Running;
        Audit.Modify();
        BeforeState := ReadStoredState(Audit."Run ID");
        AssertMaintenanceRejected(Audit, 18);
        AssertMaintenanceRejected(Audit, 19);
        if ReadStoredState(Audit."Run ID") <> BeforeState then
            Error('Clear-details rejection deleted data.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CompletedFindingReviewStatusRemainsEditable()
    var
        Result: Record "BCG User Conflict Result";
        Audit: Record "BCG Audit Run";
    begin
        Audit.Get(CreateCompletedFixture());
        Result.SetRange("Run ID", Audit."Run ID");
        Result.FindFirst();
        Result.Validate(Status, Result.Status::Accepted);
        Result.Modify(true);
        AssertMaintenanceRejected(Audit, 1);
        Result.Get(Result."Entry No.");
        Result.TestField(Status, Result.Status::Accepted);
        AssertCompleteRun(Audit."Run ID");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure WholeRunDeletionRemainsSupported()
    var
        Audit: Record "BCG Audit Run";
        Cleanup: Codeunit "BCG Run Cleanup Mgt.";
        RunId: Guid;
        OtherRunId: Guid;
        OtherState: Text;
    begin
        OtherRunId := CreateCompletedFixture();
        OtherState := ReadStoredState(OtherRunId);
        RunId := CreateCompletedFixture();
        Cleanup.DeleteRun(RunId, true);
        if Audit.Get(RunId) then
            Error('Whole-run deletion retained the header.');
        AssertNoChildren(RunId);
        if ReadStoredState(OtherRunId) <> OtherState then
            Error('Whole-run deletion changed another analysis.');
    end;

    local procedure CheckMaintenanceStates(IncludeOtherStates: Boolean)
    var
        Audit: Record "BCG Audit Run";
        BeforeState: Text;
        RunId: Guid;
        Operation: Integer;
        StateNo: Integer;
        LastState: Integer;
    begin
        RunId := CreateCompletedFixture();
        if IncludeOtherStates then
            LastState := 4;
        for StateNo := 0 to LastState do begin
            Audit.Get(RunId);
            case StateNo of
                1: Audit.Status := Audit.Status::Created;
                2: Audit.Status := Audit.Status::Error;
            end;
            if StateNo in [1, 2] then
                Audit.Modify();
            BeforeState := ReadStoredState(RunId);
            if StateNo = 3 then
                Audit."Run ID" := CreateGuid();
            if StateNo = 4 then
                Clear(Audit."Run ID");
            // The guard must read persisted status, never trust this caller buffer.
            Audit.Status := Audit.Status::Running;
            Audit."Run No." := 'FORGED NUMBER';
            for Operation := 1 to 26 do begin
                AssertMaintenanceRejected(Audit, Operation);
                if ReadStoredState(RunId) <> BeforeState then
                    Error('Operation %1 changed stored data.', Operation);
            end;
            if StateNo >= 3 then begin
                AssertNoChildren(Audit."Run ID");
                if Audit.Get(Audit."Run ID") then
                    Error('Rejected maintenance created a missing run.');
            end;
        end;
    end;

    local procedure CreateCompletedFixture(): Guid
    var
        Probe: Codeunit "BCG Full Analysis Tests";
        Snapshot: Codeunit "BCG Snapshot Mgt.";
        RunId: Guid;
    begin
        GuardSandbox();
        Probe.Configure(0);
        BindSubscription(Probe);
        RunId := Snapshot.RunFullSnapshot();
        UnbindSubscription(Probe);
        AssertCompleteRun(RunId);
        exit(RunId);
    end;

    local procedure AssertMaintenanceRejected(Audit: Record "BCG Audit Run"; Operation: Integer)
    var
        FailureText: Text;
    begin
        ClearLastError();
        // Retain writes on failure so a misplaced guard cannot hide behind rollback.
        if TryMaintenance(Audit, Operation) then
            Error('Maintenance operation %1 must be rejected.', Operation);
        FailureText := GetLastErrorText();
        if (StrPos(FailureText, 'unsupported') = 0) or (StrPos(FailureText, 'Full Analysis') = 0) then
            Error('Unexpected maintenance rejection for %1: %2', Operation, FailureText);
    end;

    [TryFunction]
    local procedure TryMaintenance(var Audit: Record "BCG Audit Run"; Operation: Integer)
    var
        Snapshot: Codeunit "BCG Snapshot Mgt.";
        Groups: Codeunit "BCG SecGrp Mgt";
        Special: Codeunit "BCG Special Permission Mgt.";
        Sources: Codeunit "BCG Conflict Source Mgt";
        Summary: Codeunit "BCG Conflict Src Summary";
        Evidence: Codeunit "BCG Conflict Evidence Mgt";
        Context: Codeunit "BCG User Access Context Mgt";
        Enrichment: Codeunit "BCG SecGrp Special Src Mgt";
        Numbering: Codeunit "BCG Run No. Mgt.";
        Cleanup: Codeunit "BCG Run Cleanup Mgt.";
        AccessMgt: Codeunit "BCG Access Mgt.";
    begin
        case Operation of
            1: Snapshot.CalculateConflicts(Audit."Run ID");
            2: Snapshot.RebuildEffectiveUserTableDataPermissions(Audit."Run ID");
            3: Groups.RestoreAssignmentsFromSnapshot(Audit."Run ID");
            4: Enrichment.MarkSpecialPermissionsAssignedThroughSecurityGroups(Audit."Run ID");
            5: Enrichment.UpdateConflictResultSourcesFromLines(Audit."Run ID");
            6: Sources.RebuildSourceTraceForRun(Audit."Run ID", false);
            7: Special.AddSpecialPermissionWildcardsForRun(Audit."Run ID", false);
            8: Summary.UpdateConflictResultSourcesForRun(Audit."Run ID", false);
            9: Evidence.UpdateEvidenceForRun(Audit."Run ID");
            10: Context.UpdateAccessContextForRun(Audit."Run ID", false);
            11: Context.UpdateSpecialPermissionSummaryForRun(Audit."Run ID");
            12: Context.UpdateConflictUserSecurityGroupContextForRun(Audit."Run ID");
            13: Numbering.EnsureRunNo(Audit);
            14: Numbering.PropagateRunNo(Audit);
            15: Numbering.EnsureRunNoAndPropagate(Audit."Run ID");
            16: Numbering.UpdateAllRunNumbers();
            17: Enrichment.RunSecurityGroupSpecialPermissionRepair(Audit."Run ID");
            18: Cleanup.DeleteRun(Audit."Run ID", false);
            19: Cleanup.DeleteRunWithConfirmation(Audit."Run ID", Audit."Run No.", false);
            20: Groups.RunSecurityGroupSnapshot(Audit."Run ID", false);
            21: Groups.RunSecurityGroupSnapshot(Audit."Run ID");
            22: Sources.RebuildSourceTraceForRun(Audit."Run ID");
            23: Special.AddSpecialPermissionWildcardsForRun(Audit."Run ID");
            24: Summary.UpdateConflictResultSourcesForRun(Audit."Run ID");
            25: Context.UpdateAccessContextForRun(Audit."Run ID");
            26: AccessMgt.RequireRunningRun(Audit."Run ID", Codeunit::"BCG Snapshot Mgt.");
        end;
    end;

    local procedure ReadStoredState(RunId: Guid): Text
    var
        Audit: Record "BCG Audit Run";
        Header: RecordRef;
        Values: JsonArray;
        Serialized: Text;
        Index: Integer;
    begin
        Audit.Get(RunId);
        Header.GetTable(Audit);
        for Index := 1 to Header.FieldCount() do
            Values.Add(Format(Header.FieldIndex(Index).Value));
        Values.Add(ReadChildState(RunId));
        Values.WriteTo(Serialized);
        exit(Serialized);
    end;

    local procedure CheckFailure(Stage: Integer)
    var
        Previous: Record "BCG Audit Run";
        Audit: Record "BCG Audit Run";
        Probe: Codeunit "BCG Full Analysis Tests";
        Snapshot: Codeunit "BCG Snapshot Mgt.";
        Presentation: Codeunit "BCG Risk Presentation Mgt.";
        RunId: Guid;
        PreviousRunId: Guid;
        BeforeCurrent: Code[20];
        AfterCurrent: Code[20];
        ExpectedError: Text;
        ActualError: Text;
        PreviousData: Text;
    begin
        GuardSandbox();
        Probe.Configure(0);
        BindSubscription(Probe);
        PreviousRunId := Snapshot.RunFullSnapshot();
        UnbindSubscription(Probe);
        AssertCompleteRun(PreviousRunId);
        Previous.Get(PreviousRunId);
        PreviousData := ReadChildState(PreviousRunId);
        if not Presentation.TryGetCurrentRunNo(BeforeCurrent) then
            Error('The completed control run must be available for presentation.');

        Probe.Configure(Stage);
        BindSubscription(Probe);
        // Exercise the public orchestrator and its propagated error, not a TryFunction wrapper.
        asserterror Snapshot.RunFullSnapshot();
        ActualError := GetLastErrorText();
        UnbindSubscription(Probe);
        RunId := Probe.GetCapturedRunId();
        ExpectedError := StrSubstNo(InjectedFailureLbl, Stage);
        if ActualError <> ExpectedError then
            Error('Expected %1, got %2.', ExpectedError, ActualError);
        Audit.Get(RunId);
        Audit.TestField(Status, Audit.Status::Error);
        Audit.TestField("Finished At");
        Audit.TestField("Error Message", ExpectedError);
        Audit.TestField("Run No.", '');
        Audit.TestField("User Count", 0);
        Audit.TestField("Assignment Count", 0);
        Audit.TestField("Object Permission Count", 0);
        Audit.TestField("Effective Permission Count", 0);
        AssertNoChildren(RunId);
        Audit.Get(PreviousRunId);
        if (Audit."Run No." <> Previous."Run No.") or
           (Audit."Started At" <> Previous."Started At") or
           (Audit."Finished At" <> Previous."Finished At") or
           (Audit."Error Message" <> Previous."Error Message") then
            Error('The previous completed header changed.');
        AssertCompleteRun(PreviousRunId);
        if ReadChildState(PreviousRunId) <> PreviousData then
            Error('Previously completed analysis data changed.');
        if not Presentation.TryGetCurrentRunNo(AfterCurrent) or (AfterCurrent <> BeforeCurrent) then
            Error('A failed run changed current-run presentation.');
    end;

    internal procedure Configure(Stage: Integer)
    begin
        FailureStage := Stage;
        Clear(CapturedRunId);
        Clear(ConflictId);
    end;

    internal procedure GetCapturedRunId(): Guid
    begin
        exit(CapturedRunId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCG Snapshot Mgt.", 'OnTestCaptureFullSnapshot', '', false, false)]
    local procedure CaptureFixture(RunId: Guid; var Handled: Boolean)
    var
        UserSnapshot: Record "BCG User Snapshot";
        Assignment: Record "BCG User Perm. Assignment";
        Permission: Record "BCG Perm. Set Object Perm.";
        GroupSnapshot: Record "BCG SecGrp Snap";
        MemberSnapshot: Record "BCG SecGrp Member Snap";
        GroupAssignment: Record "BCG SecGrp Perm Assign";
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
        UserSid: Guid;
    begin
        GuardSandbox();
        CapturedRunId := RunId;
        UserSid := CreateGuid();
        UserSnapshot."Run ID" := RunId;
        UserSnapshot."User Security ID" := UserSid;
        UserSnapshot."User Name" := 'F05 FIXTURE';
        UserSnapshot.Insert();
        Assignment."Run ID" := RunId;
        Assignment."User Security ID" := UserSid;
        Assignment."Company Name" := CopyStr(CompanyName(), 1, 30);
        Assignment."Role ID" := 'F05 ROLE';
        Assignment."Scope Text" := 'System';
        Assignment."Assignment Source Type" := 'Security Group';
        Assignment."Assignment Source Code" := 'F05 GROUP';
        Assignment.Insert();
        Permission."Run ID" := RunId;
        Permission."Role ID" := Assignment."Role ID";
        Permission."Scope Text" := 'System';
        Permission."Object Type" := 'Table Data';
        Permission."Object ID" := 23;
        Permission."Read Permission" := 'Yes';
        Permission.Insert();
        GroupSnapshot."Run ID" := RunId;
        GroupSnapshot."Security Group Code" := 'F05 GROUP';
        GroupSnapshot."Retrieved Successfully" := true;
        GroupSnapshot.Insert();
        MemberSnapshot."Run ID" := RunId;
        MemberSnapshot."Security Group Code" := 'F05 GROUP';
        MemberSnapshot."User Security ID" := UserSid;
        MemberSnapshot.Insert();
        GroupAssignment."Run ID" := RunId;
        GroupAssignment."Security Group Code" := 'F05 GROUP';
        GroupAssignment."User Security ID" := UserSid;
        GroupAssignment."Company Name" := Assignment."Company Name";
        GroupAssignment."Role ID" := CopyStr(Assignment."Role ID", 1, MaxStrLen(GroupAssignment."Role ID"));
        GroupAssignment.Scope := 'System';
        GroupAssignment.Insert();
        ConflictId := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        Header."Conflict ID" := ConflictId;
        Header."Is Active" := true;
        Header.Insert();
        Group."Conflict ID" := ConflictId;
        Group."Group No." := 1;
        Group."Is Active" := true;
        Group."Evaluation Logic" := Group."Evaluation Logic"::ALL;
        Group.Insert();
        Rule."Conflict ID" := ConflictId;
        Rule."Group No." := 1;
        Rule."Line No." := 1;
        Rule."Rule ID" := 'F05 READ';
        Rule."Object ID" := 23;
        Rule."Requires Read" := true;
        Rule."Read Permission Match" := Rule."Read Permission Match"::"Direct Only";
        Rule.Insert();
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BCG Snapshot Mgt.", 'OnTestFullSnapshotStage', '', false, false)]
    local procedure FailAtStage(RunId: Guid; Stage: Integer)
    var
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
        Trace: Record "BCG Conflict Source Trace";
        Audit: Record "BCG Audit Run";
    begin
        if (RunId <> CapturedRunId) or (FailureStage <> Stage) then
            exit;
        if Stage >= 2 then begin
            Result.SetRange("Run ID", RunId);
            Result.SetRange("Conflict Code", ConflictId);
            if not Result.FindFirst() then
                Error('F05 fixture did not produce its expected finding.');
            Line.SetRange("Conflict Result Entry No.", Result."Entry No.");
            if Line.IsEmpty() then
                Error('F05 fixture did not produce evidence lines.');
        end;
        if Stage >= 3 then begin
            Result.TestField("Matched Rule Count", 1);
            Result.TestField("Conflict Evidence Summary");
            Trace.SetRange("Run ID", RunId);
            if Trace.IsEmpty() then
                Error('F05 fixture did not produce a source trace.');
        end;
        if Stage = 4 then begin
            Audit.Get(RunId);
            Audit.TestField("Run No.");
            Audit.TestField("User Count", 1);
            Audit.TestField(Status, Audit.Status::Running);
        end;
        Error(InjectedFailureLbl, Stage);
    end;

    local procedure AssertCompleteRun(RunId: Guid)
    var
        Audit: Record "BCG Audit Run";
        Result: Record "BCG User Conflict Result";
        Presentation: Codeunit "BCG Risk Presentation Mgt.";
        Child: RecordRef;
        RunField: FieldRef;
        CurrentRunNo: Code[20];
        TableId: Integer;
    begin
        Audit.Get(RunId);
        Audit.TestField("Company Filter", CompanyName());
        Audit.TestField(Status, Audit.Status::Finished);
        Audit.TestField("Finished At");
        Audit.TestField("Error Message", '');
        Audit.TestField("Run No.");
        Audit.TestField("User Count", 1);
        Audit.TestField("Assignment Count", 1);
        Audit.TestField("Object Permission Count", 1);
        Audit.TestField("Effective Permission Count", 1);
        foreach TableId in ChildTables() do begin
            Child.Open(TableId);
            RunField := Child.Field(FindRunIdField(Child));
            RunField.SetRange(RunId);
            if not Child.FindSet() then
                Error('Completed run has no records in table %1.', TableId);
            repeat
                Child.Field(FindRunNoField(Child)).TestField(Audit."Run No.");
            until Child.Next() = 0;
            Child.Close();
        end;
        Result.SetRange("Run ID", RunId);
        Result.FindSet();
        repeat
            Result.TestField("Matched Rule Count");
            Result.TestField("Conflict Evidence Summary");
        until Result.Next() = 0;
        if not Presentation.TryGetCurrentRunNo(CurrentRunNo) then
            Error('No completed run is selected for presentation.');
    end;

    local procedure AssertNoChildren(RunId: Guid)
    var
        Child: RecordRef;
        RunField: FieldRef;
        TableId: Integer;
    begin
        foreach TableId in ChildTables() do begin
            Child.Open(TableId);
            RunField := Child.Field(FindRunIdField(Child));
            RunField.SetRange(RunId);
            if not Child.IsEmpty() then
                Error('Partial records remain in table %1.', TableId);
            Child.Close();
        end;
    end;

    local procedure ReadChildState(RunId: Guid): Text
    var
        Child: RecordRef;
        RunField: FieldRef;
        Values: JsonArray;
        Serialized: Text;
        TableId: Integer;
        Index: Integer;
    begin
        foreach TableId in ChildTables() do begin
            Child.Open(TableId);
            RunField := Child.Field(FindRunIdField(Child));
            RunField.SetRange(RunId);
            Values.Add(TableId);
            if Child.FindSet() then
                repeat
                    Values.Add(Format(Child.RecordId));
                    for Index := 1 to Child.FieldCount() do
                        Values.Add(Format(Child.FieldIndex(Index).Value));
                until Child.Next() = 0;
            Child.Close();
        end;
        Values.WriteTo(Serialized);
        exit(Serialized);
    end;

    local procedure ChildTables(): List of [Integer]
    var
        Tables: List of [Integer];
    begin
        Tables.Add(Database::"BCG User Snapshot");
        Tables.Add(Database::"BCG User Perm. Assignment");
        Tables.Add(Database::"BCG Perm. Set Object Perm.");
        Tables.Add(Database::"BCG User Table Data Perm.");
        Tables.Add(Database::"BCG User Conflict Result");
        Tables.Add(Database::"BCG User Conflict Result Line");
        Tables.Add(Database::"BCG Conflict Source Trace");
        Tables.Add(Database::"BCG SecGrp Snap");
        Tables.Add(Database::"BCG SecGrp Member Snap");
        Tables.Add(Database::"BCG SecGrp Perm Assign");
        exit(Tables);
    end;

    local procedure FindRunIdField(Child: RecordRef): Integer
    begin
        exit(FindField(Child, 'Run ID'));
    end;

    local procedure FindRunNoField(Child: RecordRef): Integer
    begin
        exit(FindField(Child, 'Run No.'));
    end;

    local procedure FindField(Child: RecordRef; FieldName: Text): Integer
    var
        Index: Integer;
    begin
        for Index := 1 to Child.FieldCount() do
            if Child.FieldIndex(Index).Name = FieldName then
                exit(Child.FieldIndex(Index).Number);
        Error('Missing %1 field on table %2.', FieldName, Child.Number);
    end;

    local procedure GuardSandbox()
    var
        Environment: Codeunit "Environment Information";
    begin
        if not Environment.IsSandbox() then
            Error('Full Analysis transaction tests require a sandbox.');
    end;
}
#endif
