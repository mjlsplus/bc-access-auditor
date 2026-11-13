table 50524 "BCG User Table Data Perm."
{
    Caption = 'BCAA User Table Data Permission';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; TableRelation = "BCG Audit Run"."Run ID"; }
        field(2; "User Security ID"; Guid) { Caption = 'User Security ID'; }
        field(3; "Company Name"; Text[30]) { Caption = 'Company Name'; }
        field(4; "Object ID"; Integer) { Caption = 'Object ID'; }
        field(5; "Object Name"; Text[249]) { Caption = 'Object Name'; }
        field(6; "Can Read"; Boolean) { Caption = 'Can Read'; }
        field(7; "Can Insert"; Boolean) { Caption = 'Can Insert'; }
        field(8; "Can Modify"; Boolean) { Caption = 'Can Modify'; }
        field(9; "Can Delete"; Boolean) { Caption = 'Can Delete'; }
        field(10; "Security Filter"; Text[2048]) { Caption = 'Security Filter'; }
        field(11; "Effective Source Count"; Integer) { Caption = 'Effective Source Count'; }
    }

    keys
    {
        key(PK; "Run ID", "User Security ID", "Company Name", "Object ID") { Clustered = true; }
        key(ObjectLookup; "Run ID", "Object ID") { }
        key(UserLookup; "Run ID", "User Security ID") { }
    }
}
