pageextension 50576 "BCG TPerm Special UX" extends "BCG User Table Data Perms"
{
    layout
    {
        addlast(Group)
        {
            field("Has SUPER"; Rec."Has SUPER")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether this wildcard row includes the SUPER permission set.';
            }

            field("Has SUPER DATA"; Rec."Has SUPER DATA")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether this wildcard row includes the SUPER (DATA) permission set.';
            }

            field("Special Permission Summary"; Rec."Special Permission Summary")
            {
                ApplicationArea = All;
                ToolTip = 'Shows a user-friendly summary of special permissions, for example SUPER + SUPER DATA.';
            }
        }
    }

}
