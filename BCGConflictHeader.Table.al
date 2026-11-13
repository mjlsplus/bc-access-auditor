table 50500 "BCG Conflict Header"
{
    Caption = 'BCAA Conflict Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Conflict ID"; Code[20]) { Caption = 'Conflict ID'; }
        field(2; Name; Text[100]) { Caption = 'Name'; }
        field(3; Category; Text[50]) { Caption = 'Category'; }
        field(4; Severity; Enum "BCG Severity") { Caption = 'Severity'; }
        field(5; "Is Active"; Boolean) { Caption = 'Is Active'; InitValue = true; }
        field(6; Recommendation; Text[250]) { Caption = 'Recommendation'; }
    }

    keys
    {
        key(PK; "Conflict ID") { Clustered = true; }
    }

    trigger OnDelete()
    var
        ConflictGroup: Record "BCG Conflict Group";
        ConflictGroupRule: Record "BCG Conflict Group Rule";
    begin
        // Delete child rules first, then groups.
        // This prevents orphaned records after deleting a conflict header.
        ConflictGroupRule.SetRange("Conflict ID", "Conflict ID");
        ConflictGroupRule.DeleteAll(true);

        ConflictGroup.SetRange("Conflict ID", "Conflict ID");
        ConflictGroup.DeleteAll(true);
    end;
}
