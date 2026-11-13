pageextension 50527 "BCG Source Trace Run No" extends "BCG Conflict Source Trace"
{
    layout
    {
        modify("Run ID")
        {
            Visible = false;
        }

        addbefore("User Security ID")
        {
            field("Run No."; Rec."Run No.")
            {
                ApplicationArea = All;
                ToolTip = 'Readable analysis run number.';
            }
        }
    }
}
