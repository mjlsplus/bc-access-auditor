tableextension 50575 "BCG ConfRes User Context" extends "BCG User Conflict Result"
{
    fields
    {
        field(50675; "User Has Security Group"; Boolean)
        {
            Caption = 'User Has Security Group';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50676; "User Security Group Count"; Integer)
        {
            Caption = 'User Security Group Count';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50677; "User Security Group Summary"; Text[250])
        {
            Caption = 'User Security Group Summary';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
