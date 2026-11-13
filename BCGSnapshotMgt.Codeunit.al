codeunit 50520 "BCG Snapshot Mgt."
{
    TableNo = "BCG Audit Run";

    Permissions =
        tabledata "BCG Audit Run" = im,
        tabledata "BCG User Snapshot" = id,
        tabledata "BCG User Perm. Assignment" = id,
        tabledata "BCG Perm. Set Object Perm." = id,
        tabledata "BCG User Table Data Perm." = imd,
        tabledata "BCG User Conflict Result" = id,
        tabledata "BCG User Conflict Result Line" = imd;

    var
        BCGAccessMgt: Codeunit "BCG Access Mgt.";
        FullSnapshotRunId: Guid;
        UnsupportedSnapshotValueErr: Label 'Unsupported captured permission value "%1". Run a new Full Analysis to capture language-independent values; historical snapshots are not converted.', Comment = '%1 = unrecognized technical value';

    trigger OnRun()
    begin
        RunFullSnapshotWorker(Rec);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure RunFullSnapshotWorker(var Rec: Record "BCG Audit Run")
    begin
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Snapshot Mgt.");
        // Only this instance's newly created run may enter the worker.
        if IsNullGuid(FullSnapshotRunId) or (Rec."Run ID" <> FullSnapshotRunId) then
            Error('Full Analysis worker must be started through RunFullSnapshot.');
        Clear(FullSnapshotRunId);
        Rec.Get(Rec."Run ID");
        Rec.TestField(Status, Rec.Status::Running);
        Rec.TestField("Finished At", 0DT);
        Rec.TestField("Error Message", '');
        Rec.TestField("Started By", CopyStr(UserId(), 1, MaxStrLen(Rec."Started By")));
        ExecuteFullSnapshot(Rec."Run ID");
        Rec.Get(Rec."Run ID");
        Rec.Status := Rec.Status::Finished;
        Rec."Finished At" := CurrentDateTime();
        Rec.Modify(true);
    end;

    procedure RunFullSnapshot(): Guid
    var
        AuditRun: Record "BCG Audit Run";
        RunId: Guid;
        FailureText: Text;
    begin
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Snapshot Mgt.");
        RunId := CreateGuid();

        AuditRun.Init();
        AuditRun."Run ID" := RunId;
        AuditRun."Company Filter" := CopyStr(CompanyName(), 1, MaxStrLen(AuditRun."Company Filter"));
        AuditRun."Started At" := CurrentDateTime();
        AuditRun."Started By" := CopyStr(UserId(), 1, MaxStrLen(AuditRun."Started By"));
        AuditRun.Status := AuditRun.Status::Running;
        AuditRun.Insert(true);

        Commit();

        FullSnapshotRunId := RunId;
        ClearLastError();
        if not Run(AuditRun) then begin
            FailureText := GetLastErrorText();
            Clear(FullSnapshotRunId);
            AuditRun.Get(RunId);
            AuditRun.Status := AuditRun.Status::Error;
            AuditRun."Finished At" := CurrentDateTime();
            AuditRun."Error Message" := CopyStr(FailureText, 1, MaxStrLen(AuditRun."Error Message"));
            AuditRun.Modify(true);
            // Boolean Run has already rolled back every worker write.
            Commit();
            Error('%1', FailureText);
        end;

        Clear(FullSnapshotRunId);
        exit(RunId);
    end;

    local procedure ExecuteFullSnapshot(RunId: Guid)
    var
        SecGrpMgt: Codeunit "BCG SecGrp Mgt";
        SpecialPermissionMgt: Codeunit "BCG Special Permission Mgt.";
        SourceMgt: Codeunit "BCG Conflict Source Mgt";
        SourceSummaryMgt: Codeunit "BCG Conflict Src Summary";
        SecGrpSpecialSourceMgt: Codeunit "BCG SecGrp Special Src Mgt";
        EvidenceMgt: Codeunit "BCG Conflict Evidence Mgt";
        ContextMgt: Codeunit "BCG User Access Context Mgt";
        RunNoMgt: Codeunit "BCG Run No. Mgt.";
#if BCG_SOURCE_COUNT_TESTS
        CaptureHandled: Boolean;
#endif
    begin
#if BCG_PERF_TESTS
        PerfStartStage();
#endif
        ClearRunData(RunId);
#if BCG_SOURCE_COUNT_TESTS
        OnTestCaptureFullSnapshot(RunId, CaptureHandled);
        if not CaptureHandled then begin
#endif
        LoadUsers(RunId);
#if BCG_PERF_TESTS
        PerfEndStage(20);
#endif
        LoadAssignments(RunId);
#if BCG_PERF_TESTS
        PerfEndStage(21);
#endif
        // Capture every permission source before RunFullSnapshot marks the run Finished.
#if BCG_PERF_TESTS
        if IsNullGuid(PerfDataset."Run ID") then
#endif
        SecGrpMgt.RunSecurityGroupSnapshot(RunId, false);
        LoadTableDataObjectPermissions(RunId);
#if BCG_SOURCE_COUNT_TESTS
        end;
        OnTestFullSnapshotStage(RunId, 1);
#endif
#if BCG_PERF_TESTS
        PerfEndStage(22);
#endif
        BuildEffectiveUserTableDataPermissions(RunId);
        SpecialPermissionMgt.AddSpecialPermissionWildcardsForRun(RunId, false);
#if BCG_PERF_TESTS
        PerfEndStage(23);
#endif
        CalculateConflicts(RunId);
#if BCG_SOURCE_COUNT_TESTS
        OnTestFullSnapshotStage(RunId, 2);
#endif
#if BCG_PERF_TESTS
        PerfEndStage(24);
#endif

        SourceMgt.RebuildSourceTraceForRun(RunId, false);
        SecGrpSpecialSourceMgt.MarkSpecialPermissionsAssignedThroughSecurityGroups(RunId);
        SourceSummaryMgt.UpdateConflictResultSourcesForRun(RunId, false);
        SecGrpSpecialSourceMgt.UpdateConflictResultSourcesFromLines(RunId);
        EvidenceMgt.UpdateEvidenceForRun(RunId);
#if BCG_SOURCE_COUNT_TESTS
        OnTestFullSnapshotStage(RunId, 3);
#endif

        ContextMgt.UpdateAccessContextForRun(RunId, false);
#if BCG_PERF_TESTS
        PerfEndStage(25);
#endif

        RunNoMgt.EnsureRunNoAndPropagate(RunId);

        UpdateRunCounters(RunId);
#if BCG_SOURCE_COUNT_TESTS
        OnTestFullSnapshotStage(RunId, 4);
#endif
#if BCG_PERF_TESTS
        PerfEndStage(26);
#endif
    end;

    local procedure ClearRunData(RunId: Guid)
    var
        UserSnapshot: Record "BCG User Snapshot";
        Assignment: Record "BCG User Perm. Assignment";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        EffectivePerm: Record "BCG User Table Data Perm.";
        ConflictResult: Record "BCG User Conflict Result";
        ConflictResultLine: Record "BCG User Conflict Result Line";
    begin
        UserSnapshot.SetRange("Run ID", RunId);
        UserSnapshot.DeleteAll();

        Assignment.SetRange("Run ID", RunId);
        Assignment.DeleteAll();

        ObjectPerm.SetRange("Run ID", RunId);
        ObjectPerm.DeleteAll();

        EffectivePerm.SetRange("Run ID", RunId);
        EffectivePerm.DeleteAll();

        ConflictResult.SetRange("Run ID", RunId);
        ConflictResult.DeleteAll();

        ConflictResultLine.SetRange("Run ID", RunId);
        ConflictResultLine.DeleteAll();
    end;

    local procedure LoadUsers(RunId: Guid)
    var
        UserRec: Record User;
    begin
#if BCG_PERF_TESTS
        if not IsNullGuid(PerfDataset."Run ID") then begin
            PerfRunner.LoadUsers(PerfDataset);
            exit;
        end;
#endif
        LoadUsersFrom(RunId, UserRec);
    end;

    local procedure LoadUsersFrom(RunId: Guid; var UserRec: Record User)
    var
        UserSnapshot: Record "BCG User Snapshot";
    begin
        UserRec.SetRange(State, UserRec.State::Enabled);
        UserRec.SetRange("License Type", UserRec."License Type"::"Full User");

        if UserRec.FindSet() then
            repeat
                UserSnapshot.Init();
                UserSnapshot."Run ID" := RunId;
                UserSnapshot."User Security ID" := UserRec."User Security ID";
                UserSnapshot."User Name" := UserRec."User Name";
                UserSnapshot."Full Name" := UserRec."Full Name";
                UserSnapshot.State := CopyStr(Format(UserRec.State), 1, MaxStrLen(UserSnapshot.State));
                UserSnapshot."Expiry Date" := DT2Date(UserRec."Expiry Date");
                UserSnapshot."Captured At" := CurrentDateTime();
                if not UserSnapshot.Insert(true) then;
            until UserRec.Next() = 0;
    end;

    local procedure LoadAssignments(RunId: Guid)
    var
        AccessControl: Record "Access Control";
    begin
#if BCG_PERF_TESTS
        if not IsNullGuid(PerfDataset."Run ID") then begin
            PerfRunner.LoadAssignments(PerfDataset);
            exit;
        end;
#endif
        LoadAssignmentsFrom(RunId, AccessControl);
    end;

    local procedure LoadAssignmentsFrom(RunId: Guid; var AccessControl: Record "Access Control")
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        AccessControl.SetAutoCalcFields("Role Name", "App Name");
        if AccessControl.FindSet() then
            repeat
                if IsAssignmentInScope(RunId, AccessControl."User Security ID", AccessControl."Company Name") then begin
                    Assignment.Init();
                    Assignment."Run ID" := RunId;
                    Assignment."User Security ID" := AccessControl."User Security ID";
                    Assignment."Company Name" := AccessControl."Company Name";
                    Assignment."Role ID" := AccessControl."Role ID";
                    Assignment."Role Name" := AccessControl."Role Name";
                    Assignment."Scope Text" := CapturedScope(AccessControl.Scope);
                    Assignment."App ID" := AccessControl."App ID";
                    Assignment."App Name" := AccessControl."App Name";
                    Assignment."Assignment Source Type" := 'Direct';
                    if not Assignment.Insert(true) then;
                end;
            until AccessControl.Next() = 0;
    end;

    local procedure LoadTableDataObjectPermissions(RunId: Guid)
    var
        ExpandedPermission: Record "Expanded Permission";
#if BCG_PERF_TESTS
        TempExpanded: Record "Expanded Permission" temporary;
#endif
    begin
#if BCG_PERF_TESTS
        if not IsNullGuid(PerfDataset."Run ID") then begin
            PerfRunner.LoadExpanded(PerfDataset, TempExpanded);
            LoadAssignedTableDataObjectPermissions(RunId, TempExpanded);
            exit;
        end;
#endif
        LoadAssignedTableDataObjectPermissions(RunId, ExpandedPermission);
    end;

#if BCG_SOURCE_COUNT_TESTS
    internal procedure TestCaptureUsersAndAssignments(RunId: Guid; var Users: Record User temporary; var Assignments: Record "Access Control" temporary)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Snapshot Mgt.");
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Company Scope Tests");
        LoadUsersFrom(RunId, Users);
        LoadAssignmentsFrom(RunId, Assignments);
    end;

    internal procedure TestLoadTableDataObjectPermissions(RunId: Guid; var ExpandedPermission: Record "Expanded Permission" temporary)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Snapshot Mgt.");
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Permission Loader Tests");
        LoadAssignedTableDataObjectPermissions(RunId, ExpandedPermission);
    end;
#endif

    local procedure CapturedScope(ScopeValue: Option System,Tenant): Text[30]
    begin
        case ScopeValue of
            ScopeValue::System: exit('System');
            ScopeValue::Tenant: exit('Tenant');
        end;
        Error(UnsupportedSnapshotValueErr, ScopeValue);
    end;

    local procedure CapturedPermission(PermissionValue: Option " ",Yes,Indirect): Text[20]
    begin
        case PermissionValue of
            PermissionValue::" ": exit('');
            PermissionValue::Yes: exit('Yes');
            PermissionValue::Indirect: exit('Indirect');
        end;
        Error(UnsupportedSnapshotValueErr, PermissionValue);
    end;

    local procedure AccessTypeToken(AccessType: Enum "BCG Access Type"): Text[30]
    begin
        case AccessType of
            AccessType::Read: exit('Read');
            AccessType::Insert: exit('Insert');
            AccessType::Modify: exit('Modify');
            AccessType::Delete: exit('Delete');
            AccessType::Execute: exit('Execute');
        end;
        Error(UnsupportedSnapshotValueErr, AccessType.AsInteger());
    end;

    local procedure ValidateSnapshotTokens(RunId: Guid)
    var
        Assignment: Record "BCG User Perm. Assignment";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
    begin
        Assignment.SetRange("Run ID", RunId);
        if Assignment.FindSet() then
            repeat
                ValidateCapturedScope(Assignment."Scope Text");
            until Assignment.Next() = 0;
        ObjectPerm.SetRange("Run ID", RunId);
        if ObjectPerm.FindSet() then
            repeat
                ValidateCapturedScope(ObjectPerm."Scope Text");
                // Canonical non-table types are valid snapshot rows; table-data consumers filter them out.
                if not (ObjectPerm."Object Type" in ['Table Data', 'Table', 'Report', 'Codeunit', 'XMLport', 'MenuSuite', 'Page', 'Query', 'System']) then
                    Error(UnsupportedSnapshotValueErr, ObjectPerm."Object Type");
                ValidatePermissionToken(ObjectPerm."Read Permission");
                ValidatePermissionToken(ObjectPerm."Insert Permission");
                ValidatePermissionToken(ObjectPerm."Modify Permission");
                ValidatePermissionToken(ObjectPerm."Delete Permission");
                ValidatePermissionToken(ObjectPerm."Execute Permission");
            until ObjectPerm.Next() = 0;
    end;

    local procedure ValidateCapturedScope(ScopeText: Text)
    begin
        // Blank is retained for older snapshots; never infer its identity.
        if not (ScopeText in ['', 'System', 'Tenant']) then
            Error(UnsupportedSnapshotValueErr, ScopeText);
    end;

    local procedure ValidatePermissionToken(PermissionText: Text)
    begin
        if SourcePermissionIsGranted(PermissionText) then;
    end;

    local procedure LoadAssignedTableDataObjectPermissions(RunId: Guid; var ExpandedPermission: Record "Expanded Permission")
    var
        Assignment: Record "BCG User Perm. Assignment";
        TempAssignedIdentity: Record "BCG Perm. Set Object Perm." temporary;
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
    begin
        Assignment.SetRange("Run ID", RunId);
        if Assignment.FindSet() then
            repeat
                // Only Role ID, App ID and Scope vary; other key fields stay at their defaults.
                TempAssignedIdentity.Init();
                TempAssignedIdentity."Role ID" := Assignment."Role ID";
                TempAssignedIdentity."App ID" := Assignment."App ID";
                TempAssignedIdentity."Scope Text" := Assignment."Scope Text";
                if not TempAssignedIdentity.Insert() then;
            until Assignment.Next() = 0;

        ExpandedPermission.SetRange("Object Type", ExpandedPermission."Object Type"::"Table Data");
        if ExpandedPermission.FindSet() then
            repeat
                if TempAssignedIdentity.Get(TempAssignedIdentity."Run ID", ExpandedPermission."Role ID",
                    ExpandedPermission."App ID", CapturedScope(ExpandedPermission.Scope), '', 0)
                then begin
                    ObjectPerm.Init();
                    ObjectPerm."Run ID" := RunId;
                    ObjectPerm."Role ID" := ExpandedPermission."Role ID";
                    ObjectPerm."Role Name" := ExpandedPermission."Role Name";
                    ObjectPerm."Scope Text" := CopyStr(CapturedScope(ExpandedPermission.Scope), 1, MaxStrLen(ObjectPerm."Scope Text"));
                    ObjectPerm."App ID" := ExpandedPermission."App ID";
                    ObjectPerm."Object Type" := 'Table Data';
                    ObjectPerm."Object ID" := ExpandedPermission."Object ID";
                    ObjectPerm."Object Name" := CopyStr(GetTableDataDisplayName(ExpandedPermission."Object ID", ExpandedPermission."Object Name"), 1, MaxStrLen(ObjectPerm."Object Name"));
                    ObjectPerm."Read Permission" := CapturedPermission(ExpandedPermission."Read Permission");
                    ObjectPerm."Insert Permission" := CapturedPermission(ExpandedPermission."Insert Permission");
                    ObjectPerm."Modify Permission" := CapturedPermission(ExpandedPermission."Modify Permission");
                    ObjectPerm."Delete Permission" := CapturedPermission(ExpandedPermission."Delete Permission");
                    ObjectPerm."Execute Permission" := CapturedPermission(ExpandedPermission."Execute Permission");
                    ObjectPerm."Security Filter" := CopyStr(Format(ExpandedPermission."Security Filter"), 1, MaxStrLen(ObjectPerm."Security Filter"));
                    if not ObjectPerm.Insert(true) then;
                end;
            until ExpandedPermission.Next() = 0;
    end;

    local procedure BuildEffectiveUserTableDataPermissions(RunId: Guid)
    var
        Assignment: Record "BCG User Perm. Assignment";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        EffectivePerm: Record "BCG User Table Data Perm.";
        TempEffectivePerm: Record "BCG User Table Data Perm." temporary;
        TempObjectPerm: Record "BCG Perm. Set Object Perm." temporary;
        TempAssignment: Record "BCG User Perm. Assignment" temporary;
        TargetCompanies: List of [Text];
        TargetCompany: Text;
    begin
        ObjectPerm.SetRange("Run ID", RunId);
        if ObjectPerm.FindSet() then
            repeat
                TempObjectPerm := ObjectPerm;
                TempObjectPerm.Insert();
            until ObjectPerm.Next() = 0;

        Assignment.SetRange("Run ID", RunId);
        if Assignment.FindSet() then
            repeat
                TempAssignment := Assignment;
                TempAssignment.Insert();
            until Assignment.Next() = 0;

        // Rebuilds retain special rows, including every extension field.
        EffectivePerm.SetRange("Run ID", RunId);
        EffectivePerm.SetRange("Is Special Permission", true);
        if EffectivePerm.FindSet() then
            repeat
                TempEffectivePerm := EffectivePerm;
                TempEffectivePerm.Insert();
            until EffectivePerm.Next() = 0;

        Assignment.SetRange("Run ID", RunId);
        if Assignment.FindSet() then
            repeat
                TempObjectPerm.SetRange("Run ID", RunId);
                TempObjectPerm.SetRange("Role ID", Assignment."Role ID");
                TempObjectPerm.SetRange("App ID", Assignment."App ID");
                TempObjectPerm.SetRange("Scope Text", Assignment."Scope Text");
                TempObjectPerm.SetRange("Object Type", 'Table Data');
                TargetCompanies := GetPermissionTargetCompanies(RunId, Assignment."User Security ID", Assignment."Company Name");
                if TempObjectPerm.FindSet() then
                    repeat
                        foreach TargetCompany in TargetCompanies do
                            UpsertEffectivePermission(TempEffectivePerm, RunId, Assignment, TempObjectPerm, CopyStr(TargetCompany, 1, 30));
                    until TempObjectPerm.Next() = 0;
                TempObjectPerm.Reset();
            until Assignment.Next() = 0;

        PersistEffectivePermissions(TempEffectivePerm, TempObjectPerm, TempAssignment);
    end;

    local procedure PersistEffectivePermissions(var TempEffectivePerm: Record "BCG User Table Data Perm." temporary; var TempObjectPerm: Record "BCG Perm. Set Object Perm." temporary; var TempAssignment: Record "BCG User Perm. Assignment" temporary)
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        TempExactSources: Record "BCG Perm. Set Object Perm." temporary;
        TempWildcardSources: Record "BCG Perm. Set Object Perm." temporary;
        TempWildcardPermission: Record "BCG User Table Data Perm." temporary;
        ContextUserId: Guid;
        ContextCompany: Text[30];
        HasContext: Boolean;
        HasWildcard: Boolean;
    begin
        TempWildcardPermission.Copy(TempEffectivePerm, true);
        TempEffectivePerm.Reset();
        if TempEffectivePerm.FindSet() then
            repeat
                if not HasContext or (ContextUserId <> TempEffectivePerm."User Security ID") or
                   (ContextCompany <> TempEffectivePerm."Company Name") then begin
                    BuildContextContributorSets(TempEffectivePerm, TempObjectPerm, TempAssignment, TempExactSources, TempWildcardSources);
                    HasWildcard := TempWildcardPermission.Get(TempEffectivePerm."Run ID",
                        TempEffectivePerm."User Security ID", TempEffectivePerm."Company Name", 0);
                    ContextUserId := TempEffectivePerm."User Security ID";
                    ContextCompany := TempEffectivePerm."Company Name";
                    HasContext := true;
                end;
                if HasWildcard and (TempEffectivePerm."Object ID" <> 0) then
                    MergeEffectiveGrants(TempEffectivePerm, TempWildcardPermission);
                if TempEffectivePerm."Is Special Permission" then
                    TempEffectivePerm."Effective Source Count" := CountEffectivePermissionSources(TempEffectivePerm)
                else
                    TempEffectivePerm."Effective Source Count" := CountCachedPermissionSources(TempEffectivePerm."Object ID", TempExactSources, TempWildcardSources);
                if TempEffectivePerm."Is Special Permission" then begin
                    EffectivePerm.Get(TempEffectivePerm."Run ID", TempEffectivePerm."User Security ID",
                        TempEffectivePerm."Company Name", TempEffectivePerm."Object ID");
                    // Only these fields can change while merging into a retained row.
                    if (EffectivePerm."Can Read" <> TempEffectivePerm."Can Read") or
                       (EffectivePerm."Can Insert" <> TempEffectivePerm."Can Insert") or
                       (EffectivePerm."Can Modify" <> TempEffectivePerm."Can Modify") or
                       (EffectivePerm."Can Delete" <> TempEffectivePerm."Can Delete") or
                       (EffectivePerm."Security Filter" <> TempEffectivePerm."Security Filter") or
                       (EffectivePerm."Effective Source Count" <> TempEffectivePerm."Effective Source Count")
                    then begin
                        EffectivePerm."Can Read" := TempEffectivePerm."Can Read";
                        EffectivePerm."Can Insert" := TempEffectivePerm."Can Insert";
                        EffectivePerm."Can Modify" := TempEffectivePerm."Can Modify";
                        EffectivePerm."Can Delete" := TempEffectivePerm."Can Delete";
                        EffectivePerm."Security Filter" := TempEffectivePerm."Security Filter";
                        EffectivePerm."Effective Source Count" := TempEffectivePerm."Effective Source Count";
                        EffectivePerm.Modify(true);
                    end;
                end else begin
                    EffectivePerm := TempEffectivePerm;
                    EffectivePerm.Insert(true);
                end;
            until TempEffectivePerm.Next() = 0;
    end;

    local procedure BuildContextContributorSets(EffectivePerm: Record "BCG User Table Data Perm."; var TempObjectPerm: Record "BCG Perm. Set Object Perm." temporary; var TempAssignment: Record "BCG User Perm. Assignment" temporary; var TempExactSources: Record "BCG Perm. Set Object Perm." temporary; var TempWildcardSources: Record "BCG Perm. Set Object Perm." temporary)
    begin
        TempExactSources.Reset();
        TempExactSources.DeleteAll();
        TempWildcardSources.Reset();
        TempWildcardSources.DeleteAll();
        TempAssignment.Reset();
        TempAssignment.SetRange("Run ID", EffectivePerm."Run ID");
        TempAssignment.SetRange("User Security ID", EffectivePerm."User Security ID");
        TempAssignment.SetFilter("Company Name", '%1|%2', EffectivePerm."Company Name", '');
        if TempAssignment.FindSet() then
            repeat
                TempObjectPerm.Reset();
                TempObjectPerm.SetRange("Run ID", EffectivePerm."Run ID");
                TempObjectPerm.SetRange("Role ID", TempAssignment."Role ID");
                TempObjectPerm.SetRange("App ID", TempAssignment."App ID");
                TempObjectPerm.SetRange("Scope Text", TempAssignment."Scope Text");
                TempObjectPerm.SetRange("Object Type", 'Table Data');
                if TempObjectPerm.FindSet() then
                    repeat
                        if SourceGrantsTableDataAccess(TempObjectPerm) then
                            if TempObjectPerm."Object ID" = 0 then
                                AddCountedPermissionIdentity(TempWildcardSources, TempObjectPerm."Role ID", TempObjectPerm."App ID", TempObjectPerm."Scope Text")
                            else begin
                                TempExactSources := TempObjectPerm;
                                if TempExactSources.Insert() then;
                            end;
                    until TempObjectPerm.Next() = 0;
            until TempAssignment.Next() = 0;
    end;

    local procedure CountCachedPermissionSources(ObjectId: Integer; var TempExactSources: Record "BCG Perm. Set Object Perm." temporary; var TempWildcardSources: Record "BCG Perm. Set Object Perm." temporary): Integer
    var
        SourceCount: Integer;
        EmptyRunId: Guid;
    begin
        SourceCount := TempWildcardSources.Count();
        if ObjectId = 0 then
            exit(SourceCount);

        TempExactSources.Reset();
        TempExactSources.SetCurrentKey("Run ID", "Object Type", "Object ID");
        TempExactSources.SetRange("Object ID", ObjectId);
        if TempExactSources.FindSet() then
            repeat
                // W already counts identities shared by exact and wildcard grants.
                if not TempWildcardSources.Get(EmptyRunId, TempExactSources."Role ID", TempExactSources."App ID", TempExactSources."Scope Text", '', 0) then
                    SourceCount += 1;
            until TempExactSources.Next() = 0;
        exit(SourceCount);
    end;

    internal procedure IsAssignmentInScope(RunId: Guid; UserSecurityId: Guid; AssignmentCompany: Text[30]): Boolean
    var
        UserSnapshot: Record "BCG User Snapshot";
    begin
        // Membership in this run's captured population means enabled Full User at capture time.
        // Keep the original blank/global company on assignments for source attribution.
        exit(((AssignmentCompany = '') or (AssignmentCompany = CompanyName())) and
            UserSnapshot.Get(RunId, UserSecurityId));
    end;

    procedure GetPermissionTargetCompanies(RunId: Guid; UserSecurityId: Guid; AssignmentCompany: Text[30]): List of [Text]
    var
        Targets: List of [Text];
    begin
        if IsAssignmentInScope(RunId, UserSecurityId, AssignmentCompany) then
            Targets.Add(CompanyName());
        exit(Targets);
    end;

    local procedure UpsertEffectivePermission(var EffectivePerm: Record "BCG User Table Data Perm." temporary; RunId: Guid; Assignment: Record "BCG User Perm. Assignment"; ObjectPerm: Record "BCG Perm. Set Object Perm."; TargetCompany: Text[30])
    var
        Exists: Boolean;
    begin
        Exists := EffectivePerm.Get(RunId, Assignment."User Security ID", TargetCompany, ObjectPerm."Object ID");
        if not Exists then begin
            EffectivePerm.Init();
            EffectivePerm."Run ID" := RunId;
            EffectivePerm."User Security ID" := Assignment."User Security ID";
            EffectivePerm."Company Name" := TargetCompany;
            EffectivePerm."Object ID" := ObjectPerm."Object ID";
            EffectivePerm."Object Name" := ObjectPerm."Object Name";
            EffectivePerm."Effective Source Count" := 0;
        end;

        EffectivePerm."Can Read" := EffectivePerm."Can Read" or IsPermissionGranted(ObjectPerm."Read Permission");
        EffectivePerm."Can Insert" := EffectivePerm."Can Insert" or IsPermissionGranted(ObjectPerm."Insert Permission");
        EffectivePerm."Can Modify" := EffectivePerm."Can Modify" or IsPermissionGranted(ObjectPerm."Modify Permission");
        EffectivePerm."Can Delete" := EffectivePerm."Can Delete" or IsPermissionGranted(ObjectPerm."Delete Permission");

        if EffectivePerm."Security Filter" = '' then
            EffectivePerm."Security Filter" := ObjectPerm."Security Filter";

        if Exists then
            EffectivePerm.Modify()
        else
            EffectivePerm.Insert();
    end;

    local procedure IsPermissionGranted(PermissionText: Text): Boolean
    begin
        exit(SourcePermissionIsGranted(PermissionText));
    end;

    procedure CountEffectivePermissionSources(EffectivePerm: Record "BCG User Table Data Perm."): Integer
    var
        Assignment: Record "BCG User Perm. Assignment";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        TempSource: Record "BCG Perm. Set Object Perm." temporary;
        SecGrpPermAssign: Record "BCG SecGrp Perm Assign";
        SpecialPermissionMgt: Codeunit "BCG Special Permission Mgt.";
        IsSpecialWildcard: Boolean;
    begin
        IsSpecialWildcard := (EffectivePerm."Object ID" = 0) and EffectivePerm."Is Special Permission";
        Assignment.SetRange("Run ID", EffectivePerm."Run ID");
        Assignment.SetRange("User Security ID", EffectivePerm."User Security ID");
        Assignment.SetFilter("Company Name", '%1|%2', EffectivePerm."Company Name", '');
        if Assignment.FindSet() then
            repeat
                if ObjectPerm.Get(EffectivePerm."Run ID", Assignment."Role ID", Assignment."App ID",
                    Assignment."Scope Text", 'Table Data', EffectivePerm."Object ID")
                then
                    if SourceGrantsTableDataAccess(ObjectPerm) then
                        AddCountedPermissionIdentity(TempSource, Assignment."Role ID", Assignment."App ID", Assignment."Scope Text");

                // A wildcard grants access to this object too. The identity key prevents double counting.
                if EffectivePerm."Object ID" <> 0 then
                    if ObjectPerm.Get(EffectivePerm."Run ID", Assignment."Role ID", Assignment."App ID",
                        Assignment."Scope Text", 'Table Data', 0)
                    then
                        if SourceGrantsTableDataAccess(ObjectPerm) then
                            AddCountedPermissionIdentity(TempSource, Assignment."Role ID", Assignment."App ID", Assignment."Scope Text");

                if IsSpecialWildcard and IsSuperAssignment(Assignment) then
                    AddCountedPermissionIdentity(TempSource, Assignment."Role ID", Assignment."App ID", Assignment."Scope Text");
            until Assignment.Next() = 0;

        if IsSpecialWildcard then begin
            // Captured fallback only: never supplement a historical run with live assignments.
            SecGrpPermAssign.SetRange("Run ID", EffectivePerm."Run ID");
            SecGrpPermAssign.SetRange("User Security ID", EffectivePerm."User Security ID");
            SecGrpPermAssign.SetFilter("Company Name", '%1|%2', EffectivePerm."Company Name", '');
            SecGrpPermAssign.SetFilter("Role ID", '%1|%2', 'SUPER', 'SUPER (DATA)');
            if SecGrpPermAssign.FindSet() then
                repeat
                    if SpecialPermissionMgt.IsPlatformSpecialPermission(SecGrpPermAssign."Role ID", SecGrpPermAssign."App ID", SecGrpPermAssign.Scope) then
                        AddCountedPermissionIdentity(TempSource, SecGrpPermAssign."Role ID", SecGrpPermAssign."App ID", SecGrpPermAssign.Scope);
                until SecGrpPermAssign.Next() = 0;
        end;

        exit(TempSource.Count());
    end;

    local procedure AddCountedPermissionIdentity(var TempSource: Record "BCG Perm. Set Object Perm." temporary; RoleId: Code[30]; AppId: Guid; ScopeText: Text[30])
    begin
        // All other primary-key fields stay at their defaults: identity is Role + App + Scope.
        TempSource.Init();
        TempSource."Role ID" := RoleId;
        TempSource."App ID" := AppId;
        TempSource."Scope Text" := ScopeText;
        if TempSource.Insert() then;
    end;

    local procedure SourceGrantsTableDataAccess(ObjectPerm: Record "BCG Perm. Set Object Perm."): Boolean
    begin
        exit(SourcePermissionIsGranted(ObjectPerm."Read Permission") or
            SourcePermissionIsGranted(ObjectPerm."Insert Permission") or
            SourcePermissionIsGranted(ObjectPerm."Modify Permission") or
            SourcePermissionIsGranted(ObjectPerm."Delete Permission"));
    end;

    local procedure SourcePermissionIsGranted(PermissionText: Text): Boolean
    var
        PermissionUpper: Text;
    begin
        PermissionUpper := UpperCase(DelChr(PermissionText, '=', ' '));
        case PermissionUpper of
            'YES', 'DIRECT', 'INDIRECT': exit(true);
            '', 'NO', '0': exit(false);
        end;
        Error(UnsupportedSnapshotValueErr, PermissionText);
    end;

    procedure RebuildEffectiveUserTableDataPermissions(RunId: Guid)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Snapshot Mgt.");
        if IsNullGuid(RunId) then
            Error('Run ID is required.');

        ValidateSnapshotTokens(RunId);
        ClearNonSpecialEffectivePermissions(RunId);
        BuildEffectiveUserTableDataPermissions(RunId);
    end;

    local procedure ClearNonSpecialEffectivePermissions(RunId: Guid)
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
    begin
        EffectivePerm.SetRange("Run ID", RunId);
        EffectivePerm.SetRange("Is Special Permission", false);
        EffectivePerm.DeleteAll();
    end;

    procedure CalculateConflicts(RunId: Guid)
    begin
        BCGAccessMgt.RequireRunningRun(RunId, Codeunit::"BCG Snapshot Mgt.");
        ValidateSnapshotTokens(RunId);
        ClearConflictResults(RunId);
        CalculateConflictsFromWizardSetup(RunId);
    end;

    local procedure ClearConflictResults(RunId: Guid)
    var
        ConflictResult: Record "BCG User Conflict Result";
        ConflictResultLine: Record "BCG User Conflict Result Line";
    begin
        ConflictResult.SetRange("Run ID", RunId);
        ConflictResult.DeleteAll();

        ConflictResultLine.SetRange("Run ID", RunId);
        ConflictResultLine.DeleteAll();
    end;

    local procedure CalculateConflictsFromWizardSetup(RunId: Guid)
    var
        EmptyGuid: Guid;
        ConflictHeader: Record "BCG Conflict Header";
        Assignment: Record "BCG User Perm. Assignment";
        TempContext: Record "BCG User Table Data Perm." temporary;
        TargetCompanies: List of [Text];
        TargetCompany: Text;
    begin
        // Important: iterate assignments, not only effective Table Data permissions.
        // Users with SUPER / SUPER (DATA) may have no expanded Table Data rows,
        // but they still need to be evaluated as high-risk users.
        ConflictHeader.SetRange("Is Active", true);
        // Synthetic definitions are permanently excluded from ordinary analysis.
        ConflictHeader.SetRange("Perf Dataset ID", EmptyGuid);
#if BCG_PERF_TESTS
        if not IsNullGuid(PerfDataset."Run ID") then
            ConflictHeader.SetRange("Perf Dataset ID", PerfDataset."Run ID");
#endif

        if ConflictHeader.FindSet() then
            repeat
                TempContext.DeleteAll();

                Assignment.Reset();
                Assignment.SetCurrentKey("Run ID", "User Security ID", "Company Name", "Role ID", "App ID");
                Assignment.SetRange("Run ID", RunId);

                if Assignment.FindSet() then
                    repeat
                        TargetCompanies := GetPermissionTargetCompanies(RunId, Assignment."User Security ID", Assignment."Company Name");
                        foreach TargetCompany in TargetCompanies do
                            if (TargetCompany <> '') and
                               not TempContext.Get(RunId, Assignment."User Security ID", TargetCompany, 0) then begin
                                TempContext.Init();
                                TempContext."Run ID" := RunId;
                                TempContext."User Security ID" := Assignment."User Security ID";
                                TempContext."Company Name" := CopyStr(TargetCompany, 1, 30);
                                TempContext."Object ID" := 0;
                                TempContext.Insert();
                                if UserMeetsConflict(RunId, Assignment."User Security ID", CopyStr(TargetCompany, 1, 30), ConflictHeader) then
                                    InsertConflictFromSetup(RunId, Assignment."User Security ID", CopyStr(TargetCompany, 1, 30), ConflictHeader);
                            end;
                    until Assignment.Next() = 0;
            until ConflictHeader.Next() = 0;
    end;

    local procedure UserMeetsConflict(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; ConflictHeader: Record "BCG Conflict Header"): Boolean
    var
        ConflictGroup: Record "BCG Conflict Group";
    begin
        ConflictGroup.SetRange("Conflict ID", ConflictHeader."Conflict ID");
        ConflictGroup.SetRange("Is Active", true);

        if not ConflictGroup.FindSet() then
            exit(false);

        repeat
            if not UserMeetsConflictGroup(RunId, UserSecurityId, CompanyName, ConflictGroup) then
                exit(false);
        until ConflictGroup.Next() = 0;

        exit(true);
    end;

    local procedure UserMeetsConflictGroup(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; ConflictGroup: Record "BCG Conflict Group"): Boolean
    var
        GroupRule: Record "BCG Conflict Group Rule";
        AtLeastOneRule: Boolean;
        IsAllLogic: Boolean;
    begin
        IsAllLogic := (ConflictGroup."Evaluation Logic" = ConflictGroup."Evaluation Logic"::ALL);

        GroupRule.SetRange("Conflict ID", ConflictGroup."Conflict ID");
        GroupRule.SetRange("Group No.", ConflictGroup."Group No.");

        if not GroupRule.FindSet() then
            exit(false);

        repeat
            AtLeastOneRule := true;

            if IsAllLogic then begin
                if not UserMeetsGroupRule(RunId, UserSecurityId, CompanyName, GroupRule) then
                    exit(false);
            end else begin
                if UserMeetsGroupRule(RunId, UserSecurityId, CompanyName, GroupRule) then
                    exit(true);
            end;
        until GroupRule.Next() = 0;

        if IsAllLogic then
            exit(AtLeastOneRule);

        exit(false);
    end;

    local procedure UserMeetsGroupRule(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; GroupRule: Record "BCG Conflict Group Rule"): Boolean
    var
        EffectivePerm: Record "BCG User Table Data Perm.";
        SuperAssignment: Record "BCG User Perm. Assignment";
    begin
        // SUPER / SUPER (DATA) is checked first because it is the primary access-risk signal.
        // It may not create explicit Expanded Permission rows for each Table Data object.
        if UserHasSuperOrSuperData(RunId, UserSecurityId, CompanyName, SuperAssignment) then
            exit(true);

        // Standard path: explicit effective permission to the requested Table Data object.
        if FindEffectivePermissionForRule(RunId, UserSecurityId, CompanyName, GroupRule, EffectivePerm) then
            exit(true);

        exit(false);
    end;

    local procedure FindEffectivePermissionForRule(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; GroupRule: Record "BCG Conflict Group Rule"; var EffectivePerm: Record "BCG User Table Data Perm."): Boolean
    var
        WildcardPermission: Record "BCG User Table Data Perm.";
        HasExact: Boolean;
    begin
        EffectivePerm.Reset();
        HasExact := EffectivePerm.Get(RunId, UserSecurityId, CompanyName, GroupRule."Object ID");
        if WildcardPermission.Get(RunId, UserSecurityId, CompanyName, 0) then begin
            if HasExact then
                MergeEffectiveGrants(EffectivePerm, WildcardPermission)
            else
                EffectivePerm := WildcardPermission;
        end else
            if not HasExact then
                exit(false);

        // Merge operations before Any/All, including snapshots captured before union aggregation.
        // Direct Only still checks exact/wildcard source values, not these inclusive booleans.
        if not EffectivePermissionSatisfiesRule(GroupRule, EffectivePerm) then
            exit(false);
        EffectivePerm."Object ID" := GroupRule."Object ID";
        if not HasExact then
            EffectivePerm."Object Name" := CopyStr(GroupRule."Object Caption", 1, MaxStrLen(EffectivePerm."Object Name"));
        exit(true);
    end;

    local procedure MergeEffectiveGrants(var EffectivePerm: Record "BCG User Table Data Perm."; WildcardPermission: Record "BCG User Table Data Perm.")
    begin
        EffectivePerm."Can Read" := EffectivePerm."Can Read" or WildcardPermission."Can Read";
        EffectivePerm."Can Insert" := EffectivePerm."Can Insert" or WildcardPermission."Can Insert";
        EffectivePerm."Can Modify" := EffectivePerm."Can Modify" or WildcardPermission."Can Modify";
        EffectivePerm."Can Delete" := EffectivePerm."Can Delete" or WildcardPermission."Can Delete";
    end;

    local procedure EffectivePermissionSatisfiesRule(GroupRule: Record "BCG Conflict Group Rule"; EffectivePerm: Record "BCG User Table Data Perm."): Boolean
    begin
        if not RuleUsesPermissionFlags(GroupRule) then
            exit(IsLegacyRequiredPermissionSatisfied(AccessTypeToken(GroupRule."Required Permission"), EffectivePerm));

        if GroupRule."Permission Match Mode" = GroupRule."Permission Match Mode"::All then begin
            if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Read) and not EffectivePermissionSatisfiesOperation(GroupRule, EffectivePerm, Enum::"BCG Access Type"::Read) then
                exit(false);
            if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Insert) and not EffectivePermissionSatisfiesOperation(GroupRule, EffectivePerm, Enum::"BCG Access Type"::Insert) then
                exit(false);
            if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Modify) and not EffectivePermissionSatisfiesOperation(GroupRule, EffectivePerm, Enum::"BCG Access Type"::Modify) then
                exit(false);
            if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Delete) and not EffectivePermissionSatisfiesOperation(GroupRule, EffectivePerm, Enum::"BCG Access Type"::Delete) then
                exit(false);

            exit(true);
        end;

        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Read) and EffectivePermissionSatisfiesOperation(GroupRule, EffectivePerm, Enum::"BCG Access Type"::Read) then
            exit(true);
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Insert) and EffectivePermissionSatisfiesOperation(GroupRule, EffectivePerm, Enum::"BCG Access Type"::Insert) then
            exit(true);
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Modify) and EffectivePermissionSatisfiesOperation(GroupRule, EffectivePerm, Enum::"BCG Access Type"::Modify) then
            exit(true);
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Delete) and EffectivePermissionSatisfiesOperation(GroupRule, EffectivePerm, Enum::"BCG Access Type"::Delete) then
            exit(true);

        exit(false);
    end;

    local procedure RuleUsesPermissionFlags(GroupRule: Record "BCG Conflict Group Rule"): Boolean
    begin
        exit(GroupRule."Requires Read" or GroupRule."Requires Insert" or GroupRule."Requires Modify" or GroupRule."Requires Delete");
    end;

    local procedure IsLegacyRequiredPermissionSatisfied(RequiredPermissionText: Text; EffectivePerm: Record "BCG User Table Data Perm."): Boolean
    var
        PermissionUpper: Text;
    begin
        PermissionUpper := UpperCase(RequiredPermissionText);

        if StrPos(PermissionUpper, 'READ') > 0 then
            exit(EffectivePerm."Can Read");

        if StrPos(PermissionUpper, 'INSERT') > 0 then
            exit(EffectivePerm."Can Insert");

        if StrPos(PermissionUpper, 'MODIFY') > 0 then
            exit(EffectivePerm."Can Modify");

        if StrPos(PermissionUpper, 'DELETE') > 0 then
            exit(EffectivePerm."Can Delete");

        exit(false);
    end;

    local procedure EffectivePermissionSatisfiesOperation(GroupRule: Record "BCG Conflict Group Rule"; EffectivePerm: Record "BCG User Table Data Perm."; AccessType: Enum "BCG Access Type"): Boolean
    var
        PermissionMatch: Enum "BCG Table Data Perm Match";
    begin
        PermissionMatch := GetRulePermissionMode(GroupRule, AccessType);

        case PermissionMatch of
            PermissionMatch::"Direct Only":
                exit(UserHasSourcePermissionForRule(EffectivePerm, GroupRule, AccessType, PermissionMatch));
            PermissionMatch::"Direct or Indirect":
                case AccessType of
                    AccessType::Read:
                        exit(EffectivePerm."Can Read");
                    AccessType::Insert:
                        exit(EffectivePerm."Can Insert");
                    AccessType::Modify:
                        exit(EffectivePerm."Can Modify");
                    AccessType::Delete:
                        exit(EffectivePerm."Can Delete");
                end;
        end;

        exit(false);
    end;

    local procedure UserHasSourcePermissionForRule(EffectivePerm: Record "BCG User Table Data Perm."; GroupRule: Record "BCG Conflict Group Rule"; AccessType: Enum "BCG Access Type"; PermissionMatch: Enum "BCG Table Data Perm Match"): Boolean
    var
        Assignment: Record "BCG User Perm. Assignment";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
    begin
        Assignment.SetRange("Run ID", EffectivePerm."Run ID");
        Assignment.SetRange("User Security ID", EffectivePerm."User Security ID");
        Assignment.SetFilter("Company Name", '%1|%2', EffectivePerm."Company Name", '');

        if Assignment.FindSet() then
            repeat
                ObjectPerm.Reset();
                ObjectPerm.SetRange("Run ID", EffectivePerm."Run ID");
                ObjectPerm.SetRange("Role ID", Assignment."Role ID");
                ObjectPerm.SetRange("App ID", Assignment."App ID");
                ObjectPerm.SetRange("Scope Text", Assignment."Scope Text");
                ObjectPerm.SetRange("Object Type", 'Table Data');
                ObjectPerm.SetFilter("Object ID", '%1|%2', GroupRule."Object ID", 0);

                if ObjectPerm.FindSet() then
                    repeat
                        if ObjectPermissionSatisfiesOperation(ObjectPerm, AccessType, PermissionMatch) then
                            exit(true);
                    until ObjectPerm.Next() = 0;
            until Assignment.Next() = 0;

        exit(false);
    end;

    local procedure OperationIsRequired(GroupRule: Record "BCG Conflict Group Rule"; AccessType: Enum "BCG Access Type"): Boolean
    begin
        exit(GetRulePermissionMode(GroupRule, AccessType) <> Enum::"BCG Table Data Perm Match"::"Not Required");
    end;

    local procedure GetRulePermissionMode(GroupRule: Record "BCG Conflict Group Rule"; AccessType: Enum "BCG Access Type"): Enum "BCG Table Data Perm Match"
    var
        PermissionMatch: Enum "BCG Table Data Perm Match";
        LegacyRequired: Boolean;
    begin
        case AccessType of
            AccessType::Read:
                begin
                    PermissionMatch := GroupRule."Read Permission Match";
                    LegacyRequired := GroupRule."Requires Read";
                end;
            AccessType::Insert:
                begin
                    PermissionMatch := GroupRule."Insert Permission Match";
                    LegacyRequired := GroupRule."Requires Insert";
                end;
            AccessType::Modify:
                begin
                    PermissionMatch := GroupRule."Modify Permission Match";
                    LegacyRequired := GroupRule."Requires Modify";
                end;
            AccessType::Delete:
                begin
                    PermissionMatch := GroupRule."Delete Permission Match";
                    LegacyRequired := GroupRule."Requires Delete";
                end;
        end;

        if (PermissionMatch = PermissionMatch::"Not Required") and LegacyRequired then
            exit(PermissionMatch::"Direct or Indirect");

        exit(PermissionMatch);
    end;


    local procedure InsertConflictFromSetup(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; ConflictHeader: Record "BCG Conflict Header")
    var
        ConflictResult: Record "BCG User Conflict Result";
        ObjectAId: Integer;
        ObjectAName: Text[249];
        ObjectAPermission: Text[30];
        ObjectBId: Integer;
        ObjectBName: Text[249];
        ObjectBPermission: Text[30];
        ResultDescription: Text[500];
    begin
        if ConflictAlreadyExists(RunId, UserSecurityId, CompanyName, ConflictHeader."Conflict ID") then
            exit;

        GetFirstTwoMatchedRuleDetails(
            RunId,
            UserSecurityId,
            CompanyName,
            ConflictHeader."Conflict ID",
            ObjectAId,
            ObjectAName,
            ObjectAPermission,
            ObjectBId,
            ObjectBName,
            ObjectBPermission);

        ConflictResult.Init();
        ConflictResult."Run ID" := RunId;
        ConflictResult."User Security ID" := UserSecurityId;
        ConflictResult."Company Name" := CompanyName;
        ConflictResult."Conflict Code" := ConflictHeader."Conflict ID";
        ConflictResult."Conflict Name" := ConflictHeader.Name;
        ConflictResult.Status := ConflictResult.Status::Open;
        ConflictResult."Detected At" := CurrentDateTime();
        SetConflictResultSeverity(ConflictResult, ConflictHeader.Severity);

        ConflictResult."Object A ID" := ObjectAId;
        ConflictResult."Object A Name" := CopyStr(ObjectAName, 1, MaxStrLen(ConflictResult."Object A Name"));
        ConflictResult."Object A Permission" := CopyStr(ObjectAPermission, 1, MaxStrLen(ConflictResult."Object A Permission"));
        ConflictResult."Object B ID" := ObjectBId;
        ConflictResult."Object B Name" := CopyStr(ObjectBName, 1, MaxStrLen(ConflictResult."Object B Name"));
        ConflictResult."Object B Permission" := CopyStr(ObjectBPermission, 1, MaxStrLen(ConflictResult."Object B Permission"));

        ResultDescription := StrSubstNo('User meets all active groups for conflict %1.', ConflictHeader."Conflict ID");
        if ConflictHeader.Recommendation <> '' then
            ResultDescription := CopyStr(ResultDescription + ' Recommendation: ' + ConflictHeader.Recommendation, 1, MaxStrLen(ResultDescription));
        ConflictResult."Result Description" := CopyStr(ResultDescription, 1, MaxStrLen(ConflictResult."Result Description"));

        ConflictResult.Insert(true);
        InsertConflictResultLines(ConflictResult, ConflictHeader."Conflict ID");
    end;


    local procedure InsertConflictResultLines(ConflictResult: Record "BCG User Conflict Result"; ConflictId: Code[20])
    var
        ConflictGroup: Record "BCG Conflict Group";
    begin
        ConflictGroup.SetRange("Conflict ID", ConflictId);
        ConflictGroup.SetRange("Is Active", true);
        ConflictGroup.SetCurrentKey("Conflict ID", Sequence);

        if ConflictGroup.FindSet() then
            repeat
                InsertConflictResultLinesForGroup(ConflictResult, ConflictGroup);
            until ConflictGroup.Next() = 0;
    end;

    local procedure InsertConflictResultLinesForGroup(ConflictResult: Record "BCG User Conflict Result"; ConflictGroup: Record "BCG Conflict Group")
    var
        GroupRule: Record "BCG Conflict Group Rule";
        EffectivePerm: Record "BCG User Table Data Perm.";
        SuperAssignment: Record "BCG User Perm. Assignment";
        IsAllLogic: Boolean;
        HasSuperSource: Boolean;
        HasNormalSource: Boolean;
    begin
        IsAllLogic := (ConflictGroup."Evaluation Logic" = ConflictGroup."Evaluation Logic"::ALL);

        GroupRule.SetRange("Conflict ID", ConflictGroup."Conflict ID");
        GroupRule.SetRange("Group No.", ConflictGroup."Group No.");

        if not GroupRule.FindSet() then
            exit;

        repeat
            HasSuperSource := UserHasSuperOrSuperData(
                ConflictResult."Run ID",
                ConflictResult."User Security ID",
                ConflictResult."Company Name",
                SuperAssignment);

            // SUPER / SUPER (DATA) is a valid source, but it must not hide normal direct permission set sources.
            // If the same user also has an explicit permission set that satisfies the rule, insert both lines.
            // The source summary will then become Mixed / Special Permission + Direct instead of only Special Permission.
            if HasSuperSource then
                InsertApplicableSpecialSources(ConflictResult, ConflictGroup, GroupRule);

            HasNormalSource := false;
            if FindEffectivePermissionForRule(
                ConflictResult."Run ID",
                ConflictResult."User Security ID",
                ConflictResult."Company Name",
                GroupRule,
                EffectivePerm)
            then begin
                InsertConflictResultLineWithSources(ConflictResult, ConflictGroup, GroupRule, EffectivePerm);
                HasNormalSource := true;
            end;

            if (HasSuperSource or HasNormalSource) and (not IsAllLogic) then
                exit;
        until GroupRule.Next() = 0;
    end;

    local procedure InsertConflictResultLineWithSources(ConflictResult: Record "BCG User Conflict Result"; ConflictGroup: Record "BCG Conflict Group"; GroupRule: Record "BCG Conflict Group Rule"; EffectivePerm: Record "BCG User Table Data Perm.")
    var
        Assignment: Record "BCG User Perm. Assignment";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        SourceFound: Boolean;
        TempSources: Record "BCG Perm. Set Object Perm." temporary;
        SpecialLine: Record "BCG User Conflict Result Line";
        MatchedOperations: Text[30];
    begin
        Assignment.SetRange("Run ID", ConflictResult."Run ID");
        Assignment.SetRange("User Security ID", ConflictResult."User Security ID");
        Assignment.SetFilter("Company Name", '%1|%2', ConflictResult."Company Name", '');

        if Assignment.FindSet() then
            repeat
                ObjectPerm.Reset();
                ObjectPerm.SetRange("Run ID", ConflictResult."Run ID");
                ObjectPerm.SetRange("Role ID", Assignment."Role ID");
                ObjectPerm.SetRange("App ID", Assignment."App ID");
                ObjectPerm.SetRange("Scope Text", Assignment."Scope Text");
                ObjectPerm.SetRange("Object Type", 'Table Data');
                ObjectPerm.SetFilter("Object ID", '%1|%2', GroupRule."Object ID", 0);

                if ObjectPerm.FindSet() then
                    repeat
                        if ObjectPermissionContributesToRule(ObjectPerm, GroupRule) then begin
                            SourceFound := true;
                            MatchedOperations := MergeMatchedOperations(MatchedOperations, GetMatchedPermissionText(ObjectPerm, GroupRule));
                            if not TempSources.Get(ObjectPerm."Run ID", ObjectPerm."Role ID", ObjectPerm."App ID", ObjectPerm."Scope Text", ObjectPerm."Object Type", ObjectPerm."Object ID") then begin
                                TempSources := ObjectPerm;
                                TempSources.Insert();
                                InsertOneConflictResultLine(ConflictResult, ConflictGroup, GroupRule, EffectivePerm, Assignment, ObjectPerm);
                            end;
                        end;
                    until ObjectPerm.Next() = 0;

            until Assignment.Next() = 0;

        if not SourceFound or MissingAllContributors(GroupRule, MatchedOperations) then begin
            SpecialLine.SetRange("Conflict Result Entry No.", ConflictResult."Entry No.");
            SpecialLine.SetRange("Group No.", ConflictGroup."Group No.");
            SpecialLine.SetRange("Rule ID", GroupRule."Rule ID");
            SpecialLine.SetRange("Object ID", GroupRule."Object ID");
            SpecialLine.SetRange("Is Special Permission Source", true);
            if SpecialLine.IsEmpty() then
                InsertOneConflictResultLineWithoutSource(ConflictResult, ConflictGroup, GroupRule, EffectivePerm);
        end;
    end;

    local procedure InsertOneConflictResultLine(ConflictResult: Record "BCG User Conflict Result"; ConflictGroup: Record "BCG Conflict Group"; GroupRule: Record "BCG Conflict Group Rule"; EffectivePerm: Record "BCG User Table Data Perm."; Assignment: Record "BCG User Perm. Assignment"; ObjectPerm: Record "BCG Perm. Set Object Perm.")
    var
        ConflictLine: Record "BCG User Conflict Result Line";
        SourceMgt: Codeunit "BCG Conflict Source Mgt";
        ContributionTraceLbl: Label 'Captured Table Data %1; operation mode %2. Matched Permission lists only operations contributed by this source.', Comment = '%1 = source object ID (0 is wildcard), %2 = Any/All operation mode';
    begin
        MergeApplicableAssignmentSources(Assignment, ConflictResult."Company Name");
        ConflictLine.Init();
        ConflictLine."Conflict Result Entry No." := ConflictResult."Entry No.";
        ConflictLine."Run ID" := ConflictResult."Run ID";
        ConflictLine."User Security ID" := ConflictResult."User Security ID";
        ConflictLine."Company Name" := ConflictResult."Company Name";
        ConflictLine."Conflict Code" := ConflictResult."Conflict Code";
        ConflictLine."Conflict Name" := CopyStr(ConflictResult."Conflict Name", 1, MaxStrLen(ConflictLine."Conflict Name"));
        ConflictLine."Group No." := ConflictGroup."Group No.";
        ConflictLine."Group Name" := ConflictGroup."Group Name";
        ConflictLine."Evaluation Logic" := CopyStr(Format(ConflictGroup."Evaluation Logic"), 1, MaxStrLen(ConflictLine."Evaluation Logic"));
        ConflictLine."Rule ID" := GroupRule."Rule ID";
        ConflictLine."Rule Name" := GroupRule."Rule Name";
        ConflictLine."Object ID" := GroupRule."Object ID";
        ConflictLine."Object Name" := CopyStr(GetTableDataDisplayName(GroupRule."Object ID", EffectivePerm."Object Name"), 1, MaxStrLen(ConflictLine."Object Name"));
        ConflictLine."Required Permission" := CopyStr(GetRulePermissionSummary(GroupRule), 1, MaxStrLen(ConflictLine."Required Permission"));
        ConflictLine."Matched Permission" := GetMatchedPermissionText(ObjectPerm, GroupRule);
        ConflictLine."Role ID" := Assignment."Role ID";
        ConflictLine."Role Name" := Assignment."Role Name";
        if ConflictLine."Role Name" = '' then
            ConflictLine."Role Name" := ObjectPerm."Role Name";
        ConflictLine."App ID" := Assignment."App ID";
        ConflictLine."App Name" := Assignment."App Name";
        ConflictLine."Scope Text" := Assignment."Scope Text";
        ConflictLine."Assignment Source Type" := Assignment."Assignment Source Type";
        ConflictLine."Security Filter" := ObjectPerm."Security Filter";
        ConflictLine."Trace Notes" := CopyStr(StrSubstNo('Permission source: role %1 / app %2.', Assignment."Role ID", Assignment."App Name"), 1, MaxStrLen(ConflictLine."Trace Notes"));

        SourceMgt.ApplySourceToConflictLine(
            ConflictLine,
            ConflictResult."Run ID",
            ConflictResult."User Security ID",
            ConflictResult."Company Name",
            Assignment."Role ID",
            CopyStr(ConflictLine."Role Name", 1, 80),
            Assignment."App ID",
            Assignment."Assignment Source Type",
            Assignment."Assignment Source Code");

        ConflictLine."Source Company Name" := Assignment."Company Name";
        ConflictLine."Trace Notes" := CopyStr(
            StrSubstNo(ContributionTraceLbl,
                ObjectPerm."Object ID", Format(GroupRule."Permission Match Mode")),
            1, MaxStrLen(ConflictLine."Trace Notes"));
        if IsSuperAssignment(Assignment) then
            SetSpecialEvidenceAttributes(ConflictLine);
        SaveEvidenceIdentity(ConflictLine);
    end;

    local procedure MergeApplicableAssignmentSources(var Assignment: Record "BCG User Perm. Assignment"; TargetCompany: Text[30])
    var
        OtherAssignment: Record "BCG User Perm. Assignment";
        HasDirect: Boolean;
        HasGroup: Boolean;
    begin
        OtherAssignment.SetRange("Run ID", Assignment."Run ID");
        OtherAssignment.SetRange("User Security ID", Assignment."User Security ID");
        OtherAssignment.SetFilter("Company Name", '%1|%2', TargetCompany, '');
        OtherAssignment.SetRange("Role ID", Assignment."Role ID");
        OtherAssignment.SetRange("App ID", Assignment."App ID");
        OtherAssignment.SetRange("Scope Text", Assignment."Scope Text");
        if OtherAssignment.FindSet() then
            repeat
                HasDirect := HasDirect or (OtherAssignment."Assignment Source Type" = '') or
                    (StrPos(UpperCase(OtherAssignment."Assignment Source Type"), 'DIRECT') > 0);
                if StrPos(UpperCase(OtherAssignment."Assignment Source Type"), 'SECURITY GROUP') > 0 then begin
                    HasGroup := true;
                    if Assignment."Assignment Source Code" = '' then
                        Assignment."Assignment Source Code" := OtherAssignment."Assignment Source Code";
                end;
            until OtherAssignment.Next() = 0;
        // Assignment is a by-value copy; captured rows and their original companies are untouched.
        if HasDirect and HasGroup then
            Assignment."Assignment Source Type" := 'Direct + Security Group';
    end;

    local procedure InsertOneConflictResultLineWithoutSource(ConflictResult: Record "BCG User Conflict Result"; ConflictGroup: Record "BCG Conflict Group"; GroupRule: Record "BCG Conflict Group Rule"; EffectivePerm: Record "BCG User Table Data Perm.")
    var
        ConflictLine: Record "BCG User Conflict Result Line";
    begin
        ConflictLine.Init();
        ConflictLine."Conflict Result Entry No." := ConflictResult."Entry No.";
        ConflictLine."Run ID" := ConflictResult."Run ID";
        ConflictLine."User Security ID" := ConflictResult."User Security ID";
        ConflictLine."Company Name" := ConflictResult."Company Name";
        ConflictLine."Conflict Code" := ConflictResult."Conflict Code";
        ConflictLine."Conflict Name" := CopyStr(ConflictResult."Conflict Name", 1, MaxStrLen(ConflictLine."Conflict Name"));
        ConflictLine."Group No." := ConflictGroup."Group No.";
        ConflictLine."Group Name" := ConflictGroup."Group Name";
        ConflictLine."Evaluation Logic" := CopyStr(Format(ConflictGroup."Evaluation Logic"), 1, MaxStrLen(ConflictLine."Evaluation Logic"));
        ConflictLine."Rule ID" := GroupRule."Rule ID";
        ConflictLine."Rule Name" := GroupRule."Rule Name";
        ConflictLine."Object ID" := GroupRule."Object ID";
        ConflictLine."Object Name" := CopyStr(GetTableDataDisplayName(GroupRule."Object ID", EffectivePerm."Object Name"), 1, MaxStrLen(ConflictLine."Object Name"));
        ConflictLine."Required Permission" := CopyStr(GetRulePermissionSummary(GroupRule), 1, MaxStrLen(ConflictLine."Required Permission"));
        ConflictLine."Matched Permission" := 'Unresolved';
        ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::Unknown;
        ConflictLine."Permission Source Summary" := 'Effective permission exists, but source attribution is incomplete.';
        ConflictLine."Source Notes" := 'One or more matched operations have no resolved captured permission source. No contributor is inferred.';
        ConflictLine."Trace Notes" := 'Effective permission exists, but source attribution is incomplete.';
        ConflictLine.Insert(true);
    end;

    local procedure InsertConflictResultLineWithSuperSource(ConflictResult: Record "BCG User Conflict Result"; ConflictGroup: Record "BCG Conflict Group"; GroupRule: Record "BCG Conflict Group Rule"; SuperAssignment: Record "BCG User Perm. Assignment")
    var
        ConflictLine: Record "BCG User Conflict Result Line";
        SourceMgt: Codeunit "BCG Conflict Source Mgt";
    begin
        MergeApplicableAssignmentSources(SuperAssignment, ConflictResult."Company Name");
        ConflictLine.Init();
        ConflictLine."Conflict Result Entry No." := ConflictResult."Entry No.";
        ConflictLine."Run ID" := ConflictResult."Run ID";
        ConflictLine."User Security ID" := ConflictResult."User Security ID";
        ConflictLine."Company Name" := ConflictResult."Company Name";
        ConflictLine."Conflict Code" := ConflictResult."Conflict Code";
        ConflictLine."Conflict Name" := CopyStr(ConflictResult."Conflict Name", 1, MaxStrLen(ConflictLine."Conflict Name"));
        ConflictLine."Group No." := ConflictGroup."Group No.";
        ConflictLine."Group Name" := ConflictGroup."Group Name";
        ConflictLine."Evaluation Logic" := CopyStr(Format(ConflictGroup."Evaluation Logic"), 1, MaxStrLen(ConflictLine."Evaluation Logic"));
        ConflictLine."Rule ID" := GroupRule."Rule ID";
        ConflictLine."Rule Name" := GroupRule."Rule Name";
        ConflictLine."Object ID" := GroupRule."Object ID";
        ConflictLine."Object Name" := CopyStr(GetTableDataDisplayName(GroupRule."Object ID", GroupRule."Object Caption"), 1, MaxStrLen(ConflictLine."Object Name"));
        ConflictLine."Required Permission" := CopyStr(GetRulePermissionSummary(GroupRule), 1, MaxStrLen(ConflictLine."Required Permission"));
        ConflictLine."Matched Permission" := 'SUPER Override';
        ConflictLine."Role ID" := SuperAssignment."Role ID";
        ConflictLine."Role Name" := SuperAssignment."Role Name";
        ConflictLine."App ID" := SuperAssignment."App ID";
        ConflictLine."App Name" := SuperAssignment."App Name";
        ConflictLine."Scope Text" := SuperAssignment."Scope Text";
        ConflictLine."Assignment Source Type" := SuperAssignment."Assignment Source Type";
        ConflictLine."Security Filter" := '';
        ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::"Special Permission";
        ConflictLine."Is Special Permission Source" := true;
        ConflictLine."Source Company Name" := SuperAssignment."Company Name";
        ConflictLine."Permission Source Summary" := CopyStr(StrSubstNo('Special Permission: %1', SuperAssignment."Role ID"), 1, MaxStrLen(ConflictLine."Permission Source Summary"));
        ConflictLine."Source Notes" := CopyStr(StrSubstNo('Rule matched because user has special permission set %1.', SuperAssignment."Role ID"), 1, MaxStrLen(ConflictLine."Source Notes"));
        ConflictLine."Trace Notes" := CopyStr(StrSubstNo('Rule matched because user has special permission set %1.', SuperAssignment."Role ID"), 1, MaxStrLen(ConflictLine."Trace Notes"));
        SourceMgt.ApplySourceToConflictLine(ConflictLine, ConflictResult."Run ID", ConflictResult."User Security ID",
            ConflictResult."Company Name", SuperAssignment."Role ID", CopyStr(SuperAssignment."Role Name", 1, 80),
            SuperAssignment."App ID", SuperAssignment."Assignment Source Type", SuperAssignment."Assignment Source Code");
        ConflictLine."Source Company Name" := SuperAssignment."Company Name";
        SetSpecialEvidenceAttributes(ConflictLine);
        SaveEvidenceIdentity(ConflictLine);
    end;

    local procedure InsertApplicableSpecialSources(ConflictResult: Record "BCG User Conflict Result"; ConflictGroup: Record "BCG Conflict Group"; GroupRule: Record "BCG Conflict Group Rule")
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        Assignment.SetRange("Run ID", ConflictResult."Run ID");
        Assignment.SetRange("User Security ID", ConflictResult."User Security ID");
        Assignment.SetFilter("Company Name", '%1|%2', ConflictResult."Company Name", '');
        if Assignment.FindSet() then
            repeat
                if IsSuperAssignment(Assignment) then
                    InsertConflictResultLineWithSuperSource(ConflictResult, ConflictGroup, GroupRule, Assignment);
            until Assignment.Next() = 0;
    end;

    local procedure SetSpecialEvidenceAttributes(var ConflictLine: Record "BCG User Conflict Result Line")
    begin
        ConflictLine."Permission Source Type" := ConflictLine."Permission Source Type"::"Special Permission";
        ConflictLine."Is Special Permission Source" := true;
        ConflictLine."Permission Source Summary" := CopyStr(
            StrSubstNo('Special Permission: %1 (%2)', ConflictLine."Role ID", ConflictLine."Assignment Source Type"),
            1, MaxStrLen(ConflictLine."Permission Source Summary"));
        ConflictLine."Source Notes" := CopyStr(
            StrSubstNo('Wildcard: %1 grants all Table Data permissions. Assignment route: %2. Group: %3.',
                ConflictLine."Role ID", ConflictLine."Assignment Source Type", ConflictLine."Security Group Code"),
            1, MaxStrLen(ConflictLine."Source Notes"));
    end;

    local procedure SaveEvidenceIdentity(var ConflictLine: Record "BCG User Conflict Result Line")
    var
        ExistingLine: Record "BCG User Conflict Result Line";
    begin
        ExistingLine.SetRange("Conflict Result Entry No.", ConflictLine."Conflict Result Entry No.");
        ExistingLine.SetRange("Group No.", ConflictLine."Group No.");
        ExistingLine.SetRange("Rule ID", ConflictLine."Rule ID");
        ExistingLine.SetRange("Object ID", ConflictLine."Object ID");
        ExistingLine.SetRange("Role ID", ConflictLine."Role ID");
        ExistingLine.SetRange("App ID", ConflictLine."App ID");
        ExistingLine.SetRange("Scope Text", ConflictLine."Scope Text");
        if ExistingLine.FindFirst() then begin
            // Both paths merge captured assignment routes before reaching this identity upsert.
            ConflictLine."Entry No." := ExistingLine."Entry No.";
            if not ConflictLine."Is Special Permission Source" and not ExistingLine."Is Special Permission Source" then begin
                ConflictLine."Matched Permission" := MergeMatchedOperations(
                    ExistingLine."Matched Permission", ConflictLine."Matched Permission");
                if ExistingLine."Trace Notes" <> ConflictLine."Trace Notes" then
                    ConflictLine."Trace Notes" := 'Captured exact-table and wildcard grants contribute to this rule. Matched Permission is their operation union; inspect captured permissions for individual security filters.';
                if ExistingLine."Security Filter" <> ConflictLine."Security Filter" then begin
                    ConflictLine."Security Filter" := '';
                    ConflictLine."Source Notes" := 'Multiple contributing source rows have different security filters. Inspect captured permissions; an empty filter here does not mean unrestricted access.';
                end;
            end;
            ConflictLine."Is Special Permission Source" :=
                ConflictLine."Is Special Permission Source" or ExistingLine."Is Special Permission Source";
            if ConflictLine."Is Special Permission Source" then
                SetSpecialEvidenceAttributes(ConflictLine);
            ConflictLine.Modify(true);
        end else
            ConflictLine.Insert(true);
    end;

    local procedure MergeMatchedOperations(FirstOperations: Text; SecondOperations: Text): Text[30]
    var
        Operations: List of [Text];
        Operation: Text;
        ResultText: Text[100];
    begin
        if FirstOperations <> '' then
            Operations := FirstOperations.Split('/');
        foreach Operation in SecondOperations.Split('/') do
            if not Operations.Contains(Operation) then
                Operations.Add(Operation);
        foreach Operation in Operations do
            AppendPermissionText(ResultText, CopyStr(Operation, 1, 30));
        exit(CopyStr(ResultText, 1, 30));
    end;

    local procedure MissingAllContributors(GroupRule: Record "BCG Conflict Group Rule"; MatchedOperations: Text): Boolean
    var
        Operations: List of [Text];
    begin
        if not RuleUsesPermissionFlags(GroupRule) or (GroupRule."Permission Match Mode" <> GroupRule."Permission Match Mode"::All) then
            exit(false);
        Operations := MatchedOperations.Split('/');
        exit((OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Read) and not Operations.Contains('Read')) or
            (OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Insert) and not Operations.Contains('Insert')) or
            (OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Modify) and not Operations.Contains('Modify')) or
            (OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Delete) and not Operations.Contains('Delete')));
    end;

    local procedure ObjectPermissionContributesToRule(ObjectPerm: Record "BCG Perm. Set Object Perm."; GroupRule: Record "BCG Conflict Group Rule"): Boolean
    begin
        if not RuleUsesPermissionFlags(GroupRule) then
            exit(ObjectPermissionSatisfiesLegacyRule(ObjectPerm, AccessTypeToken(GroupRule."Required Permission")));

        // Detection already satisfied the complete rule. Evidence records each contributing operation.
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Read) and ObjectPermissionSatisfiesOperation(ObjectPerm, Enum::"BCG Access Type"::Read, GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Read)) then
            exit(true);
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Insert) and ObjectPermissionSatisfiesOperation(ObjectPerm, Enum::"BCG Access Type"::Insert, GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Insert)) then
            exit(true);
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Modify) and ObjectPermissionSatisfiesOperation(ObjectPerm, Enum::"BCG Access Type"::Modify, GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Modify)) then
            exit(true);
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Delete) and ObjectPermissionSatisfiesOperation(ObjectPerm, Enum::"BCG Access Type"::Delete, GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Delete)) then
            exit(true);

        exit(false);
    end;

    local procedure ObjectPermissionSatisfiesOperation(ObjectPerm: Record "BCG Perm. Set Object Perm."; AccessType: Enum "BCG Access Type"; PermissionMatch: Enum "BCG Table Data Perm Match"): Boolean
    begin
        case AccessType of
            AccessType::Read:
                exit(PermissionTextSatisfiesMode(ObjectPerm."Read Permission", PermissionMatch));
            AccessType::Insert:
                exit(PermissionTextSatisfiesMode(ObjectPerm."Insert Permission", PermissionMatch));
            AccessType::Modify:
                exit(PermissionTextSatisfiesMode(ObjectPerm."Modify Permission", PermissionMatch));
            AccessType::Delete:
                exit(PermissionTextSatisfiesMode(ObjectPerm."Delete Permission", PermissionMatch));
        end;

        exit(false);
    end;

    local procedure PermissionTextSatisfiesMode(PermissionText: Text; PermissionMatch: Enum "BCG Table Data Perm Match"): Boolean
    begin
        case PermissionMatch of
            PermissionMatch::"Direct Only":
                exit(IsDirectPermissionGranted(PermissionText));
            PermissionMatch::"Direct or Indirect":
                exit(IsPermissionGranted(PermissionText));
        end;

        exit(false);
    end;

    local procedure IsDirectPermissionGranted(PermissionText: Text): Boolean
    var
        PermissionUpper: Text;
    begin
        PermissionUpper := UpperCase(DelChr(PermissionText, '=', ' '));
        exit((PermissionUpper = 'YES') or (PermissionUpper = 'DIRECT'));
    end;

    local procedure ObjectPermissionSatisfiesLegacyRule(ObjectPerm: Record "BCG Perm. Set Object Perm."; RequiredPermissionText: Text): Boolean
    var
        RequiredPermissionUpper: Text;
    begin
        RequiredPermissionUpper := UpperCase(RequiredPermissionText);

        if StrPos(RequiredPermissionUpper, 'READ') > 0 then
            exit(IsPermissionGranted(ObjectPerm."Read Permission"));

        if StrPos(RequiredPermissionUpper, 'INSERT') > 0 then
            exit(IsPermissionGranted(ObjectPerm."Insert Permission"));

        if StrPos(RequiredPermissionUpper, 'MODIFY') > 0 then
            exit(IsPermissionGranted(ObjectPerm."Modify Permission"));

        if StrPos(RequiredPermissionUpper, 'DELETE') > 0 then
            exit(IsPermissionGranted(ObjectPerm."Delete Permission"));

        exit(false);
    end;

    local procedure GetMatchedPermissionText(ObjectPerm: Record "BCG Perm. Set Object Perm."; GroupRule: Record "BCG Conflict Group Rule"): Text[30]
    var
        ResultText: Text[100];
        RequiredPermissionUpper: Text;
    begin
        if not RuleUsesPermissionFlags(GroupRule) then begin
            RequiredPermissionUpper := UpperCase(AccessTypeToken(GroupRule."Required Permission"));

            if (StrPos(RequiredPermissionUpper, 'READ') > 0) and IsPermissionGranted(ObjectPerm."Read Permission") then
                exit('Read');
            if (StrPos(RequiredPermissionUpper, 'INSERT') > 0) and IsPermissionGranted(ObjectPerm."Insert Permission") then
                exit('Insert');
            if (StrPos(RequiredPermissionUpper, 'MODIFY') > 0) and IsPermissionGranted(ObjectPerm."Modify Permission") then
                exit('Modify');
            if (StrPos(RequiredPermissionUpper, 'DELETE') > 0) and IsPermissionGranted(ObjectPerm."Delete Permission") then
                exit('Delete');

            exit(CopyStr(AccessTypeToken(GroupRule."Required Permission"), 1, 30));
        end;

        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Read) and ObjectPermissionSatisfiesOperation(ObjectPerm, Enum::"BCG Access Type"::Read, GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Read)) then
            AppendPermissionText(ResultText, 'Read');
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Insert) and ObjectPermissionSatisfiesOperation(ObjectPerm, Enum::"BCG Access Type"::Insert, GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Insert)) then
            AppendPermissionText(ResultText, 'Insert');
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Modify) and ObjectPermissionSatisfiesOperation(ObjectPerm, Enum::"BCG Access Type"::Modify, GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Modify)) then
            AppendPermissionText(ResultText, 'Modify');
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Delete) and ObjectPermissionSatisfiesOperation(ObjectPerm, Enum::"BCG Access Type"::Delete, GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Delete)) then
            AppendPermissionText(ResultText, 'Delete');

        if ResultText = '' then
            ResultText := GetRulePermissionSummary(GroupRule);

        exit(CopyStr(ResultText, 1, 30));
    end;

    local procedure GetRulePermissionSummary(GroupRule: Record "BCG Conflict Group Rule"): Text[50]
    var
        ResultText: Text[100];
    begin
        if not RuleUsesPermissionFlags(GroupRule) then
            exit(CopyStr(AccessTypeToken(GroupRule."Required Permission"), 1, 50));

        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Read) then
            AppendPermissionText(ResultText, GetOperationPermissionText('Read', GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Read)));
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Insert) then
            AppendPermissionText(ResultText, GetOperationPermissionText('Insert', GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Insert)));
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Modify) then
            AppendPermissionText(ResultText, GetOperationPermissionText('Modify', GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Modify)));
        if OperationIsRequired(GroupRule, Enum::"BCG Access Type"::Delete) then
            AppendPermissionText(ResultText, GetOperationPermissionText('Delete', GetRulePermissionMode(GroupRule, Enum::"BCG Access Type"::Delete)));

        if ResultText = '' then
            ResultText := CopyStr(AccessTypeToken(GroupRule."Required Permission"), 1, 100);

        if RuleUsesPermissionFlags(GroupRule) then
            ResultText := CopyStr(ResultText + ' (' + Format(GroupRule."Permission Match Mode") + ')', 1, 100);

        exit(CopyStr(ResultText, 1, 50));
    end;

    local procedure AppendPermissionText(var ResultText: Text[100]; PermissionText: Text[30])
    begin
        if ResultText = '' then
            ResultText := PermissionText
        else
            ResultText := CopyStr(ResultText + '/' + PermissionText, 1, MaxStrLen(ResultText));
    end;

    local procedure GetOperationPermissionText(PermissionName: Text[20]; PermissionMatch: Enum "BCG Table Data Perm Match"): Text[30]
    begin
        exit(CopyStr(StrSubstNo('%1: %2', PermissionName, Format(PermissionMatch)), 1, 30));
    end;

    local procedure GetFirstTwoMatchedRuleDetails(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; ConflictId: Code[20]; var ObjectAId: Integer; var ObjectAName: Text[249]; var ObjectAPermission: Text[30]; var ObjectBId: Integer; var ObjectBName: Text[249]; var ObjectBPermission: Text[30])
    var
        ConflictGroup: Record "BCG Conflict Group";
        EffectivePerm: Record "BCG User Table Data Perm.";
        MatchedPermissionText: Text[30];
        MatchNo: Integer;
    begin
        ConflictGroup.SetRange("Conflict ID", ConflictId);
        ConflictGroup.SetRange("Is Active", true);
        ConflictGroup.SetCurrentKey("Conflict ID", Sequence);

        if ConflictGroup.FindSet() then
            repeat
                if TryFindMatchedRuleForGroup(RunId, UserSecurityId, CompanyName, ConflictGroup, EffectivePerm, MatchedPermissionText) then begin
                    MatchNo += 1;
                    if MatchNo = 1 then begin
                        ObjectAId := EffectivePerm."Object ID";
                        ObjectAName := EffectivePerm."Object Name";
                        ObjectAPermission := MatchedPermissionText;
                    end else begin
                        ObjectBId := EffectivePerm."Object ID";
                        ObjectBName := EffectivePerm."Object Name";
                        ObjectBPermission := MatchedPermissionText;
                        exit;
                    end;
                end;
            until ConflictGroup.Next() = 0;
    end;

    local procedure TryFindMatchedRuleForGroup(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; ConflictGroup: Record "BCG Conflict Group"; var EffectivePerm: Record "BCG User Table Data Perm."; var MatchedPermissionText: Text[30]): Boolean
    var
        GroupRule: Record "BCG Conflict Group Rule";
        SuperAssignment: Record "BCG User Perm. Assignment";
    begin
        GroupRule.SetRange("Conflict ID", ConflictGroup."Conflict ID");
        GroupRule.SetRange("Group No.", ConflictGroup."Group No.");

        if GroupRule.FindSet() then
            repeat
                // SUPER / SUPER (DATA) has priority in the summary shown on the conflict result.
                if UserHasSuperOrSuperData(RunId, UserSecurityId, CompanyName, SuperAssignment) then begin
                    EffectivePerm.Init();
                    EffectivePerm."Run ID" := RunId;
                    EffectivePerm."User Security ID" := UserSecurityId;
                    EffectivePerm."Company Name" := CompanyName;
                    EffectivePerm."Object ID" := GroupRule."Object ID";
                    EffectivePerm."Object Name" := CopyStr(GetTableDataDisplayName(GroupRule."Object ID", GroupRule."Object Caption"), 1, MaxStrLen(EffectivePerm."Object Name"));
                    MatchedPermissionText := 'SUPER Override';
                    exit(true);
                end;

                if FindEffectivePermissionForRule(RunId, UserSecurityId, CompanyName, GroupRule, EffectivePerm) then begin
                    MatchedPermissionText := CopyStr(GetRulePermissionSummary(GroupRule), 1, MaxStrLen(MatchedPermissionText));
                    exit(true);
                end;
            until GroupRule.Next() = 0;

        exit(false);
    end;

    local procedure UserHasSuperOrSuperData(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; var SuperAssignment: Record "BCG User Perm. Assignment"): Boolean
    var
        Assignment: Record "BCG User Perm. Assignment";
    begin
        // Only target-company and global SUPER assignments apply.

        // 1. Company-specific assignment.
        Assignment.Reset();
        Assignment.SetRange("Run ID", RunId);
        Assignment.SetRange("User Security ID", UserSecurityId);
        Assignment.SetRange("Company Name", CompanyName);
        if Assignment.FindSet() then
            repeat
                if IsSuperAssignment(Assignment) then begin
                    SuperAssignment := Assignment;
                    exit(true);
                end;
            until Assignment.Next() = 0;

        // 2. Global assignment, represented in Access Control by blank Company Name.
        Assignment.Reset();
        Assignment.SetRange("Run ID", RunId);
        Assignment.SetRange("User Security ID", UserSecurityId);
        Assignment.SetRange("Company Name", '');
        if Assignment.FindSet() then
            repeat
                if IsSuperAssignment(Assignment) then begin
                    SuperAssignment := Assignment;
                    exit(true);
                end;
            until Assignment.Next() = 0;

        exit(false);
    end;

    local procedure IsSuperAssignment(Assignment: Record "BCG User Perm. Assignment"): Boolean
    var
        SpecialPermissionMgt: Codeunit "BCG Special Permission Mgt.";
    begin
        exit(SpecialPermissionMgt.IsPlatformSpecialPermission(Assignment."Role ID", Assignment."App ID", Assignment."Scope Text"));
    end;



    local procedure GetTableDataDisplayName(ObjectId: Integer; PreferredName: Text): Text[100]
    var
        AllObj: Record AllObjWithCaption;
        Candidate: Text[100];
    begin
        Candidate := CopyStr(PreferredName, 1, 100);
        if IsUsableTableName(Candidate) then
            exit(Candidate);

        if ObjectId <> 0 then
            if AllObj.Get(AllObj."Object Type"::TableData, ObjectId) then begin
                Candidate := CopyStr(AllObj."Object Caption", 1, 100);
                if IsUsableTableName(Candidate) then
                    exit(Candidate);

                Candidate := CopyStr(AllObj."Object Name", 1, 100);
                if IsUsableTableName(Candidate) then
                    exit(Candidate);
            end;

        if ObjectId <> 0 then
            exit(Format(ObjectId));

        exit('');
    end;

    local procedure IsUsableTableName(Value: Text): Boolean
    var
        IntValue: Integer;
    begin
        Value := DelChr(Value, '<>', ' ');

        if Value = '' then
            exit(false);

        if Evaluate(IntValue, Value) then
            exit(false);

        exit(true);
    end;

    local procedure SetConflictResultSeverity(var ConflictResult: Record "BCG User Conflict Result"; Severity: Enum "BCG Severity")
    begin
        case Severity of
            Severity::Critical: ConflictResult.Severity := ConflictResult.Severity::Critical;
            Severity::High: ConflictResult.Severity := ConflictResult.Severity::High;
            Severity::Medium: ConflictResult.Severity := ConflictResult.Severity::Medium;
            Severity::Low: ConflictResult.Severity := ConflictResult.Severity::Low;
            else
                Error(UnsupportedSnapshotValueErr, Severity.AsInteger());
        end;
    end;

    local procedure ConflictAlreadyExists(RunId: Guid; UserSecurityId: Guid; CompanyName: Text[30]; ConflictCode: Code[50]): Boolean
    var
        ConflictResult: Record "BCG User Conflict Result";
    begin
        ConflictResult.SetRange("Run ID", RunId);
        ConflictResult.SetRange("User Security ID", UserSecurityId);
        ConflictResult.SetRange("Company Name", CompanyName);
        ConflictResult.SetRange("Conflict Code", ConflictCode);
        exit(not ConflictResult.IsEmpty());
    end;

    local procedure UpdateRunCounters(RunId: Guid)
    var
        AuditRun: Record "BCG Audit Run";
        UserSnapshot: Record "BCG User Snapshot";
        Assignment: Record "BCG User Perm. Assignment";
        ObjectPerm: Record "BCG Perm. Set Object Perm.";
        EffectivePerm: Record "BCG User Table Data Perm.";
    begin
        AuditRun.Get(RunId);

        UserSnapshot.SetRange("Run ID", RunId);
        AuditRun."User Count" := UserSnapshot.Count();

        Assignment.SetRange("Run ID", RunId);
        AuditRun."Assignment Count" := Assignment.Count();

        ObjectPerm.SetRange("Run ID", RunId);
        AuditRun."Object Permission Count" := ObjectPerm.Count();

        EffectivePerm.SetRange("Run ID", RunId);
        AuditRun."Effective Permission Count" := EffectivePerm.Count();

        AuditRun.Modify(true);
    end;
