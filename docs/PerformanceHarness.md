# Sandbox performance harness — 1.0.0.0

The developer harness enters `BCG Snapshot Mgt.` at the user/assignment collection boundary. It inserts only BCAA snapshots and supplies a **temporary Expanded Permission** record to the existing permission loader. The same full-pipeline procedure then builds effective permissions, calculates conflicts and evidence, rebuilds source trace, updates summaries/context, propagates run numbers and updates counters. It does not write User, Access Control, permission-set definitions, Company, or security-group membership.

Synthetic user and assignment collection replaces live collection. Live security-group collection is skipped. Consequently these timings measure the downstream analysis architecture, **not tenant security-table enumeration, Entra latency, or permission-set expansion by the platform**. Permission-load time includes constructing the temporary fixture plus the real loader. The full wrapper uses a dataset-owned audit header and atomic error propagation instead of the normal UI's commit/error wrapper.

## Build and run

From the repository in PowerShell:

```powershell
.\tests\Build-Performance.ps1 -Mode Normal
.\tests\Build-Performance.ps1 -Mode Tests
```

The helper discovers the installed AL compiler and builds in fresh **external** `%TEMP%\BCAA-Performance` directories. Optional `-Compiler` and `-Dotnet` arguments select other installations. Runtime discovery checks the previous `.build/dotnet10` location, then `%TEMP%\BCAA-Performance\dotnet10`, then `dotnet` on PATH. It checks diagnostic errors as well as exit status. Output packages are `.build/BCAA-performance-Normal.app` and `.build/BCAA-performance-Tests.app`; JSON diagnostics are also retained in `.build`. Temporary projects are deleted in `finally` unless a successful build used `-KeepProject`. It leaves the repository manifest, launch configuration and translations unchanged.

### Normal and test development

Follow the [README](../README.md) for prerequisites, local launch configuration and symbol download. The normal build helper removes test symbols in its staged manifest. The root manifest enables all three test symbols, so main-workspace F5 publishes a test-enabled development build.

The unguarded performance dataset table 50960 and root rule-owner table extension remain in normal builds for schema compatibility. Executable tests, the performance page/runner and synthetic hooks are gated.

To retain a performance project:

```powershell
./tests/Build-Performance.ps1 -Mode Tests -KeepProject
```

This option needs a local `.vscode/launch.json` containing exactly one AL Sandbox configuration. Copy the sanitized example only when no local file exists, then configure your own target. Use the separate VS Code window command printed by the script. Check the target before F5: it publishes the test-enabled application with the same identity/version as Normal, not an independent app. See [compatibility guidance](Compatibility.md) for package-registration constraints.

The launch opens page **50960**, BCG Perf Datasets. Use developer privileges; operational VIEW/ADMIN roles do not grant harness execution. The page and generator/run/cleanup entry points require a recognized sandbox. Regenerate disposable projects after source changes rather than editing copied AL files.

Clean owned datasets after testing, then restore an explicitly built Normal package if appropriate. Do not use main-workspace F5 as a way to disable test objects. Preserve historical packages and evidence in private backups.

Git ignores do not exclude AL source from compilation. The helper refuses AL copies under `.build` and stages source outside the repository. Keep generated projects out of the original workspace.

### Synthetic dataset lifecycle

The following operations affect only harness-owned fixtures. They are not supported actions for ordinary completed analysis runs.

1. **Generate SMALL**, then select the new row and **Run Full Test**. Check `Full Passed` and the expected/actual row counts.
2. **Run Conflict-only Test**. This disables only the first control owned by that dataset, tests the core conflict calculation, then tests the retained shared calculation sequence on its owned Running fixture. Check `Recalc Passed`.
3. Repeat **Run Full Test** to restore the first control and prove repeatability; then rerun conflict-only.
4. **Cleanup Selected Dataset**, twice. Cleanup is idempotent and retains the metrics row with state `Cleaned`. A cleaned dataset must be regenerated for further tests.
5. **Run All and Cleanup** runs SMALL, MEDIUM and LARGE, validates each and retains their metrics. Each successful scenario is committed after cleanup. If a later scenario fails, its transaction rolls back and earlier results remain.
6. Run All three times on an otherwise idle Sandbox; export/copy the list to retain results. Compare MEDIUM medians and the individual stages; keep the first/cold run separately. Avoid concurrent full analyses while collecting comparable timings.

The retained table and rule-ownership extension exist in normal builds too, so disabling the test compilation symbols does not remove data-bearing schema. The page, runner, tests and pipeline hooks are compiled only with `BCG_PERF_TESTS`. Clean active datasets before returning to a normal build. Generated snapshots are identifiable in existing audit pages until cleaned; the ordinary conflict engine always excludes synthetic rule ownership, even in a normal build.

## Scenarios and independent expectations

These are deterministic fixture volumes, **not observed Sandbox results**. The harness verifies actual database counts after analysis.

