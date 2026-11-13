page 50597 "BCG Security Group Members"
{
    PageType = List;
    SourceTable = "BCG SecGrp Member Snap";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Security Group Members';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; }
                field("Security Group Code"; Rec."Security Group Code") { ApplicationArea = All; ToolTip = 'Specifies the security-group code associated with this captured membership record.'; }
                field("Security Group Name"; Rec."Security Group Name") { ApplicationArea = All; ToolTip = 'Shows the security-group name stored with this membership snapshot; the current name may differ.'; }
                field("User Security ID"; Rec."User Security ID") { ApplicationArea = All; ToolTip = 'Specifies the technical Business Central user identifier of the captured member, not the group identifier or a business account number.'; }
                field("User Name"; Rec."User Name") { ApplicationArea = All; ToolTip = 'Shows the user name stored for this captured member. The snapshot does not establish current group membership.'; }
                field("User Full Name"; Rec."User Full Name") { ApplicationArea = All; ToolTip = 'Shows the full user name stored with this membership snapshot, not a live lookup of the current user.'; }
                field("Captured At"; Rec."Captured At") { ApplicationArea = All; ToolTip = 'Specifies when this membership record was captured, not when the user joined the group.'; }
            }
        }
    }
}
