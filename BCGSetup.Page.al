page 50517 "BCG Setup"
{
    PageType = Card;
    SourceTable = "BCG Setup";
    Caption = 'BC Access Auditor Setup';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Last Run ID"; Rec."Last Run ID") { ApplicationArea = All; }
                field("Last Calculation"; Rec."Last Calculation") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        BCGAccessMgt.RequireAdminPage(Page::"BCG Setup");
        if not Rec.Get('SETUP') then begin
            Rec.Init();
            Rec."Primary Key" := 'SETUP';
            Rec.Insert();
        end;
    end;
    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
}
