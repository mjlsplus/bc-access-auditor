pageextension 50597 "BCG Table Perm Run Cleanup" extends "BCG User Table Data Perms"
{
    actions
    {
        addlast("BCG Advanced Repair")
        {
            action(BCGDeleteCurrentRunData)
            {
                AccessByPermission = codeunit "BCG Run Cleanup Mgt." = X;
                Caption = 'Delete Current Run Data';
                ApplicationArea = All;
                Visible = false;
                Image = Delete;
                ToolTip = 'Delete the current Run ID and all related analysis data. Use this to clean old test runs.';

                trigger OnAction()
                var
                    CleanupMgt: Codeunit "BCG Run Cleanup Mgt.";
                begin
                    CleanupMgt.DeleteRunWithConfirmation(Rec."Run ID", Rec."Run No.", true);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
