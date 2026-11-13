page 50612 "BCG Affected Users"
{
    Caption = 'Affected Users';
    PageType = List;
    SourceTable = "BCG Affected User Buffer";
    SourceTableView = sorting("User Name");
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filters';
                field(FindingsView; OpenFindingsLbl)
                {
                    Caption = 'Findings View';
                    ApplicationArea = All;
                    ToolTip = 'Specifies that this page includes only Open findings for the selected run.';
                }
                field(RunNo; SelectedRunNo)
                {
                    Caption = 'Run No.';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the run used by the Affected Users cue. Refresh keeps this run.';
                }
            }
            repeater(Users)
            {
                field("User Name"; Rec."User Name") { ApplicationArea = All; ToolTip = 'Shows the captured user name when available, otherwise the same name lookup as User Conflict Results. Users are grouped by their security ID, even if a name is unavailable.'; }
                field("Detected Conflict Count"; Rec."Detected Conflict Count")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    ToolTip = 'Specifies the number of distinct conflict codes in this user''s Open findings. Select to open the underlying findings.';
                    trigger OnDrillDown()
                    begin
                        OpenUserFindings(false);
                    end;
                }
                field("Finding Count"; Rec."Finding Count")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    ToolTip = 'Specifies the number of Open result records for this user. Evidence rows do not increase this count.';
                    trigger OnDrillDown()
                    begin
                        OpenUserFindings(false);
                    end;
                }
                field("Company Count"; Rec."Company Count")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    ToolTip = 'Specifies the number of distinct stored company names in this user''s Open findings. Select to open the underlying findings.';
                    trigger OnDrillDown()
                    begin
                        OpenUserFindings(false);
                    end;
                }
                field("High Severity Finding Count"; Rec."High Severity Finding Count")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    ToolTip = 'Specifies the number of Open findings with stored severity High, excluding Critical. Select to open those findings.';
                    trigger OnDrillDown()
                    begin
                        OpenUserFindings(true);
                    end;
                }
                field("Has Special Permissions"; Rec."Has Special Permissions") { ApplicationArea = All; ToolTip = 'Specifies whether any included finding has a stored special permission source.'; }
                field("Has Security Group Findings"; Rec."Has Security Group Findings") { ApplicationArea = All; ToolTip = 'Specifies whether any included finding has a stored security group source, including Mixed findings.'; }
                field("Has Direct Assignments"; Rec."Has Direct Assignments") { ApplicationArea = All; ToolTip = 'Specifies whether any included finding has a stored direct source.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UserFindings)
            {
                Caption = 'Open User Findings';
                ApplicationArea = All;
                Image = Ledger;
                ToolTip = 'Open detailed results for the selected user, run, and Open Findings scope.';
                trigger OnAction()
                begin
                    OpenUserFindings(false);
                end;
            }
            action(Refresh)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Reread Open findings for the selected run without running analysis or changing audit data.';
                trigger OnAction()
                begin
                    ReloadSummary();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReloadSummary();
    end;

    procedure InitializeOpenScope(RunNo: Code[20])
    var
        AffectedUserMgt: Codeunit "BCG Affected User Mgt.";
    begin
        SelectedRunId := AffectedUserMgt.ResolveCueRun(RunNo);
        SelectedRunNo := RunNo;
    end;

    procedure InitializeOpenScope(RunId: Guid)
    begin
        SelectedRunId := RunId;
    end;

    local procedure ReloadSummary()
    var
        AuditRun: Record "BCG Audit Run";
        Findings: Record "BCG User Conflict Result";
        AffectedUserMgt: Codeunit "BCG Affected User Mgt.";
    begin
        if IsNullGuid(SelectedRunId) then
            Error(OpenFromCueLbl);
        if not AuditRun.Get(SelectedRunId) then
            Error(OpenFromCueLbl);
        if AuditRun.Status <> AuditRun.Status::Finished then
            Error(OpenFromCueLbl);
        SelectedRunNo := AuditRun."Run No.";
        AffectedUserMgt.BuildSummary(SelectedRunId, SelectedRunNo, Findings, Rec);
        Rec.SetCurrentKey("User Name");
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    local procedure OpenUserFindings(HighSeverityOnly: Boolean)
    var
        Findings: Record "BCG User Conflict Result";
    begin
        if IsNullGuid(SelectedRunId) or Rec.IsEmpty() then
            exit;
        // Protect the navigation scope when users change views in the detailed page.
        Findings.FilterGroup(10);
        Findings.SetRange("Run ID", SelectedRunId);
        Findings.SetRange("User Security ID", Rec."User Security ID");
        Findings.SetRange(Status, Findings.Status::Open);
        if HighSeverityOnly then
            Findings.SetRange(Severity, Findings.Severity::High);
        Findings.FilterGroup(0);
        // Also expose the identity to the detailed page navigation-scope protection.
        Findings.SetRange("Run ID", SelectedRunId);
        Page.Run(Page::"BCG User Conflict Results", Findings);
    end;

    var
        SelectedRunId: Guid;
        SelectedRunNo: Code[20];
        OpenFindingsLbl: Label 'Open Findings';
        OpenFromCueLbl: Label 'Open Affected Users from the Role Center cue to select its current run and Open Findings scope.';
}
