page 50511 "BCG Conflict Card"
{
    PageType = Card;
    SourceTable = "BCG Conflict Header";
    Caption = 'Conflict';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Conflict ID"; Rec."Conflict ID") { ApplicationArea = All; ToolTip = 'Specifies the unique identifier linking this SoD conflict to its rule groups and analysis findings.'; }
                field(Name; Rec.Name) { ApplicationArea = All; ToolTip = 'Specifies the business name of a potential access conflict. A matching finding indicates a risk, not confirmed misuse.'; }
                field(Category; Rec.Category) { ApplicationArea = All; ToolTip = 'Specifies the business category used to organize this conflict definition; it does not change permission matching.'; }
                field(Severity; Rec.Severity) { ApplicationArea = All; ToolTip = 'Specifies the risk priority assigned to findings from this definition. It is configured manually, not calculated from user activity.'; }
                field("Is Active"; Rec."Is Active") { ApplicationArea = All; ToolTip = 'Specifies whether future analyses evaluate this conflict. Changing this setting does not alter completed analysis results.'; }
                field(Recommendation; Rec.Recommendation) { ApplicationArea = All; ToolTip = 'Specifies suggested review or mitigation steps for this potential access risk; no access changes are performed automatically.'; MultiLine = true; }
            }
            part(Groups; "BCG Conflict Groups")
            {
                ApplicationArea = All;
                SubPageLink = "Conflict ID" = field("Conflict ID");
            }
            part(GroupRules; "BCG Conflict Group Rules")
            {
                ApplicationArea = All;
                SubPageLink = "Conflict ID" = field("Conflict ID");
            }
        }
    }
    trigger OnOpenPage()
    begin
        if not BCGAccessMgt.CanManageCodeunit(Codeunit::"BCG Snapshot Mgt.") then
            CurrPage.Editable(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Card");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Card");
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Card");
        exit(true);
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
