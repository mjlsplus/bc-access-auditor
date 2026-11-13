tableextension 50515 "BCG Source Trace Run No" extends "BCG Conflict Source Trace"
{
    fields { field(50650; "Run No."; Code[20]) { Caption = 'Run No.'; DataClassification = CustomerContent; } }
    keys { key(BCG_RunNo; "Run No.") { } }
}
