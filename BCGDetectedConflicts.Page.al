page 50607 "BCG Detected Conflicts"
{
    Caption = 'Detected Conflicts';
    PageType = List;
    SourceTable = "BCG Detected Conflict Buffer";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Selection)
            {
                Caption = 'Filters';
                field(FindingScope; SelectedFindingScope)
                {
                    Caption = 'Findings View';
                    ApplicationArea = All;
                    Editable = false;
                    OptionCaption = 'All Findings,Open Findings';
                    ToolTip = 'Specifies whether the page shows all findings or only open findings for the selected run.';
                }
                field(RunNo; SelectedRunNo)
                {
                    Caption = 'Run No.';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the selected completed run. Use Select Run to review another run; Refresh keeps this selection.';
                }
                field(SeverityFilter; SelectedSeverity)
                {
                    Caption = 'Severity';
                    ApplicationArea = All;
                    OptionCaption = 'All,Low,Medium,High,Critical';
                    ToolTip = 'Filters findings by their stored severity before counts are calculated.';
                    trigger OnValidate()
                    begin
                        ReloadSummary();
                    end;
                }
                field(SpecialPermissionFilter; SelectedSpecialPermission)
                {
                    Caption = 'Special Permission';
                    ApplicationArea = All;
                    OptionCaption = 'All,Yes,No';
                    ToolTip = 'Filters findings by whether they have a stored special permission source, such as SUPER or SUPER (DATA).';
                    trigger OnValidate()
                    begin
                        ReloadSummary();
                    end;
                }
                field(SecurityGroupFilter; SelectedSecurityGroup)
                {
                    Caption = 'Security Group';
                    ApplicationArea = All;
                    OptionCaption = 'All,Yes,No';
                    ToolTip = 'Filters findings by whether they have a stored security group source, including Mixed findings.';
                    trigger OnValidate()
                    begin
                        ReloadSummary();
                    end;
                }
                field(ScopeMessage; ScopeMessage)
                {
                    Caption = 'Information';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = ScopeMessage <> '';
                    ToolTip = 'Explains an empty or unavailable selected scope.';
                }
            }
            repeater(Conflicts)
            {
                Editable = false;
                field("Conflict Code"; Rec."Conflict Code") { ApplicationArea = All; ToolTip = 'Specifies the conflict code stored with the findings.'; }
                field("Conflict Name"; Rec."Conflict Name") { ApplicationArea = All; ToolTip = 'Specifies the captured conflict name, without looking up current setup.'; }
                field(Severity; Rec.Severity) { ApplicationArea = All; ToolTip = 'Specifies the highest stored severity among the included findings.'; }
                field("Affected User Count"; Rec."Affected User Count")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    ToolTip = 'Specifies the number of distinct users in the included findings. A user with findings in two companies counts as one user. Select the count to open the underlying findings.';
                    trigger OnDrillDown()
                    begin
                        OpenCountFindings();
                    end;
                }
                field("Finding Count"; Rec."Finding Count")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    ToolTip = 'Specifies the number of included findings. One user with a finding in each of two companies counts as two findings. Supporting evidence lines do not increase this count. Select the count to open the underlying findings.';
                    trigger OnDrillDown()
                    begin
                        OpenCountFindings();
                    end;
                }
                field("Company Count"; Rec."Company Count")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    ToolTip = 'Specifies the number of distinct stored company names in the included findings. Select the count to open the underlying findings.';
                    trigger OnDrillDown()
                    begin
                        OpenCountFindings();
                    end;
                }
                field("Has Special Permissions"; Rec."Has Special Permissions") { ApplicationArea = All; ToolTip = 'Specifies whether at least one finding for this conflict is supported by a special permission such as SUPER or SUPER (DATA).'; }
                field("Has Direct Assignments"; Rec."Has Direct Assignments") { ApplicationArea = All; ToolTip = 'Specifies whether at least one included finding is supported by permissions assigned directly to the user, based on its stored Direct-source flag.'; }
                field("Has Group Based Findings"; Rec."Has Group Based Findings") { ApplicationArea = All; ToolTip = 'Specifies whether any included finding has a stored security group source flag, including Mixed findings.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectRun)
            {
                Caption = 'Select Run';
                ApplicationArea = All;
                Image = List;
                ToolTip = 'Select a completed analysis run without changing its data.';
                trigger OnAction()
                var
                    AuditRun: Record "BCG Audit Run";
                    AuditRuns: Page "BCG Audit Runs";
                begin
                    AuditRun.SetRange(Status, AuditRun.Status::Finished);
                    AuditRun.SetFilter("Run No.", '<>%1', '');
                    AuditRuns.SetTableView(AuditRun);
                    AuditRuns.LookupMode(true);
                    if AuditRuns.RunModal() = Action::LookupOK then begin
                        AuditRuns.GetRecord(AuditRun);
                        SelectedRunId := AuditRun."Run ID";
                        SelectedRunNo := AuditRun."Run No.";
                        ReloadSummary();
                    end;
                end;
            }
            action(Refresh)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Reread stored findings for the selected run and filters. Does not run analysis or update stored summaries.';
                trigger OnAction()
                begin
                    ReloadSummary();
                end;
            }
            action(ReviewConflict)
            {
                Caption = 'Review Conflict';
                ApplicationArea = All;
                Image = View;
                ToolTip = 'Review the selected conflict and its findings, preserving the selected run and finding filters.';
                trigger OnAction()
                var
                    Findings: Record "BCG User Conflict Result";
                    ConflictReview: Page "BCG Conflict Review";
                begin
                    if IsNullGuid(SelectedRunId) or Rec.IsEmpty() then
                        exit;
                    ApplyFindingFilters(Findings);
                    Findings.SetRange("Conflict Code", Rec."Conflict Code");
                    ConflictReview.InitializeReview(Rec, Findings, SelectedRunNo, Format(SelectedSeverity), Format(SelectedSpecialPermission), Format(SelectedSecurityGroup));
                    ConflictReview.RunModal();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        RunNoMgt: Codeunit "BCG Risk Presentation Mgt.";
    begin
        if not ScopeInitialized then
            RunNoMgt.TryGetCurrentRun(SelectedRunId, SelectedRunNo);
        ReloadSummary();
    end;

    procedure InitializeScope(RunId: Guid; SeverityFilter: Option All,Low,Medium,High,Critical; SpecialPermissionFilter: Option All,Yes,No; SecurityGroupFilter: Option All,Yes,No)
    begin
        SelectedRunId := RunId;
        SelectedSeverity := SeverityFilter;
        SelectedSpecialPermission := SpecialPermissionFilter;
        SelectedSecurityGroup := SecurityGroupFilter;
        SelectedFindingScope := SelectedFindingScope::All;
        ScopeInitialized := true;
    end;

    procedure InitializeOpenScope(RunId: Guid)
    begin
        InitializeScope(RunId, SelectedSeverity::All, SelectedSpecialPermission::All, SelectedSecurityGroup::All);
        SelectedFindingScope := SelectedFindingScope::Open;
    end;

    local procedure ReloadSummary()
    var
        AuditRun: Record "BCG Audit Run";
        Findings: Record "BCG User Conflict Result";
        PresentationMgt: Codeunit "BCG Risk Presentation Mgt.";
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Clear(ScopeMessage);
        if IsNullGuid(SelectedRunId) then begin
            ScopeMessage := SelectRunLbl;
            CurrPage.Update(false);
            exit;
        end;
        if not AuditRun.Get(SelectedRunId) then begin
            ScopeMessage := RunUnavailableLbl;
            CurrPage.Update(false);
            exit;
        end;
        if AuditRun.Status <> AuditRun.Status::Finished then begin
            ScopeMessage := RunUnavailableLbl;
            CurrPage.Update(false);
            exit;
        end;
        SelectedRunNo := AuditRun."Run No.";
        ApplyFindingFilters(Findings);
        PresentationMgt.BuildSummary(SelectedRunId, Findings, Rec);
        if not Rec.FindFirst() then
            ScopeMessage := NoFindingsLbl;
        CurrPage.Update(false);
    end;

    local procedure OpenCountFindings()
    var
        Findings: Record "BCG User Conflict Result";
    begin
        // Shared navigation for count drill-downs.
        if IsNullGuid(SelectedRunId) or Rec.IsEmpty() then
            exit;
        ApplyFindingFilters(Findings);
        Findings.SetRange("Conflict Code", Rec."Conflict Code");
        Page.Run(Page::"BCG User Conflict Results", Findings);
    end;

    local procedure ApplyFindingFilters(var Findings: Record "BCG User Conflict Result")
    begin
        Findings.SetRange("Run ID", SelectedRunId);
        // Keep navigation scope protected in detailed pages as well as in the
        // current view copied into the review ListPart.
        Findings.FilterGroup(10);
        Findings.SetRange(Status);
        if SelectedFindingScope = SelectedFindingScope::Open then
            Findings.SetRange(Status, Findings.Status::Open);
        Findings.FilterGroup(0);
        Findings.SetRange(Status);
        if SelectedFindingScope = SelectedFindingScope::Open then
            Findings.SetRange(Status, Findings.Status::Open);
        Findings.SetRange(Severity);
        case SelectedSeverity of
            SelectedSeverity::Low:
                Findings.SetRange(Severity, Findings.Severity::Low);
            SelectedSeverity::Medium:
                Findings.SetRange(Severity, Findings.Severity::Medium);
            SelectedSeverity::High:
                Findings.SetRange(Severity, Findings.Severity::High);
            SelectedSeverity::Critical:
                Findings.SetRange(Severity, Findings.Severity::Critical);
        end;
        Findings.SetRange("Has Special Permission Source");
        if SelectedSpecialPermission <> SelectedSpecialPermission::All then
            Findings.SetRange("Has Special Permission Source", SelectedSpecialPermission = SelectedSpecialPermission::Yes);
        Findings.SetRange("Has Security Group Source");
        if SelectedSecurityGroup <> SelectedSecurityGroup::All then
            Findings.SetRange("Has Security Group Source", SelectedSecurityGroup = SelectedSecurityGroup::Yes);
    end;

    var
        ScopeInitialized: Boolean;
        SelectedFindingScope: Option All,Open;
        SelectedRunId: Guid;
        SelectedRunNo: Code[20];
        SelectedSeverity: Option All,Low,Medium,High,Critical;
        SelectedSpecialPermission: Option All,Yes,No;
        SelectedSecurityGroup: Option All,Yes,No;
        ScopeMessage: Text[250];
        SelectRunLbl: Label 'No unambiguous completed run is selected. Use Select Run to choose a completed run.';
        RunUnavailableLbl: Label 'The selected run is unavailable or is no longer Finished. Select another run; no automatic switch was made.';
        NoFindingsLbl: Label 'No findings match the selected run and finding filters.';
}
