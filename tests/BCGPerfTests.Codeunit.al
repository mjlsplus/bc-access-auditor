#if BCG_PERF_TESTS
codeunit 50961 "BCG Perf Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SmallRepeatAndIsolation()
    var
        Runner: Codeunit "BCG Perf Runner";
        Dataset: Record "BCG Perf Dataset";
        Other: Record "BCG Perf Dataset";
        Audit: Record "BCG Audit Run";
        Header: Record "BCG Conflict Header";
        Users: Record "BCG User Snapshot";
        Result: Record "BCG User Conflict Result";
        Snapshot: Codeunit "BCG Snapshot Mgt.";
        FirstId: Integer;
        OtherId: Integer;
        CountBefore: Integer;
    begin
        FirstId := Runner.Generate('SMALL');
        OtherId := Runner.Generate('SMALL');
        Other.Get(OtherId);
        Runner.RunFull(OtherId);
        Runner.RunFull(FirstId);
        Runner.RunConflictOnly(FirstId);
        Runner.RunFull(FirstId);
        Dataset.Get(FirstId);
        Dataset.TestField("Full Passed", true);
        if Dataset."Full Conflicts" <> 50 then
            Error('SMALL must produce 50 findings after rerunning full analysis.');
        // An ordinary engine instance must never evaluate synthetic definitions.
        Dataset.Get(FirstId);
        Audit.Get(Dataset."Run ID");
        Audit.Status := Audit.Status::Running;
        Audit.Modify();
        Snapshot.CalculateConflicts(Dataset."Run ID");
        Result.SetRange("Run ID", Dataset."Run ID");
        Result.SetFilter("Conflict Code", '%1', Dataset."Rule Prefix" + '*');
        if not Result.IsEmpty() then
            Error('Normal conflict calculation included synthetic definitions.');
        Users.SetRange("Run ID", Other."Run ID");
        CountBefore := Users.Count();
        Runner.Cleanup(FirstId);
        Runner.Cleanup(FirstId); // Idempotent cleanup.
        if Users.Count() <> CountBefore then
            Error('Cleanup changed another dataset.');
        Audit.Get(Other."Run ID");
        if Audit.Get(Dataset."Run ID") then
            Error('Cleaned audit header remains.');
        Header.SetRange("Perf Dataset ID", Dataset."Run ID");
        if not Header.IsEmpty() then
            Error('Cleaned rules remain.');
        Users.SetRange("Run ID", Dataset."Run ID");
        if not Users.IsEmpty() then
            Error('Cleaned users remain.');
        Runner.RunConflictOnly(OtherId);
        Runner.Cleanup(OtherId);
    end;

    [Test]
    procedure MediumCorrectness()
    begin
        RunScenario('MEDIUM');
    end;

    [Test]
    procedure LargeCorrectness()
    begin
        RunScenario('LARGE');
    end;

    local procedure RunScenario(Scenario: Code[10])
    var
        Runner: Codeunit "BCG Perf Runner";
        EntryNo: Integer;
    begin
        EntryNo := Runner.Generate(Scenario);
        Runner.RunFull(EntryNo);
        Runner.RunConflictOnly(EntryNo);
        Runner.Cleanup(EntryNo);
    end;
}
#endif
