tableextension 50512 "BCG User Table Perm Run No" extends "BCG User Table Data Perm."
{
    fields { field(50650; "Run No."; Code[20]) { Caption = 'Run No.'; DataClassification = CustomerContent; } }
    keys { key(BCG_RunNo; "Run No.") { } }
}
