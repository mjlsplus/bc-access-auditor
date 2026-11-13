pageextension 50598 "BCG Source View Actions" extends "BCG User Table Data Perms"
{
    actions
    {
        addlast("BCG Advanced Repair")
        {
            action("Open Conflict Lines Source View")
            {
                Caption = 'Open Conflict Lines Source View';
                ApplicationArea = All;
                Visible = false;
                Image = Line;
                RunObject = page "BCG Conflict Lines Source";
            }
        }
    }
}
