codeunit 50563 "BCG Conflict Src Summary"
{
    Permissions =
        tabledata "BCG User Conflict Result" = m;

    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";

    procedure UpdateConflictResultSourcesForRun(RunId: Guid)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Conflict Src Summary");
        UpdateConflictResultSourcesForRun(RunId, true);
    end;

    procedure UpdateConflictResultSourcesForRun(RunId: Guid; ShowCompletionMessage: Boolean)
    var
        ConflictResult: Record "BCG User Conflict Result";
        UpdatedCount: Integer;
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Conflict Src Summary");
        if IsNullGuid(RunId) then
            Error('Run ID is required. Select a conflict result line with a valid Run ID.');

        ConflictResult.Reset();
        ConflictResult.SetRange("Run ID", RunId);
        if ConflictResult.FindSet(true) then
            repeat
                UpdateOneConflictResult(ConflictResult);
                ConflictResult.Modify(true);
                UpdatedCount += 1;
            until ConflictResult.Next() = 0;

        if ShowCompletionMessage then
            Message('%1 conflict result source summaries were updated for Run ID %2.', UpdatedCount, RunId);
    end;

    procedure UpdateOneConflictResult(var ConflictResult: Record "BCG User Conflict Result")
    var
        ConflictLine: Record "BCG User Conflict Result Line";
        SeenSources: List of [Text];
        DirectSummary: Text;
        GroupSummary: Text;
        UnknownSummary: Text;
        SourceSummary: Text;
        HasDirect: Boolean;
        HasSecurityGroup: Boolean;
        HasSpecial: Boolean;
        LineDirect: Boolean;
        LineGroup: Boolean;
    begin
        ConflictLine.SetRange("Conflict Result Entry No.", ConflictResult."Entry No.");
        if ConflictLine.FindSet() then
            repeat
                HasSpecial := HasSpecial or ConflictLine."Is Special Permission Source" or
                    (ConflictLine."Permission Source Type" = ConflictLine."Permission Source Type"::"Special Permission");
                GetCapturedRoutes(ConflictLine, LineDirect, LineGroup);
                HasDirect := HasDirect or LineDirect;
                HasSecurityGroup := HasSecurityGroup or LineGroup;
                if LineDirect then
                    AddSource(SeenSources, DirectSummary, 'Direct', ConflictLine);
                if LineGroup then
                    AddSource(SeenSources, GroupSummary, 'Security Group', ConflictLine);
                if not LineDirect and not LineGroup then
                    AddSource(SeenSources, UnknownSummary, 'Unknown', ConflictLine);
            until ConflictLine.Next() = 0
        else
            // A run/user trace is not evidence that a source contributed to this particular result.
            // With no result lines, retain known special status but do not reconstruct assignment routes.
            HasSpecial := ConflictResult."Has Special Permission Source";

        AppendRouteSummary(SourceSummary, 'Direct', DirectSummary);
        AppendRouteSummary(SourceSummary, 'Security Group', GroupSummary);
        AppendRouteSummary(SourceSummary, 'Unknown', UnknownSummary);
        if SourceSummary = '' then
            SourceSummary := 'Unknown: source unavailable';

        ConflictResult."Has Direct Source" := HasDirect;
        ConflictResult."Has Security Group Source" := HasSecurityGroup;
        ConflictResult."Has Special Permission Source" := HasSpecial;
        ConflictResult."Permission Source Summary" := CopyStr(SourceSummary, 1, MaxStrLen(ConflictResult."Permission Source Summary"));
        if HasDirect and HasSecurityGroup then
            ConflictResult."Primary Permission Source" := ConflictResult."Primary Permission Source"::Mixed
        else
            if HasDirect then
                ConflictResult."Primary Permission Source" := ConflictResult."Primary Permission Source"::Direct
            else
                if HasSecurityGroup then
                    ConflictResult."Primary Permission Source" := ConflictResult."Primary Permission Source"::"Security Group"
                else
                    ConflictResult."Primary Permission Source" := ConflictResult."Primary Permission Source"::Unknown;
    end;

    local procedure GetCapturedRoutes(ConflictLine: Record "BCG User Conflict Result Line"; var HasDirect: Boolean; var HasSecurityGroup: Boolean)
    var
        RouteParts: List of [Text];
        RoutePart: Text;
    begin
        HasDirect := false;
        HasSecurityGroup := ConflictLine."Is From Security Group";
        RouteParts := ConflictLine."Assignment Source Type".Split('+');
        foreach RoutePart in RouteParts do
            case UpperCase(RoutePart.Trim()) of
                'DIRECT': HasDirect := true;
                'SECURITY GROUP': HasSecurityGroup := true;
            end;
        // Permission Source Type historically mixed routes and special categories, and could
        // default unresolved sources to Direct. It is deliberately not a route fallback.
    end;

    local procedure AddSource(var SeenSources: List of [Text]; var Summary: Text; Route: Text; ConflictLine: Record "BCG User Conflict Result Line")
    var
        RoleId: Text;
        Identity: Text;
        DisplayName: Text;
    begin
        RoleId := ConflictLine."Role ID";
        if RoleId = '' then
            RoleId := ConflictLine."Source Permission Set ID";
        // Length-prefixed text components avoid delimiter collisions; membership is exact.
        Identity := Route + '|' + Format(StrLen(RoleId)) + ':' + RoleId + '|' +
            Format(ConflictLine."App ID") + '|' + Format(StrLen(ConflictLine."Scope Text")) + ':' + ConflictLine."Scope Text";
        if RoleId = '' then
            // Missing IDs cannot establish that two legacy evidence rows are the same source.
            Identity += '|' + Format(ConflictLine."Entry No.");
        if SeenSources.Contains(Identity) then
            exit;
        SeenSources.Add(Identity);
        DisplayName := RoleId;
        if DisplayName = '' then
            DisplayName := 'source unavailable';
        if Summary <> '' then
            Summary += ', ';
        Summary += DisplayName;
    end;

    local procedure AppendRouteSummary(var Summary: Text; Route: Text; Sources: Text)
    begin
        if Sources = '' then
            exit;
        if Summary <> '' then
            Summary += '; ';
        Summary += Route + ': ' + Sources;
    end;
}
