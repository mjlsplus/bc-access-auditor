pageextension 50528 "BCG SecGrp Snap Run No" extends "BCG Security Groups"
{
    layout
    {
        modify("Run ID")
        {
            Visible = false;
        }

        addbefore("Security Group Code")
        {
            field("Run No."; Rec."Run No.")
            {
                ApplicationArea = All;
                ToolTip = 'Readable analysis run number.';
            }
        }
    }
}
