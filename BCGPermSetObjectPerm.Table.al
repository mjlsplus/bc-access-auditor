table 50523 "BCG Perm. Set Object Perm."
{
    Caption = 'BCAA Permission Set Object Permission';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; TableRelation = "BCG Audit Run"."Run ID"; }
        field(2; "Role ID"; Code[30]) { Caption = 'Role ID'; }
        field(3; "Role Name"; Text[100]) { Caption = 'Role Name'; }
        field(4; "Scope Text"; Text[30]) { Caption = 'Scope'; }
        field(5; "App ID"; Guid) { Caption = 'App ID'; }
        field(6; "Object Type"; Text[30]) { Caption = 'Object Type'; }
        field(7; "Object ID"; Integer) { Caption = 'Object ID'; }
        field(8; "Object Name"; Text[249]) { Caption = 'Object Name'; }
        field(9; "Read Permission"; Text[20]) { Caption = 'Read Permission'; }
        field(10; "Insert Permission"; Text[20]) { Caption = 'Insert Permission'; }
        field(11; "Modify Permission"; Text[20]) { Caption = 'Modify Permission'; }
        field(12; "Delete Permission"; Text[20]) { Caption = 'Delete Permission'; }
        field(13; "Execute Permission"; Text[20]) { Caption = 'Execute Permission'; }
        field(14; "Security Filter"; Text[2048]) { Caption = 'Security Filter'; }
    }

    keys
    {
        key(PK; "Run ID", "Role ID", "App ID", "Scope Text", "Object Type", "Object ID") { Clustered = true; }
        key(ObjectLookup; "Run ID", "Object Type", "Object ID") { }
    }
}
