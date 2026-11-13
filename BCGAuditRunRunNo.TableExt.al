tableextension 50508 "BCG Audit Run Run No" extends "BCG Audit Run"
{
    fields
    {
        field(50650; "Run No."; Code[20])
        {
            Caption = 'Run No.';
            DataClassification = CustomerContent;
        }
        field(50651; "Run Description"; Text[100])
        {
            Caption = 'Run Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(BCG_RunNo; "Run No.") { }
    }
}
