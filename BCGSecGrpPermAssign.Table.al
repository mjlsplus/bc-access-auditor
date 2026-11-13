table 50594 "BCG SecGrp Perm Assign"
{
    Caption = 'BCAA Security Group Permission Assignment';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; }
        field(2; "Security Group Code"; Code[20]) { Caption = 'Security Group Code'; }
        field(3; "Security Group Name"; Text[250]) { Caption = 'Security Group Name'; }
        field(4; "User Security ID"; Guid) { Caption = 'User Security ID'; }
        field(5; "User Name"; Code[50]) { Caption = 'User Name'; }
        field(6; "User Full Name"; Text[80]) { Caption = 'User Full Name'; }
        field(7; "Company Name"; Text[30]) { Caption = 'Company Name'; }
        field(8; "Role ID"; Code[20]) { Caption = 'Role ID'; }
        field(9; "Role Name"; Text[80]) { Caption = 'Role Name'; }
        field(10; "Scope"; Text[30]) { Caption = 'Scope'; }
        field(11; "App ID"; Guid) { Caption = 'App ID'; }
        field(12; "App Name"; Text[250]) { Caption = 'App Name'; }
        field(13; "Assignment Source Type"; Text[30]) { Caption = 'Assignment Source Type'; }
        field(14; "Captured At"; DateTime) { Caption = 'Captured At'; }
    }

    keys
    {
        key(PK; "Run ID", "Security Group Code", "User Security ID", "Company Name", "Role ID", "App ID", Scope) { Clustered = true; }
        key(UserRoleIdx; "Run ID", "User Security ID", "Role ID") { }
    }
}
