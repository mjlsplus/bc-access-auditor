page 50592 "BCG Conflict Results Source"
{
    Caption = 'Conflict Results - Source View';
    PageType = List;
    SourceTable = "BCG User Conflict Result";
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
                field("User Name"; Rec."BCG User Name") { ApplicationArea = All; ToolTip = 'Shows the current user name looked up by security identifier, not a name preserved in the analysis snapshot. It may be blank if the user no longer exists.'; }
                field("Has Security Group Source"; Rec."Has Security Group Source") { ApplicationArea = All; ToolTip = 'Specifies whether this finding''s evidence records access through a security-group permission-set assignment. Direct assignments may also contribute.'; }
                field("Has Direct Source"; Rec."Has Direct Source") { ApplicationArea = All; ToolTip = 'Specifies whether this finding''s evidence records a permission set assigned directly to the user. This does not mean its table permissions are Direct Only.'; }
                field("Has Special Permission Source"; Rec."Has Special Permission Source") { ApplicationArea = All; ToolTip = 'Specifies whether this finding records a special permission source, such as SUPER or SUPER (DATA), independently of its direct or security-group assignment route.'; }
                field("Primary Permission Source"; Rec."Primary Permission Source") { ApplicationArea = All; ToolTip = 'Summarizes assignment routes recorded in this finding''s evidence: Direct, Security Group, Mixed or Unknown. Special-permission status is shown separately.'; }
                field("Permission Source Summary"; Rec."Permission Source Summary") { ApplicationArea = All; ToolTip = 'Lists captured permission sets by assignment route for this finding. The stored summary can be shortened and does not establish current access.'; }
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
            action("Open Conflict Result Lines Source")
            {
                Caption = 'Open Conflict Result Lines Source';
                ApplicationArea = All;
                ToolTip = 'Open stored source-attribution details for conflict evidence lines. The view is not automatically filtered to the selected finding; filter by run and user.';
                Image = Line;
                RunObject = page "BCG Conflict Lines Source";
            }
        }
    }
}
