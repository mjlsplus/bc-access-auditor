pageextension 50570 "BCG Conf Results Evidence" extends "BCG User Conflict Results"
{
    layout
    {
        addafter("Conflict Name")
        {
            field("Matched Group Count"; Rec."Matched Group Count")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies how many conflict groups were matched by the user.';
            }
            field("Matched Rule Count"; Rec."Matched Rule Count")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies how many unique rules were matched by the user.';
            }
            field("Matched Object Count"; Rec."Matched Object Count")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies how many unique table data objects were matched by the user.';
            }
            field("Matched Groups Summary"; Rec."Matched Groups Summary")
            {
                ApplicationArea = All;
                ToolTip = 'Shows a summary of matched conflict groups.';
            }
            field("Matched Objects Summary"; Rec."Matched Objects Summary")
            {
                ApplicationArea = All;
                Visible = false;
                ToolTip = 'Shows matched objects grouped by conflict group.';
            }
            field("Matched Permissions Summary"; Rec."Matched Permissions Summary")
            {
                ApplicationArea = All;
                ToolTip = 'Shows matched operations for each table.';
            }
            field("Conflict Evidence Summary"; Rec."Conflict Evidence Summary")
            {
                ApplicationArea = All;
                ToolTip = 'Shows matched tables grouped by conflict group.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(BCGUpdateConflictEvidenceSummary)
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Conflict Evidence Mgt" = X;
                Caption = 'Update Conflict Evidence Summary';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Update evidence summary fields for the selected Run ID based on conflict result lines.';

                trigger OnAction()
                var
                    EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
                begin
                    if IsNullGuid(Rec."Run ID") then
                        Error('Run ID is empty.');

                    EvidenceMgt.UpdateEvidenceForRun(Rec."Run ID");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
