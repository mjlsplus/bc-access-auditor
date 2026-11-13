page 50524 "BCG User Table Data Perms"
{
    PageType = List;
    SourceTable = "BCG User Table Data Perm.";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'User Table Data Permissions';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; }
                field("User Security ID"; Rec."User Security ID") { ApplicationArea = All; Visible = false; }
                field("Company Name"; Rec."Company Name") { ApplicationArea = All; ToolTip = 'Specifies the company context for these calculated permissions. Blank represents the all-company context; this snapshot does not establish current access.'; }
                field("Object ID"; Rec."Object ID") { ApplicationArea = All; ToolTip = 'Specifies the Table Data object represented by this calculated row. Zero represents a wildcard, including special permissions such as SUPER or SUPER (DATA).'; }
                field("Object Name"; Rec."Object Name") { ApplicationArea = All; ToolTip = 'Shows the table name stored for this calculated permission row. Special-permission wildcard rows can represent all Table Data objects.'; }
                field("Can Read"; Rec."Can Read") { ApplicationArea = All; ToolTip = 'Indicates calculated permission to read records from captured direct or indirect grants, including special permissions where applicable. It is not a direct-assignment flag or a guarantee of current access.'; }
                field("Can Insert"; Rec."Can Insert") { ApplicationArea = All; ToolTip = 'Indicates calculated permission to create records from captured direct or indirect grants, including special permissions where applicable. It is not a direct-assignment flag or a guarantee of current access.'; }
                field("Can Modify"; Rec."Can Modify") { ApplicationArea = All; ToolTip = 'Indicates calculated permission to change records from captured direct or indirect grants, including special permissions where applicable. It is not a direct-assignment flag or a guarantee of current access.'; }
                field("Can Delete"; Rec."Can Delete") { ApplicationArea = All; ToolTip = 'Indicates calculated permission to delete records from captured direct or indirect grants, including special permissions where applicable. It is not a direct-assignment flag or a guarantee of current access.'; }
                field("Security Filter"; Rec."Security Filter") { ApplicationArea = All; ToolTip = 'Shows captured filter text retained on this calculated row, not a complete combination of source restrictions. A blank value does not guarantee unrestricted access.'; }
                field("Effective Source Count"; Rec."Effective Source Count") { ApplicationArea = All; ToolTip = 'Counts distinct captured permission-set identities contributing Table Data access, distinguished by set, app and scope. Repeated assignment routes do not count as separate sources.'; }
            }
        }
    }
}
