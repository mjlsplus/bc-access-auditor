page 50582 "BCG Conflict Evidence FactBox"
{
    PageType = ListPart;
    SourceTable = "BCG User Conflict Result Line";
    Caption = 'Conflict Evidence';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Evidence)
            {
                field("Permission Source Summary"; Rec."Permission Source Summary")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the stored description of the permission set and assignment route associated with this evidence, or explains incomplete source attribution.';
                    Caption = 'Source Summary';
                }
                field("Role ID"; Rec."Role ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the captured permission set associated with this evidence line. A blank value means no permission set was resolved for the line.';
                    Caption = 'Permission Set ID';
                }
                field("Matched Permission"; Rec."Matched Permission")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the operations contributed by this source, a special-permission override, or unresolved attribution. One source need not satisfy the entire rule.';
                }
                field("Group Name"; Rec."Group Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SoD rule group represented by this evidence line. This is a conflict-definition group, not a Business Central security group.';
                }
                field("Rule Name"; Rec."Rule Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rule name recorded for this finding. It describes the access requirement evaluated during the analysis.';
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table whose data permissions were evaluated for this evidence line, not a page or report used to access it.';
                    Caption = 'Table Data Name';
                }
                field("Assignment Source Type"; Rec."Assignment Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how the permission set was assigned: directly to the user, through a security group, or both. This is separate from Direct Only permission matching.';
                }
            }
        }
    }
}
