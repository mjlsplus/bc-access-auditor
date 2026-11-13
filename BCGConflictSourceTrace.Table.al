table 50584 "BCG Conflict Source Trace"
{
    Caption = 'BCAA Conflict Source Trace';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Run ID"; Guid)
        {
            Caption = 'Run ID';
        }
        field(3; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
        }
        field(4; "User Name"; Code[50])
        {
            Caption = 'User Name';
        }
        field(5; "User Full Name"; Text[80])
        {
            Caption = 'User Full Name';
        }
        field(6; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
        }
        field(7; "Permission Source Type"; Option)
        {
            Caption = 'Permission Source Type';
            OptionMembers = Unknown,Direct,"Security Group","Special Permission",Mixed;
            OptionCaption = 'Unknown,Direct,Security Group,Special Permission,Mixed';
        }
        field(8; "Role ID"; Code[20])
        {
            Caption = 'Role ID';
        }
        field(9; "Role Name"; Text[80])
        {
            Caption = 'Role Name';
        }
        field(10; "Security Group Code"; Code[20])
        {
            Caption = 'Security Group Code';
        }
        field(11; "Security Group Name"; Text[250])
        {
            Caption = 'Security Group Name';
        }
        field(12; "Source Notes"; Text[250])
        {
            Caption = 'Source Notes';
        }
        field(13; "Captured At"; DateTime)
        {
            Caption = 'Captured At';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(RunUserIdx; "Run ID", "User Security ID", "Company Name", "Role ID") { }
    }
}
