page 50585 "BCG Conflict Source Trace"
{
    Caption = 'Conflict Source Trace';
    PageType = List;
    SourceTable = "BCG Conflict Source Trace";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; }
                field("User Security ID"; Rec."User Security ID") { ApplicationArea = All; ToolTip = 'Specifies the security identifier of the user associated with this historical analysis record.'; }
                field("User Name"; Rec."User Name") { ApplicationArea = All; ToolTip = 'Shows the user name copied into this trace record when available. Special-permission trace records may leave this blank.'; }
                field("User Full Name"; Rec."User Full Name") { ApplicationArea = All; ToolTip = 'Shows the full user name copied into this trace record when available; it is not a live user lookup.'; }
                field("Company Name"; Rec."Company Name") { ApplicationArea = All; ToolTip = 'Specifies the company context recorded for this source trace. A blank assignment company can indicate access across companies.'; }
                field("Permission Source Type"; Rec."Permission Source Type") { ApplicationArea = All; ToolTip = 'Identifies a captured security-group or special-permission source. A trace record alone does not establish that the source contributed to a particular conflict.'; }
                field("Role ID"; Rec."Role ID") { ApplicationArea = All; ToolTip = 'Specifies the permission set recorded for this source trace. A security group assigns permission sets; it is not itself a permission set.'; }
                field("Role Name"; Rec."Role Name") { ApplicationArea = All; ToolTip = 'Shows the permission-set name stored in this trace. The display name may be shortened and may differ from its current name.'; }
                field("Security Group Code"; Rec."Security Group Code") { ApplicationArea = All; ToolTip = 'Specifies the captured security-group identifier for this assignment trace, when available. Special-permission traces may leave it blank.'; }
                field("Security Group Name"; Rec."Security Group Name") { ApplicationArea = All; ToolTip = 'Shows the captured security-group name associated with this assignment trace, when available.'; }
                field("Source Notes"; Rec."Source Notes") { ApplicationArea = All; ToolTip = 'Shows the recorded explanation of this source, including security-group assignment or special-permission details.'; }
                field("Captured At"; Rec."Captured At") { ApplicationArea = All; ToolTip = 'Specifies when this trace record was created during analysis, not when permissions were assigned or last changed.'; }
            }
        }
    }
}
