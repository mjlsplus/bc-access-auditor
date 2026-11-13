# BCAA user guide — 1.0.0.0

BCAA identifies potential conflicts between captured Table Data permissions and configured segregation-of-duties rules. A finding is a reason to investigate access; it is not evidence that a user performed a transaction or violated a policy.

## Supported workflow

1. An administrator reviews active conflict definitions, groups and rules. Use the New SoD Conflict Wizard or the definition pages to prepare the rules appropriate to the sandbox.
2. Open **Run Analysis** from the BC Access Auditor Role Center and run **Full Analysis**. Each analysis creates a new run for the current company, records Company Scope, and captures permission inputs before calculating findings and evidence. Global assignments apply to this company; assignments for other companies do not.
3. Confirm the run has **Finished** status, a Run No. and populated counters. A Running or Error run is not a completed analysis.
4. Open **Detected Conflicts**, select the completed run, and review its findings. Use **Detailed Findings**, **Conflict Review** and **Affected Users** to investigate the stored results.
5. Inspect evidence and source views for captured permission-set identities, direct/group attribution, special permissions and company context. Use the captured security-group and source-trace views when more detail is needed.
6. After changing rules or access assignments, run a **new Full Analysis**. Compare the new run with the earlier completed run; do not try to update the earlier analysis in place.

VIEW users can browse the Role Center, definitions and stored findings. ADMIN includes VIEW and permits setup changes, Full Analysis and authorized whole-run deletion. See the [permission model](PermissionModel.md) for grants and limitations.

## Historical results

Completed runs retain their stored analysis results when a new analysis is run or live permissions and rules change. Refreshing a review page refreshes its display; it does not recapture permissions or recalculate findings.

Historical in-place recalculation, repair, bulk renumbering and clearing details while retaining the run header are unavailable in release 1.0.0.0. These are not troubleshooting steps. Existing historical inconsistencies are not repaired automatically.

This is not a tamper-proof audit store: there is no general table-level immutability guarantee. Authorized code can still edit some stored information, and an administrator can delete a whole run. The normal review pages are read-only; a stored review-status field does not imply an available user-facing approval workflow. Preserve runs required for comparison and retention before using deletion.

## Reading the results

- Findings describe the rules and permission inputs captured for that run. They are not a live effective-access query.
- **Open Findings** counts finding records, not distinct conflict definitions. **High Severity** counts High findings across statuses; Critical is not included in that filter. Overlapping cues must not be added together.
- Direct, security-group and special-permission evidence can overlap. A mixed source does not represent an additional independent permission-set identity.
- New findings cover the hosting company. A blank source company identifies a global assignment applied to that company. Historical runs can retain older company contexts. Company fields do not provide row-level security; a reviewer can see the captured contexts stored in the BCAA storage company.

## Limits and troubleshooting

The model does not fully evaluate security-filter overlap, license entitlements or the executable business processes needed to exercise indirect permissions. A conflict can require further review before changing access. Direct, Security Group and special-permission paths consistently include enabled Full Users. This eligibility rule does not evaluate license entitlements. Group completeness and authorization depend on the target environment and should be checked in a sandbox.

If analysis fails, inspect the reported error and the run status. Normal handled failures are covered by rollback tests, but abrupt session termination or failure to persist the Error header can leave a Running run. Correct the cause and start a new Full Analysis; do not use retired repair actions or edit the run status to bypass checks.

Stored snapshots, evidence and exports can expose sensitive security information. Share only synthetic or sanitized examples. BCAA is an experimental Community Preview, with no production-readiness or guaranteed support claim.
