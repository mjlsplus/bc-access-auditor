tableextension 50591 "BCG ConfRes User" extends "BCG User Conflict Result"
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
