table 50530 "BCG Wizard Buffer"
{
    Caption = 'BCAA Wizard Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; }
        field(2; "Conflict ID"; Code[20]) { Caption = 'Conflict ID'; }
        field(3; "Conflict Name"; Text[100]) { Caption = 'Conflict Name'; }
        field(4; Category; Text[50]) { Caption = 'Category'; }
        field(5; Severity; Enum "BCG Severity") { Caption = 'Severity'; InitValue = Medium; }
        field(6; Recommendation; Text[250]) { Caption = 'Recommendation'; }

        field(10; "Group 1 Name"; Text[100]) { Caption = 'Group 1 Name'; }
        field(11; "Group 1 Logic"; Enum "BCG Group Eval Logic") { Caption = 'Group 1 Logic'; InitValue = ANY; }
        field(12; "Group 1 Table Data ID"; Integer)
        {
            Caption = 'Group 1 Table Data ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(TableData));

            trigger OnValidate()
            var
                AllObj: Record AllObjWithCaption;
            begin
                if AllObj.Get(AllObj."Object Type"::TableData, "Group 1 Table Data ID") then
                    "Group 1 Table Data Name" := CopyStr(AllObj."Object Caption", 1, MaxStrLen("Group 1 Table Data Name"));
            end;
        }
        field(13; "Group 1 Table Data Name"; Text[100]) { Caption = 'Group 1 Table Data Name'; Editable = false; }
        field(15; "Group 1 Table Data ID 2"; Integer)
        {
            Caption = 'Group 1 Table Data ID 2';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(TableData));

            trigger OnValidate()
            var
                AllObj: Record AllObjWithCaption;
            begin
                if "Group 1 Table Data ID 2" = 0 then begin
                    "Group 1 Table Data Name 2" := '';
                    exit;
                end;

                if AllObj.Get(AllObj."Object Type"::TableData, "Group 1 Table Data ID 2") then
                    "Group 1 Table Data Name 2" := CopyStr(AllObj."Object Caption", 1, MaxStrLen("Group 1 Table Data Name 2"));
            end;
        }
        field(16; "Group 1 Table Data Name 2"; Text[100]) { Caption = 'Group 1 Table Data Name 2'; Editable = false; }

        // Legacy field kept for compatibility with older wizard versions. New wizard uses granular permission flags below.
        field(14; "Group 1 Permission"; Enum "BCG Access Type")
        {
            Caption = 'Group 1 Required Permission (Legacy)';
            InitValue = Modify;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by granular Group 1 permission fields.';
            ObsoleteTag = '5.0.0.0';
        }

        field(30; "Group 1 Requires Read"; Boolean)
        {
            Caption = 'Read';

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Group 1 Requires Read", "G1 Read Perm Match");
            end;
        }
        field(31; "Group 1 Requires Insert"; Boolean)
        {
            Caption = 'Insert';

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Group 1 Requires Insert", "G1 Insert Perm Match");
            end;
        }
        field(32; "Group 1 Requires Modify"; Boolean)
        {
            Caption = 'Modify';

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Group 1 Requires Modify", "G1 Modify Perm Match");
            end;
        }
        field(33; "Group 1 Requires Delete"; Boolean)
        {
            Caption = 'Delete';

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Group 1 Requires Delete", "G1 Delete Perm Match");
            end;
        }
        field(34; "Group 1 Permission Match Mode"; Option)
        {
            Caption = 'Permission Match Mode';
            OptionMembers = Any,All;
            OptionCaption = 'Any,All';
            InitValue = Any;
        }
        field(35; "G1 Read Perm Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Read Permission Match';

            trigger OnValidate()
            begin
                "Group 1 Requires Read" := "G1 Read Perm Match" <> "G1 Read Perm Match"::"Not Required";
            end;
        }
        field(36; "G1 Insert Perm Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Insert Permission Match';

            trigger OnValidate()
            begin
                "Group 1 Requires Insert" := "G1 Insert Perm Match" <> "G1 Insert Perm Match"::"Not Required";
            end;
        }
        field(37; "G1 Modify Perm Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Modify Permission Match';

            trigger OnValidate()
            begin
                "Group 1 Requires Modify" := "G1 Modify Perm Match" <> "G1 Modify Perm Match"::"Not Required";
            end;
        }
        field(38; "G1 Delete Perm Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Delete Permission Match';

            trigger OnValidate()
            begin
                "Group 1 Requires Delete" := "G1 Delete Perm Match" <> "G1 Delete Perm Match"::"Not Required";
            end;
        }

        field(20; "Group 2 Name"; Text[100]) { Caption = 'Group 2 Name'; }
        field(21; "Group 2 Logic"; Enum "BCG Group Eval Logic") { Caption = 'Group 2 Logic'; InitValue = ANY; }
        field(22; "Group 2 Table Data ID"; Integer)
        {
            Caption = 'Group 2 Table Data ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(TableData));

            trigger OnValidate()
            var
                AllObj: Record AllObjWithCaption;
            begin
                if AllObj.Get(AllObj."Object Type"::TableData, "Group 2 Table Data ID") then
                    "Group 2 Table Data Name" := CopyStr(AllObj."Object Caption", 1, MaxStrLen("Group 2 Table Data Name"));
            end;
        }
        field(23; "Group 2 Table Data Name"; Text[100]) { Caption = 'Group 2 Table Data Name'; Editable = false; }
        field(25; "Group 2 Table Data ID 2"; Integer)
        {
            Caption = 'Group 2 Table Data ID 2';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(TableData));

            trigger OnValidate()
            var
                AllObj: Record AllObjWithCaption;
            begin
                if "Group 2 Table Data ID 2" = 0 then begin
                    "Group 2 Table Data Name 2" := '';
                    exit;
                end;

                if AllObj.Get(AllObj."Object Type"::TableData, "Group 2 Table Data ID 2") then
                    "Group 2 Table Data Name 2" := CopyStr(AllObj."Object Caption", 1, MaxStrLen("Group 2 Table Data Name 2"));
            end;
        }
        field(26; "Group 2 Table Data Name 2"; Text[100]) { Caption = 'Group 2 Table Data Name 2'; Editable = false; }

        // Legacy field kept for compatibility with older wizard versions. New wizard uses granular permission flags below.
        field(24; "Group 2 Permission"; Enum "BCG Access Type")
        {
            Caption = 'Group 2 Required Permission (Legacy)';
            InitValue = Modify;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by granular Group 2 permission fields.';
            ObsoleteTag = '5.0.0.0';
        }

        field(40; "Group 2 Requires Read"; Boolean)
        {
            Caption = 'Read';

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Group 2 Requires Read", "G2 Read Perm Match");
            end;
        }
        field(41; "Group 2 Requires Insert"; Boolean)
        {
            Caption = 'Insert';

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Group 2 Requires Insert", "G2 Insert Perm Match");
            end;
        }
        field(42; "Group 2 Requires Modify"; Boolean)
        {
            Caption = 'Modify';

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Group 2 Requires Modify", "G2 Modify Perm Match");
            end;
        }
        field(43; "Group 2 Requires Delete"; Boolean)
        {
            Caption = 'Delete';

            trigger OnValidate()
            begin
                SyncMatchModeFromRequired("Group 2 Requires Delete", "G2 Delete Perm Match");
            end;
        }
        field(44; "Group 2 Permission Match Mode"; Option)
        {
            Caption = 'Permission Match Mode';
            OptionMembers = Any,All;
            OptionCaption = 'Any,All';
            InitValue = Any;
        }
        field(46; "G2 Read Perm Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Read Permission Match';

            trigger OnValidate()
            begin
                "Group 2 Requires Read" := "G2 Read Perm Match" <> "G2 Read Perm Match"::"Not Required";
            end;
        }
        field(47; "G2 Insert Perm Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Insert Permission Match';

            trigger OnValidate()
            begin
                "Group 2 Requires Insert" := "G2 Insert Perm Match" <> "G2 Insert Perm Match"::"Not Required";
            end;
        }
        field(48; "G2 Modify Perm Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Modify Permission Match';

            trigger OnValidate()
            begin
                "Group 2 Requires Modify" := "G2 Modify Perm Match" <> "G2 Modify Perm Match"::"Not Required";
            end;
        }
        field(49; "G2 Delete Perm Match"; Enum "BCG Table Data Perm Match")
        {
            Caption = 'Delete Permission Match';

            trigger OnValidate()
            begin
                "Group 2 Requires Delete" := "G2 Delete Perm Match" <> "G2 Delete Perm Match"::"Not Required";
            end;
        }

        field(45; "Group 2 Use Table 2"; Boolean)
        {
            Caption = 'Use Group 2 Table 2';

            trigger OnValidate()
            begin
                if not "Group 2 Use Table 2" then
                    Validate("Group 2 Table Data ID 2", 0);
            end;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    local procedure SyncMatchModeFromRequired(IsRequired: Boolean; var PermissionMatch: Enum "BCG Table Data Perm Match")
    begin
        if IsRequired then begin
            if PermissionMatch = PermissionMatch::"Not Required" then
                PermissionMatch := PermissionMatch::"Direct or Indirect";
        end else
            PermissionMatch := PermissionMatch::"Not Required";
    end;
}
