pageextension 50596 "BCG Audit Run Cleanup" extends "BCG Audit Runs"
{
    actions
    {
        addlast(Processing)
        {
            action(BCGDeleteRunData)
            {
                AccessByPermission = codeunit "BCG Run Cleanup Mgt." = X;
                Caption = 'Delete Selected Run Data';
                Visible = CanManageCleanup;
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Delete the selected audit run and all related snapshot, conflict, source trace and Security Group data.';

                trigger OnAction()
                var
                    CleanupMgt: Codeunit "BCG Run Cleanup Mgt.";
                begin
                    CleanupMgt.DeleteRunWithConfirmation(Rec."Run ID", Rec."Run No.", true);
                    CurrPage.Update(false);
                end;
            }

            action(BCGClearRunDataKeepHeader)
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Run Cleanup Mgt." = X;
                Caption = 'Clear Run Details Only';
                ApplicationArea = All;
                Image = ClearLog;
                ToolTip = 'Delete all detail data for the selected Run ID, but keep the audit run header.';

                trigger OnAction()
                var
                    CleanupMgt: Codeunit "BCG Run Cleanup Mgt.";
                begin
                    CleanupMgt.DeleteRunWithConfirmation(Rec."Run ID", Rec."Run No.", false);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
    begin
        CanManageCleanup := BCGAccessMgt.CanManageCodeunit(Codeunit::"BCG Run Cleanup Mgt.");
    end;

    var
        CanManageCleanup: Boolean;
}
