tableextension 50548 "BCG TPerm UserName" extends "BCG User Table Data Perm."
{
    fields
    {
        field(50648; "BCG User Name"; Text[50])
        {
            Caption = 'User Name';
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
            Editable = false;
        }
    }
}
