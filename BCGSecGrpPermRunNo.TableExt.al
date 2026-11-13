tableextension 50518 "BCG SecGrp Perm Run No" extends "BCG SecGrp Perm Assign"
{
    fields { field(50650; "Run No."; Code[20]) { Caption = 'Run No.'; DataClassification = CustomerContent; } }
    keys { key(BCG_RunNo; "Run No.") { } }
}
