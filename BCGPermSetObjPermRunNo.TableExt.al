tableextension 50511 "BCG PermSet ObjPerm Run No" extends "BCG Perm. Set Object Perm."
{
    fields { field(50650; "Run No."; Code[20]) { Caption = 'Run No.'; DataClassification = CustomerContent; } }
    keys { key(BCG_RunNo; "Run No.") { } }
}