| Scenario | Users | Company contexts | Sets | Assignments | Source rows | Effective rows | Controls | Full conflicts | Origin lines | Recalculated conflicts |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| SMALL | 20 | 1 | 20 | 80 | 800 | 3,140 | 10 | 50 | 100 | 45 |
| MEDIUM | 100 | 1 | 50 | 700 | 4,000 | 55,400 | 18 | 450 | 900 | 425 |
| LARGE | 250 | 1 | 100 | 2,500 | 12,000 | 297,750 | 20 | 1,240 | 2,480 | 1,178 |

All fixtures analyze only the hosting company; no companies are created. Each user has one global common-read assignment and 3/6/9 assignments specific to the hosting company. The blank assignment company is retained as source provenance, but global permissions apply to the hosting company. There is no additional blank-company effective-permission bucket.

Every set grants a shared Customer (18) read and 39/79/119 distinct workload permissions. Source merging therefore has an exact oracle: shared-read source count equals assignments per user. Other object IDs are synthetic Table Data identifiers, with isolated maintenance/payment pairs and finance/purchasing/sales role labels. They do not claim to model specific standard BC business processes. Direct and indirect grants are included. Every twentieth user also receives a privileged CRUD maintenance set; SUPER wildcard and security-group workloads remain covered by existing regression tests, not this volume fixture.

Every fourth user receives both maintenance and payment permissions in one company and matches every active control. Other users remain clean. Each control has two required groups with one direct-permission rule per group. Disabling control 1 removes exactly `users div 4` findings. LARGE has 62 such users, not 62.5. Origins are actual `BCG User Conflict Result Line` rows; each finding has two source lines. `BCG Conflict Source Trace` has **zero expected rows** for these direct, non-SUPER fixtures: production only populates that table for security-group/special sources. Both counts are reported separately; zero is not presented as missing ordinary evidence.

Effective-row expectation per user is:

`rowsPerSet + (assignmentsPerUser - 1) * (rowsPerSet - 1)`

Multiply this per-user count by the number of users; no other-company adjustment applies. This is a fixture formula independent of the effective-permission implementation. The loader must retain all configured sets, and every set is assigned. Work is bounded at **400,000 estimated rows per dataset** and **six active datasets per company**; estimated totals including findings/evidence are 4,240 / 61,640 / 316,320. There are no inserts into system security tables or permission-granting objects.

## Metrics and correctness

The page shows millisecond values from DateTime differences (clock resolution may produce zero for short stages), with separate full, core conflict-only and shared-sequence durations. Validation and report counting are outside measured intervals. Full time includes header status updates; stage sums exclude that small wrapper overhead.

Stages follow the existing code: clear/snapshot; assignment collection; permission input/loading; effective aggregation plus special permissions; conflicts plus origin lines; trace/summaries/evidence/context; run-number propagation/counters. Harness full reruns also clear the owned synthetic run's previous snapshots/results; ordinary historical runs cannot use this workflow. There are no dialogs inside measured loops.

**Metric interpretation:** the legacy caption `Existing recalculation ms` measures a shared sequence of effective-permission rebuilding, conflict calculation and source-summary updates on a Running synthetic fixture. `Conflict engine only ms` measures CalculateConflicts alone. Neither is a supported historical-run UI action in release 1.0.0.0. The harness explicitly transitions its owned synthetic audit header into Running and back to Finished; it does not bypass the production guard or authorize maintenance on an ordinary completed run. The deterministic rule change is outside both measured intervals. These diagnostic timings must not be presented as end-to-end live Full Analysis timings.

Assertions cover user/assignment/source/effective cardinalities, per-user and total findings, exact origin-line counts, expected maintenance permission, absent payment permission for a clean user, shared-source counts, active dataset-owned control identity, and every evidence line's source/result run ownership. Cleanup verifies all eleven run-owned tables are empty for that exact Run ID. It never deletes a different run. Source/rule identities use `BCAA-PERF-`; rule headers additionally hold an exact dataset GUID. Cleanup never resets setup or the rule dictionary.

Test codeunit **50961 `BCG Perf Tests`** adds SMALL rerun, two-dataset isolation, ordinary-engine rule exclusion, idempotent cleanup, MEDIUM and LARGE tests. Run it using your existing AL Test Tool/test runner. Existing test codeunits 50972–50976 and 50613 are included through `BCG_SOURCE_COUNT_TESTS` and `BCG_AFFECTED_USER_TESTS`. Run existing suites too. Page actions provide the practical entry point if no Test Tool is installed. Errors fail the action and roll back its writes; previous successful metrics remain rather than being overwritten by a partial pass.

## Validation and limits

Use the codeunit-isolated test runner and suite instructions in [Validation.md](Validation.md). Record actual assertions, environment/build versions and timing results separately. Fixture sizes above are expected volumes, not measured throughput or a performance sign-off.

The harness replaces live user/assignment collection and skips live group collection. It cannot establish Entra latency, security-group completeness or production-scale performance. Tests cover reruns, isolation, idempotent cleanup and SMALL/MEDIUM/LARGE scenarios; operational non-SUPER authorization requires separate testing.

Conflict matching traverses configured controls, eligible users in the hosting company and captured permissions. Measure representative volumes before making scalability claims. Keep cold runs separate, compare repeated medians and avoid concurrent analyses during timing. This experimental Community Preview promises no particular runtime or supported data volume.
