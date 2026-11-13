table 50598 "BCG Conflict Cue"
{
    Caption = 'BCAA Conflict Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10]) { Caption = 'Primary Key'; }
        field(10; "Open Conflicts"; Integer)
        {
            Caption = 'Open Conflicts';
            FieldClass = FlowField;
            CalcFormula = count("BCG User Conflict Result" where(Status = const(Open)));
        }
        field(11; "High Severity"; Integer)
        {
            Caption = 'High Severity';
            FieldClass = FlowField;
            CalcFormula = count("BCG User Conflict Result" where(Severity = const(High)));
        }
        field(12; "Users with Conflicts"; Integer)
        {
            Caption = 'Users with Conflicts';
            FieldClass = FlowField;
            CalcFormula = count("BCG User Conflict Result" where(Status = const(Open)));
        }
        field(13; "SUPER Conflicts"; Integer)
        {
            Caption = 'SUPER Conflicts';
            FieldClass = FlowField;
            CalcFormula = count("BCG User Conflict Result" where("Has Special Permission Source" = const(true)));
        }
        field(14; "Security Group Conflicts"; Integer)
        {
            Caption = 'Security Group Conflicts';
            FieldClass = FlowField;
            CalcFormula = count("BCG User Conflict Result" where("Has Security Group Source" = const(true)));
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
