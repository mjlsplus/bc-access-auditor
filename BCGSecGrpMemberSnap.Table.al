table 50593 "BCG SecGrp Member Snap"
{
    Caption = 'BCAA Security Group Member Snapshot';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; }
        field(2; "Security Group Code"; Code[20]) { Caption = 'Security Group Code'; }
        field(3; "User Security ID"; Guid) { Caption = 'User Security ID'; }
        field(4; "Security Group Name"; Text[250]) { Caption = 'Security Group Name'; }
        field(5; "User Name"; Code[50]) { Caption = 'User Name'; }
        field(6; "User Full Name"; Text[80]) { Caption = 'User Full Name'; }
        field(7; "Captured At"; DateTime) { Caption = 'Captured At'; }
    }

    keys
    {
        key(PK; "Run ID", "Security Group Code", "User Security ID") { Clustered = true; }
        key(UserIdx; "Run ID", "User Security ID") { }
    }
}
