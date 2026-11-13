page 50609 "BCG Affected Findings Part"
{
    Caption = 'Affected Users / Findings';
    PageType = ListPart;
    SourceTable = "BCG User Conflict Result";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Findings)
            {
                field("User Name"; Rec."BCG User Name") { ApplicationArea = All; ToolTip = 'Shows the same user name as the existing User Conflict Results page.'; }
                field("Company Name"; Rec."Company Name") { ApplicationArea = All; ToolTip = 'Specifies the company context of this finding.'; }
                field(Source; Rec."Primary Permission Source") { Caption = 'Source'; ApplicationArea = All; ToolTip = 'Specifies the stored source classification for this finding.'; }
                field(Special; Rec."Has Special Permission Source") { Caption = 'Special'; ApplicationArea = All; ToolTip = 'Specifies whether this finding includes a stored special permission source.'; }
                field("Matched Permissions Summary"; Rec."Matched Permissions Summary") { ApplicationArea = All; ToolTip = 'Shows the existing stored matched permissions summary without recalculating it.'; }
                field("Conflict Evidence Summary"; Rec."Conflict Evidence Summary") { ApplicationArea = All; Visible = false; ToolTip = 'Shows the existing stored evidence summary for this finding.'; }
                field("Detected At"; Rec."Detected At") { ApplicationArea = All; ToolTip = 'Specifies when this finding was recorded.'; }
                field("Captured Explanation"; Rec."Result Description")
                {
                    Caption = 'Captured Explanation';
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Shows the explanation stored with this finding, including any recommendation captured at detection time. It is separate from the current Recommendation.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenDetailedFinding)
            {
                Caption = 'Open Detailed Finding';
                ApplicationArea = All;
                Image = Ledger;
                ToolTip = 'Open the existing detailed results page filtered to exactly the selected finding.';
                trigger OnAction()
                var
                    Finding: Record "BCG User Conflict Result";
                begin
                    if Rec.IsEmpty() then
                        exit;
                    Finding.CopyFilters(Rec);
                    Finding.SetRange("Entry No.", Rec."Entry No.");
                    Page.Run(Page::"BCG User Conflict Results", Finding);
                end;
            }
            action(ShowConflictEvidence)
            {
                Caption = 'Show Conflict Evidence';
                ApplicationArea = All;
                Image = View;
                ToolTip = 'Open existing conflict evidence for exactly the selected finding.';
                trigger OnAction()
                var
                    Evidence: Record "BCG User Conflict Result Line";
                begin
                    if Rec.IsEmpty() then
                        exit;
                    Evidence.SetRange("Conflict Result Entry No.", Rec."Entry No.");
                    Page.Run(Page::"BCG User Conflict Result Line", Evidence);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Do not expose unscoped findings while the parent initializes the part.
        if not ScopeInitialized then begin
            Rec.FilterGroup(10);
            Rec.SetRange("Entry No.", 0);
            Rec.FilterGroup(0);
        end;
    end;

    procedure SetReviewScope(var Findings: Record "BCG User Conflict Result")
    begin
        // Apply the already-filtered Stage A view inside the child page. Group 4
        // remains owned by SubPageLink; custom group 10 prevents widening the review scope.
        Rec.FilterGroup(10);
        Rec.SetView(Findings.GetView(false));
        Rec.FilterGroup(0);
        ScopeInitialized := true;
        CurrPage.Update(false);
    end;

    var
        ScopeInitialized: Boolean;
}
