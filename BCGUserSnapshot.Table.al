table 50521 "BCG User Snapshot"
{
    Caption = 'BCAA User Snapshot';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; TableRelation = "BCG Audit Run"."Run ID"; }
        field(2; "User Security ID"; Guid) { Caption = 'User Security ID'; }
        field(3; "User Name"; Code[50]) { Caption = 'User Name'; }
        field(4; "Full Name"; Text[80]) { Caption = 'Full Name'; }
        field(5; State; Text[30]) { Caption = 'State'; }
        field(6; "Expiry Date"; Date) { Caption = 'Expiry Date'; }
        field(7; "Captured At"; DateTime) { Caption = 'Captured At'; }
    }

    keys
    {
        key(PK; "Run ID", "User Security ID") { Clustered = true; }
        key(UserName; "User Name") { }
    }
}
