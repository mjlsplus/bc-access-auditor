page 50510 "BCG Conflicts"
{
    PageType = List;
    SourceTable = "BCG Conflict Header";
    Caption = 'Conflicts';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "BCG Conflict Card";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Conflict ID"; Rec."Conflict ID") { ApplicationArea = All; ToolTip = 'Specifies the unique identifier linking this SoD conflict to its rule groups and analysis findings.'; }
                field("Is Active"; Rec."Is Active") { ApplicationArea = All; ToolTip = 'Specifies whether future analyses evaluate this conflict. Changing this setting does not alter completed analysis results.'; }
                field(Severity; Rec.Severity) { ApplicationArea = All; ToolTip = 'Specifies the risk priority assigned to findings from this definition. It is configured manually, not calculated from user activity.'; }
                field(Name; Rec.Name) { ApplicationArea = All; ToolTip = 'Specifies the business name of a potential access conflict. A matching finding indicates a risk, not confirmed misuse.'; }
                field(Category; Rec.Category) { ApplicationArea = All; ToolTip = 'Specifies the business category used to organize this conflict definition; it does not change permission matching.'; }
                field(Recommendation; Rec.Recommendation) { ApplicationArea = All; ToolTip = 'Specifies suggested review or mitigation steps for this potential access risk; no access changes are performed automatically.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenWizard)
            {
                Caption = 'New SoD Conflict Wizard';
                Visible = CanManageDefinitions;
                AccessByPermission = tabledata "BCG Setup" = M;
                ApplicationArea = All;
                ToolTip = 'Create a conflict with two sides of Table Data permission requirements. Both groups must match for a user to produce a potential SoD finding.';
                Image = CreateDocument;
                RunObject = page "BCG Simple Wizard";
            }
        }
    }
    trigger OnOpenPage()
    begin
        CanManageDefinitions := BCGAccessMgt.CanManageCodeunit(Codeunit::"BCG Snapshot Mgt.");
        if not CanManageDefinitions then
            CurrPage.Editable(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflicts");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflicts");
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflicts");
        exit(true);
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
        CanManageDefinitions: Boolean;
}
