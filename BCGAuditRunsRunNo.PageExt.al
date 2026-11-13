pageextension 50519 "BCG Audit Runs Run No" extends "BCG Audit Runs"
{
    layout
    {
        modify("Run ID")
        {
            Visible = false;
        }

        addbefore(Status)
        {
            field("Run No."; Rec."Run No.")
            {
                ApplicationArea = All;
                ToolTip = 'User-friendly number of the analysis run. Technical Run ID is hidden on the standard view.';
            }
            field("Run Description"; Rec."Run Description")
            {
                ApplicationArea = All;
                ToolTip = 'Short readable description of the analysis run.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("Update Run Numbers")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Run No. Mgt." = X;
                Caption = 'Update Run Numbers';
                ApplicationArea = All;
                Image = NumberGroup;
                ToolTip = 'Assign missing readable Run No. values and copy them to all related result tables.';

                trigger OnAction()
                var
                    RunNoMgt: Codeunit "BCG Run No. Mgt.";
                begin
                    RunNoMgt.UpdateAllRunNumbers();
                    CurrPage.Update(false);
                end;
            }

            action("Update Selected Run Number")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Run No. Mgt." = X;
                Caption = 'Update Selected Run Number';
                ApplicationArea = All;
                Image = NumberSetup;
                ToolTip = 'Assign or refresh the readable Run No. for the selected analysis run and all its detail records.';

                trigger OnAction()
                var
                    RunNoMgt: Codeunit "BCG Run No. Mgt.";
                    RunNo: Code[20];
                begin
                    RunNo := RunNoMgt.EnsureRunNoAndPropagate(Rec."Run ID");
                    Message('Run number %1 has been updated for the selected run.', RunNo);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
