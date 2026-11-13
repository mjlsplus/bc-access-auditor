page 50520 "BCG Audit Runs"
{
    PageType = List;
    SourceTable = "BCG Audit Run";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Audit Runs';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; }
                field("Company Scope"; Rec."Company Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Company Scope';
                    ToolTip = 'Specifies the hosting company analyzed by this run. Global assignments apply to this company. A blank value on an older run means its scope was not recorded.';
                }
                field(Status; Rec.Status) { ApplicationArea = All; ToolTip = 'Specifies whether the analysis is running, finished, or failed. Only a finished run represents a completed analysis.'; }
                field("Started At"; Rec."Started At") { ApplicationArea = All; ToolTip = 'Specifies when this analysis run began capturing access information.'; }
                field("Finished At"; Rec."Finished At") { ApplicationArea = All; ToolTip = 'Specifies when this run finished or failed. Check the status to determine whether the analysis completed successfully.'; }
                field("Started By"; Rec."Started By") { ApplicationArea = All; ToolTip = 'Specifies the Business Central user who started this analysis run.'; }
                field("User Count"; Rec."User Count") { ApplicationArea = All; ToolTip = 'Specifies the number of user snapshot records captured for this run, not the number of users with conflicts.'; }
                field("Assignment Count"; Rec."Assignment Count") { ApplicationArea = All; ToolTip = 'Specifies the number of captured user permission-set assignment records, not the number of effective table permissions.'; }
                field("Object Permission Count"; Rec."Object Permission Count") { ApplicationArea = All; ToolTip = 'Specifies the number of captured Table Data permission entries from permission sets, before aggregation into effective permissions.'; }
                field("Effective Permission Count"; Rec."Effective Permission Count") { ApplicationArea = All; ToolTip = 'Specifies the number of calculated user Table Data permission records, including special-permission wildcard records. This is not a count of distinct users or tables.'; }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; ToolTip = 'Specifies the error recorded when this analysis run failed. Review it before starting a new Full Analysis.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunFullSnapshot)
            {
                AccessByPermission = codeunit "BCG Snapshot Mgt." = X;
                Caption = 'Run Full Analysis';
                ApplicationArea = All;
                Visible = false;
                Image = Refresh;

                trigger OnAction()
                var
                    SnapshotMgt: Codeunit "BCG Snapshot Mgt.";
                    NewRunId: Guid;
                begin
                    NewRunId := SnapshotMgt.RunFullSnapshot();
                    Message('Analysis snapshot finished. Run ID: %1', NewRunId);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
