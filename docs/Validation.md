# Sandbox validation — 1.0.0.0

These are developer acceptance checks, not a claim that a particular sandbox has passed. Use synthetic data in an isolated BC 28 sandbox. Follow the [README](../README.md) for builds and [compatibility guidance](Compatibility.md) before installation. Never change real user assignments or historical analysis data merely to prepare a fixture.

## Build and automated suites

Build Normal and Tests packages with `tests/Build-Performance.ps1`, then run `python tests/Check-PermissionModel.py`. These commands do not deploy. The static permission check cannot establish effective runtime authorization.

For automated AL execution, install the test-enabled package in your developer sandbox and use AL Test Tool runner **130450 — Test Runner - Isol. Codeunit**. The Full Analysis transaction tests deliberately commit fixtures and require outer codeunit isolation. Do not use an isolation-disabled runner. Runtime 15 does not support the RequiredTestIsolation property; select the correct runner explicitly.

Update the discovered methods before running these suites:

| Codeunit | Coverage | Test methods in this baseline |
| --- | --- | ---: |
| 50972 | Permission loading | 16 |
| 50973 | Scope and identity | 35 |
| 50974 | Source counts, evidence, identity boundaries and Wizard consistency | 83 |
| 50975 | Full Analysis transactions and withdrawn maintenance boundaries | 12 |
| 50976 | Current-company scope and user eligibility | 7 |
| 50613 | Affected-user navigation and Run ID isolation | 10 |
| 50961 | Synthetic performance lifecycle | 3 |

Suites 50972–50975 contain 146 tests. All seven suites listed above contain 166 test methods. These counts describe the source test inventory, not recorded execution results. Record actual runs separately with the package version, sandbox, runner and pass/fail totals. Run 50976, 50613 and 50961 separately as well. Acceptance of the exact release snapshot remains pending until its execution results are recorded. Performance scenarios can take longer. Test objects require separate developer privileges; operational VIEW/ADMIN roles do not grant them. Passing tests that disable test permission enforcement is not evidence that non-SUPER operational accounts have the right grants.

Codeunit 50974 includes boundary tests for maximum-length group names, exact source identities, explicit rejection of overlength identities, and preservation of captured evidence names. Wizard consistency tests cover both groups and all four operations, checkbox/selector synchronization including Not Required, Any/All matching, Review versus persisted rules, complete four-operation summaries, rejection of unselected groups, and existing rule identity/reuse behavior.

## Scope and run-identity regression checks

Run all seven tests in 50976 and all ten tests in 50613, including duplicate Run No. selection and Run ID isolation. In 50974, verify `TraceCanonicalSourceKeepsNameBoundaries`, `TraceKeepsMaximumSourceIdentity` and `TraceRejectsOverlengthSourceIdentity`, then rerun the full 50972–50975 regression set. Passing a subset does not establish that the full set passed.

## Full Analysis transactions

Codeunit 50975 tests failure after snapshot capture, finding/evidence creation, evidence summaries and finalization. For each handled failure, verify an Error header remains, all ten child datasets for that run are empty, and previously completed data and current-run selection are unchanged. The success case checks Finished status, counters, run numbering and child data after a later unrelated error.

The suite also rejects an unarmed worker and reuse of a historical run. This is not a test of a non-SUPER user's effective permissions. Abrupt session termination or a failure to write the Error header can still leave Running rows; the application does not repair them automatically.

## Historical-run protection

The five maintenance-boundary cases in 50975 cover Finished, Created, Error, missing and null run identities, compare complete stored headers and child datasets, reject retained-header detail clearing even on Running runs, and verify whole-run deletion leaves another completed run unchanged. The review-status case deliberately checks record-level editability; it does not claim table-level immutability or a user-facing review editor.

As an ADMIN user, verify retired maintenance actions are unavailable on administration, audit-run, table-permission and finding pages. Run a new Full Analysis and confirm Finished status, counters, evidence and navigation. A completed run must retain its stored analysis after later permission/rule changes and another Full Analysis. Do not invoke old repair actions as positive acceptance steps.

Shared calculation procedures require management authorization and an existing Running run. Bulk renumbering, composite special-permission repair and detail clearing with a retained header reject execution. The state check is not proof of active-worker ownership: authorized code can still operate on a stale Running run. Developer harness transitions apply only to its owned synthetic datasets.

## Non-SUPER acceptance and browsing

Use separate licensed test accounts with baseline login rights and either BCG AUDIT VIEW or BCG AUDIT ADMIN in the intended company. Check all direct and group-derived effective permissions; avoid SUPER or other broad grants that mask missing dependencies.

1. VIEW can browse the Role Center, definitions, completed findings and evidence. Capture stored counts, values and SystemModifiedAt before and after navigation; they must not change.
2. VIEW cannot create/edit definitions, run Full Analysis, invoke management APIs or delete run data. A direct attempt to open Run Full Analysis must not create a run.
3. ADMIN can manage definitions and finish a new Full Analysis with direct, group and special-permission fixtures without changing real security assignments.
4. Confirm neither role gains direct writes to generated audit/snapshot/result data or additional writes to standard security/business data through BCAA.
5. Check ADMIN in one company and VIEW in another, including composed/group assignments and a fresh session after revocation. Captured company names are not row-level security boundaries.
6. Cancel whole-run deletion and confirm no changes. Then delete only an intentionally disposable run and verify another completed run remains unchanged.

Additional checks: [detected-conflict browsing](DetectedConflictsStageATests.md), [source counts](EffectiveSourceCountChecks.md), [permission model](PermissionModel.md) and [performance harness](PerformanceHarness.md). Preserve sanitized test results and environment/build versions separately; do not publish real user/security snapshots.
