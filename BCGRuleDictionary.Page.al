page 50514 "BCG Rule Dictionary"
{
    PageType = List;
    SourceTable = "BCG Rule Dictionary";
    Caption = 'Rule Dictionary';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Rule ID"; Rec."Rule ID") { ApplicationArea = All; ToolTip = 'Specifies the unique identifier used to select and copy this permission rule into conflict groups.'; }
                field("Rule Name"; Rec."Rule Name") { ApplicationArea = All; ToolTip = 'Specifies the business capability represented by this Table Data permission rule.'; }
                field("Object ID"; Rec."Object ID") { ApplicationArea = All; ToolTip = 'Specifies the table whose data permissions are checked by this rule, not a page or report that displays the data.'; Caption = 'Table Data ID'; }
                field("Object Caption"; Rec."Object Caption") { ApplicationArea = All; ToolTip = 'Specifies the name of the table selected for the permission check.'; Caption = 'Table Data Name'; }
                field("Requires Read"; Rec."Requires Read") { ApplicationArea = All; ToolTip = 'Specifies whether permission to view records is included in this rule. Permission Match Mode determines whether any or all selected operations must match.'; }
                field("Read Permission Match"; Rec."Read Permission Match") { ApplicationArea = All; ToolTip = 'Specifies read matching: Direct Only accepts a direct grant; Direct or Indirect also accepts an indirect grant. This concerns the permission level, not direct versus security-group assignment.'; }
                field("Requires Insert"; Rec."Requires Insert") { ApplicationArea = All; ToolTip = 'Specifies whether permission to create records is included in this rule. Permission Match Mode determines whether any or all selected operations must match.'; }
                field("Insert Permission Match"; Rec."Insert Permission Match") { ApplicationArea = All; ToolTip = 'Specifies insert matching: Direct Only accepts a direct grant; Direct or Indirect also accepts an indirect grant. This concerns the permission level, not direct versus security-group assignment.'; }
                field("Requires Modify"; Rec."Requires Modify") { ApplicationArea = All; ToolTip = 'Specifies whether permission to change existing records is included in this rule. Permission Match Mode determines whether any or all selected operations must match.'; }
                field("Modify Permission Match"; Rec."Modify Permission Match") { ApplicationArea = All; ToolTip = 'Specifies modify matching: Direct Only accepts a direct grant; Direct or Indirect also accepts an indirect grant. This concerns the permission level, not direct versus security-group assignment.'; }
                field("Requires Delete"; Rec."Requires Delete") { ApplicationArea = All; ToolTip = 'Specifies whether permission to remove records is included in this rule. Permission Match Mode determines whether any or all selected operations must match.'; }
                field("Delete Permission Match"; Rec."Delete Permission Match") { ApplicationArea = All; ToolTip = 'Specifies delete matching: Direct Only accepts a direct grant; Direct or Indirect also accepts an indirect grant. This concerns the permission level, not direct versus security-group assignment.'; }
                field("Permission Match Mode"; Rec."Permission Match Mode") { ApplicationArea = All; ToolTip = 'Specifies how required operations on this table are combined: Any needs at least one to match; All needs every selected operation to match.'; }
                field("Required Permission"; Rec."Required Permission")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Legacy field kept for compatibility. Use the permission checkboxes instead.';
                }
                field("Risk Weight"; Rec."Risk Weight") { ApplicationArea = All; Visible = false; }
                field("Is Active"; Rec."Is Active") { ApplicationArea = All; ToolTip = 'Specifies whether this dictionary rule is available for selection in new group lines. Existing group lines retain their copied requirements.'; }
                field(Notes; Rec.Notes)
                {
                    ApplicationArea = All;
                    Caption = 'Rule Notes';
                    ToolTip = 'Explains the purpose or control reason for this rule.';
                }
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
        BCGAccessMgt.RequireAdminPage(Page::"BCG Rule Dictionary");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Rule Dictionary");
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Rule Dictionary");
        exit(true);
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
