pageextension 50562 "BCG ConfRes Src Columns" extends "BCG User Conflict Results"
{
    layout
    {
        addafter(Severity)
        {
            field("Primary Permission Source"; Rec."Primary Permission Source")
            {
                ApplicationArea = All;
                ToolTip = 'Summarizes assignment routes recorded in this finding''s evidence: Direct, Security Group, Mixed or Unknown. Special-permission status is shown separately.';
                Caption = 'Source';
            }
            field("Permission Source Summary"; Rec."Permission Source Summary")
            {
                ApplicationArea = All;
                ToolTip = 'Lists captured permission sets by assignment route for this finding. The stored summary can be shortened and does not establish current access.';
                Caption = 'Source Summary';
            }
            field("Has Direct Source"; Rec."Has Direct Source")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether this finding''s evidence records a permission set assigned directly to the user. This does not mean its table permissions are Direct Only.';
                Caption = 'Direct';
            }
            field("Has Security Group Source"; Rec."Has Security Group Source")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether this finding''s evidence records access through a security-group permission-set assignment. Direct assignments may also contribute.';
                Caption = 'Security Group';
                Style = Ambiguous;
                StyleExpr = Rec."Has Security Group Source";
            }
            field("Has Special Permission Source"; Rec."Has Special Permission Source")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether this finding records a special permission source, such as SUPER or SUPER (DATA), independently of its direct or security-group assignment route.';
                Caption = 'Special';
                Style = Unfavorable;
                StyleExpr = Rec."Has Special Permission Source";
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("Update Source Summary")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Conflict Src Summary" = X;
                ApplicationArea = All;
                Caption = 'Update Source Summary';
                Image = Refresh;
                ToolTip = 'Updates source flags and summary on conflict result headers for the selected Run ID.';

                trigger OnAction()
                var
                    SourceSummaryMgt: Codeunit "BCG Conflict Src Summary";
                begin
                    SourceSummaryMgt.UpdateConflictResultSourcesForRun(Rec."Run ID");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
