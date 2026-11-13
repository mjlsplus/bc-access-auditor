page 50513 "BCG Conflict Group Rules"
{
    PageType = ListPart;
    SourceTable = "BCG Conflict Group Rule";
    Caption = 'Conflict Group Rules';
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Group No."; Rec."Group No.") { ApplicationArea = All; ToolTip = 'Specifies the conflict group to which this rule line belongs.'; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; ToolTip = 'Specifies the position and identifier of this rule line within its conflict group.'; }
                field("Rule ID"; Rec."Rule ID") { ApplicationArea = All; ToolTip = 'Select an active dictionary rule to copy its table and permission requirements into this group line. Later dictionary edits do not automatically update the copied values.'; }
                field("Rule Name"; Rec."Rule Name") { ApplicationArea = All; ToolTip = 'Specifies the rule name copied from the dictionary when this group line was configured.'; }
                field("Object ID"; Rec."Object ID") { ApplicationArea = All; ToolTip = 'Specifies the Table Data object copied from the selected dictionary rule for this group line.'; Caption = 'Table Data ID'; }
                field("Object Caption"; Rec."Object Caption") { ApplicationArea = All; ToolTip = 'Specifies the table name copied from the selected dictionary rule for this group line.'; Caption = 'Table Data Name'; }
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
                    ToolTip = 'Legacy field kept for compatibility. Use the permission checkboxes from the rule dictionary.';
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
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Group Rules");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Group Rules");
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Group Rules");
        exit(true);
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
