pageextension 50590 "BCG ConfResults User" extends "BCG User Conflict Results"
{
    layout
    {
        addafter("User Security ID")
        {
            field("BCG User Name"; Rec."BCG User Name")
            {
                ApplicationArea = All;
                Caption = 'User Name';
                ToolTip = 'Shows the Business Central user name for the User Security ID.';
            }
        }
    }
}
