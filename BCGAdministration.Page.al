page 50589 "BCG Administration"
{
    Caption = 'BC Access Auditor Administration';
    PageType = Card;
    SourceTable = "BCG Audit Run";
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group("Selected Run")
            {
                Caption = 'Selected Run';

                field("Run No."; Rec."Run No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the readable analysis run number.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the selected analysis run.';
                }
                field("Started At"; Rec."Started At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the selected analysis run started.';
                }
                field("Finished At"; Rec."Finished At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the selected analysis run finished.';
                }
                field("Started By"; Rec."Started By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who started the selected analysis run.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group("Analysis Maintenance")
            {
                Caption = 'Analysis Maintenance';

                action("Run Security Group Snapshot")
                {
                    Visible = false;
                    Enabled = false;
                    AccessByPermission = codeunit "BCG SecGrp Mgt" = X;
                    Caption = '1. Run Security Group Snapshot';
                    ApplicationArea = All;
                    Image = Process;
                    ToolTip = 'Rerun the security group snapshot for the selected analysis run.';

                    trigger OnAction()
                    var
                        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
                    begin
                        EnsureSelectedRun();
                        SecGrpMgt.RunSecurityGroupSnapshot(Rec."Run ID");
                        CurrPage.Update(false);
                    end;
                }

                action("Add SUPER/SUPER DATA Wildcards")
                {
                    Visible = false;
                    Enabled = false;
                    AccessByPermission = codeunit "BCG Special Permission Mgt." = X;
                    Caption = '2. Add SUPER/SUPER DATA Wildcards';
                    ApplicationArea = All;
                    Image = Calculate;
                    ToolTip = 'Create or update wildcard effective permission records for SUPER or SUPER DATA permissions in the selected analysis run.';

                    trigger OnAction()
                    var
                        SpecialPermissionMgt: Codeunit "BCG Special Permission Mgt.";
                    begin
                        EnsureSelectedRun();
                        SpecialPermissionMgt.AddSpecialPermissionWildcardsForRun(Rec."Run ID");
                        CurrPage.Update(false);
                    end;
                }

                action("Repair Security Group SUPER Analysis")
                {
                    Visible = false;
                    Enabled = false;
                    AccessByPermission = codeunit "BCG SecGrp Special Src Mgt" = X;
                    Caption = '3. Repair Security Group SUPER Analysis';
                    ApplicationArea = All;
                    Image = Refresh;
                    ToolTip = 'Rerun the security group SUPER/SUPER DATA repair process for the selected analysis run.';

                    trigger OnAction()
                    var
                        SecGrpSpecialSourceMgt: Codeunit "BCG SecGrp Special Src Mgt";
                    begin
                        EnsureSelectedRun();
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
                    Caption = '4. Recalculate Conflicts';
                    ApplicationArea = All;
                    Image = Calculate;
                    ToolTip = 'Recalculate conflict results for the selected analysis run.';

                    trigger OnAction()
                    var
                        SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
                        SecGrpSpecialSourceMgt: Codeunit "BCG SecGrp Special Src Mgt";
                        SourceSummaryMgt: Codeunit "BCG Conflict Src Summary";
                    begin
                        EnsureSelectedRun();
                        SnapshotMgt.RebuildEffectiveUserTableDataPermissions(Rec."Run ID");
                        SnapshotMgt.CalculateConflicts(Rec."Run ID");
                        SecGrpSpecialSourceMgt.MarkSpecialPermissionsAssignedThroughSecurityGroups(Rec."Run ID");
                        SourceSummaryMgt.UpdateConflictResultSourcesForRun(Rec."Run ID");
                        SecGrpSpecialSourceMgt.UpdateConflictResultSourcesFromLines(Rec."Run ID");
                        Message('Effective permissions and conflicts recalculated for Run ID %1.', Rec."Run ID");
                        CurrPage.Update(false);
                    end;
                }

                action("Rebuild Conflict Source Trace")
                {
                    Visible = false;
                    Enabled = false;
                    AccessByPermission = codeunit "BCG Conflict Source Mgt" = X;
                    Caption = '5. Rebuild Conflict Source Trace';
                    ApplicationArea = All;
                    Image = Trace;
                    ToolTip = 'Rebuild technical source trace rows for the selected analysis run.';

                    trigger OnAction()
                    var
                        SourceMgt: Codeunit "BCG Conflict Source Mgt";
                    begin
                        EnsureSelectedRun();
                        SourceMgt.RebuildSourceTraceForRun(Rec."Run ID");
                        CurrPage.Update(false);
                    end;
                }

                action("Update Result Source Summary")
                {
                    Visible = false;
                    Enabled = false;
                    AccessByPermission = codeunit "BCG Conflict Src Summary" = X;
                    Caption = '6. Update Result Source Summary';
                    ApplicationArea = All;
                    Image = Refresh;
                    ToolTip = 'Update source flags and source summaries on conflict result headers for the selected analysis run.';

                    trigger OnAction()
                    var
                        SourceSummaryMgt: Codeunit "BCG Conflict Src Summary";
                    begin
                        EnsureSelectedRun();
                        SourceSummaryMgt.UpdateConflictResultSourcesForRun(Rec."Run ID");
                        CurrPage.Update(false);
                    end;
                }

                action("Update Conflict Evidence Summary")
                {
                    Visible = false;
                    Enabled = false;
                    AccessByPermission = codeunit "BCG Conflict Evidence Mgt" = X;
                    Caption = '7. Update Conflict Evidence Summary';
                    ApplicationArea = All;
                    Image = Refresh;
                    ToolTip = 'Update evidence summary fields on conflict results for the selected analysis run.';

                    trigger OnAction()
                    var
                        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
                    begin
                        EnsureSelectedRun();
                        EvidenceMgt.UpdateEvidenceForRun(Rec."Run ID");
                        Message('Conflict evidence summary updated for Run ID %1.', Rec."Run ID");
                        CurrPage.Update(false);
                    end;
                }

                action("Update User Access Context")
                {
                    Visible = false;
                    Enabled = false;
                    AccessByPermission = codeunit "BCG User Access Context Mgt" = X;
                    Caption = '8. Update User Access Context';
                    ApplicationArea = All;
                    Image = Refresh;
                    ToolTip = 'Update user-friendly SUPER/SUPER DATA and security group context for the selected analysis run.';

                    trigger OnAction()
                    var
                        ContextMgt: Codeunit "BCG User Access Context Mgt";
                    begin
                        EnsureSelectedRun();
                        ContextMgt.UpdateAccessContextForRun(Rec."Run ID");
                        CurrPage.Update(false);
                    end;
                }
            }

            group(Diagnostics)
            {
                Caption = 'Diagnostics';

                action("Conflict Source Trace")
                {
                    Caption = 'Conflict Source Trace';
                    ApplicationArea = All;
                    Image = Trace;
                    RunObject = page "BCG Conflict Source Trace";
                    ToolTip = 'Open the technical source trace for access sources.';
                }

                action("Security Groups")
                {
                    Caption = 'Security Groups';
                    ApplicationArea = All;
                    Image = Users;
                    RunObject = page "BCG Security Groups";
                    ToolTip = 'Open captured Business Central security groups.';
                }

                action("Security Group Members")
                {
                    Caption = 'Security Group Members';
                    ApplicationArea = All;
                    Image = Users;
                    RunObject = page "BCG Security Group Members";
                    ToolTip = 'Open captured security group members.';
                }

                action("Security Group Permissions")
                {
                    Caption = 'Security Group Permissions';
                    ApplicationArea = All;
                    Image = Permission;
                    RunObject = page "BCG SecGrp Permissions";
                    ToolTip = 'Open derived permission assignments from security groups.';
                }

                action("Conflict Lines Source View")
                {
                    Caption = 'Conflict Lines Source View';
                    ApplicationArea = All;
                    Image = Line;
                    RunObject = page "BCG Conflict Lines Source";
                    ToolTip = 'Open source-aware conflict result lines.';
                }
            }

            group("Run Maintenance")
            {
                Caption = 'Run Maintenance';

                action("Audit Runs")
                {
                    Caption = 'Audit Runs';
                    ApplicationArea = All;
                    Image = List;
                    RunObject = page "BCG Audit Runs";
                    ToolTip = 'Open audit runs for run review and deletion.';
                }

                action("Update Current Run Number")
                {
                    Visible = false;
                    Enabled = false;
                    AccessByPermission = codeunit "BCG Run No. Mgt." = X;
                    Caption = 'Update Current Run Number';
                    ApplicationArea = All;
                    Image = NumberSetup;
                    ToolTip = 'Assign or refresh the readable Run No. for the selected analysis run and all related analysis records.';

                    trigger OnAction()
                    var
                        RunNoMgt: Codeunit "BCG Run No. Mgt.";
                        RunNo: Code[20];
                    begin
                        EnsureSelectedRun();
                        RunNo := RunNoMgt.EnsureRunNoAndPropagate(Rec."Run ID");
                        Message('Run number %1 has been updated.', RunNo);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Administration");
        Rec.SetCurrentKey("Started At");
        Rec.Ascending(false);
        if Rec.FindFirst() then;
    end;

    local procedure EnsureSelectedRun()
    begin
        if IsNullGuid(Rec."Run ID") then
            Error('Select an analysis run first.');
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
