page 50512 "BCG Conflict Groups"
{
    PageType = ListPart;
    SourceTable = "BCG Conflict Group";
    SourceTableView = sorting("Conflict ID", Sequence);
    Caption = 'Conflict Groups';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Group No."; Rec."Group No.") { ApplicationArea = All; ToolTip = 'Specifies the identifier that links rule lines to this group within the conflict.'; }
                field("Group Name"; Rec."Group Name") { ApplicationArea = All; ToolTip = 'Specifies the business capability represented by this group. A user must match every active group in the conflict.'; }
                field("Evaluation Logic"; Rec."Evaluation Logic") { ApplicationArea = All; ToolTip = 'Specifies how rules within this group match: Any requires at least one matching rule; All requires every rule. A group without rules does not match.'; }
                field(Sequence; Rec.Sequence) { ApplicationArea = All; ToolTip = 'Specifies the display and evidence ordering of groups within this conflict; it does not change which permissions must match.'; }
                field("Is Active"; Rec."Is Active") { ApplicationArea = All; ToolTip = 'Specifies whether this group participates in future conflict evaluations. Every active group must match; inactive groups are ignored.'; }
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
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Groups");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Groups");
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Groups");
        exit(true);
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
