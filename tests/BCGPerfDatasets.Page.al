#if BCG_PERF_TESTS
page 50960 "BCG Perf Datasets"
{
    Caption = 'BCAA Performance Tests (Sandbox)';
    PageType = List;
    SourceTable = "BCG Perf Dataset";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Results)
            {
                field(Id; Rec."Entry No.") { ApplicationArea = All; }
                field(RunId; Rec."Run ID") { ApplicationArea = All; }
                field(Scenario; Rec.Scenario) { ApplicationArea = All; }
                field(State; Rec.State) { ApplicationArea = All; }
                field(FullPassed; Rec."Full Passed") { ApplicationArea = All; }
                field(RecalcPassed; Rec."Recalc Passed") { ApplicationArea = All; }
                field(Users; Rec.Users) { ApplicationArea = All; }
                field(Companies; Rec.Companies) { ApplicationArea = All; }
                field(Sets; Rec."Permission Sets") { ApplicationArea = All; }
                field(Assignments; Rec.Assignments) { ApplicationArea = All; }
                field(SourceRows; Rec."Source Rows") { ApplicationArea = All; }
                field(EffectiveRows; Rec."Effective Rows") { ApplicationArea = All; }
                field(ExpectedEffective; Rec."Expected Effective") { ApplicationArea = All; }
                field(OriginLines; Rec."Origin Lines") { ApplicationArea = All; }
                field(TraceRows; Rec."Trace Rows") { ApplicationArea = All; }
                field(Controls; Rec.Controls) { ApplicationArea = All; }
                field(FullConflicts; Rec."Full Conflicts") { ApplicationArea = All; }
                field(RecalcConflicts; Rec."Recalc Conflicts") { ApplicationArea = All; }
                field(FullMs; Rec."Full Time" / 1) { ApplicationArea = All; Caption = 'Full ms'; DecimalPlaces = 0; }
                field(CoreMs; Rec."Conflict Only Time" / 1) { ApplicationArea = All; Caption = 'Conflict engine only ms'; DecimalPlaces = 0; }
                field(RecalcMs; Rec."Existing Recalc Time" / 1) { ApplicationArea = All; Caption = 'Existing recalculation ms'; DecimalPlaces = 0; }
                field(SnapshotMs; Rec."Snapshot Time" / 1) { ApplicationArea = All; Caption = 'Snapshot ms'; DecimalPlaces = 0; }
                field(AssignmentsMs; Rec."Assignment Time" / 1) { ApplicationArea = All; Caption = 'Assignments ms'; DecimalPlaces = 0; }
                field(LoadMs; Rec."Permission Load Time" / 1) { ApplicationArea = All; Caption = 'Permission load ms'; DecimalPlaces = 0; }
                field(EffectiveMs; Rec."Effective Time" / 1) { ApplicationArea = All; Caption = 'Effective ms'; DecimalPlaces = 0; }
                field(ConflictMs; Rec."Conflict Time" / 1) { ApplicationArea = All; Caption = 'Conflicts and origins ms'; DecimalPlaces = 0; }
                field(TraceMs; Rec."Trace Summary Time" / 1) { ApplicationArea = All; Caption = 'Trace and summaries ms'; DecimalPlaces = 0; }
                field(FinalMs; Rec."Finalization Time" / 1) { ApplicationArea = All; Caption = 'Finalization ms'; DecimalPlaces = 0; }
                field(Cap; Rec."Estimated Row Cap") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Small)
            {
                Caption = 'Generate SMALL';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Runner.Generate('SMALL');
                    CurrPage.Update(false);
                end;
            }
            action(Medium)
            {
                Caption = 'Generate MEDIUM';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Runner.Generate('MEDIUM');
                    CurrPage.Update(false);
                end;
            }
            action(Large)
            {
                Caption = 'Generate LARGE';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Runner.Generate('LARGE');
                    CurrPage.Update(false);
                end;
            }
            action(Full)
            {
                Caption = 'Run Full Test';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Runner.RunFull(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
            action(Conflicts)
            {
                Caption = 'Run Conflict-only Test';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Runner.RunConflictOnly(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
            action(AllScenarios)
            {
                Caption = 'Run All and Cleanup';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Runner.RunAll();
                    CurrPage.Update(false);
                end;
            }
            action(Cleanup)
            {
                Caption = 'Cleanup Selected Dataset';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Runner.Cleanup(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        Runner.Guard();
    end;
    var
        Runner: Codeunit "BCG Perf Runner";
}
#endif
