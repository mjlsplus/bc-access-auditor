pageextension 50584 "BCG Conflict Results Trace" extends "BCG User Conflict Results"
{
    actions
    {
        addlast(Processing)
        {
            action("Show Permission Sources")
            {
                Caption = 'Show Conflict Evidence';
                ApplicationArea = All;
                ToolTip = 'Show which conflict rules were matched and which permission sets granted the required permissions.';

                trigger OnAction()
                var
                    ConflictLine: Record "BCG User Conflict Result Line";
                begin
                    ConflictLine.SetRange("Conflict Result Entry No.", Rec."Entry No.");
                    Page.Run(Page::"BCG User Conflict Result Line", ConflictLine);
                end;
            }
        }
    }
}
