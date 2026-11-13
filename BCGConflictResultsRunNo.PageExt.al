pageextension 50526 "BCG Conflict Results Run No" extends "BCG User Conflict Results"
{
    layout
    {
        modify("Run ID")
        {
            Visible = false;
        }

        addbefore("User Security ID")
        {
            field("Run No."; Rec."Run No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the readable analysis run number. Use this column to filter by Run No.; the internal Run ID scope remains active.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("Update Current Run Number")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Run No. Mgt." = X;
                Caption = 'Update Current Run Number';
                ApplicationArea = All;
                Image = NumberSetup;
                ToolTip = 'Assign or refresh the readable Run No. for the selected Run ID and all related analysis records.';

                trigger OnAction()
                var
                    RunNoMgt: Codeunit "BCG Run No. Mgt.";
                    RunNo: Code[20];
                begin
                    RunNo := RunNoMgt.EnsureRunNoAndPropagate(Rec."Run ID");
                    Message('Run number %1 has been updated.', RunNo);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Scope: Record "BCG User Conflict Result";
        RunId: Guid;
        ScopeGroup: Integer;
    begin
        Scope.CopyFilters(Rec);
        // Preserve every incoming filter and keep navigation identity outside
        // the editable filter pane. Run No. is display only, even for duplicates.
        for ScopeGroup := 0 to 10 do
            if (ScopeGroup <= 4) or (ScopeGroup = 10) then begin
                Scope.FilterGroup(ScopeGroup);
                if Evaluate(RunId, Scope.GetFilter("Run ID")) then
                    if not IsNullGuid(RunId) then begin
                        Rec.FilterGroup(100);
                        Rec.SetRange("Run ID", RunId);
                        Rec.FilterGroup(0);
                        exit;
                    end;
            end;
    end;
}
