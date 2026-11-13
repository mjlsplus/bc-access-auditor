table 50605 "BCG Detected Conflict Buffer"
{
    Caption = 'Detected Conflict';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Run ID'; }
        field(2; "Conflict Code"; Code[50]) { Caption = 'Conflict Code'; }
        field(3; "Conflict Name"; Text[250]) { Caption = 'Conflict Name'; }
        field(4; Severity; Option)
        {
            Caption = 'Severity';
            OptionMembers = Low,Medium,High,Critical;
            OptionCaption = 'Low,Medium,High,Critical';
        }
        field(5; "Affected User Count"; Integer) { Caption = 'Affected User Count'; }
        field(6; "Finding Count"; Integer) { Caption = 'Finding Count'; }
        field(7; "Company Count"; Integer) { Caption = 'Company Count'; }
        field(8; "Has Special Permissions"; Boolean) { Caption = 'Has Special Permissions'; }
        field(9; "Has Group Based Findings"; Boolean) { Caption = 'Has Security Group Based Findings'; }
        field(10; "Inconsistent Stored Values"; Boolean) { Caption = 'Inconsistent Stored Values'; }
        field(11; "Summary Note"; Text[250]) { Caption = 'Summary Note'; }
        field(12; "Representative Entry No."; Integer) { Caption = 'Representative Entry No.'; }
        field(13; "Has Direct Assignments"; Boolean) { Caption = 'Has Direct Assignments'; }
    }

    keys
    {
        key(PK; "Run ID", "Conflict Code") { Clustered = true; }
    }
}
