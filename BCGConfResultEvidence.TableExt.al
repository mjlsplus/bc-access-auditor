tableextension 50569 "BCG Conf Result Evidence" extends "BCG User Conflict Result"
{
    fields
    {
        field(50668; "Matched Group Count"; Integer)
        {
            Caption = 'Matched Group Count';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50669; "Matched Rule Count"; Integer)
        {
            Caption = 'Matched Rule Count';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50670; "Matched Object Count"; Integer)
        {
            Caption = 'Matched Object Count';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50671; "Matched Groups Summary"; Text[500])
        {
            Caption = 'Matched Groups Summary';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50672; "Matched Objects Summary"; Text[1000])
        {
            Caption = 'Matched Objects Summary';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50673; "Matched Permissions Summary"; Text[2048])
        {
            Caption = 'Matched Permissions Summary';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50674; "Conflict Evidence Summary"; Text[2048])
        {
            Caption = 'Conflict Evidence Summary';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
