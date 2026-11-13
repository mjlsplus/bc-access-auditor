page 50599 "BCG Security Overview RC"
{
    Caption = 'BC Access Auditor';
    PageType = RoleCenter;
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
        {
            part(Cues; "BCG Conflict Cues")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Sections)
        {
            group(Analysis)
            {
                Caption = 'Analysis';

                action(RunAnalysis)
                {
                    AccessByPermission = tabledata "BCG Setup" = M;
                    Caption = 'Run Analysis';
                    ApplicationArea = All;
                    ToolTip = 'Open Full Analysis to capture permissions and evaluate configured Table Data conflict rules for the current company.';
                    RunObject = page "BCG Run Analysis";
                }

                action(DetectedConflicts)
                {
                    Caption = 'Detected Conflicts';
                    ApplicationArea = All;
                    RunObject = page "BCG Detected Conflicts";
                    RunPageMode = Edit;
                    ToolTip = 'Open detected conflicts for the current completed run with all severity and source filters.';
                }

                action(ConflictResults)
                {
                    Caption = 'User Conflict Results';
                    ApplicationArea = All;
                    ToolTip = 'Review stored user-level SoD findings from analysis runs. A finding indicates a potential access risk, not proof of fraud or user activity.';
                    RunObject = page "BCG User Conflict Results";
                }

            }

            group(SoDDefinitions)
            {
                Caption = 'SoD Definitions';

                action(BrowseSoDConflicts)
                {
                    Caption = 'Conflicts';
                    ApplicationArea = All;
                    AccessByPermission = tabledata "BCG Conflict Header" = R;
                    RunObject = page "BCG Conflicts";
                    ToolTip = 'Browse current SoD conflict definitions, groups, and group rules. These may differ from definitions used for historical findings.';
                }

                action(NewConflictWizard)
                {
                    AccessByPermission = tabledata "BCG Setup" = M;
                    Caption = 'New SoD Conflict Wizard';
                    ApplicationArea = All;
                    ToolTip = 'Create a SoD conflict with two groups of Table Data permission requirements using a guided setup.';
                    RunObject = page "BCG Simple Wizard";
                }

                action(BrowseSoDRules)
                {
                    Caption = 'Rule Dictionary';
                    ApplicationArea = All;
                    AccessByPermission = tabledata "BCG Rule Dictionary" = R;
                    RunObject = page "BCG Rule Dictionary";
                    ToolTip = 'Browse current SoD rules and their required table data permissions.';
                }
            }

            group(Administration)
            {
                Caption = 'Administration';

                action(AuditRuns)
                {
                    Caption = 'Audit Runs';
                    ApplicationArea = All;
                    ToolTip = 'Review analysis run status, capture times, record counts, and failure details. Completed results describe access captured at that time.';
                    RunObject = page "BCG Audit Runs";
                }

                action(UserTablePermissions)
                {
                    AccessByPermission = tabledata "BCG Setup" = M;
                    Caption = 'User Table Permissions';
                    ApplicationArea = All;
                    ToolTip = 'Inspect stored aggregated Table Data permissions by analysis run, user, company, and table. These results describe captured access, not necessarily current permissions.';
                    RunObject = page "BCG User Table Data Perms";
                    RunPageMode = View;
                }

                action(AdministrationPage)
                {
                    AccessByPermission = tabledata "BCG Setup" = M;
                    Caption = 'BC Access Auditor Administration';
                    ApplicationArea = All;
                    ToolTip = 'Open captured permission-source diagnostics and analysis run administration.';
                    RunObject = page "BCG Administration";
                }
            }
        }
    }
}
