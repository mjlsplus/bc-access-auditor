table 50610 "BCG Affected User Buffer"
{
    Caption = 'Affected User';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; }
        field(2; "Run No."; Code[20]) { Caption = 'Run No.'; }
        field(3; "User Security ID"; Guid) { Caption = 'User Security ID'; }
        field(4; "User Name"; Text[50]) { Caption = 'User Name'; }
        field(5; "Company Count"; Integer) { Caption = 'Company Count'; }
        field(6; "Detected Conflict Count"; Integer) { Caption = 'Detected Conflict Count'; }
        field(7; "Finding Count"; Integer) { Caption = 'Finding Count'; }
        field(8; "High Severity Finding Count"; Integer) { Caption = 'High Severity Finding Count'; }
        field(9; "Has Special Permissions"; Boolean) { Caption = 'Has Special Permissions'; }
        field(10; "Has Security Group Findings"; Boolean) { Caption = 'Has Security Group Findings'; }
        field(11; "Has Direct Assignments"; Boolean) { Caption = 'Has Direct Assignments'; }
    }

    keys
    {
        key(PK; "Run ID", "User Security ID") { Clustered = true; }
        key(UserName; "User Name") { }
    }
}
