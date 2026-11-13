table 50506 "BCG Setup"
{
    Caption = 'BCAA Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10]) { Caption = 'Primary Key'; }
        field(2; "Demo Mode"; Boolean)
        {
            Caption = 'Demo Mode';
            InitValue = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Legacy demo workflow is no longer used.';
            ObsoleteTag = '5.0.0.0';
        }
        field(3; "Last Run ID"; Code[30]) { Caption = 'Last Run ID'; Editable = false; }
        field(4; "Last Calculation"; DateTime) { Caption = 'Last Calculation'; Editable = false; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
