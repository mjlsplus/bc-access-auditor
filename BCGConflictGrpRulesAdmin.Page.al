page 50519 "BCG Conflict Grp Rules Admin"
{
    PageType = List;
    SourceTable = "BCG Conflict Group Rule";
    Caption = 'Conflict Group Rules Administration';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Conflict ID"; Rec."Conflict ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the conflict definition to which this group rule belongs.';
                }
                field("Group No."; Rec."Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the group within the conflict that contains this rule line.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identifier and ordering of this rule line within its conflict group.';
                }
                field("Rule ID"; Rec."Rule ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select an active dictionary rule to copy its table and permission requirements into this line. Later dictionary edits do not automatically update the copied values.';
                }
                field("Rule Name"; Rec."Rule Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the read-only rule name copied from the dictionary when the rule was selected.';
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the read-only Table Data object identifier copied from the selected rule, not a page or report identifier.';
                }
                field("Object Caption"; Rec."Object Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the read-only table name copied from the selected dictionary rule.';
                }
                field("Required Permission"; Rec."Required Permission")
                {
                    ApplicationArea = All;
                }
                field("Requires Read"; Rec."Requires Read")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the copied, read-only requirement for permission to read records. Permission Match Mode combines the selected operations using Any or All.';
                }
                field("Requires Insert"; Rec."Requires Insert")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the copied, read-only requirement for permission to create records. Permission Match Mode combines the selected operations using Any or All.';
                }
                field("Requires Modify"; Rec."Requires Modify")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the copied, read-only requirement for permission to change existing records. Permission Match Mode combines the selected operations using Any or All.';
                }
                field("Requires Delete"; Rec."Requires Delete")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the copied, read-only requirement for permission to remove records. Permission Match Mode combines the selected operations using Any or All.';
                }
                field("Permission Match Mode"; Rec."Permission Match Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the copied, read-only operation matching mode: Any requires one selected operation to match; All requires every selected operation.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteCurrentConflictRules)
            {
                ApplicationArea = All;
                Caption = 'Delete Current Conflict Rules';
                Image = Delete;
                ToolTip = 'Deletes all group rules for the selected Conflict ID. Use this before deleting orphaned groups.';

                trigger OnAction()
                var
                    ConflictGroupRule: Record "BCG Conflict Group Rule";
                    ConflictIdToDelete: Code[20];
                begin
                    ConflictIdToDelete := Rec."Conflict ID";
                    if ConflictIdToDelete = '' then
                        Error('Select a conflict group rule first.');

                    if not Confirm('Delete all group rules for Conflict ID %1?', false, ConflictIdToDelete) then
                        exit;

                    ConflictGroupRule.SetRange("Conflict ID", ConflictIdToDelete);
                    ConflictGroupRule.DeleteAll(true);

                    CurrPage.Update(false);
                    Message('Conflict group rules for Conflict ID %1 were deleted.', ConflictIdToDelete);
                end;
            }

            action(DeleteOrphanedRules)
            {
                ApplicationArea = All;
                Caption = 'Delete Orphaned Rules';
                Image = Delete;
                ToolTip = 'Deletes conflict group rules whose conflict header or conflict group no longer exists.';

                trigger OnAction()
                var
                    ConflictHeader: Record "BCG Conflict Header";
                    ConflictGroup: Record "BCG Conflict Group";
                    ConflictGroupRule: Record "BCG Conflict Group Rule";
                    DeletedCount: Integer;
                    IsOrphaned: Boolean;
                begin
                    if not Confirm('Delete all conflict group rules without an existing conflict header/group?', false) then
                        exit;

                    if ConflictGroupRule.FindSet(true) then
                        repeat
                            IsOrphaned := false;

                            if not ConflictHeader.Get(ConflictGroupRule."Conflict ID") then
                                IsOrphaned := true;

                            if not ConflictGroup.Get(ConflictGroupRule."Conflict ID", ConflictGroupRule."Group No.") then
                                IsOrphaned := true;

                            if IsOrphaned then begin
                                ConflictGroupRule.Delete(true);
                                DeletedCount += 1;
                            end;
                        until ConflictGroupRule.Next() = 0;

                    CurrPage.Update(false);
                    Message('%1 orphaned conflict group rule record(s) were deleted.', DeletedCount);
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Grp Rules Admin");
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
