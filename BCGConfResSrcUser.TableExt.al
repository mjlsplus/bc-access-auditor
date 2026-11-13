tableextension 50596 "BCG ConfRes SrcUser" extends "BCG User Conflict Result"
{
    fields
    {
        field(50696; "BCG Source User Name"; Text[50])
        {
            Caption = 'User Name';
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
            Editable = false;
        }
    }
}
