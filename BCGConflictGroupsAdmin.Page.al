page 50518 "BCG Conflict Groups Admin"
{
    PageType = List;
    SourceTable = "BCG Conflict Group";
    SourceTableView = sorting("Conflict ID", Sequence);
    Caption = 'Conflict Groups Administration';
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
                    ToolTip = 'Specifies the conflict definition that owns this group. Changes affect future analyses, not completed results.';
                }
                field("Group No."; Rec."Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identifier linking rule lines to this group within the conflict.';
                }
                field("Group Name"; Rec."Group Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the business capability represented by this SoD rule group, not a Business Central security group.';
                }
                field("Evaluation Logic"; Rec."Evaluation Logic")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how rules in this group match: Any requires at least one matching rule; All requires every rule. A group without rules does not match.';
                }
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display and evidence order of groups within the conflict; it does not change which permissions must match.';
                }
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether future analyses evaluate this group. A user must match every active group in the conflict.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteCurrentConflictData)
            {
                ApplicationArea = All;
                Caption = 'Delete Current Conflict Data';
                Image = Delete;
                ToolTip = 'Deletes all group rules and groups for the selected Conflict ID. Use this to clean orphaned setup data.';

                trigger OnAction()
                var
                    ConflictGroup: Record "BCG Conflict Group";
                    ConflictGroupRule: Record "BCG Conflict Group Rule";
                    ConflictIdToDelete: Code[20];
                begin
                    ConflictIdToDelete := Rec."Conflict ID";
                    if ConflictIdToDelete = '' then
                        Error('Select a conflict group first.');

                    if not Confirm('Delete all groups and group rules for Conflict ID %1?', false, ConflictIdToDelete) then
                        exit;

                    ConflictGroupRule.SetRange("Conflict ID", ConflictIdToDelete);
                    ConflictGroupRule.DeleteAll(true);

                    ConflictGroup.SetRange("Conflict ID", ConflictIdToDelete);
                    ConflictGroup.DeleteAll(true);

                    CurrPage.Update(false);
                    Message('Conflict groups and rules for Conflict ID %1 were deleted.', ConflictIdToDelete);
                end;
            }

            action(DeleteOrphanedGroups)
            {
                ApplicationArea = All;
                Caption = 'Delete Orphaned Groups';
                Image = Delete;
                ToolTip = 'Deletes conflict groups whose conflict header no longer exists. Rules should be deleted first.';

                trigger OnAction()
                var
                    ConflictHeader: Record "BCG Conflict Header";
                    ConflictGroup: Record "BCG Conflict Group";
                    DeletedCount: Integer;
                begin
                    if not Confirm('Delete all conflict groups without an existing conflict header?', false) then
                        exit;

                    if ConflictGroup.FindSet(true) then
                        repeat
                            if not ConflictHeader.Get(ConflictGroup."Conflict ID") then begin
                                ConflictGroup.Delete(true);
                                DeletedCount += 1;
                            end;
                        until ConflictGroup.Next() = 0;

                    CurrPage.Update(false);
                    Message('%1 orphaned conflict group record(s) were deleted.', DeletedCount);
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Conflict Groups Admin");
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
