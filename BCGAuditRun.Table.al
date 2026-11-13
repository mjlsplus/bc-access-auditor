table 50520 "BCG Audit Run"
{
    Caption = 'BCAA Audit Run';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; }
        field(2; "Started At"; DateTime) { Caption = 'Started At'; }
        field(3; "Finished At"; DateTime) { Caption = 'Finished At'; }
        field(4; "Started By"; Code[50]) { Caption = 'Started By'; }
        field(5; "Company Filter"; Text[250]) { Caption = 'Company Filter'; }
        field(6; Status; Enum "BCG Audit Run Status") { Caption = 'Status'; }
        field(7; "Error Message"; Text[2048]) { Caption = 'Error Message'; }
        field(8; "User Count"; Integer) { Caption = 'User Count'; }
        field(9; "Assignment Count"; Integer) { Caption = 'Assignment Count'; }
        field(10; "Object Permission Count"; Integer) { Caption = 'Object Permission Count'; }
        field(11; "Effective Permission Count"; Integer) { Caption = 'Effective Permission Count'; }
    }

    keys
    {
        key(PK; "Run ID") { Clustered = true; }
        key(StartDate; "Started At") { }
    }
}
