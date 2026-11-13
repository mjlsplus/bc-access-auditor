tableextension 50574 "BCG TablePerm Special UX" extends "BCG User Table Data Perm."
{
    fields
    {
        field(50655; "Has SUPER"; Boolean)
        {
            Caption = 'Has SUPER';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50656; "Has SUPER DATA"; Boolean)
        {
            Caption = 'Has SUPER DATA';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50657; "Special Permission Summary"; Text[250])
        {
            Caption = 'Special Permission Summary';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
