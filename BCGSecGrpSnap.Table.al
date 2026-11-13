table 50592 "BCG SecGrp Snap"
{
    Caption = 'BCAA Security Group Snapshot';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; }
        field(2; "Security Group Code"; Code[20]) { Caption = 'Security Group Code'; }
        field(3; "Group User SID"; Guid) { Caption = 'Group User SID'; }
        field(4; "Group ID"; Text[250]) { Caption = 'Group ID'; }
        field(5; "Group Name"; Text[250]) { Caption = 'Group Name'; }
        field(6; "Retrieved Successfully"; Boolean) { Caption = 'Retrieved Successfully'; }
        field(7; "Captured At"; DateTime) { Caption = 'Captured At'; }
    }

    keys
    {
        key(PK; "Run ID", "Security Group Code") { Clustered = true; }
        key(GroupUserSID; "Run ID", "Group User SID") { }
    }
}
