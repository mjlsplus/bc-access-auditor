table 50504 "BCG User Permission Demo"
{
    Caption = 'BCAA User Permission Demo';
    DataClassification = CustomerContent;
    ObsoleteState = Pending;
    ObsoleteReason = 'Legacy demo workflow is no longer used.';
    ObsoleteTag = '5.0.0.0';

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "User ID"; Code[50]) { Caption = 'User ID'; }
        field(3; "User Name"; Text[100]) { Caption = 'User Name'; }
        field(4; "Object Type"; Enum "BCG Object Type") { Caption = 'Object Type'; InitValue = "Table Data"; Editable = false; }
        field(5; "Object ID"; Integer) { Caption = 'Table Data ID'; }
        field(6; "Object Caption"; Text[100]) { Caption = 'Table Data Name'; }
        field(7; "Access Type"; Enum "BCG Access Type") { Caption = 'Access Type'; }
        field(8; "Permission Source"; Text[100]) { Caption = 'Permission Source'; }
        field(9; "Company Name"; Text[50]) { Caption = 'Company Name'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(UserObject; "User ID", "Object Type", "Object ID", "Access Type") { }
    }

    trigger OnInsert()
    begin
        "Object Type" := "Object Type"::"Table Data";
    end;
}
