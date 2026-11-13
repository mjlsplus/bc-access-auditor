tableextension 50517 "BCG SecGrp Member Run No" extends "BCG SecGrp Member Snap"
{
    fields { field(50650; "Run No."; Code[20]) { Caption = 'Run No.'; DataClassification = CustomerContent; } }
    keys { key(BCG_RunNo; "Run No.") { } }
}
