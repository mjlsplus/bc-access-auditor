tableextension 50513 "BCG Conflict Result Run No" extends "BCG User Conflict Result"
{
    fields { field(50650; "Run No."; Code[20]) { Caption = 'Run No.'; DataClassification = CustomerContent; } }
    keys { key(BCG_RunNo; "Run No.") { } }
}
