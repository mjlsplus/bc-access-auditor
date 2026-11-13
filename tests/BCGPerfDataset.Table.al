// Keep the result schema in normal builds so switching off the developer harness
// never requires removing a table or losing stored measurements.
table 50960 "BCG Perf Dataset"
{
    Caption = 'BCAA Performance Dataset';
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; Caption = 'Entry No.'; }
        field(2; "Run ID"; Guid) { Caption = 'Run ID'; }
        field(3; "Scenario"; Code[10]) { Caption = 'Scenario'; }
        field(4; "Rule Prefix"; Code[18]) { Caption = 'Rule Prefix'; }
        field(5; "Users"; Integer) { Caption = 'Users'; }
        field(6; "Companies"; Integer) { Caption = 'Companies'; }
        field(7; "Permission Sets"; Integer) { Caption = 'Permission Sets'; }
        field(8; "Assignments per User"; Integer) { Caption = 'Assignments per User'; }
        field(9; "Rows per Set"; Integer) { Caption = 'Rows per Set'; }
        field(10; "Controls"; Integer) { Caption = 'Controls'; }
        field(11; "Assignments"; Integer) { Caption = 'Assignments'; }
        field(12; "Source Rows"; Integer) { Caption = 'Source Rows'; }
        field(13; "Effective Rows"; Integer) { Caption = 'Effective Rows'; }
        field(14; "Origin Lines"; Integer) { Caption = 'Origin Lines'; }
        field(15; "Trace Rows"; Integer) { Caption = 'Trace Rows'; }
        field(16; "Full Conflicts"; Integer) { Caption = 'Full Conflicts'; }
        field(17; "Recalc Conflicts"; Integer) { Caption = 'Recalc Conflicts'; }
        field(18; "Expected Effective"; Integer) { Caption = 'Expected Effective'; }
        field(19; "State"; Text[30]) { Caption = 'State'; }
        field(20; "Snapshot Time"; Duration) { Caption = 'Snapshot Time'; }
        field(21; "Assignment Time"; Duration) { Caption = 'Assignment Time'; }
        field(22; "Permission Load Time"; Duration) { Caption = 'Permission Load Time'; }
        field(23; "Effective Time"; Duration) { Caption = 'Effective Time'; }
        field(24; "Conflict Time"; Duration) { Caption = 'Conflict Time'; }
        field(25; "Trace Summary Time"; Duration) { Caption = 'Trace Summary Time'; }
        field(26; "Finalization Time"; Duration) { Caption = 'Finalization Time'; }
        field(27; "Full Time"; Duration) { Caption = 'Full Time'; }
        field(28; "Conflict Only Time"; Duration) { Caption = 'Conflict Only Time'; }
        field(29; "Existing Recalc Time"; Duration) { Caption = 'Existing Recalc Time'; }
        field(30; "Full Passed"; Boolean) { Caption = 'Full Passed'; }
        field(31; "Recalc Passed"; Boolean) { Caption = 'Recalc Passed'; }
        field(32; "Estimated Row Cap"; Integer) { Caption = 'Estimated Row Cap'; }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Run; "Run ID") { Unique = true; }
    }
}
