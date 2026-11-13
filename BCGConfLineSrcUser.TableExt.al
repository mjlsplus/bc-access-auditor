tableextension 50597 "BCG ConfLine SrcUser" extends "BCG User Conflict Result Line"
{
    fields
    {
        field(50697; "BCG Source User Name"; Text[50])
        {
            Caption = 'User Name';
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
            Editable = false;
        }
    }
}
