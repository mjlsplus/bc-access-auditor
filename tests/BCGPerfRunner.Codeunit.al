#if BCG_PERF_TESTS
codeunit 50960 "BCG Perf Runner"
{
    // No elevated permissions and no system security writes.
    procedure Guard()
    var
        Environment: Codeunit "Environment Information";
    begin
        if not Environment.IsSandbox() then
            Error('BCAA performance tests require a Sandbox environment.');
    end;

    procedure EnsureOwned(Dataset: Record "BCG Perf Dataset")
    var
        Stored: Record "BCG Perf Dataset";
        Audit: Record "BCG Audit Run";
    begin
        Guard();
        Stored.Get(Dataset."Entry No.");
        if IsNullGuid(Dataset."Run ID") or (Stored."Run ID" <> Dataset."Run ID") then
            Error('Invalid performance dataset ownership.');
        if Dataset.State = 'Cleaned' then
            Error('This dataset was cleaned. Generate a new dataset.');
        Audit.Get(Dataset."Run ID");
        if Audit."Run Description" <> 'BCAA-PERF-' + Format(Dataset."Entry No.") then
            Error('The selected audit run is not owned by this dataset.');
    end;

    procedure Generate(Scenario: Code[10]): Integer
    var
        Dataset: Record "BCG Perf Dataset";
        Audit: Record "BCG Audit Run";
        Active: Record "BCG Perf Dataset";
    begin
        Guard();
        // Bound total retained datasets as well as individual dataset size.
        Active.LockTable();
        Active.SetFilter(State, '<>%1', 'Cleaned');
        if Active.Count() >= 6 then
            Error('Clean up an existing dataset first (maximum six active datasets).');
        Dataset.Init();
        Dataset.Scenario := Scenario;
        case Scenario of
            'SMALL': Configure(Dataset, 20, 1, 20, 4, 40, 10);
            'MEDIUM': Configure(Dataset, 100, 1, 50, 7, 80, 18);
            'LARGE': Configure(Dataset, 250, 1, 100, 10, 120, 20);
            else Error('Unknown scenario %1.', Scenario);
        end;
        Dataset."Run ID" := CreateGuid();
        Dataset.State := 'Generated';
        Dataset.Assignments := Dataset.Users * Dataset."Assignments per User";
        Dataset."Source Rows" := Dataset."Permission Sets" * Dataset."Rows per Set";
        Dataset."Expected Effective" := Dataset.Users * (Dataset."Rows per Set" +
            (Dataset."Assignments per User" - 1) * (Dataset."Rows per Set" - 1));
        // Includes effective rows, snapshots, source rows, definitions, conflicts and evidence.
        Dataset."Estimated Row Cap" := Dataset."Expected Effective" + Dataset.Users +
            Dataset.Assignments + Dataset."Source Rows" + Dataset.Controls * 5 +
            (Dataset.Users div 4) * Dataset.Controls * 3;
        if Dataset."Estimated Row Cap" > 400000 then
            Error('Estimated %1 rows exceeds the 400,000 row safety limit.', Dataset."Estimated Row Cap");
        Dataset.Insert(true);
        if Dataset."Entry No." > 999999 then
            Error('Performance dataset ID limit reached.');
        Dataset."Rule Prefix" := CopyStr('BCAA-PERF-' + Format(Dataset."Entry No.") + '-', 1, 18);
        Dataset.Modify();
        Audit.Init();
        Audit."Run ID" := Dataset."Run ID";
        Audit."Run Description" := 'BCAA-PERF-' + Format(Dataset."Entry No.");
        Audit."Run No." := CopyStr(Audit."Run Description", 1, 20);
        Audit."Company Filter" := CopyStr(CompanyName(), 1, MaxStrLen(Audit."Company Filter"));
        Audit."Started At" := CurrentDateTime();
        Audit."Started By" := CopyStr(UserId(), 1, 50);
        Audit.Insert();
        LoadUsers(Dataset);
        LoadAssignments(Dataset);
        CreateRules(Dataset);
        exit(Dataset."Entry No.");
    end;

    local procedure Configure(var Dataset: Record "BCG Perf Dataset"; Users: Integer; Companies: Integer; Sets: Integer; Assignments: Integer; Rows: Integer; Controls: Integer)
    begin
        Dataset.Users := Users;
        Dataset.Companies := Companies;
        Dataset."Permission Sets" := Sets;
        Dataset."Assignments per User" := Assignments;
        Dataset."Rows per Set" := Rows;
        Dataset.Controls := Controls;
    end;

    internal procedure LoadUsers(Dataset: Record "BCG Perf Dataset")
    var
        Snapshot: Record "BCG User Snapshot";
        UserNo: Integer;
    begin
        EnsureOwned(Dataset);
        for UserNo := 1 to Dataset.Users do begin
            Snapshot.Init();
            Snapshot."Run ID" := Dataset."Run ID";
            Snapshot."User Security ID" := UserSid(UserNo);
            Snapshot."User Name" := 'BCAA-PERF-U' + Format(UserNo);
            Snapshot."Full Name" := Snapshot."User Name";
            Snapshot.State := 'Enabled';
            Snapshot."Captured At" := CurrentDateTime();
            Snapshot.Insert();
        end;
    end;

    internal procedure LoadAssignments(Dataset: Record "BCG Perf Dataset")
    var
        Assignment: Record "BCG User Perm. Assignment";
        UserNo: Integer;
        Slot: Integer;
        RoleNo: Integer;
    begin
        EnsureOwned(Dataset);
        for UserNo := 1 to Dataset.Users do
            for Slot := 1 to Dataset."Assignments per User" do begin
                RoleNo := AssignedRole(Dataset, UserNo, Slot);
                Assignment.Init();
                Assignment."Run ID" := Dataset."Run ID";
                Assignment."User Security ID" := UserSid(UserNo);
                if Slot > 1 then
                    Assignment."Company Name" := TargetCompany()
                else
                    Assignment."Company Name" := '';
                Assignment."Role ID" := RoleId(RoleNo);
                Assignment."Role Name" := RoleName(RoleNo);
                Assignment."Scope Text" := 'System';
                Assignment."Assignment Source Type" := 'Direct';
                Assignment.Insert();
            end;
    end;

    local procedure AssignedRole(Dataset: Record "BCG Perf Dataset"; UserNo: Integer; Slot: Integer): Integer
    begin
        if Slot = 1 then
            exit(1);
        if Slot = 2 then begin
            if (UserNo mod 4) in [0, 1] then
                exit(2);
            if (UserNo mod 4) = 2 then
                exit(3);
        end;
        if (Slot = 3) and ((UserNo mod 4) = 0) then
            exit(3);
        if (Slot = Dataset."Assignments per User") and ((UserNo mod 20) = 0) then
            exit(4);
        exit(5 + ((UserNo + Slot) mod (Dataset."Permission Sets" - 4)));
    end;

    internal procedure LoadExpanded(Dataset: Record "BCG Perf Dataset"; var Expanded: Record "Expanded Permission" temporary)
    var
        RoleNo: Integer;
        RowNo: Integer;
    begin
        EnsureOwned(Dataset);
        Expanded.Reset();
        Expanded.DeleteAll();
        for RoleNo := 1 to Dataset."Permission Sets" do
            for RowNo := 1 to Dataset."Rows per Set" do begin
                Expanded.Init();
                Expanded."Role ID" := RoleId(RoleNo);
                Expanded."Object Type" := Expanded."Object Type"::"Table Data";
                Expanded."Object ID" := ObjectId(Dataset, RoleNo, RowNo);
                Expanded."Read Permission" := Expanded."Read Permission"::Yes;
                if RoleNo = 2 then
                    Expanded."Modify Permission" := Expanded."Modify Permission"::Yes;
                if RoleNo = 3 then
                    Expanded."Insert Permission" := Expanded."Insert Permission"::Yes;
                if RoleNo = 4 then begin
                    Expanded."Insert Permission" := Expanded."Insert Permission"::Yes;
                    Expanded."Modify Permission" := Expanded."Modify Permission"::Yes;
                    Expanded."Delete Permission" := Expanded."Delete Permission"::Yes;
                end;
                if (RoleNo > 3) and (RowNo > 1) then begin
                    if (RoleNo mod 3) = 0 then
                        Expanded."Modify Permission" := Expanded."Modify Permission"::Indirect;
                    if (RoleNo mod 5) = 0 then
                        Expanded."Delete Permission" := Expanded."Delete Permission"::Yes;
                end;
                Expanded.Insert();
            end;
    end;

    local procedure ObjectId(Dataset: Record "BCG Perf Dataset"; RoleNo: Integer; RowNo: Integer): Integer
    begin
        if RowNo = 1 then
            exit(18); // Shared customer read across every set, exercises source merging.
        if (RoleNo in [2, 3]) and (RowNo <= Dataset.Controls + 1) then
            exit(RoleNo * 200 + RowNo);
        exit(100000 + RoleNo * 200 + RowNo);
    end;

    local procedure CreateRules(Dataset: Record "BCG Perf Dataset")
    var
        Header: Record "BCG Conflict Header";
        Group: Record "BCG Conflict Group";
        Rule: Record "BCG Conflict Group Rule";
        ControlNo: Integer;
        GroupNo: Integer;
    begin
        for ControlNo := 1 to Dataset.Controls do begin
            Header.Init();
            Header."Conflict ID" := ControlId(Dataset, ControlNo);
            Header."Perf Dataset ID" := Dataset."Run ID";
            Header.Name := 'BCAA-PERF- maintenance / payment ' + Format(ControlNo);
            Header."Is Active" := true;
            Header.Severity := Header.Severity::High;
            Header.Insert(); // Never overwrite a prefix collision.
            for GroupNo := 1 to 2 do begin
                Group.Init();
                Group."Conflict ID" := Header."Conflict ID";
                Group."Group No." := GroupNo;
                Group."Group Name" := 'BCAA-PERF-' + Format(GroupNo);
                Group.Sequence := GroupNo * 10;
                Group."Is Active" := true;
                Group.Insert();
                Rule.Init();
                Rule."Conflict ID" := Header."Conflict ID";
                Rule."Group No." := GroupNo;
                Rule."Line No." := 10000;
                Rule."Rule ID" := CopyStr(Header."Conflict ID" + '-' + Format(GroupNo), 1, 30);
                Rule."Object ID" := ObjectId(Dataset, GroupNo + 1, ControlNo + 1);
                Rule."Rule Name" := Group."Group Name";
                if GroupNo = 1 then begin
                    Rule."Requires Modify" := true;
                    Rule."Modify Permission Match" := Rule."Modify Permission Match"::"Direct Only";
                end else begin
                    Rule."Requires Insert" := true;
                    Rule."Insert Permission Match" := Rule."Insert Permission Match"::"Direct Only";
                end;
                Rule.Insert();
            end;
        end;
    end;

    procedure RunFull(EntryNo: Integer)
    var
        Dataset: Record "BCG Perf Dataset";
        Snapshot: Codeunit "BCG Snapshot Mgt.";
        Audit: Record "BCG Audit Run";
        Started: DateTime;
    begin
        Dataset.Get(EntryNo);
        EnsureOwned(Dataset);
        SetFirstControl(Dataset, true);
        Dataset."Full Passed" := false;
        Dataset."Recalc Passed" := false;
        Dataset."Conflict Only Time" := 0;
        Dataset."Existing Recalc Time" := 0;
        Dataset."Recalc Conflicts" := 0;
        Started := CurrentDateTime();
        Audit.Get(Dataset."Run ID");
        Audit.Status := Audit.Status::Running;
        Audit."Started At" := Started;
        Audit.Modify();
        Snapshot.PerfFull(Dataset);
        Audit.Get(Dataset."Run ID");
        Audit.Status := Audit.Status::Finished;
        Audit."Finished At" := CurrentDateTime();
        Audit.Modify();
        Dataset."Full Time" := CurrentDateTime() - Started;
        CaptureCounts(Dataset, false);
        Validate(Dataset, Dataset.Controls);
        Dataset."Full Passed" := true;
        Dataset.State := 'Full passed';
        Dataset.Modify();
    end;

    procedure RunConflictOnly(EntryNo: Integer)
    var
        Dataset: Record "BCG Perf Dataset";
        Audit: Record "BCG Audit Run";
        Snapshot: Codeunit "BCG Snapshot Mgt.";
        SpecialSources: Codeunit "BCG SecGrp Special Src Mgt";
        Summary: Codeunit "BCG Conflict Src Summary";
        Started: DateTime;
    begin
        Dataset.Get(EntryNo);
        EnsureOwned(Dataset);
        Dataset.TestField("Full Passed", true);
        // Only this owned synthetic dataset enters a new calculation phase.
        Audit.Get(Dataset."Run ID");
        Audit.Status := Audit.Status::Running;
        Audit.Modify();
        SetFirstControl(Dataset, false);
        Snapshot.PerfSelect(Dataset);
        // The true conflict-only engine path: no effective permission rebuild.
        Started := CurrentDateTime();
        Snapshot.CalculateConflicts(Dataset."Run ID");
        Dataset."Conflict Only Time" := CurrentDateTime() - Started;
        Validate(Dataset, Dataset.Controls - 1);
        // Exercise the shared calculation sequence on the Running synthetic dataset.
        Started := CurrentDateTime();
        Snapshot.RebuildEffectiveUserTableDataPermissions(Dataset."Run ID");
        Snapshot.CalculateConflicts(Dataset."Run ID");
        SpecialSources.MarkSpecialPermissionsAssignedThroughSecurityGroups(Dataset."Run ID");
        Summary.UpdateConflictResultSourcesForRun(Dataset."Run ID", false);
        SpecialSources.UpdateConflictResultSourcesFromLines(Dataset."Run ID");
        Dataset."Existing Recalc Time" := CurrentDateTime() - Started;
        Validate(Dataset, Dataset.Controls - 1);
        CaptureCounts(Dataset, true);
        Dataset."Recalc Passed" := true;
        Dataset.State := 'All passed';
        Dataset.Modify();
        Audit.Get(Dataset."Run ID");
        Audit.Status := Audit.Status::Finished;
        Audit.Modify();
    end;

    local procedure SetFirstControl(Dataset: Record "BCG Perf Dataset"; Enabled: Boolean)
    var
        Header: Record "BCG Conflict Header";
    begin
        Header.Get(ControlId(Dataset, 1));
        Header.TestField("Perf Dataset ID", Dataset."Run ID");
        Header."Is Active" := Enabled;
        Header.Modify();
    end;

    local procedure CaptureCounts(var Dataset: Record "BCG Perf Dataset"; Recalculated: Boolean)
    var
        Effective: Record "BCG User Table Data Perm.";
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
        Trace: Record "BCG Conflict Source Trace";
        Assignment: Record "BCG User Perm. Assignment";
        Source: Record "BCG Perm. Set Object Perm.";
    begin
        Effective.SetRange("Run ID", Dataset."Run ID");
        Result.SetRange("Run ID", Dataset."Run ID");
        Line.SetRange("Run ID", Dataset."Run ID");
        Trace.SetRange("Run ID", Dataset."Run ID");
        Assignment.SetRange("Run ID", Dataset."Run ID");
        Source.SetRange("Run ID", Dataset."Run ID");
        if Recalculated then
            Dataset."Recalc Conflicts" := Result.Count()
        else begin
            Dataset."Full Conflicts" := Result.Count();
            Dataset.Assignments := Assignment.Count();
            Dataset."Source Rows" := Source.Count();
            Dataset."Effective Rows" := Effective.Count();
            Dataset."Origin Lines" := Line.Count();
            Dataset."Trace Rows" := Trace.Count();
        end;
    end;

    local procedure Validate(Dataset: Record "BCG Perf Dataset"; ActiveControls: Integer)
    var
        Users: Record "BCG User Snapshot";
        Assignment: Record "BCG User Perm. Assignment";
        Source: Record "BCG Perm. Set Object Perm.";
        Effective: Record "BCG User Table Data Perm.";
        Result: Record "BCG User Conflict Result";
        Line: Record "BCG User Conflict Result Line";
        Header: Record "BCG Conflict Header";
        UserNo: Integer;
        Expected: Integer;
    begin
        Users.SetRange("Run ID", Dataset."Run ID");
        AssertEqual(Dataset.Users, Users.Count(), 'users');
        Assignment.SetRange("Run ID", Dataset."Run ID");
        AssertEqual(Dataset.Users * Dataset."Assignments per User", Assignment.Count(), 'assignments');
        Source.SetRange("Run ID", Dataset."Run ID");
        AssertEqual(Dataset."Permission Sets" * Dataset."Rows per Set", Source.Count(), 'loaded source rows');
        Effective.SetRange("Run ID", Dataset."Run ID");
        AssertEqual(Dataset."Expected Effective", Effective.Count(), 'effective rows');
        Result.SetRange("Run ID", Dataset."Run ID");
        AssertEqual((Dataset.Users div 4) * ActiveControls, Result.Count(), 'conflicts');
        Line.SetRange("Run ID", Dataset."Run ID");
        AssertEqual((Dataset.Users div 4) * ActiveControls * 2, Line.Count(), 'origin lines');
        for UserNo := 1 to Dataset.Users do begin
            Assignment.SetRange("User Security ID", UserSid(UserNo));
            Assignment.SetRange("Role ID", RoleId(1));
            AssertEqual(1, Assignment.Count(), 'per-user common-read assignment');
            Assignment.FindFirst();
            Assignment.TestField("Company Name", '');
            Result.SetRange("User Security ID", UserSid(UserNo));
            Expected := 0;
            if (UserNo mod 4) = 0 then
                Expected := ActiveControls;
            AssertEqual(Expected, Result.Count(), 'per-user conflicts');
            Effective.Get(Dataset."Run ID", UserSid(UserNo), TargetCompany(), 18);
            Effective.TestField("Can Read", true);
            AssertEqual(Dataset."Assignments per User", Effective."Effective Source Count", 'shared read sources');
        end;
        Effective.Get(Dataset."Run ID", UserSid(1), TargetCompany(), ObjectId(Dataset, 2, 2));
        Effective.TestField("Can Modify", true);
        if Effective.Get(Dataset."Run ID", UserSid(1), TargetCompany(), ObjectId(Dataset, 3, 2)) then
            Error('Clean user unexpectedly has payment access.');
        Result.SetRange("User Security ID");
        if Result.FindSet() then
            repeat
                Header.Get(Result."Conflict Code");
                Header.TestField("Perf Dataset ID", Dataset."Run ID");
                Header.TestField("Is Active", true);
            until Result.Next() = 0;
        // Every evidence line must point to this run's source identity and its own result.
        if Line.FindSet() then
            repeat
                Result.Get(Line."Conflict Result Entry No.");
                Result.TestField("Run ID", Dataset."Run ID");
                Source.Get(Dataset."Run ID", Line."Role ID", Line."App ID", Line."Scope Text", 'Table Data', Line."Object ID");
            until Line.Next() = 0;
    end;

    procedure Cleanup(EntryNo: Integer)
    var
        Dataset: Record "BCG Perf Dataset";
        Header: Record "BCG Conflict Header";
        CleanupMgt: Codeunit "BCG Run Cleanup Mgt.";
    begin
        Guard();
        Dataset.Get(EntryNo);
        if Dataset.State = 'Cleaned' then
            exit;
        EnsureOwned(Dataset);
        Header.SetRange("Perf Dataset ID", Dataset."Run ID");
        Header.DeleteAll(true);
        CleanupMgt.DeleteRun(Dataset."Run ID", true);
        AssertClean(Dataset."Run ID");
        Dataset.State := 'Cleaned';
        Dataset.Modify(); // Keep metrics for comparison, never delete another dataset.
    end;

    procedure RunAll()
    var
        EntryNo: Integer;
    begin
        EntryNo := Generate('SMALL');
        RunFull(EntryNo);
        RunConflictOnly(EntryNo);
        Cleanup(EntryNo);
        Commit();
        EntryNo := Generate('MEDIUM');
        RunFull(EntryNo);
        RunConflictOnly(EntryNo);
        Cleanup(EntryNo);
        Commit();
        EntryNo := Generate('LARGE');
        RunFull(EntryNo);
        RunConflictOnly(EntryNo);
        Cleanup(EntryNo);
    end;

    local procedure AssertEqual(Expected: Integer; Actual: Integer; Context: Text)
    begin
        if Expected <> Actual then
            Error('BCAA-PERF assertion failed (%1): expected %2, actual %3.', Context, Expected, Actual);
    end;

    local procedure AssertClean(RunId: Guid)
    var
        Remaining: RecordRef;
        RunField: FieldRef;
        TableIds: List of [Integer];
        TableId: Integer;
        FieldIndex: Integer;
    begin
        TableIds.Add(Database::"BCG Audit Run");
        TableIds.Add(Database::"BCG User Snapshot");
        TableIds.Add(Database::"BCG User Perm. Assignment");
        TableIds.Add(Database::"BCG Perm. Set Object Perm.");
        TableIds.Add(Database::"BCG User Table Data Perm.");
        TableIds.Add(Database::"BCG User Conflict Result");
        TableIds.Add(Database::"BCG User Conflict Result Line");
        TableIds.Add(Database::"BCG Conflict Source Trace");
        TableIds.Add(Database::"BCG SecGrp Snap");
        TableIds.Add(Database::"BCG SecGrp Member Snap");
        TableIds.Add(Database::"BCG SecGrp Perm Assign");
        foreach TableId in TableIds do begin
            Remaining.Open(TableId);
            for FieldIndex := 1 to Remaining.FieldCount() do begin
                RunField := Remaining.FieldIndex(FieldIndex);
                if RunField.Name = 'Run ID' then begin
                    RunField.SetRange(RunId);
                    if not Remaining.IsEmpty() then
                        Error('Cleanup left records in %1 for %2.', Remaining.Name, RunId);
                end;
            end;
            Remaining.Close();
        end;
    end;

    internal procedure UserSid(UserNo: Integer): Guid
    var
        Sid: Guid;
    begin
        Evaluate(Sid, 'BCAA0000-0000-0000-0000-' + Format(UserNo, 0, '<Integer,12><Filler Character,0>'));
        exit(Sid);
    end;

    local procedure TargetCompany(): Text[30]
    begin
        exit(CopyStr(CompanyName(), 1, 30));
    end;

    local procedure RoleId(RoleNo: Integer): Code[20]
    begin
        exit('BCAA-PERF-R' + Format(RoleNo));
    end;

    local procedure RoleName(RoleNo: Integer): Text[100]
    begin
        case RoleNo of
            1: exit('BCAA-PERF-Common read');
            2: exit('BCAA-PERF-Master data maintenance');
            3: exit('BCAA-PERF-Payments');
            4: exit('BCAA-PERF-Privileged maintenance');
        end;
        case RoleNo mod 3 of
            0: exit('BCAA-PERF-Finance');
            1: exit('BCAA-PERF-Purchasing');
            2: exit('BCAA-PERF-Sales');
        end;
    end;

    local procedure ControlId(Dataset: Record "BCG Perf Dataset"; ControlNo: Integer): Code[20]
    begin
        exit(CopyStr(Dataset."Rule Prefix" + Format(ControlNo), 1, 20));
    end;
}
#endif