#if BCG_PERF_TESTS
    var
        PerfDataset: Record "BCG Perf Dataset";
        PerfRunner: Codeunit "BCG Perf Runner";
        PerfStageStarted: DateTime;

    internal procedure PerfFull(var Dataset: Record "BCG Perf Dataset")
    begin
        BCGAccessMgt.RequireRunningRun(Dataset."Run ID", Codeunit::"BCG Snapshot Mgt.");
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Perf Runner");
        PerfRunner.EnsureOwned(Dataset);
        PerfDataset := Dataset;
        ExecuteFullSnapshot(Dataset."Run ID");
        Dataset := PerfDataset;
        Clear(PerfDataset);
    end;

    internal procedure PerfSelect(Dataset: Record "BCG Perf Dataset")
    begin
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Snapshot Mgt.");
        BCGAccessMgt.RequireCodeunit(Codeunit::"BCG Perf Runner");
        PerfRunner.EnsureOwned(Dataset);
        PerfDataset := Dataset;
    end;

    local procedure PerfStartStage()
    begin
        PerfStageStarted := CurrentDateTime();
    end;

    local procedure PerfEndStage(FieldNumber: Integer)
    var
        DatasetRef: RecordRef;
        StageField: FieldRef;
        Elapsed: Duration;
    begin
        if IsNullGuid(PerfDataset."Run ID") then
            exit;
        Elapsed := CurrentDateTime() - PerfStageStarted;
        DatasetRef.GetTable(PerfDataset);
        StageField := DatasetRef.Field(FieldNumber);
        StageField.Value := Elapsed;
        DatasetRef.SetTable(PerfDataset);
        PerfStartStage();
    end;
#endif

#if BCG_SOURCE_COUNT_TESTS
    [IntegrationEvent(false, false)]
    local procedure OnTestCaptureFullSnapshot(RunId: Guid; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestFullSnapshotStage(RunId: Guid; Stage: Integer)
    begin
    end;
#endif
}
