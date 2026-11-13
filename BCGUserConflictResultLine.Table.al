table 50582 "BCG User Conflict Result Line"
{
    Caption = 'BCAA User Conflict Result Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Conflict Result Entry No."; Integer)
        {
            Caption = 'Conflict Result Entry No.';
            TableRelation = "BCG User Conflict Result"."Entry No.";
        }
        field(3; "Run ID"; Guid)
        {
            Caption = 'Run ID';
            TableRelation = "BCG Audit Run"."Run ID";
        }
        field(4; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
        }
        field(5; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
        }
        field(6; "Conflict Code"; Code[50])
        {
            Caption = 'Conflict Code';
        }
        field(7; "Conflict Name"; Text[250])
        {
            Caption = 'Conflict Name';
        }
        field(8; "Group No."; Integer)
        {
            Caption = 'Group No.';
        }
        field(9; "Group Name"; Text[100])
        {
            Caption = 'Group Name';
        }
        field(10; "Evaluation Logic"; Text[30])
        {
            Caption = 'Evaluation Logic';
        }
        field(11; "Rule ID"; Code[30])
        {
            Caption = 'Rule ID';
        }
        field(12; "Rule Name"; Text[100])
        {
            Caption = 'Rule Name';
        }
        field(13; "Object ID"; Integer)
        {
            Caption = 'Object ID';
        }
        field(14; "Object Name"; Text[249])
        {
            Caption = 'Object Name';
        }
        field(15; "Required Permission"; Text[30])
        {
            Caption = 'Required Permission';
        }
        field(16; "Matched Permission"; Text[30])
        {
            Caption = 'Matched Permission';
        }
        field(17; "Role ID"; Code[30])
        {
            Caption = 'Permission Set ID';
        }
        field(18; "Role Name"; Text[100])
        {
            Caption = 'Permission Set Name';
        }
        field(19; "App ID"; Guid)
        {
            Caption = 'App ID';
        }
        field(20; "App Name"; Text[250])
        {
            Caption = 'App Name';
        }
        field(21; "Scope Text"; Text[30])
        {
            Caption = 'Scope';
        }
        field(22; "Assignment Source Type"; Text[30])
        {
            Caption = 'Assignment Source Type';
        }
        field(23; "Security Filter"; Text[2048])
        {
            Caption = 'Security Filter';
        }
        field(24; "Trace Notes"; Text[250])
        {
            Caption = 'Trace Notes';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ResultEntry; "Conflict Result Entry No.", "Group No.", "Rule ID", "Role ID")
        {
        }
        key(RunConflict; "Run ID", "User Security ID", "Company Name", "Conflict Code")
        {
        }
        key(SourceLookup; "Run ID", "User Security ID", "Company Name", "Object ID")
        {
        }
    }
}
