pageextension 50599 "BCG SecGrp Actions" extends "BCG User Table Data Perms"
{
    actions
    {
        addlast("BCG Advanced Repair")
        {
            action("Open Security Groups")
            {
                Caption = 'Open Security Groups';
                ApplicationArea = All;
                Visible = false;
                Image = Users;
                RunObject = page "BCG Security Groups";
            }

            action("Open Security Group Members")
            {
                Caption = 'Open Security Group Members';
                ApplicationArea = All;
                Visible = false;
                Image = Users;
                RunObject = page "BCG Security Group Members";
            }

            action("Open Security Group Permissions")
            {
                Caption = 'Open Security Group Permissions';
                ApplicationArea = All;
                Visible = false;
                Image = Permission;
                RunObject = page "BCG SecGrp Permissions";
            }
        }
    }
}
