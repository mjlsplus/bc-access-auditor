pageextension 50533 "BCG SecGrp Perm Run No" extends "BCG SecGrp Permissions"
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
