codeunit 50568 "BCG Conflict Evidence Mgt"
{
    Permissions =
        tabledata "BCG User Conflict Result" = m;


    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";

    procedure UpdateEvidenceForRun(RunId: Guid): Integer
    var
        ConflictResult: Record "BCG User Conflict Result";
        UpdatedCount: Integer;
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Conflict Evidence Mgt");
        if IsNullGuid(RunId) then
            Error('Run ID is empty.');

        ConflictResult.SetRange("Run ID", RunId);
        if ConflictResult.FindSet(true) then
            repeat
                UpdateEvidenceForResult(ConflictResult);
                ConflictResult.Modify(true);
                UpdatedCount += 1;
            until ConflictResult.Next() = 0;

        exit(UpdatedCount);
    end;

    procedure UpdateEvidenceForResult(var ConflictResult: Record "BCG User Conflict Result")
    var
        ConflictLine: Record "BCG User Conflict Result Line";
        GroupKeys: Dictionary of [Text, Boolean];
        ObjectKeys: Dictionary of [Text, Boolean];
        RuleKeys: Dictionary of [Text, Boolean];
        GroupsSummary: Text[2048];
        ObjectsSummary: Text[2048];
        GroupCount: Integer;
        ObjectCount: Integer;
        RuleCount: Integer;
        ObjectDisplay: Text;
    begin
        ClearEvidenceFields(ConflictResult);

        ConflictLine.Reset();
        ConflictLine.SetRange("Conflict Result Entry No.", ConflictResult."Entry No.");
        if ConflictLine.FindSet() then
            repeat
                AddUniqueValue(
                    GroupKeys,
                    GroupsSummary,
                    GroupCount,
                    Format(ConflictLine."Group No."),
                    FormatGroupDisplay(ConflictLine),
                    ' + ');

                ObjectDisplay := FormatObjectDisplay(ConflictLine);
                AddUniqueValue(
                    ObjectKeys,
                    ObjectsSummary,
                    ObjectCount,
                    Format(ConflictLine."Group No.") + '|' + Format(ConflictLine."Object ID"),
                    ObjectDisplay,
                    '; ');

                AddUniqueValue(
                    RuleKeys,
                    ConflictResult."Conflict Evidence Summary",
                    RuleCount,
                    Format(ConflictLine."Group No.") + '|' + ConflictLine."Rule ID" + '|' + Format(ConflictLine."Object ID"),
                    FormatEvidenceLine(ConflictLine),
                    '; ');

            until ConflictLine.Next() = 0;

        ConflictResult."Matched Group Count" := GroupCount;
        ConflictResult."Matched Object Count" := ObjectCount;
        ConflictResult."Matched Rule Count" := RuleCount;
        ConflictResult."Matched Groups Summary" := CopyStr(GroupsSummary, 1, MaxStrLen(ConflictResult."Matched Groups Summary"));
        ConflictResult."Matched Objects Summary" := CopyStr(ObjectsSummary, 1, MaxStrLen(ConflictResult."Matched Objects Summary"));
        // Display aggregation is independent of the existing evidence identity counters above.
        BuildCustomerSummaries(ConflictResult);
    end;

    local procedure BuildCustomerSummaries(var ConflictResult: Record "BCG User Conflict Result")
    var
        Line: Record "BCG User Conflict Result Line";
        ObjectNames: Dictionary of [Integer, Text];
        ObjectOperations: Dictionary of [Integer, Text];
        GroupNames: Dictionary of [Integer, Text];
        GroupObjects: Dictionary of [Integer, Text];
        ObjectOrder: List of [Integer];
        GroupOrder: List of [Integer];
        SeenOperations: List of [Text];
        SeenGroupObjects: List of [Text];
        Operations: List of [Text];
        Operation: Text;
        Identity: Text;
        ObjectName: Text;
        Summary: Text;
        Id: Integer;
    begin
        Line.SetRange("Conflict Result Entry No.", ConflictResult."Entry No.");
        if Line.FindSet() then
            repeat
                ObjectName := Line."Object Name";
                if ObjectName = '' then
                    ObjectName := 'Object ' + Format(Line."Object ID");
                if not ObjectNames.ContainsKey(Line."Object ID") then begin
                    ObjectOrder.Add(Line."Object ID");
                    ObjectNames.Add(Line."Object ID", ObjectName);
                    ObjectOperations.Add(Line."Object ID", '');
                end;
                Operations := CapturedOperations(Line);
                foreach Operation in Operations do begin
                    Identity := Format(Line."Object ID") + '|' + Operation;
                    if not SeenOperations.Contains(Identity) then begin
                        SeenOperations.Add(Identity);
                        ObjectOperations.Set(Line."Object ID", JoinDisplay(ObjectOperations.Get(Line."Object ID"), Operation, ', '));
                    end;
                end;
                if not GroupNames.ContainsKey(Line."Group No.") then begin
                    GroupOrder.Add(Line."Group No.");
                    GroupNames.Add(Line."Group No.", FormatGroupDisplay(Line));
                    GroupObjects.Add(Line."Group No.", '');
                end;
                Identity := Format(Line."Group No.") + '|' + Format(Line."Object ID");
                if not SeenGroupObjects.Contains(Identity) then begin
                    SeenGroupObjects.Add(Identity);
                    GroupObjects.Set(Line."Group No.", JoinDisplay(GroupObjects.Get(Line."Group No."), ObjectName, ', '));
                end;
            until Line.Next() = 0;

        foreach Id in ObjectOrder do
            Summary := JoinDisplay(Summary, ObjectNames.Get(Id) + ': ' + ObjectOperations.Get(Id), '; ');
        ConflictResult."Matched Permissions Summary" := CopyStr(Summary, 1, MaxStrLen(ConflictResult."Matched Permissions Summary"));
        Summary := '';
        foreach Id in GroupOrder do
            Summary := JoinDisplay(Summary, GroupNames.Get(Id) + ': ' + GroupObjects.Get(Id), '; ');
        ConflictResult."Conflict Evidence Summary" := CopyStr(Summary, 1, MaxStrLen(ConflictResult."Conflict Evidence Summary"));
    end;

    local procedure CapturedOperations(Line: Record "BCG User Conflict Result Line"): List of [Text]
    var
        Operations: List of [Text];
        Parts: List of [Text];
        Part: Text;
        Token: Text;
        Operation: Text;
        Position: Integer;
        Incomplete: Boolean;
    begin
        // Only matched evidence is authoritative. Required text may describe unmatched ANY operations.
        if (UpperCase(Line."Matched Permission") = 'SUPER OVERRIDE') then begin
            Operations.Add('Special permission');
            exit(Operations);
        end;
        Parts := Line."Matched Permission".Split('/');
        foreach Part in Parts do begin
            Token := Part.Trim();
            Position := StrPos(Token, ':');
            if Position > 0 then
                Token := CopyStr(Token, 1, Position - 1);
            Position := StrPos(Token, '(');
            if Position > 0 then
                Token := CopyStr(Token, 1, Position - 1);
            Operation := '';
            case UpperCase(Token.Trim()) of
                'READ': Operation := 'Read';
                'INSERT': Operation := 'Insert';
                'MODIFY': Operation := 'Modify';
                'DELETE': Operation := 'Delete';
                'EXECUTE': Operation := 'Execute';
            end;
            if Operation = '' then
                Incomplete := true
            else
                if not Operations.Contains(Operation) then
                    Operations.Add(Operation);
        end;
        // A clipped criterion is harmless when the complete operation name survives.
        // Unknown or missing operation names are never reconstructed from live setup or requirements.
        if Incomplete or (Operations.Count() = 0) then
            if Line."Is Special Permission Source" then
                Operations.Add('Special permission')
            else
                Operations.Add('See detailed evidence');
        exit(Operations);
    end;

    local procedure JoinDisplay(CurrentText: Text; NewText: Text; Separator: Text): Text
    begin
        if CurrentText = '' then
            exit(NewText);
        exit(CurrentText + Separator + NewText);
    end;

    local procedure ClearEvidenceFields(var ConflictResult: Record "BCG User Conflict Result")
    begin
        ConflictResult."Matched Group Count" := 0;
        ConflictResult."Matched Rule Count" := 0;
        ConflictResult."Matched Object Count" := 0;
        ConflictResult."Matched Groups Summary" := '';
        ConflictResult."Matched Objects Summary" := '';
        ConflictResult."Matched Permissions Summary" := '';
        ConflictResult."Conflict Evidence Summary" := '';
    end;

    local procedure AddUniqueValue(var Keys: Dictionary of [Text, Boolean]; var Summary: Text[2048]; var CountValue: Integer; KeyValue: Text; DisplayValue: Text; Separator: Text)
    begin
        if KeyValue = '' then
            exit;

        if Keys.ContainsKey(KeyValue) then
            exit;

        Keys.Add(KeyValue, true);

        if Summary = '' then
            Summary := CopyStr(DisplayValue, 1, MaxStrLen(Summary))
        else
            Summary := CopyStr(Summary + Separator + DisplayValue, 1, MaxStrLen(Summary));

        CountValue += 1;
    end;

    local procedure FormatGroupDisplay(ConflictLine: Record "BCG User Conflict Result Line"): Text
    begin
        if ConflictLine."Group Name" <> '' then
            exit(ConflictLine."Group Name");

        exit('Group ' + Format(ConflictLine."Group No."));
    end;

    local procedure FormatObjectDisplay(ConflictLine: Record "BCG User Conflict Result Line"): Text
    var
        GroupText: Text;
        ObjectText: Text;
    begin
        GroupText := FormatGroupDisplay(ConflictLine);

        if ConflictLine."Object Name" <> '' then
            ObjectText := ConflictLine."Object Name"
        else
            ObjectText := 'Object ' + Format(ConflictLine."Object ID");

        exit(GroupText + ': ' + ObjectText);
    end;

    local procedure FormatPermissionDisplay(ConflictLine: Record "BCG User Conflict Result Line"): Text
    var
        ObjectText: Text;
    begin
        if ConflictLine."Object Name" <> '' then
            ObjectText := ConflictLine."Object Name"
        else
            ObjectText := 'Object ' + Format(ConflictLine."Object ID");

        if ConflictLine."Matched Permission" <> '' then
            exit(ObjectText + ' ' + ConflictLine."Required Permission" + ' -> ' + ConflictLine."Matched Permission");

        exit(ObjectText + ' ' + ConflictLine."Required Permission");
    end;

    local procedure FormatEvidenceLine(ConflictLine: Record "BCG User Conflict Result Line"): Text
    begin
        exit(
            FormatGroupDisplay(ConflictLine) + ' / ' +
            ConflictLine."Rule ID" + ' / ' +
            FormatPermissionDisplay(ConflictLine));
    end;
}
