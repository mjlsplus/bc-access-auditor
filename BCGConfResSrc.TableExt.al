tableextension 50582 "BCG ConfRes Src" extends "BCG User Conflict Result"
{
    fields
    {
        field(50500; "Has Security Group Source"; Boolean)
        {
            Caption = 'Has Security Group Source';
            DataClassification = CustomerContent;
        }
        field(50501; "Has Direct Source"; Boolean)
        {
            Caption = 'Has Direct Source';
            DataClassification = CustomerContent;
        }
        field(50502; "Has Special Permission Source"; Boolean)
        {
            Caption = 'Has Special Permission Source';
            DataClassification = CustomerContent;
        }
        field(50503; "Primary Permission Source"; Option)
        {
            Caption = 'Primary Permission Source';
            OptionMembers = Unknown,Direct,"Security Group","Special Permission",Mixed;
            OptionCaption = 'Unknown,Direct,Security Group,Special Permission,Mixed';
            DataClassification = CustomerContent;
        }
        field(50504; "Permission Source Summary"; Text[250])
        {
            Caption = 'Permission Source Summary';
            DataClassification = CustomerContent;
        }
    }
}
