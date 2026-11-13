table 50503 "BCG Conflict Group Rule"
{
    Caption = 'BCAA Conflict Group Rule';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Conflict ID"; Code[20])
        {
            Caption = 'Conflict ID';
            TableRelation = "BCG Conflict Header"."Conflict ID";
        }
        field(2; "Group No."; Integer)
        {
            Caption = 'Group No.';
            TableRelation = "BCG Conflict Group"."Group No." where("Conflict ID" = field("Conflict ID"));
        }
        field(3; "Line No."; Integer) { Caption = 'Line No.'; }
        field(4; "Rule ID"; Code[30])
        {
            Caption = 'Rule ID';
            TableRelation = "BCG Rule Dictionary"."Rule ID" where("Is Active" = const(true));

            trigger OnValidate()
            var
                Rule: Record "BCG Rule Dictionary";
            begin
                if Rule.Get("Rule ID") then begin
                    "Rule Name" := Rule."Rule Name";
                    "Object ID" := Rule."Object ID";
                    "Object Caption" := Rule."Object Caption";
                    "Required Permission" := Rule."Required Permission";
                    "Requires Read" := Rule."Requires Read";
                    "Requires Insert" := Rule."Requires Insert";
                    "Requires Modify" := Rule."Requires Modify";
                    "Requires Delete" := Rule."Requires Delete";
                    "Read Permission Match" := Rule."Read Permission Match";
                    "Insert Permission Match" := Rule."Insert Permission Match";
                    "Modify Permission Match" := Rule."Modify Permission Match";
                    "Delete Permission Match" := Rule."Delete Permission Match";
                    "Permission Match Mode" := Rule."Permission Match Mode";
                end;
            end;
        }
        field(5; "Rule Name"; Text[100]) { Caption = 'Rule Name'; Editable = false; }
        field(6; "Object ID"; Integer) { Caption = 'Table Data ID'; Editable = false; }
        field(7; "Object Caption"; Text[100]) { Caption = 'Table Data Name'; Editable = false; }
        field(8; "Required Permission"; Enum "BCG Access Type")
        {
            Caption = 'Required Permission (Legacy)';
            Editable = false;

        }
        field(20; "Requires Read"; Boolean) { Caption = 'Requires Read'; Editable = false; }
        field(21; "Requires Insert"; Boolean) { Caption = 'Requires Insert'; Editable = false; }
        field(22; "Requires Modify"; Boolean) { Caption = 'Requires Modify'; Editable = false; }
        field(23; "Requires Delete"; Boolean) { Caption = 'Requires Delete'; Editable = false; }
        field(30; "Read Permission Match"; Enum "BCG Table Data Perm Match") { Caption = 'Read Permission Match'; Editable = false; }
        field(31; "Insert Permission Match"; Enum "BCG Table Data Perm Match") { Caption = 'Insert Permission Match'; Editable = false; }
        field(32; "Modify Permission Match"; Enum "BCG Table Data Perm Match") { Caption = 'Modify Permission Match'; Editable = false; }
        field(33; "Delete Permission Match"; Enum "BCG Table Data Perm Match") { Caption = 'Delete Permission Match'; Editable = false; }
        field(25; "Permission Match Mode"; Option)
        {
            Caption = 'Permission Match Mode';
            OptionMembers = Any,All;
            OptionCaption = 'Any,All';
            InitValue = Any;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Conflict ID", "Group No.", "Line No.") { Clustered = true; }
        key(RuleKey; "Rule ID") { }
    }
}
