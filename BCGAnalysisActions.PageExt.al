pageextension 50566 "BCG Analysis Actions" extends "BCG User Table Data Perms"
{
    actions
    {
        addfirst("BCG User Process")
        {
            action("Run Full BCG Analysis")
            {
                AccessByPermission = codeunit "BCG Snapshot Mgt." = X;
                Caption = 'Run Full Analysis';
                ApplicationArea = All;
                Image = Process;
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
                        ProgressDialog.Open('Running Full Analysis...\This may take a few minutes.');

                    RunId := SnapshotMgt.RunFullSnapshot();

                    AuditRun.Get(RunId);
                    RunNo := AuditRun."Run No.";

                    if GuiAllowed() then
                        ProgressDialog.Close();

                    Message('Full analysis completed for Run No. %1.', RunNo);
                    CurrPage.Update(false);
                end;
            }

            action("Run Security Group Snapshot")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG SecGrp Mgt" = X;
                Caption = 'Run Security Group Snapshot';
                ApplicationArea = All;
                Image = Process;

                trigger OnAction()
                var
                    SecGrpMgt: Codeunit "BCG SecGrp Mgt";
                begin
                    SecGrpMgt.RunSecurityGroupSnapshot(Rec."Run ID");
                end;
            }

            action("BCG Add Special Wildcards")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Special Permission Mgt." = X;
                Caption = 'Add SUPER/SUPER DATA Wildcards';
                ApplicationArea = All;
                Image = Calculate;
                ToolTip = 'Creates or updates wildcard effective permission records for users with SUPER or SUPER (DATA) permission sets for the selected Run ID.';

                trigger OnAction()
                var
                    SpecialPermissionMgt: Codeunit "BCG Special Permission Mgt.";
                begin
                    SpecialPermissionMgt.AddSpecialPermissionWildcardsForRun(Rec."Run ID");
                    CurrPage.Update(false);
                end;
            }

            action("Fix Security Group SUPER Analysis")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG SecGrp Special Src Mgt" = X;
                Caption = 'Repair Security Group SUPER Analysis';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'For the selected Run ID, reruns Security Group snapshot, adds SUPER/SUPER DATA wildcard rows from security groups, recalculates conflicts and updates source flags.';

                trigger OnAction()
                var
                    SecGrpSpecialSourceMgt: Codeunit "BCG SecGrp Special Src Mgt";
                begin
                    if IsNullGuid(Rec."Run ID") then
                        Error('Run ID is empty. Select a line with a valid Run ID.');

                    SecGrpSpecialSourceMgt.RunSecurityGroupSpecialPermissionRepair(Rec."Run ID");
                    Message('Security Group SUPER/SUPER DATA analysis was repaired for Run ID %1.', Rec."Run ID");
                    CurrPage.Update(false);
                end;
            }

            action("Recalculate Conflicts")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Snapshot Mgt." = X;
                Caption = 'Recalculate Conflicts';
                ApplicationArea = All;
                Image = Calculate;
                ToolTip = 'Recalculate conflict results for the selected Run ID.';

                trigger OnAction()
                var
                    SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
                    SecGrpSpecialSourceMgt: Codeunit "BCG SecGrp Special Src Mgt";
                    SourceSummaryMgt: Codeunit "BCG Conflict Src Summary";
                    RunNoMgt: Codeunit "BCG Run No. Mgt.";
                    RunId: Guid;
                begin
                    RunId := Rec."Run ID";
                    if IsNullGuid(RunId) then
                        Error('Run ID is empty. Select a line with a valid Run ID.');

                    SnapshotMgt.RebuildEffectiveUserTableDataPermissions(RunId);
                    SnapshotMgt.CalculateConflicts(RunId);
                    SecGrpSpecialSourceMgt.MarkSpecialPermissionsAssignedThroughSecurityGroups(RunId);
                    SourceSummaryMgt.UpdateConflictResultSourcesForRun(RunId);
                    SecGrpSpecialSourceMgt.UpdateConflictResultSourcesFromLines(RunId);
                    RunNoMgt.EnsureRunNoAndPropagate(RunId);
                    CurrPage.Update(false);
                    Message('Effective permissions and conflicts recalculated for Run ID %1.', RunId);
                end;
            }

            action("Rebuild Conflict Source Trace")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Conflict Source Mgt" = X;
                Caption = 'Rebuild Conflict Source Trace';
                ApplicationArea = All;
                Image = Trace;

                trigger OnAction()
                var
                    SourceMgt: Codeunit "BCG Conflict Source Mgt";
                begin
                    SourceMgt.RebuildSourceTraceForRun(Rec."Run ID");
                end;
            }

            action("Update Conflict Result Source Summary")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Conflict Src Summary" = X;
                Caption = 'Update Result Source Summary';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Update source flags and source summary on conflict result headers for the selected Run ID.';

                trigger OnAction()
                var
                    SourceSummaryMgt: Codeunit "BCG Conflict Src Summary";
                begin
                    if IsNullGuid(Rec."Run ID") then
                        Error('Run ID is empty. Select a line with a valid Run ID.');

                    SourceSummaryMgt.UpdateConflictResultSourcesForRun(Rec."Run ID");
                    CurrPage.Update(false);
                end;
            }

            action(BCGUpdateConflictEvidenceSummaryFromPerms)
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG Conflict Evidence Mgt" = X;
                Caption = 'Update Conflict Evidence Summary';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Update evidence summary fields on conflict results for the selected Run ID.';

                trigger OnAction()
                var
                    EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
                begin
                    if IsNullGuid(Rec."Run ID") then
                        Error('Run ID is empty.');

                    EvidenceMgt.UpdateEvidenceForRun(Rec."Run ID");
                    Message('Conflict evidence summary updated for Run ID %1.', Rec."Run ID");
                end;
            }

            action("Update User Access Context")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG User Access Context Mgt" = X;
                ApplicationArea = All;
                Caption = 'Update User Access Context';
                Image = Refresh;
                ToolTip = 'Updates user-friendly SUPER/SUPER DATA summary and user security group context for the selected Run ID.';

                trigger OnAction()
                var
                    ContextMgt: Codeunit "BCG User Access Context Mgt";
                begin
                    ContextMgt.UpdateAccessContextForRun(Rec."Run ID");
                end;
            }

            action("Open Conflict Results Source View")
            {
                Caption = 'Open Conflict Results';
                ApplicationArea = All;
                Visible = false;
                Image = List;
                RunObject = page "BCG Conflict Results Source";
            }
        }
    }
}
