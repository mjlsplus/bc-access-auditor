pageextension 50529 "BCG SecGrp Member Run No" extends "BCG Security Group Members"
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
