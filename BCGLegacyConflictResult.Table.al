table 50505 "BCG Legacy Conflict Result"
{
    Caption = 'BCAA User Conflict Result';
    DataClassification = CustomerContent;
    ObsoleteState = Pending;
    ObsoleteReason = 'Legacy demo workflow is no longer used.';
    ObsoleteTag = '5.0.0.0';

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "Run ID"; Code[30]) { Caption = 'Run ID'; }
        field(3; "User ID"; Code[50]) { Caption = 'User ID'; }
        field(4; "User Name"; Text[100]) { Caption = 'User Name'; }
        field(5; "Conflict ID"; Code[20]) { Caption = 'Conflict ID'; TableRelation = "BCG Conflict Header"."Conflict ID"; }
        field(6; "Conflict Name"; Text[100]) { Caption = 'Conflict Name'; }
        field(7; Severity; Enum "BCG Severity") { Caption = 'Severity'; }
        field(8; "Matched Rule IDs"; Text[250]) { Caption = 'Matched Rule IDs'; }
        field(9; "Matched Groups"; Text[100]) { Caption = 'Matched Groups'; }
        field(10; "Detection DateTime"; DateTime) { Caption = 'Detection DateTime'; }
        field(11; "Company Name"; Text[50]) { Caption = 'Company Name'; }
        field(12; Recommendation; Text[250]) { Caption = 'Recommendation'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(UserConflict; "User ID", "Conflict ID") { }
    }
}
