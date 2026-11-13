tableextension 50516 "BCG SecGrp Snap Run No" extends "BCG SecGrp Snap"
{
    fields { field(50650; "Run No."; Code[20]) { Caption = 'Run No.'; DataClassification = CustomerContent; } }
    keys { key(BCG_RunNo; "Run No.") { } }
}
