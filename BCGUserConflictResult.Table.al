table 50580 "BCG User Conflict Result"
{
    Caption = 'BCAA User Conflict Result';
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
            TableRelation = "BCG Audit Run"."Run ID";
        }

        field(3; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
        }

        field(4; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
        }

        field(5; "Conflict Code"; Code[50])
        {
            Caption = 'Conflict Code';
        }

        field(6; "Conflict Name"; Text[250])
        {
            Caption = 'Conflict Name';
        }

        field(7; Severity; Option)
        {
            Caption = 'Severity';
            OptionMembers = Low,Medium,High,Critical;
            OptionCaption = 'Low,Medium,High,Critical';
        }

        field(8; "Detected At"; DateTime)
        {
            Caption = 'Detected At';
        }

        field(9; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Open,Accepted,Resolved,Ignored;
            OptionCaption = 'Open,Accepted,Resolved,Ignored';
        }

        field(10; "Object A ID"; Integer)
        {
            Caption = 'Object A ID';
        }

        field(11; "Object A Name"; Text[249])
        {
            Caption = 'Object A Name';
        }

        field(12; "Object A Permission"; Text[30])
        {
            Caption = 'Object A Permission';
        }

        field(13; "Object B ID"; Integer)
        {
            Caption = 'Object B ID';
        }

        field(14; "Object B Name"; Text[249])
        {
            Caption = 'Object B Name';
        }

        field(15; "Object B Permission"; Text[30])
        {
            Caption = 'Object B Permission';
        }

        field(16; "Result Description"; Text[500])
        {
            Caption = 'Result Description';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(RunUserConflict; "Run ID", "User Security ID", "Company Name", "Conflict Code")
        {
        }

        key(RunConflict; "Run ID", "Conflict Code")
        {
        }
    }
}
