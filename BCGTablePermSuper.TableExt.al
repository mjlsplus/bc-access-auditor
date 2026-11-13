tableextension 50544 "BCG TablePerm Super" extends "BCG User Table Data Perm."
{
    fields
    {
        field(50640; "Is Special Permission"; Boolean)
        {
            Caption = 'Is Special Permission';
            DataClassification = CustomerContent;
        }

        field(50641; "Special Permission Type"; Enum "BCG Special Permission Type")
        {
            Caption = 'Special Permission Type';
            DataClassification = CustomerContent;
        }

        field(50642; "Applies To All Objects"; Boolean)
        {
            Caption = 'Applies To All Objects';
            DataClassification = CustomerContent;
        }

        field(50643; "Source Permission Set ID"; Code[30])
        {
            Caption = 'Source Permission Set ID';
            DataClassification = CustomerContent;
        }

        field(50644; "Source Permission Set Name"; Text[100])
        {
            Caption = 'Source Permission Set Name';
            DataClassification = CustomerContent;
        }

        field(50645; "BCG Assignment Source Type"; Enum "BCG Assignment Source Type")
        {
            Caption = 'Assignment Source Type';
            DataClassification = CustomerContent;
        }

        field(50646; "Special Permission Notes"; Text[250])
        {
            Caption = 'Special Permission Notes';
            DataClassification = CustomerContent;
        }
    }
}
