page 50530 "BCG Simple Wizard"
{
    PageType = NavigatePage;
    SourceTable = "BCG Wizard Buffer";
    SourceTableTemporary = true;
    Caption = 'New SoD Conflict';
    ApplicationArea = All;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(Welcome)
            {
                Visible = Step1Visible;
                Caption = 'Step 1 - Conflict header';

                field("Conflict ID"; Rec."Conflict ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter a short unique conflict ID.';
                }
                field("Conflict Name"; Rec."Conflict Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter a business name for the conflict.';
                }
                field(Category; Rec.Category)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the business category used to organize this conflict definition; it does not change permission matching.';
                }
                field(Severity; Rec.Severity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the risk priority assigned to findings from this definition. It is configured manually, not calculated from user activity.';
                }
                field(Recommendation; Rec.Recommendation)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies suggested review or mitigation steps for this potential access risk; no access changes are performed automatically.';
                    MultiLine = true;
                }
            }

            group(GroupOne)
            {
                Visible = Step2Visible;
                Caption = 'Step 2 - Group 1';

                group(Group1Setup)
                {
                    Caption = 'Group 1 Setup';

                    field("Group 1 Name"; Rec."Group 1 Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the business capability on side 1 of the conflict. A user must match both groups for this conflict to be detected.';
                    }
                    field("Group 1 Logic"; Rec."Group 1 Logic")
                    {
                        ApplicationArea = All;
                        ToolTip = 'ANY means that one table/rule in this group is enough. ALL means that all tables/rules are required.';
                    }
                    field("Group 1 Permission Match Mode"; Rec."Group 1 Permission Match Mode")
                    {
                        ApplicationArea = All;
                        ToolTip = 'ANY means that one selected permission is enough. ALL means that all selected permissions are required.';
                    }
                }

                group(Group1Tables)
                {
                    Caption = 'Group 1 Tables';

                    group(Group1Table1)
                    {
                        Caption = 'Table 1';

                        field("Group 1 Table Data ID"; Rec."Group 1 Table Data ID")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies the first table checked on side 1. The selected permissions apply to each table in this group.';
                        }
                        field("Group 1 Table Data Name"; Rec."Group 1 Table Data Name")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Shows the name of the first table selected for group 1.';
                        }
                    }

                    group(Group1Table2)
                    {
                        Caption = 'Table 2';

                        field("Group 1 Table Data ID 2"; Rec."Group 1 Table Data ID 2")
                        {
                            ApplicationArea = All;
                            Caption = 'Group 1 Table Data ID 2';
                            ToolTip = 'Optional. Add a second table to the same conflict group.';
                        }
                        field("Group 1 Table Data Name 2"; Rec."Group 1 Table Data Name 2")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Shows the name of the optional second table selected for group 1.';
                            Caption = 'Group 1 Table Data Name 2';
                        }
                    }
                }

                group(Group1RequiredPermissions)
                {
                    Caption = 'Required Permissions for Group 1 Tables';

                    field("Group 1 Requires Read"; Rec."Group 1 Requires Read")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Includes permission to view records in the rules for group 1 tables. Selecting this defaults the match setting to Direct or Indirect; clearing it resets the setting to Not Required.';
                        Caption = 'Read';
                    }
                    field("G1 Read Perm Match"; Rec."G1 Read Perm Match")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies read matching for group 1: Direct Only accepts direct grants; Direct or Indirect accepts either. Either choice selects Requires Read; Not Required clears it. This is not the assignment route.';
                    }
                    field("Group 1 Requires Insert"; Rec."Group 1 Requires Insert")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Includes permission to create records in the rules for group 1 tables. Selecting this defaults the match setting to Direct or Indirect; clearing it resets the setting to Not Required.';
                        Caption = 'Insert';
                    }
                    field("G1 Insert Perm Match"; Rec."G1 Insert Perm Match")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies insert matching for group 1: Direct Only accepts direct grants; Direct or Indirect accepts either. Either choice selects Requires Insert; Not Required clears it. This is not the assignment route.';
                    }
                    field("Group 1 Requires Modify"; Rec."Group 1 Requires Modify")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Includes permission to change existing records in the rules for group 1 tables. Selecting this defaults the match setting to Direct or Indirect; clearing it resets the setting to Not Required.';
                        Caption = 'Modify';
                    }
                    field("G1 Modify Perm Match"; Rec."G1 Modify Perm Match")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies modify matching for group 1: Direct Only accepts direct grants; Direct or Indirect accepts either. Either choice selects Requires Modify; Not Required clears it. This is not the assignment route.';
                    }
                    field("Group 1 Requires Delete"; Rec."Group 1 Requires Delete")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Includes permission to remove records in the rules for group 1 tables. Selecting this defaults the match setting to Direct or Indirect; clearing it resets the setting to Not Required.';
                        Caption = 'Delete';
                    }
                    field("G1 Delete Perm Match"; Rec."G1 Delete Perm Match")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies delete matching for group 1: Direct Only accepts direct grants; Direct or Indirect accepts either. Either choice selects Requires Delete; Not Required clears it. This is not the assignment route.';
                    }
                }
            }

            group(GroupTwo)
            {
                Visible = Step3Visible;
                Caption = 'Step 3 - Group 2';

                group(Group2Setup)
                {
                    Caption = 'Group 2 Setup';

                    field("Group 2 Name"; Rec."Group 2 Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the business capability on side 2 of the conflict. A user must match both groups for this conflict to be detected.';
                    }
                    field("Group 2 Logic"; Rec."Group 2 Logic")
                    {
                        ApplicationArea = All;
                        ToolTip = 'ANY means that one table/rule in this group is enough. ALL means that all tables/rules are required.';
                    }
                    field("Group 2 Permission Match Mode"; Rec."Group 2 Permission Match Mode")
                    {
                        ApplicationArea = All;
                        ToolTip = 'ANY means that one selected permission is enough. ALL means that all selected permissions are required.';
                    }
                }

                group(Group2Tables)
                {
                    Caption = 'Group 2 Tables';

                    group(Group2Table1)
                    {
                        Caption = 'Table 1';

                        field("Group 2 Table Data ID"; Rec."Group 2 Table Data ID")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies the first table checked on side 2. The selected permissions apply to each table in this group.';
                        }
                        field("Group 2 Table Data Name"; Rec."Group 2 Table Data Name")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Shows the name of the first table selected for group 2.';
                        }
                    }

                    field("Group 2 Use Table 2"; Rec."Group 2 Use Table 2")
                    {
                        ApplicationArea = All;
                        Caption = 'Add optional Table 2';
                        ToolTip = 'Turn on only when this group requires a second table.';

                        trigger OnValidate()
                        begin
                            SetStepVisibility();
                        end;
                    }

                    group(Group2Table2)
                    {
                        Caption = 'Optional Table 2';
                        Visible = Group2Table2Visible;

                        field("Group 2 Table Data ID 2"; Rec."Group 2 Table Data ID 2")
                        {
                            ApplicationArea = All;
                            Caption = 'Group 2 Table Data ID 2';
                            ToolTip = 'Optional. Add a second table to the same conflict group.';
                        }
                        field("Group 2 Table Data Name 2"; Rec."Group 2 Table Data Name 2")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Shows the name of the optional second table selected for group 2.';
                            Caption = 'Group 2 Table Data Name 2';
                        }
                    }
                }

                group(Group2RequiredPermissions)
                {
                    Caption = 'Required Permissions for Group 2 Tables';

                    field("Group 2 Requires Read"; Rec."Group 2 Requires Read")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Includes permission to view records in the rules for group 2 tables. Selecting this defaults the match setting to Direct or Indirect; clearing it resets the setting to Not Required.';
                        Caption = 'Read';
                    }
                    field("G2 Read Perm Match"; Rec."G2 Read Perm Match")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies read matching for group 2: Direct Only accepts direct grants; Direct or Indirect accepts either. Either choice selects Requires Read; Not Required clears it. This is not the assignment route.';
                    }
                    field("Group 2 Requires Insert"; Rec."Group 2 Requires Insert")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Includes permission to create records in the rules for group 2 tables. Selecting this defaults the match setting to Direct or Indirect; clearing it resets the setting to Not Required.';
                        Caption = 'Insert';
                    }
                    field("G2 Insert Perm Match"; Rec."G2 Insert Perm Match")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies insert matching for group 2: Direct Only accepts direct grants; Direct or Indirect accepts either. Either choice selects Requires Insert; Not Required clears it. This is not the assignment route.';
                    }
                    field("Group 2 Requires Modify"; Rec."Group 2 Requires Modify")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Includes permission to change existing records in the rules for group 2 tables. Selecting this defaults the match setting to Direct or Indirect; clearing it resets the setting to Not Required.';
                        Caption = 'Modify';
                    }
                    field("G2 Modify Perm Match"; Rec."G2 Modify Perm Match")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies modify matching for group 2: Direct Only accepts direct grants; Direct or Indirect accepts either. Either choice selects Requires Modify; Not Required clears it. This is not the assignment route.';
                    }
                    field("Group 2 Requires Delete"; Rec."Group 2 Requires Delete")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Includes permission to remove records in the rules for group 2 tables. Selecting this defaults the match setting to Direct or Indirect; clearing it resets the setting to Not Required.';
                        Caption = 'Delete';
                    }
                    field("G2 Delete Perm Match"; Rec."G2 Delete Perm Match")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies delete matching for group 2: Direct Only accepts direct grants; Direct or Indirect accepts either. Either choice selects Requires Delete; Not Required clears it. This is not the assignment route.';
                    }
                }
            }

            group(Review)
            {
                Visible = Step4Visible;
                Caption = 'Step 4 - Review SoD Conflict Setup';

                group(ReviewHeader)
                {
                    Caption = 'Conflict';

                    field(ReviewConflictName; Rec."Conflict Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows the name of the potential access conflict to be created, not an analysis finding.';
                        Caption = 'Conflict Name';
                        Editable = false;
                    }
                    field(ReviewCategory; Rec.Category)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows the business category that will be saved with this conflict definition.';
                        Caption = 'Category';
                        Editable = false;
                    }
                    field(ReviewSeverity; Rec.Severity)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows the configured risk priority that will be assigned to findings from this conflict.';
                        Caption = 'Severity';
                        Editable = false;
                    }
                }

                group(ReviewMasterData)
                {
                    Caption = 'Group 1';

                    field(ReviewGroup1Logic; Rec."Group 1 Logic")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows how group 1 combines its table rules: Any requires one rule to match; All requires every rule to match.';
                        Caption = 'Logic';
                        Editable = false;
                    }
                    field(ReviewGroup1Tables; ReviewGroup1TablesTxt)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows the tables selected for side 1 of the conflict. Each uses this group''s configured permission requirements.';
                        Caption = 'Tables';
                        Editable = false;
                    }
                    field(ReviewGroup1Permissions; ReviewGroup1PermissionsTxt)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows the selected operations and grant types for group 1. The word or indicates Any permission matching; and indicates All.';
                        Caption = 'Required Permissions';
                        Editable = false;
                    }
                }

                group(ReviewPayment)
                {
                    Caption = 'Group 2';

                    field(ReviewGroup2Logic; Rec."Group 2 Logic")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows how group 2 combines its table rules: Any requires one rule to match; All requires every rule to match.';
                        Caption = 'Logic';
                        Editable = false;
                    }
                    field(ReviewGroup2Tables; ReviewGroup2TablesTxt)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows the tables selected for side 2 of the conflict. Each uses this group''s configured permission requirements.';
                        Caption = 'Tables';
                        Editable = false;
                    }
                    field(ReviewGroup2Permissions; ReviewGroup2PermissionsTxt)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows the selected operations and grant types for group 2. The word or indicates Any permission matching; and indicates All.';
                        Caption = 'Required Permissions';
                        Editable = false;
                    }
                }

                group(ReviewResultGroup)
                {
                    Caption = 'Result';

                    field(ReviewResult; ReviewResultTxt)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows the two sides of the conflict. A user matching both groups has a potential access risk; this does not establish misuse or prove that any action occurred.';
                        Caption = 'Conflict Rule';
                        Editable = false;
                        MultiLine = true;
                    }
                    field(ReviewRecommendation; Rec.Recommendation)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Shows the review or mitigation guidance that will be saved with this definition. It does not change user access.';
                        Caption = 'Recommendation';
                        Editable = false;
                        MultiLine = true;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Back)
            {
                Caption = 'Back';
                ApplicationArea = All;
                ToolTip = 'Return to the previous setup step without creating the conflict.';
                InFooterBar = true;
                Image = PreviousRecord;

                trigger OnAction()
                begin
                    if Step > 1 then
                        Step -= 1;
                    SetStepVisibility();
                end;
            }
            action(Next)
            {
                Caption = 'Next';
                ApplicationArea = All;
                ToolTip = 'Move to the next setup step. The conflict is validated and saved when you choose Finish.';
                InFooterBar = true;
                Image = NextRecord;

                trigger OnAction()
                begin
                    if Step < 4 then
                        Step += 1;
                    SetStepVisibility();
                end;
            }
            action(Finish)
            {
                Caption = 'Finish';
                ApplicationArea = All;
                ToolTip = 'Validate and save an active conflict with two groups and their permission rules. Run a new Full Analysis separately to evaluate user access.';
                InFooterBar = true;
                Image = Approve;

                trigger OnAction()
                var
                    WizardMgt: Codeunit "BCG Wizard Mgt";
                begin
                    WizardMgt.CreateSimpleConflict(Rec, Rec."Conflict ID" = ProposedConflictId);
                    Message('Conflict %1 was created successfully.', Rec."Conflict ID");
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        WizardMgt: Codeunit "BCG Wizard Mgt";
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Simple Wizard");
        Rec.Init();
        Rec."Entry No." := 1;
        if Rec."Conflict ID" = '' then begin
            Rec."Conflict ID" := WizardMgt.GetNextCustomConflictId();
            ProposedConflictId := Rec."Conflict ID";
        end;
        Rec.Severity := Rec.Severity::Medium;
        Rec."Group 1 Logic" := Rec."Group 1 Logic"::ANY;
        Rec."Group 1 Permission Match Mode" := Rec."Group 1 Permission Match Mode"::Any;

        Rec."Group 2 Logic" := Rec."Group 2 Logic"::ANY;
        Rec."Group 2 Permission Match Mode" := Rec."Group 2 Permission Match Mode"::Any;
        Rec.Insert();
        Step := 1;
        SetStepVisibility();
    end;

    local procedure SetStepVisibility()
    begin
        Step1Visible := Step = 1;
        Step2Visible := Step = 2;
        Step3Visible := Step = 3;
        Step4Visible := Step = 4;
        Group2Table2Visible := Rec."Group 2 Use Table 2" or (Rec."Group 2 Table Data ID 2" <> 0);

        if Step4Visible then
            SetReviewTexts();

        CurrPage.Update(false);
    end;

    local procedure SetReviewTexts()
    begin
        ReviewGroup1TablesTxt := GetTableListText(Rec."Group 1 Table Data Name", Rec."Group 1 Table Data Name 2");
        ReviewGroup2TablesTxt := GetTableListText(Rec."Group 2 Table Data Name", Rec."Group 2 Table Data Name 2");
        ReviewGroup1PermissionsTxt := GetPermissionText(
            Rec."Group 1 Requires Read", Rec."G1 Read Perm Match",
            Rec."Group 1 Requires Insert", Rec."G1 Insert Perm Match",
            Rec."Group 1 Requires Modify", Rec."G1 Modify Perm Match",
            Rec."Group 1 Requires Delete", Rec."G1 Delete Perm Match",
            Rec."Group 1 Permission Match Mode");
        ReviewGroup2PermissionsTxt := GetPermissionText(
            Rec."Group 2 Requires Read", Rec."G2 Read Perm Match",
            Rec."Group 2 Requires Insert", Rec."G2 Insert Perm Match",
            Rec."Group 2 Requires Modify", Rec."G2 Modify Perm Match",
            Rec."Group 2 Requires Delete", Rec."G2 Delete Perm Match",
            Rec."Group 2 Permission Match Mode");
        ReviewResultTxt := 'A conflict is detected when a user matches both groups: ' + Rec."Group 1 Name" + ' and ' + Rec."Group 2 Name" + '.';
    end;

    local procedure GetTableListText(TableName1: Text[100]; TableName2: Text[100]): Text[250]
    begin
        if TableName2 <> '' then
            exit(CopyStr(StrSubstNo('%1; %2', TableName1, TableName2), 1, 250));

        exit(TableName1);
    end;

    local procedure GetPermissionText(ReqRead: Boolean; ReadPermissionMatch: Enum "BCG Table Data Perm Match"; ReqInsert: Boolean; InsertPermissionMatch: Enum "BCG Table Data Perm Match"; ReqModify: Boolean; ModifyPermissionMatch: Enum "BCG Table Data Perm Match"; ReqDelete: Boolean; DeletePermissionMatch: Enum "BCG Table Data Perm Match"; PermissionMatchMode: Option Any,All): Text
    var
        ResultText: Text;
        Separator: Text[5];
    begin
        if PermissionMatchMode = PermissionMatchMode::All then
            Separator := ' and '
        else
            Separator := ' or ';

        AddPermissionText(ResultText, 'Read', ReadPermissionMatch, Separator, ReqRead);
        AddPermissionText(ResultText, 'Insert', InsertPermissionMatch, Separator, ReqInsert);
        AddPermissionText(ResultText, 'Modify', ModifyPermissionMatch, Separator, ReqModify);
        AddPermissionText(ResultText, 'Delete', DeletePermissionMatch, Separator, ReqDelete);

        if ResultText = '' then
            exit('Not selected');

        exit(ResultText);
    end;

    local procedure AddPermissionText(var ResultText: Text; PermissionName: Text[20]; PermissionMatch: Enum "BCG Table Data Perm Match"; Separator: Text[5]; AddPermission: Boolean)
    var
        PermissionText: Text;
    begin
        if not AddPermission then
            exit;

        if PermissionMatch = PermissionMatch::"Not Required" then
            PermissionMatch := PermissionMatch::"Direct or Indirect";

        PermissionText := StrSubstNo('%1: %2', PermissionName, Format(PermissionMatch));

        if ResultText = '' then
            ResultText := PermissionText
        else
            ResultText := ResultText + Separator + PermissionText;
    end;

    var
        Step: Integer;
        ProposedConflictId: Code[20];
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        Step4Visible: Boolean;
        Group2Table2Visible: Boolean;
        ReviewGroup1TablesTxt: Text[250];
        ReviewGroup2TablesTxt: Text[250];
        ReviewGroup1PermissionsTxt: Text;
        ReviewGroup2PermissionsTxt: Text;
        ReviewResultTxt: Text;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
