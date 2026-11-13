pageextension 50577 "BCG ConfRes User Context" extends "BCG User Conflict Results"
{
    layout
    {
        addlast(Group)
        {
            field("User Has Security Group"; Rec."User Has Security Group")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the user had any security group assignment in this Run ID. This is user context, not necessarily the source of this specific conflict.';
            }

            field("User Security Group Count"; Rec."User Security Group Count")
            {
                ApplicationArea = All;
                ToolTip = 'Shows how many security groups were captured for the user in this Run ID.';
            }

            field("User Security Group Summary"; Rec."User Security Group Summary")
            {
                ApplicationArea = All;
                ToolTip = 'Shows security groups assigned to the user in this Run ID.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("Update User Access Context")
            {
                Visible = false;
                Enabled = false;
                AccessByPermission = codeunit "BCG User Access Context Mgt" = X;
                ApplicationArea = All;
                Caption = 'Update User Access Context';
                Image = Refresh;
                ToolTip = 'Updates user-friendly SUPER/SUPER DATA summary and user security group context for the selected Run ID.';

                trigger OnAction()
                var
                    ContextMgt: Codeunit "BCG User Access Context Mgt";
                begin
                    ContextMgt.UpdateAccessContextForRun(Rec."Run ID");
                end;
            }
        }
    }
}
