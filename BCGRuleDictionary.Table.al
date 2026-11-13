table 50502 "BCG Rule Dictionary"
{
    Caption = 'BCAA Rule Dictionary';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Rule ID"; Code[30])
        {
            Caption = 'Rule ID';
            DataClassification = CustomerContent;
        }

        field(2; "Rule Name"; Text[100])
        {
            Caption = 'Rule Name';
            DataClassification = CustomerContent;
        }

        field(3; "Object Type"; Enum "BCG Object Type")
        {
            Caption = 'Permission Object Type';
            DataClassification = CustomerContent;
            InitValue = "Table Data";
            Editable = false;
        }

        field(4; "Object ID"; Integer)
        {
            Caption = 'Table Data ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(TableData));

            trigger OnValidate()
            var
                AllObj: Record AllObjWithCaption;
            begin
                "Object Type" := "Object Type"::"Table Data";

                if AllObj.Get(AllObj."Object Type"::TableData, "Object ID") then
                    "Object Caption" := CopyStr(AllObj."Object Caption", 1, MaxStrLen("Object Caption"))
                else
                    Clear("Object Caption");
            end;
        }

        field(5; "Object Caption"; Text[100])
        {
            Caption = 'Table Data Name';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(6; "Required Permission"; Enum "BCG Access Type")
        {
            Caption = 'Required Permission (Legacy)';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                SetPermissionFlagsFromLegacyPermission();
            end;
        }

        field(20; "Requires Read"; Boolean)
        {
            Caption = 'Requires Read';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Requires Read", "Read Permission Match");
            end;
        }

        field(21; "Requires Insert"; Boolean)
        {
            Caption = 'Requires Insert';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Requires Insert", "Insert Permission Match");
            end;
        }

        field(22; "Requires Modify"; Boolean)
        {
            Caption = 'Requires Modify';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Requires Modify", "Modify Permission Match");
            end;
        }

        field(23; "Requires Delete"; Boolean)
        {
            Caption = 'Requires Delete';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Requires Delete", "Delete Permission Match");
            end;
        }

        field(30; "Read Permission Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Read Permission Match';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Requires Read" := "Read Permission Match" <> "Read Permission Match"::"Not Required";
            end;
        }

        field(31; "Insert Permission Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Insert Permission Match';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Requires Insert" := "Insert Permission Match" <> "Insert Permission Match"::"Not Required";
            end;
        }

        field(32; "Modify Permission Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Modify Permission Match';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Requires Modify" := "Modify Permission Match" <> "Modify Permission Match"::"Not Required";
            end;
        }

        field(33; "Delete Permission Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Delete Permission Match';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Requires Delete" := "Delete Permission Match" <> "Delete Permission Match"::"Not Required";
            end;
        }

        field(25; "Permission Match Mode"; Option)
        {
            Caption = 'Permission Match Mode';
            OptionMembers = Any,All;
            OptionCaption = 'Any,All';
            DataClassification = CustomerContent;
            InitValue = Any;
        }

        field(7; "Risk Weight"; Text[30])
        {
            Caption = 'Risk Weight';
            DataClassification = CustomerContent;
        }

        field(8; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
            DataClassification = CustomerContent;
            InitValue = true;
        }

        field(9; Notes; Text[250])
        {
            Caption = 'Notes';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Rule ID")
        {
            Clustered = true;
        }

        key(ObjectKey; "Object Type", "Object ID")
        {
        }
    }

    trigger OnInsert()
    begin
        "Object Type" := "Object Type"::"Table Data";

        if not ("Requires Read" or "Requires Insert" or "Requires Modify" or "Requires Delete") then
            SetPermissionFlagsFromLegacyPermission();
    end;

    trigger OnModify()
    begin
        "Object Type" := "Object Type"::"Table Data";
    end;

    local procedure SetPermissionFlagsFromLegacyPermission()
    begin
        ClearPermissionFlags();

        case "Required Permission" of
            "Required Permission"::Read:
                begin
                    "Requires Read" := true;
                    "Read Permission Match" := "Read Permission Match"::"Direct or Indirect";
                end;
            "Required Permission"::Insert:
                begin
                    "Requires Insert" := true;
                    "Insert Permission Match" := "Insert Permission Match"::"Direct or Indirect";
                end;
            "Required Permission"::Modify:
                begin
                    "Requires Modify" := true;
                    "Modify Permission Match" := "Modify Permission Match"::"Direct or Indirect";
                end;
            "Required Permission"::Delete:
                begin
                    "Requires Delete" := true;
                    "Delete Permission Match" := "Delete Permission Match"::"Direct or Indirect";
                end;
        end;
    end;

    local procedure ClearPermissionFlags()
    begin
        "Requires Read" := false;
        "Requires Insert" := false;
        "Requires Modify" := false;
        "Requires Delete" := false;
        "Read Permission Match" := "Read Permission Match"::"Not Required";
        "Insert Permission Match" := "Insert Permission Match"::"Not Required";
        "Modify Permission Match" := "Modify Permission Match"::"Not Required";
        "Delete Permission Match" := "Delete Permission Match"::"Not Required";
    end;

    local procedure SyncMatchModeFromRequired(IsRequired: Boolean; var PermissionMatch: Enum "BCG Table Data Perm Match")
    begin
        if IsRequired then begin
            if PermissionMatch = PermissionMatch::"Not Required" then
                PermissionMatch := PermissionMatch::"Direct or Indirect";
        end else
            PermissionMatch := PermissionMatch::"Not Required";
    end;
}
