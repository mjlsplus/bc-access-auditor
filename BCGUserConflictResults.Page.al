page 50581 "BCG User Conflict Results"
{
    PageType = List;
    SourceTable = "BCG User Conflict Result";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'User Conflict Results';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; }
                field("User Security ID"; Rec."User Security ID") { ApplicationArea = All; Visible = false; }
                field("Company Name"; Rec."Company Name") { ApplicationArea = All; ToolTip = 'Specifies the company context evaluated for this stored finding. The result reflects the analysis snapshot, not necessarily current access.'; }
                field("Conflict Code"; Rec."Conflict Code") { ApplicationArea = All; ToolTip = 'Specifies the identifier of the SoD conflict definition evaluated in this run. The current definition may have changed since the analysis.'; }
                field("Conflict Name"; Rec."Conflict Name") { ApplicationArea = All; ToolTip = 'Specifies the conflict name recorded when this potential access risk was detected. A finding is not proof of fraud or misconduct.'; }
                field(Severity; Rec.Severity) { ApplicationArea = All; ToolTip = 'Specifies the risk priority copied from the conflict definition when the finding was created; it is not a measure of observed user activity.'; }
                field(Status; Rec.Status) { ApplicationArea = All; Visible = false; }
                field("Detected At"; Rec."Detected At") { ApplicationArea = All; ToolTip = 'Specifies when the analysis created this finding, not when a user performed a business transaction.'; }
                field("Object A ID"; Rec."Object A ID") { ApplicationArea = All; Visible = false; }
                field("Object A Name"; Rec."Object A Name") { ApplicationArea = All; Visible = false; }
                field("Object A Permission"; Rec."Object A Permission") { ApplicationArea = All; Visible = false; }
                field("Object B ID"; Rec."Object B ID") { ApplicationArea = All; Visible = false; }
                field("Object B Name"; Rec."Object B Name") { ApplicationArea = All; Visible = false; }
                field("Object B Permission"; Rec."Object B Permission") { ApplicationArea = All; Visible = false; }
                field("Result Description"; Rec."Result Description") { ApplicationArea = All; ToolTip = 'Shows the stored explanation and any recommendation recorded for this finding. Recommendations do not automatically change user permissions.'; }
            }
        }
        area(FactBoxes)
        {
            part(ConflictEvidence; "BCG Conflict Evidence FactBox")
            {
                ApplicationArea = All;
                Caption = 'Conflict Evidence';
                SubPageLink = "Conflict Result Entry No." = field("Entry No.");
            }
        }
    }

    views
    {
        view(BCGAll)
        {
            Caption = 'All';
        }
        view(BCGOpen)
        {
            Caption = 'Open';
            Filters = where(Status = const(Open));
        }
        view(BCGHighSeverity)
        {
            Caption = 'High Severity';
            Filters = where(Severity = const(High));
        }
        view(BCGSpecialPermissions)
        {
            Caption = 'Special Permissions';
            Filters = where("Has Special Permission Source" = const(true));
        }
        view(BCGSecurityGroupBased)
        {
            Caption = 'Security Group Based';
            Filters = where("Has Security Group Source" = const(true));
        }
        view(BCGDirectAssignments)
        {
            Caption = 'Direct Assignments';
            Filters = where("Has Direct Source" = const(true));
        }
    }
}
