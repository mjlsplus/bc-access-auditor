# BCAA permission model — 1.0.0.0

BCAA separates stored-result browsing from definition management and Full Analysis. This document describes the current source grants; it does not certify effective permissions in a particular tenant. Use the [sandbox validation guide](Validation.md) with non-SUPER accounts.

## Operational roles

[PermissionMatrix.csv](PermissionMatrix.csv) lists explicit grants by object type, ID and name. ADMIN includes VIEW. Uppercase R/I/M/D/X means direct access; lowercase means indirect access through an appropriately permissioned object; `-` means no grant from that role. These sets contain no wildcard grants or security filters.

| Data | VIEW 50998 | ADMIN 50999, including VIEW |
| --- | --- | --- |
| Definition/setup tables 50500–50503 and 50506 | R | RIMD |
| Audit/run-owned tables 50520–50524, 50580, 50582, 50584, 50592–50594 | R | Rimd |
| Cue table 50598 | R | RI retained in the permission set |
| Legacy tables 50504/50505, performance table 50960 | None | None |
| Persisted Wizard Buffer 50530 | None | None; the wizard uses temporary records |
| Temporary summary tables 50605/50610 | Table X only | Inherited Table X |

VIEW can execute the Role Center, cue page, definition-browsing pages and stored-result/evidence pages. The cue page uses a temporary source table; opening it does not initialize a persisted singleton. Definition writes and wizard/management actions require administrative authorization even where browsing uses the same page.

VIEW executes BCAA codeunits 50606 (presentation), 50611 (temporary affected-user summaries) and 50615 (authorization checks), none with elevated Permissions properties. It receives no management-codeunit Execute. ADMIN additionally executes the setup/wizard/administration/Full Analysis pages and management codeunits listed in the matrix.

Permission set 50997 `BCG SCHEMA COVERAGE` is internal and nonassignable. It grants R on retained tables 50504, 50505, 50530 and 50960 for schema coverage. Neither operational role includes it; do not compose it into user roles. Keep this schema as explained in [compatibility guidance](Compatibility.md).

## Standard Business Central dependencies

| Object | Explicit grant | Purpose |
| --- | --- | --- |
| User 2000000120 | R/X, both roles | User-name FlowFields; ADMIN also captures users |
| Access Control 2000000053 | R/X, ADMIN | Captured direct/group assignments |
| Expanded Permission 2000000254 | R/X, ADMIN; Table X for VIEW | Permission inputs; temporary effective-permission checks |
| Aggregate Permission Set 2000000167 | R/X, ADMIN | Permission-set names and app metadata |
| AllObjWithCaption 2000000058 | R/X, ADMIN | Object names and definition lookups |
| Security Group buffers 9021/9022 | Table X, ADMIN | Temporary group API buffers |
| Security Group codeunit 9031 | X, ADMIN | Group/member collection |
| User Permissions codeunit 152 | X, both roles | Current-user/company effective-permission checks |

BCAA does not grant writes to standard BC security tables or business transactions. Platform/group APIs have their own authorization requirements; verify those on the target BC 28 environment rather than adding broad security-management permissions to hide a missing dependency.

## Analysis scope

Each new run records the current (hosting) company in its Company Scope. Global (blank-company) assignments and assignments for the hosting company apply to that company; other-company assignments are excluded. Direct, Security Group, restored group and special/SUPER permission paths use the same captured population of enabled Full Users. Original assignment company and permission identities remain available for evidence. This is a TableData risk model, not a complete license-entitlement or executable-access evaluation.

## Authorization and calculation boundaries

Codeunit 50615 checks effective grants in the current company, including composed sets and group-derived permissions. Management requires audit-run Modify permission (direct or indirect) and direct Execute on the specific management codeunit. It does not authorize by role name or by elevated Record.WritePermission. UI visibility is not the authorization boundary: mutating APIs also check access.

Shared calculation procedures require an existing **Running** audit header under an update lock. Completed-run in-place recalculation/repair is withdrawn. Bulk renumbering, composite special-permission repair and clearing details while retaining a header reject execution. Users run a new Full Analysis after input changes. Authorized whole-run deletion remains available.

| Management codeunit | Elevated BCAA table operations |
| --- | --- |
| 50507 Run No. Mgt. | m on eleven run-owned tables |
| 50520 Snapshot Mgt. | 50520 im; 50521/50522/50523 id; 50524 imd; 50580 id; 50582 imd |
| 50532 Wizard Mgt | None; relies on direct setup rights |
| 50540 Special Permission Mgt. | 50524 im |
| 50563 Conflict Src Summary | 50580 m |
| 50568 Conflict Evidence Mgt | 50580 m |
| 50575 Run Cleanup Mgt. | d on eleven run-owned tables; 50520 m |
| 50578 User Access Context Mgt | 50524/50580 m |
| 50579 SecGrp Special Src Mgt | 50580/50582 m |
| 50586 Conflict Source Mgt | 50584 id |
| 50595 SecGrp Mgt | 50592 id; 50593 imd; 50594 id; 50522 im |

Retained management grants support the Full Analysis pipeline; they are not permission to use withdrawn historical maintenance. The Running-state check does not prove active-worker ownership, and authorized code can still operate on stale Running runs.

Test codeunits 50613, 50960, 50961, 50972–50976 and page 50960 receive no Execute from VIEW or ADMIN. Normal builds omit executable test objects/hooks while retaining data-bearing schema. Developer tests need separate privileges. Existing tests with TestPermissions Disabled do not prove operational authorization.

## Installation and verification

Follow [README build/install steps](../README.md) and [compatibility guidance](Compatibility.md). Check package identity/version registration, then install the Normal build into an isolated BC 28 sandbox for operational role testing. Do not test these roles with SUPER or broad security-administration grants.

Run `python tests/Check-PermissionModel.py` after building both modes. It checks compiled role boundaries, no wildcard/standard-data writes, no VIEW elevation, absence of operational test/legacy grants and retained-schema coverage. It does not contact Business Central or replace the [runtime acceptance checks](Validation.md).

Verify VIEW browsing and denied writes, ADMIN Full Analysis, company/composed/group assignments, and cancel/confirm whole-run deletion on disposable data. Compare stored values and SystemModifiedAt before/after read-only navigation. Retired maintenance must reject invocation, not refresh completed results.

## Limitations

- Permission sets are additive, not deny policies. Other roles can grant more access.
- New analysis results cover only the hosting company. Captured user identities and raw group membership can still be tenant-wide, and historical results can retain older company contexts. A Company Name value does not impose row-level security within the storage company. User-name lookups can require live tenant-wide User access.
- Group membership completeness, licensing/entitlements and platform API authorization need environment-specific validation.
- Stored analysis is retained by the supported workflow, not by an all-purpose immutability constraint. Whole-run deletion and authorized record-level changes remain possible.
- Normal packages retain legacy/performance schema. The manifest also enables source exposure, including test source; absence of executable test objects is not source secrecy.
- Analyzer success and synthetic tests do not establish production readiness, complete access accuracy or runtime authorization.
