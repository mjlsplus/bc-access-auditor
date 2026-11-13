table 50501 "BCG Conflict Group"
{
    Caption = 'BCAA Conflict Group';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Conflict ID"; Code[20])
        {
            Caption = 'Conflict ID';
            TableRelation = "BCG Conflict Header"."Conflict ID";
        }
        field(2; "Group No."; Integer) { Caption = 'Group No.'; }
        field(3; "Group Name"; Text[100]) { Caption = 'Group Name'; }
        field(4; "Evaluation Logic"; Enum "BCG Group Eval Logic")
        {
            Caption = 'Evaluation Logic';
            InitValue = ANY;
        }
        field(5; Sequence; Integer) { Caption = 'Sequence'; }
        field(6; "Is Active"; Boolean) { Caption = 'Is Active'; InitValue = true; }
    }

    keys
    {
        key(PK; "Conflict ID", "Group No.") { Clustered = true; }
        key(SequenceKey; "Conflict ID", Sequence) { }
    }

    trigger OnInsert()
    begin
        if Sequence = 0 then
            Sequence := GetNextGroupSequence("Conflict ID");
    end;

    trigger OnDelete()
    var
        GroupRule: Record "BCG Conflict Group Rule";
    begin
        GroupRule.SetRange("Conflict ID", "Conflict ID");
        GroupRule.SetRange("Group No.", "Group No.");
        if not GroupRule.IsEmpty() then
            Error(GroupHasRulesErr);
    end;

    var
        GroupHasRulesErr: Label 'The conflict group contains rules. Delete its group rules first.';

    local procedure GetNextGroupSequence(ConflictId: Code[20]): Integer
    var
        ConflictGroup: Record "BCG Conflict Group";
    begin
        if ConflictId = '' then
            exit(10);

        ConflictGroup.SetCurrentKey("Conflict ID", Sequence);
        ConflictGroup.SetRange("Conflict ID", ConflictId);

        if ConflictGroup.FindLast() then
            exit(ConflictGroup.Sequence + 10);

        exit(10);
    end;
}
