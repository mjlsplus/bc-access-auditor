codeunit 50531 "BCG Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        InsertSetup();
    end;

    local procedure InsertSetup()
    var
        Setup: Record "BCG Setup";
    begin
        if Setup.Get('SETUP') then
            exit;
        Setup.Init();
        Setup."Primary Key" := 'SETUP';
        Setup.Insert();
    end;
}
