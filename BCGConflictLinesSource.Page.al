page 50593 "BCG Conflict Lines Source"
{
    Caption = 'Conflict Result Lines - Source View';
    PageType = List;
    SourceTable = "BCG User Conflict Result Line";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; ToolTip = 'Specifies the analysis run that produced this stored record. Its captured access information may differ from current permissions.'; }
                field("User Security ID"; Rec."User Security ID") { ApplicationArea = All; ToolTip = 'Specifies the security identifier of the user associated with this historical analysis record.'; }
                field("User Name"; Rec."BCG Source User Name") { ApplicationArea = All; ToolTip = 'Shows the current user name looked up by security identifier, not a name preserved in the analysis snapshot. It may be blank if the user no longer exists.'; }
                field("Permission Source Type"; Rec."Permission Source Type") { ApplicationArea = All; ToolTip = 'Shows the stored source classification, including mixed routes, special permissions or unknown attribution. Use Assignment Source Type to review the assignment route.'; }
                field("Permission Source Summary"; Rec."Permission Source Summary") { ApplicationArea = All; ToolTip = 'Shows the stored description of the permission set and assignment route associated with this evidence, or explains incomplete source attribution.'; }
                field("Source Permission Set ID"; Rec."Source Permission Set ID") { ApplicationArea = All; ToolTip = 'Specifies the permission-set identifier recorded during source attribution for this evidence line. A blank value does not mean the user had no permissions.'; }
                field("Source Permission Set Name"; Rec."Source Permission Set Name") { ApplicationArea = All; ToolTip = 'Shows the permission-set name stored during source attribution. This display name may be shortened and is not a live lookup.'; }
                field("Source Company Name"; Rec."Source Company Name") { ApplicationArea = All; ToolTip = 'Specifies the captured assignment company when attribution is resolved; blank then means all companies. If attribution is unresolved, blank does not establish the assignment scope.'; }
                field("Is From Security Group"; Rec."Is From Security Group") { ApplicationArea = All; ToolTip = 'Specifies whether this evidence line records a security-group assignment route. The same permission set may also be assigned directly.'; }
                field("Security Group Code"; Rec."Security Group Code") { ApplicationArea = All; ToolTip = 'Specifies the captured identifier of a security group associated with this permission-set assignment, when resolved.'; }
                field("Security Group Name"; Rec."Security Group Name") { ApplicationArea = All; ToolTip = 'Specifies the captured name of a security group associated with this permission-set assignment, when resolved.'; }
                field("Is Special Permission Source"; Rec."Is Special Permission Source") { ApplicationArea = All; ToolTip = 'Specifies whether this evidence uses a special permission source, such as SUPER or SUPER (DATA). Its assignment route is recorded separately.'; }
                field("Source Notes"; Rec."Source Notes") { ApplicationArea = All; ToolTip = 'Shows recorded details or limitations of source attribution, including special permissions, unresolved contributors or differing security filters.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Open Conflict Source Trace")
            {
                Caption = 'Open Conflict Source Trace';
                ApplicationArea = All;
                ToolTip = 'Open captured security-group and special-permission trace records. The view is not automatically filtered to the selected finding; filter by run and user.';
                Image = Trace;
                RunObject = page "BCG Conflict Source Trace";
            }
        }
    }
}
