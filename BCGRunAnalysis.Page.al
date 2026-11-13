page 50614 "BCG Run Analysis"
{
    Caption = 'Run Full Analysis';
    PageType = NavigatePage;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            label(Explanation)
            {
                ApplicationArea = All;
                Caption = 'This will capture the current access configuration and calculate access conflicts for the current company. The process may take several minutes.';
            }
            label(Coverage)
            {
                ApplicationArea = All;
                Caption = 'Analyzes Table Data permissions against configured conflict rules. Findings show potential access conflicts, not actions users have performed.';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunAnalysis)
            {
                AccessByPermission = codeunit "BCG Snapshot Mgt." = X;
                Caption = 'Run Analysis';
                ApplicationArea = All;
                Image = Process;
                InFooterBar = true;
                ToolTip = 'Capture current permissions and evaluate configured Table Data conflict rules in a new run for the current company. Completed runs retain their results. This does not evaluate every Business Central authorization mechanism.';

                trigger OnAction()
                var
                    SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
                    AuditRun: Record "BCG Audit Run";
                    ProgressDialog: Dialog;
                    RunId: Guid;
                    RunNo: Code[20];
                begin
                    if GuiAllowed() then
                        ProgressDialog.Open(ProgressLbl);

                    RunId := SnapshotMgt.RunFullSnapshot();
                    AuditRun.Get(RunId);
                    RunNo := AuditRun."Run No.";

                    if GuiAllowed() then
                        ProgressDialog.Close();

                    Message(CompletedLbl, RunNo);
                    CurrPage.Close();
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel';
                ApplicationArea = All;
                InFooterBar = true;
                ToolTip = 'Close without running an analysis.';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        ProgressLbl: Label 'Running Full Analysis...\This may take a few minutes.';
        CompletedLbl: Label 'Analysis completed successfully. Run No.: %1', Comment = '%1 = readable number of the completed analysis run.';
    trigger OnOpenPage()
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Run Analysis");
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
