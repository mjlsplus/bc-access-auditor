# BC Access Auditor (BCAA)

BCAA is an open-source Microsoft Dynamics 365 Business Central AL extension, released under the [MIT License](LICENSE), for permissions and segregation-of-duties (SoD) analysis. It captures permission inputs, evaluates configurable Table Data conflict rules and presents findings with direct, security-group and special-permission source evidence.

Version **1.0.0.0** supports a **Full Analysis → review stored findings → new Full Analysis when inputs change** workflow. Completed runs retain their historical analysis results. Historical in-place recalculation and repair are withdrawn.

Each new run records and analyzes the current (hosting) company only. Global assignments apply to that company; assignments for other companies are excluded. Direct, Security Group and special-permission paths use the same captured population of enabled Full Users.

Findings are TableData-focused risk indicators, not certified audit conclusions, actions users performed, a complete effective-access assessment or proof of a policy violation. This preview makes no production-readiness or security-certification claim. Maintenance, future compatibility, response times and support are not guaranteed.

## Sample configuration

The [nine sample/demo controls and import instructions](review-assets/README.md) provide a starting point for BCAA 1.0.0.0. They are risk indicators, not certified audit controls; adapt them to your own processes and permission model.

## Target and prerequisites

- **Business Central 28**, with application/platform symbols compatible with the manifest's 28.0.0.0 target and AL runtime **15.0**. Earlier/later major versions are not claimed compatible.
- Windows PowerShell, VS Code and the Microsoft AL Language extension.
- A .NET runtime compatible with the installed AL compiler. The build helper accepts explicit `-Compiler` and `-Dotnet` paths.
- An authorized isolated sandbox for installation and runtime validation.
- Python 3 for the static permission-model check; Microsoft AL Test Tool for automated sandbox tests.

## Configure and build

For a fresh checkout, copy `.vscode/launch.example.json` to `.vscode/launch.json` **only if a local launch file does not already exist**. Replace the sandbox placeholder with your own target. Keep exactly one AL Sandbox configuration for `-KeepProject`. Authenticate through the AL tooling and use **AL: Download Symbols** to populate `.alpackages/`.

Existing developers should preserve their local launch settings. Git ignores that file; never commit credentials or tenant-specific configuration.

From the repository root:

```powershell
./tests/Build-Performance.ps1 -Mode Normal -Analyze
./tests/Build-Performance.ps1 -Mode Tests -Analyze
python tests/Check-PermissionModel.py
```

These commands build and check packages without deploying. The helper stages source outside the repository and leaves the root manifest, translations and launch settings unchanged. With symbols already available, these builds do not need `launch.json`. Add `-KeepProject` to retain a separate development project; that option requires local launch settings.

Outputs are `.build/BCAA-performance-Normal.app` and `.build/BCAA-performance-Tests.app`. Normal mode removes test compilation symbols in the staged manifest. The root manifest enables tests, so direct workspace F5 is a development/test workflow, not the normal-package workflow. Do not place generated AL projects under the repository: Git ignores do not exclude AL source from compilation.

## Install and validate in a sandbox

1. Read [installation and schema compatibility](docs/Compatibility.md). Use a clean BC 28 sandbox with available object IDs 50500–50999. Preserve any existing installation and data.
2. Build the intended package. For ordinary evaluation, use the Normal output explicitly; historical root packages are not current release artifacts.
3. As an authorized deployment administrator, upload the package through the sandbox's extension-deployment tooling. Check package registration and the installed version first. Normal and Tests builds share identity/version and cannot be installed side by side. Do not use ForceSync or delete existing data to bypass compatibility failures.
4. Verify installed version 1.0.0.0, assign appropriate baseline login rights plus BCG AUDIT VIEW or BCG AUDIT ADMIN in the intended company, and follow the [user guide](docs/UserGuide.md).
5. Follow [sandbox validation](docs/Validation.md) for non-SUPER authorization, transactions, historical-run protection and regression suites. Compilation alone does not establish runtime correctness.

For developer performance testing, `-Mode Tests -KeepProject` prepares a separate project opening the performance page. Inspect its sandbox target before F5, which publishes. Never add the generated project to the original workspace. Restore a deliberately built Normal package after testing if needed; main-workspace F5 still enables tests.

## Known limitations

- BCAA primarily evaluates **TableData permissions**. Security-filter overlap, license entitlements and the ability to execute complete business processes are not fully evaluated. Findings are risk indicators and require human review.
- New analysis runs are scoped to the **current company**. Global permissions applicable to that company are included. Captured user and Security Group information may still contain tenant-wide identities or membership information, and historical runs may contain data from earlier scope behavior. The `Company Name` field is not a security boundary; protect snapshots and exports accordingly.
- BCAA retains analysis history, but it is **not a tamper-proof audit log**. Authorized users can delete complete runs and some stored information may remain editable.
- An interrupted or failed session may leave an analysis run in `Running` status. The application does not currently provide reliable active-worker ownership or automatic recovery for such runs.
- Upgrade or migration from earlier internal/development object-ID ranges is not provided. Installing a different package version should not be treated as a database migration or rollback mechanism.
- Security Group completeness, effective access in the target environment, extension compatibility and realistic performance must be validated in the target Business Central environment. Synthetic performance tests do not represent the complete live permission-collection process.

## Documentation

Runtime acceptance of this exact 1.0.0.0 release snapshot remains pending. Test inventory and results from earlier builds do not certify it. Follow the [release checklist](docs/ReleaseChecklist.md) and record the validation actually performed.

Contributions are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). Report suspected vulnerabilities through the private route described in [SECURITY.md](SECURITY.md), not public Issues.

| Audience | Guides |
| --- | --- |
| Users and operators | [User workflow](docs/UserGuide.md), [installation/compatibility](docs/Compatibility.md), [permission model](docs/PermissionModel.md) |
| Developers | [Validation](docs/Validation.md), [permission matrix](docs/PermissionMatrix.csv), [source counts](docs/EffectiveSourceCountChecks.md), [browsing checks](docs/DetectedConflictsStageATests.md), [performance harness](docs/PerformanceHarness.md) |

This repository includes source, tests, build scripts, translations and sample configuration. Local deployment settings, generated outputs and internal change records are excluded. Keep customer data and deployment credentials out of commits and issue attachments.

Copyright (c) 2026 MJLS Plus. The software is provided under the [MIT License](LICENSE), "AS IS" and without warranty. Open-source availability does not imply production readiness or guaranteed maintenance or support.
