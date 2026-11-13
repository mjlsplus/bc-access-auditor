tableextension 50510 "BCG User Perm Assign Run No" extends "BCG User Perm. Assignment"
{
    fields { field(50650; "Run No."; Code[20]) { Caption = 'Run No.'; DataClassification = CustomerContent; } }
    keys { key(BCG_RunNo; "Run No.") { } }
}
