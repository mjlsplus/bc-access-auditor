tableextension 50583 "BCG ConfLine Src" extends "BCG User Conflict Result Line"
{
    fields
    {
        field(50500; "Permission Source Type"; Option)
        {
            Caption = 'Permission Source Type';
            OptionMembers = Unknown,Direct,"Security Group","Special Permission",Mixed;
            OptionCaption = 'Unknown,Direct,Security Group,Special Permission,Mixed';
            DataClassification = CustomerContent;
        }
        field(50501; "Source Permission Set ID"; Code[20])
        {
            Caption = 'Source Permission Set ID';
            DataClassification = CustomerContent;
        }
        field(50502; "Source Permission Set Name"; Text[80])
        {
            Caption = 'Source Permission Set Name';
            DataClassification = CustomerContent;
        }
        field(50503; "Is From Security Group"; Boolean)
        {
            Caption = 'Is From Security Group';
            DataClassification = CustomerContent;
        }
        field(50504; "Security Group Code"; Code[20])
        {
            Caption = 'Security Group Code';
            DataClassification = CustomerContent;
        }
        field(50505; "Security Group Name"; Text[250])
        {
            Caption = 'Security Group Name';
            DataClassification = CustomerContent;
        }
        field(50506; "Is Special Permission Source"; Boolean)
        {
            Caption = 'Is Special Permission Source';
            DataClassification = CustomerContent;
        }
        field(50507; "Source Company Name"; Text[30])
        {
            Caption = 'Source Company Name';
            DataClassification = CustomerContent;
        }
        field(50508; "Permission Source Summary"; Text[250])
        {
            Caption = 'Permission Source Summary';
            DataClassification = CustomerContent;
        }
        field(50509; "Source Notes"; Text[250])
        {
            Caption = 'Source Notes';
            DataClassification = CustomerContent;
        }
    }
}
