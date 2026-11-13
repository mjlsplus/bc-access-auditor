permissionset 50997 "BCG SCHEMA COVERAGE"
{
    Assignable = false;
    Access = Internal;
    Caption = 'BCAA Retained Schema';

    Permissions =
        tabledata "BCG User Permission Demo" = R,
        tabledata "BCG Legacy Conflict Result" = R,
        tabledata "BCG Wizard Buffer" = R,
        tabledata "BCG Perf Dataset" = R;
}
