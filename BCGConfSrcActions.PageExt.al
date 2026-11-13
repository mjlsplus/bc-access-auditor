pageextension 50587 "BCG ConfSrc Actions" extends "BCG User Table Data Perms"
{
    actions
    {
        addlast("BCG Advanced Repair")
        {
            action("Open Conflict Source Trace")
            {
                Caption = 'Open Conflict Source Trace';
                ApplicationArea = All;
                Visible = false;
                Image = List;
                RunObject = page "BCG Conflict Source Trace";
            }
        }
    }
}
