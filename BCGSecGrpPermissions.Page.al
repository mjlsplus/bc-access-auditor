page 50598 "BCG SecGrp Permissions"
{
    PageType = List;
    SourceTable = "BCG SecGrp Perm Assign";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Security Group Permission Assignments';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; }
                field("User Name"; Rec."User Name") { ApplicationArea = All; ToolTip = 'Shows the stored name of the user whose permission-set assignment was derived from captured group membership; it does not establish current access.'; }
                field("User Full Name"; Rec."User Full Name") { ApplicationArea = All; ToolTip = 'Shows the full user name stored with this derived assignment, not a live lookup.'; }
                field("User Security ID"; Rec."User Security ID") { ApplicationArea = All; ToolTip = 'Specifies the technical Business Central user identifier of the member receiving the captured assignment, not the group''s security identifier.'; }
                field("Security Group Code"; Rec."Security Group Code") { ApplicationArea = All; ToolTip = 'Specifies the captured group through which this permission set was assigned to the user.'; }
                field("Security Group Name"; Rec."Security Group Name") { ApplicationArea = All; ToolTip = 'Shows the group name stored for this assignment route. Membership and group names may have changed since capture.'; }
                field("Company Name"; Rec."Company Name") { ApplicationArea = All; ToolTip = 'Specifies the company scope captured for the group''s permission-set assignment. Blank means the assignment applies across companies.'; }
                field("Role ID"; Rec."Role ID") { ApplicationArea = All; ToolTip = 'Specifies the permission set assigned through the captured group. This is an assignment record, not a calculated effective Table Data permission.'; }
                field("Role Name"; Rec."Role Name") { ApplicationArea = All; ToolTip = 'Shows the permission-set name stored with the group assignment; it may be shortened or differ from the current name.'; }
                field("Scope"; Rec."Scope") { ApplicationArea = All; ToolTip = 'Specifies the captured permission-set scope, System or Tenant. This identifies the permission-set definition, not the company scope.'; }
                field("App Name"; Rec."App Name") { ApplicationArea = All; ToolTip = 'Shows the application name captured with the permission-set assignment, when available; it does not indicate that the user ran the application.'; }
                field("Assignment Source Type"; Rec."Assignment Source Type") { ApplicationArea = All; ToolTip = 'Identifies this derived assignment as coming through a security group. This is separate from direct or indirect Table Data permission grants.'; }
                field("Captured At"; Rec."Captured At") { ApplicationArea = All; ToolTip = 'Specifies when this derived group assignment was stored, not when permissions were assigned or last changed.'; }
            }
        }
    }
}
