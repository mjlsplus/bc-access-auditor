page 50596 "BCG Security Groups"
{
    PageType = List;
    SourceTable = "BCG SecGrp Snap";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Security Groups';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; }
                field("Security Group Code"; Rec."Security Group Code") { ApplicationArea = All; ToolTip = 'Specifies the Business Central security-group code captured in this run. It identifies a group, not a permission set.'; }
                field("Group Name"; Rec."Group Name") { ApplicationArea = All; ToolTip = 'Shows the group name stored when this snapshot was captured. The current name may differ.'; }
                field("Group User SID"; Rec."Group User SID") { ApplicationArea = All; ToolTip = 'Specifies the captured security identifier used to locate the group''s permission-set assignments in Business Central. It is not an individual member''s user identifier.'; }
                field("Group ID"; Rec."Group ID") { ApplicationArea = All; ToolTip = 'Specifies the technical group identifier returned by Business Central during capture, distinct from the group code and individual member identifiers.'; }
                field("Retrieved Successfully"; Rec."Retrieved Successfully") { ApplicationArea = All; ToolTip = 'Shows the group-retrieval status reported by Business Central during capture. Success does not guarantee complete membership or permission coverage.'; }
                field("Captured At"; Rec."Captured At") { ApplicationArea = All; ToolTip = 'Specifies when this group snapshot was stored, not when the group or its permissions were last changed.'; }
            }
        }
    }
}
