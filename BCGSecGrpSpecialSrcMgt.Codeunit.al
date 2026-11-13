codeunit 50579 "BCG SecGrp Special Src Mgt"
{
    Permissions =
        tabledata "BCG User Conflict Result Line" = m,
        tabledata "BCG User Conflict Result" = m;

    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";

    procedure RunSecurityGroupSpecialPermissionRepair(RunId: Guid)
    begin
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG SecGrp Special Src Mgt");
        Error('Historical analysis maintenance is unsupported. Run a new Full Analysis instead.');
    end;

    procedure MarkSpecialPermissionsAssignedThroughSecurityGroups(RunId: Guid)
    var
        ConflictLine: Record "BCG User Conflict Result Line";
        SecGrpPermAssign: Record "BCG SecGrp Perm Assign";
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG SecGrp Special Src Mgt");
        if IsNullGuid(RunId) then
            Error('Run ID is required.');

        ConflictLine.Reset();
        ConflictLine.SetRange("Run ID", RunId);
        ConflictLine.SetRange("Is Special Permission Source", true);
        if ConflictLine.FindSet(true) then
            repeat
                if FindSecurityGroupSpecialAssignment(ConflictLine, SecGrpPermAssign) then begin
                    ConflictLine."Is From Security Group" := true;
                    ConflictLine."Security Group Code" := SecGrpPermAssign."Security Group Code";
                    ConflictLine."Security Group Name" := SecGrpPermAssign."Security Group Name";
                    ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::"Special Permission";
                    if StrPos(UpperCase(ConflictLine."Assignment Source Type"), 'DIRECT') > 0 then
                        ConflictLine."Assignment Source Type" := 'Direct + Security Group'
                    else
                        ConflictLine."Assignment Source Type" := 'Security Group';
                    ConflictLine."Permission Source Summary" :=
                        CopyStr('Special Permission via Security Group: ' + SecGrpPermAssign."Security Group Name" + ' / ' + Format(ConflictLine."Role ID"),
                            1, MaxStrLen(ConflictLine."Permission Source Summary"));
                    ConflictLine."Source Notes" :=
                        CopyStr('Wildcard: ' + ConflictLine."Role ID" + ' grants all Table Data permissions. Route: ' +
                            ConflictLine."Assignment Source Type" + '. Group: ' + SecGrpPermAssign."Security Group Code", 1, MaxStrLen(ConflictLine."Source Notes"));
                    ConflictLine.Modify(true);
                end;
            until ConflictLine.Next() = 0;
    end;

    procedure UpdateConflictResultSourcesFromLines(RunId: Guid)
    var
        ConflictResult: Record "BCG User Conflict Result";
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG SecGrp Special Src Mgt");
        if IsNullGuid(RunId) then
            Error('Run ID is required.');

        ConflictResult.Reset();
        ConflictResult.SetRange("Run ID", RunId);
        if ConflictResult.FindSet(true) then
            repeat
                UpdateOneConflictResultSourcesFromLines(ConflictResult);
                ConflictResult.Modify(true);
            until ConflictResult.Next() = 0;
    end;

    local procedure UpdateOneConflictResultSourcesFromLines(var ConflictResult: Record "BCG User Conflict Result")
    var
        SourceSummaryMgt: Codeunit "BCG Conflict Src Summary";
    begin
        // Use the same attribute-aware summary after the special/group enrichment pass.
        SourceSummaryMgt.UpdateOneConflictResult(ConflictResult);
    end;

    local procedure FindSecurityGroupSpecialAssignment(ConflictLine: Record "BCG User Conflict Result Line"; var SecGrpPermAssign: Record "BCG SecGrp Perm Assign"): Boolean
    begin
        SecGrpPermAssign.Reset();
        SecGrpPermAssign.SetRange("Run ID", ConflictLine."Run ID");
        SecGrpPermAssign.SetRange("User Security ID", ConflictLine."User Security ID");
        SecGrpPermAssign.SetFilter("Company Name", '%1|%2', ConflictLine."Company Name", '');
        SecGrpPermAssign.SetRange("Role ID", ConflictLine."Role ID");
        SecGrpPermAssign.SetRange("App ID", ConflictLine."App ID");
        SecGrpPermAssign.SetRange(Scope, ConflictLine."Scope Text");
        exit(SecGrpPermAssign.FindFirst());
    end;

    local procedure AddToSummary(var SourceSummary: Text[250]; NewText: Text[50])
    begin
        if NewText = '' then
            exit;

        if StrPos(SourceSummary, NewText) > 0 then
            exit;

        if SourceSummary = '' then
            SourceSummary := CopyStr(NewText, 1, MaxStrLen(SourceSummary))
        else
            SourceSummary := CopyStr(SourceSummary + '; ' + NewText, 1, MaxStrLen(SourceSummary));
    end;
}
