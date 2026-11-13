pageextension 50525 "BCG Table Perm Run No" extends "BCG User Table Data Perms"
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

    actions
    {
        addlast(Processing)
        {
            group("BCG User Process")
            {
                Caption = 'Analysis';
            }

            group("BCG Advanced Repair")
            {
                Caption = 'Advanced';
            }
        }
    }
}
