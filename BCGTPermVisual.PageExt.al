pageextension 50548 "BCG TPerm Visual" extends "BCG User Table Data Perms"
{
    layout
    {
        addafter("User Security ID")
        {
            field("BCG User Name"; Rec."BCG User Name")
            {
                ApplicationArea = All;
                Caption = 'User Name';
                ToolTip = 'Shows the Business Central user name for this user security ID.';
            }
        }

        addafter("Security Filter")
        {
            field("Is Special Permission"; Rec."Is Special Permission")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether this row represents a special wildcard permission such as SUPER or SUPER DATA.';
            }
            field("Special Permission Type"; Rec."Special Permission Type")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the special permission type, such as SUPER or SUPER DATA.';
            }
            field("BCG Assignment Source Type"; Rec."BCG Assignment Source Type")
            {
                ApplicationArea = All;
                Visible = false;
                ToolTip = 'Specifies the source type of the permission assignment.';
            }
            field("Special Perm. Source Summary"; Rec."Special Perm. Source Summary")
            {
                ApplicationArea = All;
                ToolTip = 'Shows all special permission sources used to create this effective wildcard permission.';
            }
            field("Special Permission Notes"; Rec."Special Permission Notes")
            {
                ApplicationArea = All;
                ToolTip = 'Shows explanatory notes for special permission wildcard rows.';
            }
        }
    }
}
