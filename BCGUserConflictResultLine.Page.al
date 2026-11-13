page 50583 "BCG User Conflict Result Line"
{
    PageType = List;
    SourceTable = "BCG User Conflict Result Line";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Conflict Evidence';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Group Name"; Rec."Group Name") { ApplicationArea = All; ToolTip = 'Specifies the SoD rule group represented by this evidence line. This is a conflict-definition group, not a Business Central security group.'; }
                field("Rule Name"; Rec."Rule Name") { ApplicationArea = All; ToolTip = 'Specifies the rule name recorded for this finding. It describes the access requirement evaluated during the analysis.'; }
                field("Rule ID"; Rec."Rule ID") { ApplicationArea = All; ToolTip = 'Specifies the rule identifier recorded for this evidence line. Current rule definitions may differ from those used by this historical run.'; }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table whose data permissions were evaluated for this evidence line, not a page or report used to access it.';
                    Caption = 'Table Data Name';
                }
                field("Required Permission"; Rec."Required Permission") { ApplicationArea = All; ToolTip = 'Shows a shortened summary of the rule requirements recorded for this run. The stored text may omit later operations, grant types or the Any/All setting.'; }
                field("Matched Permission"; Rec."Matched Permission") { ApplicationArea = All; ToolTip = 'Shows the operations contributed by this source, a special-permission override, or unresolved attribution. One source need not satisfy the entire rule.'; }
                field("Role ID"; Rec."Role ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the captured permission set associated with this evidence line. A blank value means no permission set was resolved for the line.';
                    Caption = 'Permission Set ID';
                }
                field("Role Name"; Rec."Role Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the captured name of the permission set associated with this evidence line; it may differ from its current name.';
                    Caption = 'Permission Set Name';
                }
                field("Permission Source Summary"; Rec."Permission Source Summary") { ApplicationArea = All; ToolTip = 'Shows the stored description of the permission set and assignment route associated with this evidence, or explains incomplete source attribution.'; }
                field("Assignment Source Type"; Rec."Assignment Source Type") { ApplicationArea = All; ToolTip = 'Specifies how the permission set was assigned: directly to the user, through a security group, or both. This is separate from Direct Only permission matching.'; }
                field("Permission Source Type"; Rec."Permission Source Type") { ApplicationArea = All; ToolTip = 'Shows the stored source classification, including mixed routes, special permissions or unknown attribution. Use Assignment Source Type to review the assignment route.'; }
                field("Security Group Name"; Rec."Security Group Name") { ApplicationArea = All; ToolTip = 'Specifies the captured name of a security group associated with this permission-set assignment, when resolved.'; }
                field("Company Name"; Rec."Company Name") { ApplicationArea = All; ToolTip = 'Specifies the company context in which the rule matched during this analysis run; this does not establish the user''s current access.'; }
                field("Evaluation Logic"; Rec."Evaluation Logic") { ApplicationArea = All; ToolTip = 'Specifies the recorded group logic: Any requires a matching rule; All requires every rule in the group. This is separate from matching operations within a rule.'; }
                field("Security Filter"; Rec."Security Filter") { ApplicationArea = All; ToolTip = 'Shows captured record-filter text for this source. A blank value does not prove unrestricted access; merged sources may have different filters. Review Source Notes.'; }
                field("Source Notes"; Rec."Source Notes") { ApplicationArea = All; ToolTip = 'Shows recorded details or limitations of source attribution, including special permissions, unresolved contributors or differing security filters.'; }
                field("Conflict Code"; Rec."Conflict Code") { ApplicationArea = All; ToolTip = 'Specifies the SoD conflict identifier associated with this stored evidence line.'; }
                field("Conflict Name"; Rec."Conflict Name") { ApplicationArea = All; ToolTip = 'Specifies the conflict name recorded for this potential access risk. The evidence describes permissions, not actions a user has performed.'; }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Table Data object evaluated by the rule. Evidence may come from a permission on that table or an applicable wildcard grant.';
                    Caption = 'Table Data ID';
                }
                field("Group No."; Rec."Group No.") { ApplicationArea = All; Visible = false; }
                field("Is From Security Group"; Rec."Is From Security Group") { ApplicationArea = All; ToolTip = 'Specifies whether this evidence line records a security-group assignment route. The same permission set may also be assigned directly.'; }
                field("Security Group Code"; Rec."Security Group Code") { ApplicationArea = All; ToolTip = 'Specifies the captured identifier of a security group associated with this permission-set assignment, when resolved.'; }
                field("Is Special Permission Source"; Rec."Is Special Permission Source") { ApplicationArea = All; ToolTip = 'Specifies whether this evidence uses a special permission source, such as SUPER or SUPER (DATA). Its assignment route is recorded separately.'; }
                field("App Name"; Rec."App Name") { ApplicationArea = All; ToolTip = 'Specifies the application name captured with the permission-set assignment, when available. It is not evidence that the user ran that application.'; }
                field("Scope Text"; Rec."Scope Text") { ApplicationArea = All; Visible = false; }
                field("Trace Notes"; Rec."Trace Notes") { ApplicationArea = All; Visible = false; }
                field("Conflict Result Entry No."; Rec."Conflict Result Entry No.") { ApplicationArea = All; Visible = false; }
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; Visible = false; }
                field("User Security ID"; Rec."User Security ID") { ApplicationArea = All; Visible = false; }
            }
        }
    }
}
