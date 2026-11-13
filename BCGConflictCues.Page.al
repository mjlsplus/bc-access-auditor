page 50594 "BCG Conflict Cues"
{
    Caption = 'Access Risk Overview';
    PageType = CardPart;
    SourceTable = "BCG Conflict Cue";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            cuegroup(Conflicts)
            {
                Caption = 'Access Risk Overview';

                field("Active Conflicts"; ActiveConflictsCount)
                {
                    Caption = 'Open Findings';
                    ToolTip = 'Counts Open finding records for the current run, not distinct conflicts. Cue values may overlap and should not be added together.';
                    ApplicationArea = All;
                    DrillDown = true;
                    StyleExpr = 'Unfavorable';

                    trigger OnDrillDown()
                    var
                        ConflictResult: Record "BCG User Conflict Result";
                    begin
                        if IsNullGuid(CurrentRunId) then
                            exit;

                        ConflictResult.SetRange("Run ID", CurrentRunId);
                        ConflictResult.SetRange(Status, ConflictResult.Status::Open);
                        OpenDetectedConflicts(ConflictResult);
                    end;
                }

                field("High Severity"; HighSeverityCount)
                {
                    Caption = 'High Severity';
                    ToolTip = 'Counts High severity finding records across all statuses for the current run. Critical is not included. Cue values may overlap and should not be added together.';
                    ApplicationArea = All;
                    DrillDown = true;
                    StyleExpr = 'Unfavorable';

                    trigger OnDrillDown()
                    var
                        ConflictResult: Record "BCG User Conflict Result";
                    begin
                        if IsNullGuid(CurrentRunId) then
                            exit;

                        ConflictResult.SetRange("Run ID", CurrentRunId);
                        ConflictResult.SetRange(Severity, ConflictResult.Severity::High);
                        OpenDetectedConflicts(ConflictResult);
                    end;
                }

                field("Users with Conflicts"; UsersWithConflictsCount)
                {
                    Caption = 'Affected Users';
                    ToolTip = 'Counts distinct users with Open findings for the current run, not finding records. Cue values may overlap and should not be added together.';
                    ApplicationArea = All;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        AffectedUsers: Page "BCG Affected Users";
                    begin
                        if IsNullGuid(CurrentRunId) then
                            exit;

                        AffectedUsers.InitializeOpenScope(CurrentRunId);
                        AffectedUsers.Run();
                    end;
                }

                field("Privileged Access Risks"; PrivilegedRisksCount)
                {
                    Caption = 'Special Permission Findings';
                    ToolTip = 'Counts finding records with a special-permission source across all statuses for the current run, not distinct users. Cue values may overlap and should not be added together.';
                    ApplicationArea = All;
                    DrillDown = true;
                    StyleExpr = 'Attention';

                    trigger OnDrillDown()
                    var
                        ConflictResult: Record "BCG User Conflict Result";
                    begin
                        if IsNullGuid(CurrentRunId) then
                            exit;

                        ConflictResult.SetRange("Run ID", CurrentRunId);
                        ConflictResult.SetRange("Has Special Permission Source", true);
                        OpenDetectedConflicts(ConflictResult);
                    end;
                }

                field("Group-Based Risks"; GroupBasedRisksCount)
                {
                    Caption = 'Security Group Findings';
                    ToolTip = 'Counts finding records with a security-group source across all statuses for the current run, including Mixed findings. Cue values may overlap and should not be added together.';
                    ApplicationArea = All;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        ConflictResult: Record "BCG User Conflict Result";
                    begin
                        if IsNullGuid(CurrentRunId) then
                            exit;

                        ConflictResult.SetRange("Run ID", CurrentRunId);
                        ConflictResult.SetRange("Has Security Group Source", true);
                        OpenDetectedConflicts(ConflictResult);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        // The singleton exists only in this page's temporary source table.
        if not Rec.Get('MAIN') then begin
            Rec.Init();
            Rec."Primary Key" := 'MAIN';
            Rec.Insert();
        end;

    end;

    trigger OnAfterGetRecord()
    begin
        RefreshCueValues();
    end;

    local procedure OpenDetectedConflicts(var Findings: Record "BCG User Conflict Result")
    var
        AuditRun: Record "BCG Audit Run";
        DetectedConflicts: Page "BCG Detected Conflicts";
        SeverityFilter: Option All,Low,Medium,High,Critical;
        SpecialPermissionFilter: Option All,Yes,No;
        SecurityGroupFilter: Option All,Yes,No;
    begin
        if not AuditRun.Get(CurrentRunId) then
            exit;
        if AuditRun.Status <> AuditRun.Status::Finished then
            exit;

        if Findings.GetFilter(Severity) <> '' then
            SeverityFilter := SeverityFilter::High;
        if Findings.GetFilter("Has Special Permission Source") <> '' then
            SpecialPermissionFilter := SpecialPermissionFilter::Yes;
        if Findings.GetFilter("Has Security Group Source") <> '' then
            SecurityGroupFilter := SecurityGroupFilter::Yes;
        if Findings.GetFilter(Status) <> '' then
            DetectedConflicts.InitializeOpenScope(AuditRun."Run ID")
        else
            DetectedConflicts.InitializeScope(AuditRun."Run ID", SeverityFilter, SpecialPermissionFilter, SecurityGroupFilter);
        DetectedConflicts.Run();
    end;

    local procedure RefreshCueValues()
    var
        ConflictResult: Record "BCG User Conflict Result";
        RunNoMgt: Codeunit "BCG Risk Presentation Mgt.";
        UserSecurityIds: List of [Guid];
    begin
        Clear(CurrentRunId);
        Clear(CurrentRunNo);
        Clear(ActiveConflictsCount);
        Clear(HighSeverityCount);
        Clear(UsersWithConflictsCount);
        Clear(PrivilegedRisksCount);
        Clear(GroupBasedRisksCount);

        if not RunNoMgt.TryGetCurrentRun(CurrentRunId, CurrentRunNo) then
            exit;

        ConflictResult.SetRange("Run ID", CurrentRunId);
        ConflictResult.SetRange(Status, ConflictResult.Status::Open);
        ActiveConflictsCount := ConflictResult.Count();

        if ConflictResult.FindSet() then
            repeat
                if not UserSecurityIds.Contains(ConflictResult."User Security ID") then begin
                    UserSecurityIds.Add(ConflictResult."User Security ID");
                    UsersWithConflictsCount += 1;
                end;
            until ConflictResult.Next() = 0;

        ConflictResult.Reset();
        ConflictResult.SetRange("Run ID", CurrentRunId);
        ConflictResult.SetRange(Severity, ConflictResult.Severity::High);
        HighSeverityCount := ConflictResult.Count();

        ConflictResult.Reset();
        ConflictResult.SetRange("Run ID", CurrentRunId);
        ConflictResult.SetRange("Has Special Permission Source", true);
        PrivilegedRisksCount := ConflictResult.Count();

        ConflictResult.Reset();
        ConflictResult.SetRange("Run ID", CurrentRunId);
        ConflictResult.SetRange("Has Security Group Source", true);
        GroupBasedRisksCount := ConflictResult.Count();
    end;

    var
        CurrentRunId: Guid;
        CurrentRunNo: Code[20];
        ActiveConflictsCount: Integer;
        HighSeverityCount: Integer;
        UsersWithConflictsCount: Integer;
        PrivilegedRisksCount: Integer;
        GroupBasedRisksCount: Integer;
}
