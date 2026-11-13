codeunit 50532 "BCG Wizard Mgt"
{
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";

    procedure CreateSimpleConflict(var Wizard: Record "BCG Wizard Buffer"; AutomaticallyProposedConflictId: Boolean)
    var
        Header: Record "BCG Conflict Header";
        Rule1Id: Code[30];
        Rule1BId: Code[30];
        Rule2Id: Code[30];
        Rule2BId: Code[30];
    begin
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Wizard Mgt");
        ValidateWizard(Wizard);

        Header.LockTable();
        if Header.Get(Wizard."Conflict ID") then begin
            if AutomaticallyProposedConflictId then
                Wizard."Conflict ID" := GetNextCustomConflictId()
            else
                Error('Conflict %1 already exists.', Wizard."Conflict ID");
        end;

        Header.Init();
        Header."Conflict ID" := Wizard."Conflict ID";
        Header.Name := Wizard."Conflict Name";
        Header.Category := Wizard.Category;
        Header.Severity := Wizard.Severity;
        Header."Is Active" := true;
        Header.Recommendation := Wizard.Recommendation;
        Header.Insert();

        InsertGroup(Wizard."Conflict ID", 10000, Wizard."Group 1 Name", Wizard."Group 1 Logic", 10);
        InsertGroup(Wizard."Conflict ID", 20000, Wizard."Group 2 Name", Wizard."Group 2 Logic", 20);

        Rule1Id := EnsureRule(
            Wizard."Group 1 Table Data ID",
            Wizard."Group 1 Table Data Name",
            Wizard."Group 1 Requires Read",
            Wizard."Group 1 Requires Insert",
            Wizard."Group 1 Requires Modify",
            Wizard."Group 1 Requires Delete",
            Wizard."G1 Read Perm Match",
            Wizard."G1 Insert Perm Match",
            Wizard."G1 Modify Perm Match",
            Wizard."G1 Delete Perm Match",
            Wizard."Group 1 Permission Match Mode");

        if Wizard."Group 1 Table Data ID 2" <> 0 then
            Rule1BId := EnsureRule(
                Wizard."Group 1 Table Data ID 2",
                Wizard."Group 1 Table Data Name 2",
                Wizard."Group 1 Requires Read",
                Wizard."Group 1 Requires Insert",
                Wizard."Group 1 Requires Modify",
                Wizard."Group 1 Requires Delete",
                Wizard."G1 Read Perm Match",
                Wizard."G1 Insert Perm Match",
                Wizard."G1 Modify Perm Match",
                Wizard."G1 Delete Perm Match",
                Wizard."Group 1 Permission Match Mode");

        Rule2Id := EnsureRule(
            Wizard."Group 2 Table Data ID",
            Wizard."Group 2 Table Data Name",
            Wizard."Group 2 Requires Read",
            Wizard."Group 2 Requires Insert",
            Wizard."Group 2 Requires Modify",
            Wizard."Group 2 Requires Delete",
            Wizard."G2 Read Perm Match",
            Wizard."G2 Insert Perm Match",
            Wizard."G2 Modify Perm Match",
            Wizard."G2 Delete Perm Match",
            Wizard."Group 2 Permission Match Mode");

        if Wizard."Group 2 Table Data ID 2" <> 0 then
            Rule2BId := EnsureRule(
                Wizard."Group 2 Table Data ID 2",
                Wizard."Group 2 Table Data Name 2",
                Wizard."Group 2 Requires Read",
                Wizard."Group 2 Requires Insert",
                Wizard."Group 2 Requires Modify",
                Wizard."Group 2 Requires Delete",
                Wizard."G2 Read Perm Match",
                Wizard."G2 Insert Perm Match",
                Wizard."G2 Modify Perm Match",
                Wizard."G2 Delete Perm Match",
                Wizard."Group 2 Permission Match Mode");

        InsertGroupRule(Wizard."Conflict ID", 10000, 10000, Rule1Id);
        if Rule1BId <> '' then
            InsertGroupRule(Wizard."Conflict ID", 10000, 20000, Rule1BId);

        InsertGroupRule(Wizard."Conflict ID", 20000, 10000, Rule2Id);
        if Rule2BId <> '' then
            InsertGroupRule(Wizard."Conflict ID", 20000, 20000, Rule2BId);

    end;

    procedure GetNextCustomConflictId(): Code[20]
    var
        Header: Record "BCG Conflict Header";
        ConflictNo: Integer;
        HighestConflictNo: Integer;
        ConflictNoText: Text;
    begin
        Header.SetFilter("Conflict ID", 'CUST-*');
        if Header.FindSet() then
            repeat
                ConflictNoText := CopyStr(Header."Conflict ID", 6);
                if (ConflictNoText <> '') and Evaluate(ConflictNo, ConflictNoText) then
                    if (ConflictNo > 0) and (ConflictNo > HighestConflictNo) then
                        HighestConflictNo := ConflictNo;
            until Header.Next() = 0;

        ConflictNo := HighestConflictNo + 1;
        ConflictNoText := Format(ConflictNo);
        if StrLen(ConflictNoText) < 3 then
            ConflictNoText := PadStr('', 3 - StrLen(ConflictNoText), '0') + ConflictNoText;

        exit(CopyStr('CUST-' + ConflictNoText, 1, 20));
    end;

    local procedure ValidateWizard(Wizard: Record "BCG Wizard Buffer")
    begin
        if Wizard."Conflict ID" = '' then
            Error('Conflict ID is required.');
        if Wizard."Conflict Name" = '' then
            Error('Conflict Name is required.');
        if Wizard."Group 1 Name" = '' then
            Error('Group 1 Name is required.');
        if Wizard."Group 2 Name" = '' then
            Error('Group 2 Name is required.');
        if Wizard."Group 1 Table Data ID" = 0 then
            Error('Group 1 Table Data ID is required.');
        if Wizard."Group 2 Table Data ID" = 0 then
            Error('Group 2 Table Data ID is required.');
        if not HasAnyPermissionFlag(Wizard."Group 1 Requires Read", Wizard."Group 1 Requires Insert", Wizard."Group 1 Requires Modify", Wizard."Group 1 Requires Delete") then
            Error('Select at least one required permission for Group 1.');
        if not HasAnyPermissionFlag(Wizard."Group 2 Requires Read", Wizard."Group 2 Requires Insert", Wizard."Group 2 Requires Modify", Wizard."Group 2 Requires Delete") then
            Error('Select at least one required permission for Group 2.');
    end;

    local procedure InsertGroup(ConflictId: Code[20]; GroupNo: Integer; GroupName: Text[100]; Logic: Enum "BCG Group Eval Logic"; Sequence: Integer)
    var
        Group: Record "BCG Conflict Group";
    begin
        Group.Init();
        Group."Conflict ID" := ConflictId;
        Group."Group No." := GroupNo;
        Group."Group Name" := GroupName;
        Group."Evaluation Logic" := Logic;
        Group.Sequence := Sequence;
        Group."Is Active" := true;
        Group.Insert();
    end;

    local procedure EnsureRule(ObjectId: Integer; ObjectCaption: Text[100]; ReqRead: Boolean; ReqInsert: Boolean; ReqModify: Boolean; ReqDelete: Boolean; ReadPermissionMatch: Enum "BCG Table Data Perm Match"; InsertPermissionMatch: Enum "BCG Table Data Perm Match"; ModifyPermissionMatch: Enum "BCG Table Data Perm Match"; DeletePermissionMatch: Enum "BCG Table Data Perm Match"; PermissionMatchMode: Option Any,All): Code[30]
    var
        Rule: Record "BCG Rule Dictionary";
        RuleId: Code[30];
        PermissionSummary: Text[30];
    begin
        NormalizePermissionMatch(ReqRead, ReadPermissionMatch);
        NormalizePermissionMatch(ReqInsert, InsertPermissionMatch);
        NormalizePermissionMatch(ReqModify, ModifyPermissionMatch);
        NormalizePermissionMatch(ReqDelete, DeletePermissionMatch);

        PermissionSummary := GetPermissionSummary(ReqRead, ReqInsert, ReqModify, ReqDelete);
        RuleId := GetRuleId(ObjectId, PermissionSummary, ReqRead, ReqInsert, ReqModify, ReqDelete, ReadPermissionMatch, InsertPermissionMatch, ModifyPermissionMatch, DeletePermissionMatch, PermissionMatchMode);

        if Rule.Get(RuleId) then begin
            // Generated names are not proof that an existing, editable definition still matches.
            Rule.TestField("Is Active", true);
            Rule.TestField("Object Type", Rule."Object Type"::"Table Data");
            Rule.TestField("Object ID", ObjectId);
            Rule.TestField("Required Permission", GetLegacyPermissionFromFlags(ReqRead, ReqInsert, ReqModify, ReqDelete));
            Rule.TestField("Requires Read", ReqRead);
            Rule.TestField("Requires Insert", ReqInsert);
            Rule.TestField("Requires Modify", ReqModify);
            Rule.TestField("Requires Delete", ReqDelete);
            Rule.TestField("Read Permission Match", ReadPermissionMatch);
            Rule.TestField("Insert Permission Match", InsertPermissionMatch);
            Rule.TestField("Modify Permission Match", ModifyPermissionMatch);
            Rule.TestField("Delete Permission Match", DeletePermissionMatch);
            Rule.TestField("Permission Match Mode", PermissionMatchMode);
            exit(RuleId);
        end;

        Rule.Init();
        Rule."Rule ID" := RuleId;
        Rule."Rule Name" := CopyStr(StrSubstNo('%1 access: %2', ObjectCaption, PermissionSummary), 1, MaxStrLen(Rule."Rule Name"));
        Rule."Object Type" := Rule."Object Type"::"Table Data";
        Rule."Object ID" := ObjectId;
        Rule."Object Caption" := ObjectCaption;
        Rule."Required Permission" := GetLegacyPermissionFromFlags(ReqRead, ReqInsert, ReqModify, ReqDelete);
        Rule."Requires Read" := ReqRead;
        Rule."Requires Insert" := ReqInsert;
        Rule."Requires Modify" := ReqModify;
        Rule."Requires Delete" := ReqDelete;
        Rule."Read Permission Match" := ReadPermissionMatch;
        Rule."Insert Permission Match" := InsertPermissionMatch;
        Rule."Modify Permission Match" := ModifyPermissionMatch;
        Rule."Delete Permission Match" := DeletePermissionMatch;
        SetRulePermissionMatchMode(Rule, PermissionMatchMode);
        Rule."Is Active" := true;
        Rule.Notes := 'Created from simple wizard';
        Rule.Insert();

        exit(RuleId);
    end;

    local procedure InsertGroupRule(ConflictId: Code[20]; GroupNo: Integer; LineNo: Integer; RuleId: Code[30])
    var
        GroupRule: Record "BCG Conflict Group Rule";
    begin
        GroupRule.Init();
        GroupRule."Conflict ID" := ConflictId;
        GroupRule."Group No." := GroupNo;
        GroupRule."Line No." := LineNo;
        GroupRule.Validate("Rule ID", RuleId);
        GroupRule.Insert();
    end;

    local procedure SetRulePermissionMatchMode(var Rule: Record "BCG Rule Dictionary"; PermissionMatchMode: Option Any,All)
    begin
        case PermissionMatchMode of
            PermissionMatchMode::All:
                Rule."Permission Match Mode" := Rule."Permission Match Mode"::All;
            else
                Rule."Permission Match Mode" := Rule."Permission Match Mode"::Any;
        end;
    end;

    local procedure GetRuleId(ObjectId: Integer; PermissionSummary: Text[30]; ReqRead: Boolean; ReqInsert: Boolean; ReqModify: Boolean; ReqDelete: Boolean; ReadPermissionMatch: Enum "BCG Table Data Perm Match"; InsertPermissionMatch: Enum "BCG Table Data Perm Match"; ModifyPermissionMatch: Enum "BCG Table Data Perm Match"; DeletePermissionMatch: Enum "BCG Table Data Perm Match"; PermissionMatchMode: Option Any,All): Code[30]
    var
        MatchCode: Text[8];
        ModeCode: Code[3];
    begin
        MatchCode := GetMatchCode(ReqRead, ReqInsert, ReqModify, ReqDelete, ReadPermissionMatch, InsertPermissionMatch, ModifyPermissionMatch, DeletePermissionMatch);
        if PermissionMatchMode = PermissionMatchMode::All then
            ModeCode := 'ALL'
        else
            ModeCode := 'ANY';
        exit(CopyStr(StrSubstNo('TD%1-%2-%3-%4', ObjectId, PermissionSummary, MatchCode, ModeCode), 1, 30));
    end;

    local procedure HasAnyPermissionFlag(ReqRead: Boolean; ReqInsert: Boolean; ReqModify: Boolean; ReqDelete: Boolean): Boolean
    begin
        exit(ReqRead or ReqInsert or ReqModify or ReqDelete);
    end;

    local procedure GetLegacyPermissionFromFlags(ReqRead: Boolean; ReqInsert: Boolean; ReqModify: Boolean; ReqDelete: Boolean): Enum "BCG Access Type"
    var
        AccessType: Enum "BCG Access Type";
    begin
        if ReqModify then
            exit(AccessType::Modify);
        if ReqInsert then
            exit(AccessType::Insert);
        if ReqDelete then
            exit(AccessType::Delete);
        if ReqRead then
            exit(AccessType::Read);

        exit(AccessType::Read);
    end;

    local procedure GetPermissionSummary(ReqRead: Boolean; ReqInsert: Boolean; ReqModify: Boolean; ReqDelete: Boolean): Text[30]
    var
        ResultText: Text[30];
    begin
        if ReqRead then
            ResultText := CopyStr(ResultText + 'R', 1, MaxStrLen(ResultText));
        if ReqInsert then
            ResultText := CopyStr(ResultText + 'I', 1, MaxStrLen(ResultText));
        if ReqModify then
            ResultText := CopyStr(ResultText + 'M', 1, MaxStrLen(ResultText));
        if ReqDelete then
            ResultText := CopyStr(ResultText + 'D', 1, MaxStrLen(ResultText));

        if ResultText = '' then
            Error('At least one required permission must be selected.');

        exit(ResultText);
    end;

    local procedure GetMatchCode(ReqRead: Boolean; ReqInsert: Boolean; ReqModify: Boolean; ReqDelete: Boolean; ReadPermissionMatch: Enum "BCG Table Data Perm Match"; InsertPermissionMatch: Enum "BCG Table Data Perm Match"; ModifyPermissionMatch: Enum "BCG Table Data Perm Match"; DeletePermissionMatch: Enum "BCG Table Data Perm Match"): Text[8]
    var
        ResultText: Text[8];
    begin
        if ReqRead then
            ResultText := CopyStr(ResultText + GetPermissionMatchCode(ReadPermissionMatch), 1, MaxStrLen(ResultText));
        if ReqInsert then
            ResultText := CopyStr(ResultText + GetPermissionMatchCode(InsertPermissionMatch), 1, MaxStrLen(ResultText));
        if ReqModify then
            ResultText := CopyStr(ResultText + GetPermissionMatchCode(ModifyPermissionMatch), 1, MaxStrLen(ResultText));
        if ReqDelete then
            ResultText := CopyStr(ResultText + GetPermissionMatchCode(DeletePermissionMatch), 1, MaxStrLen(ResultText));

        exit(ResultText);
    end;

    local procedure NormalizePermissionMatch(var IsRequired: Boolean; var PermissionMatch: Enum "BCG Table Data Perm Match")
    begin
        if IsRequired then begin
            if PermissionMatch = PermissionMatch::"Not Required" then
                PermissionMatch := PermissionMatch::"Direct or Indirect";
        end else
            IsRequired := PermissionMatch <> PermissionMatch::"Not Required";
    end;

    local procedure GetPermissionMatchCode(PermissionMatch: Enum "BCG Table Data Perm Match"): Code[2]
    begin
        case PermissionMatch of
            PermissionMatch::"Direct Only":
                exit('DO');
            PermissionMatch::"Direct or Indirect":
                exit('DI');
        end;

        Error('A required permission must use Direct Only or Direct or Indirect matching.');
    end;
}
