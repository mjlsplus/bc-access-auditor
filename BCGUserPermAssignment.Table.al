table 50522 "BCG User Perm. Assignment"
{
    Caption = 'BCAA User Permission Assignment';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; TableRelation = "BCG Audit Run"."Run ID"; }
        field(2; "User Security ID"; Guid) { Caption = 'User Security ID'; }
        field(3; "Company Name"; Text[30]) { Caption = 'Company Name'; }
        field(4; "Role ID"; Code[30]) { Caption = 'Role ID'; }
        field(5; "Role Name"; Text[100]) { Caption = 'Role Name'; }
        field(6; "Scope Text"; Text[30]) { Caption = 'Scope'; }
        field(7; "App ID"; Guid) { Caption = 'App ID'; }
        field(8; "App Name"; Text[250]) { Caption = 'App Name'; }
        field(9; "Assignment Source Type"; Text[30]) { Caption = 'Assignment Source Type'; }
        field(10; "Assignment Source Code"; Text[100]) { Caption = 'Assignment Source Code'; }
    }

    keys
    {
        key(PK; "Run ID", "User Security ID", "Company Name", "Role ID", "App ID", "Scope Text") { Clustered = true; }
        key(RoleLookup; "Run ID", "Role ID", "App ID", "Scope Text") { }
    }
}
