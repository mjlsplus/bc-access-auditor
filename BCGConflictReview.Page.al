page 50608 "BCG Conflict Review"
{
    Caption = 'Conflict Review';
    DataCaptionExpression = SelectedRunNo + ' - ' + Rec."Conflict Code";
    PageType = Card;
    SourceTable = "BCG Detected Conflict Buffer";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Detected Conflict';
                field(RunNo; SelectedRunNo) { Caption = 'Run No.'; ApplicationArea = All; ToolTip = 'Specifies the run selected on Detected Conflicts. Opening this review does not select a newer run.'; }
                field(ReviewContext; ReviewContextText)
                {
                    Caption = 'Review Context';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Shows the inherited findings view and filters for this review and its detailed findings. The selected run remains unchanged.';
                }
                field(SummaryNote; Rec."Summary Note")
                {
                    Caption = 'Summary Note';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    Visible = Rec."Summary Note" <> '';
                    ToolTip = 'Shows the existing summary explanation when stored names or severities differ among the included findings.';
                }
                field(SeverityFilter; SeverityFilterCaption) { Caption = 'Severity Filter'; ApplicationArea = All; Visible = false; ToolTip = 'Specifies the stored severity filter applied to this summary and its findings.'; }
                field(SpecialPermissionFilter; SpecialPermissionFilterCaption) { Caption = 'Special Permission Filter'; ApplicationArea = All; Visible = false; ToolTip = 'Specifies whether findings with a special permission source are included: All, Yes, or No.'; }
                field(SecurityGroupFilter; SecurityGroupFilterCaption) { Caption = 'Security Group Filter'; ApplicationArea = All; Visible = false; ToolTip = 'Specifies whether findings with a security group source are included: All, Yes, or No.'; }
                field("Conflict Code"; Rec."Conflict Code") { ApplicationArea = All; ToolTip = 'Specifies the conflict code captured in the selected results.'; }
                field("Conflict Name"; Rec."Conflict Name") { ApplicationArea = All; ToolTip = 'Specifies the stored name shown on the selected Stage A summary.'; }
                field(Severity; Rec.Severity) { ApplicationArea = All; ToolTip = 'Specifies the stored severity shown on the selected Stage A summary.'; }
                field("Affected User Count"; Rec."Affected User Count") { ApplicationArea = All; ToolTip = 'Specifies the distinct user count from the selected Stage A summary.'; }
                field("Finding Count"; Rec."Finding Count") { ApplicationArea = All; ToolTip = 'Specifies the finding count from the selected Stage A summary.'; }
                field("Company Count"; Rec."Company Count") { ApplicationArea = All; ToolTip = 'Specifies the distinct company count from the selected Stage A summary.'; }
                field("Has Special Permissions"; Format(Rec."Has Special Permissions")) { Caption = 'Has Special Permissions'; ApplicationArea = All; ToolTip = 'Specifies whether at least one included finding is supported by a special permission such as SUPER or SUPER (DATA).'; }
                field("Has Group Based Findings"; Format(Rec."Has Group Based Findings")) { Caption = 'Has Security Group Based Findings'; ApplicationArea = All; ToolTip = 'Specifies whether at least one included finding is supported by permissions assigned through a security group, including Mixed findings.'; }
                field("Has Direct Assignments"; Format(Rec."Has Direct Assignments")) { Caption = 'Has Direct Assignments'; ApplicationArea = All; ToolTip = 'Specifies whether at least one included finding is supported by permissions assigned directly to the user. Uses the summary from Detected Conflicts.'; }
            }
            group(Guidance)
            {
                Caption = 'Current Recommendation';
                field(CurrentRecommendation; CurrentRecommendation)
                {
                    Caption = 'Current Recommendation';
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Shows the current configured guidance for this conflict, if available. It may differ from the explanation captured when the historical finding was detected.';
                }
            }
            part(Findings; "BCG Affected Findings Part")
            {
                Caption = 'Affected Users / Findings';
                ApplicationArea = All;
                SubPageLink = "Run ID" = field("Run ID"), "Conflict Code" = field("Conflict Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenAllDetailedFindings)
            {
                Caption = 'Open All Detailed Findings';
                ApplicationArea = All;
                Image = Ledger;
                ToolTip = 'Open existing detailed results for this review scope, preserving its run, conflict, and finding filters.';
                trigger OnAction()
                var
                    Findings: Record "BCG User Conflict Result";
                begin
                    Findings.CopyFilters(ReviewScope);
                    Page.Run(Page::"BCG User Conflict Results", Findings);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        ConflictSetup: Record "BCG Conflict Header";
    begin
        if not ScopeInitialized then
            Error(SelectConflictLbl);

        // Setup is optional current guidance, never the source of the historical header.
        if StrLen(Rec."Conflict Code") <= MaxStrLen(ConflictSetup."Conflict ID") then
            if ConflictSetup.Get(Rec."Conflict Code") then
                CurrentRecommendation := ConflictSetup.Recommendation;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Findings.Page.SetReviewScope(ReviewScope);
    end;

    procedure InitializeReview(Summary: Record "BCG Detected Conflict Buffer"; var Findings: Record "BCG User Conflict Result"; RunNo: Code[20]; SeverityCaption: Text; SpecialPermissionCaption: Text; SecurityGroupCaption: Text)
    begin
        if IsNullGuid(Summary."Run ID") then
            Error(SelectConflictLbl);
        Rec.Reset();
        Rec.DeleteAll();
        Rec := Summary;
        Rec.Insert();
        Rec.SetRange("Run ID", Summary."Run ID");
        Rec.SetRange("Conflict Code", Summary."Conflict Code");
        ReviewScope.Reset();
        ReviewScope.CopyFilters(Findings);
        ReviewScope.SetRange("Run ID", Summary."Run ID");
        ReviewScope.SetRange("Conflict Code", Summary."Conflict Code");
        SelectedRunNo := RunNo;
        SeverityFilterCaption := SeverityCaption;
        SpecialPermissionFilterCaption := SpecialPermissionCaption;
        SecurityGroupFilterCaption := SecurityGroupCaption;
        if ReviewScope.GetFilter(Status) = '' then
            ReviewContextText := AllFindingsLbl
        else
            ReviewContextText := OpenFindingsLbl;
        ReviewContextText := StrSubstNo(ReviewContextLbl, ReviewContextText, SeverityFilterCaption, SpecialPermissionFilterCaption, SecurityGroupFilterCaption);
        Clear(CurrentRecommendation);
        ScopeInitialized := true;
    end;

    var
        ReviewScope: Record "BCG User Conflict Result";
        SelectedRunNo: Code[20];
        SeverityFilterCaption: Text;
        SpecialPermissionFilterCaption: Text;
        SecurityGroupFilterCaption: Text;
        CurrentRecommendation: Text[250];
        ScopeInitialized: Boolean;
        ReviewContextText: Text;
        AllFindingsLbl: Label 'All Findings';
        OpenFindingsLbl: Label 'Open Findings';
        ReviewContextLbl: Label 'View: %1 | Severity: %2 | Special: %3 | Security Group: %4', Comment = '%1 = inherited findings view, %2 = severity filter, %3 = special permission filter, %4 = security group filter.';
        SelectConflictLbl: Label 'Select a detected conflict to open Conflict Review.';
}
