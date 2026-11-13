# Effective source-count checks — 1.0.0.0

These checks describe captured-data calculations and developer fixtures. The supported user workflow is a new Full Analysis; completed runs are not rebuilt or repaired in place.

## Counting model

The count is the number of distinct Role ID + App ID + Scope identities contributing Table Data access for a stored Run/User/target Company/Object. An assignment in the target company or the blank all-company scope qualifies; another named company's assignment does not.

Direct and security-group routes for the same identity count once. Named and blank-company assignments for the same identity also count once. Special wildcard grants and exact object entries are combined without counting one identity twice.

For ordinary entries, any qualifying direct or indirect Read/Insert/Modify/Delete grant can contribute. Empty/No permissions do not. An exact Table Data object grant or an Object ID 0 wildcard grant can qualify the identity; non-Table-Data entries do not.

A source count is broader than evidence for one rule: a read-only source may contribute to the object count without supporting a Modify rule. Do not infer the count from Modify evidence alone.

Blank-company grants retain their original blank assignment company for source attribution, but apply to the hosting company during analysis. New effective permissions and findings are created only for the current company; assignments for another named company are excluded. There is no additional blank-company effective-permission bucket. Evidence can combine direct/group attribution while retaining representative source-company information. Historical stored results are not rewritten by this scope rule.

## Automated developer coverage

Build Tests mode and run codeunit **50974**, together with 50972/50973 and transaction/boundary suite 50975 using the [validation guide](Validation.md). Running fixtures exercise shared procedures; this does not make those procedures supported maintenance for a completed run.

Coverage includes:

- SUPER with and without expanded wildcard entries; special plus ordinary sources.
- One identity through direct, group and mixed routes; distinct app/scope identities count separately.
- Empty grants, indirect grants, exact/wildcard overlap and non-Table-Data exclusion.
- Blank/named company applicability and prevention of cross-company SUPER leakage.
- Captured-source behavior despite later changes to synthetic live permissions.
- Restoration of fixture assignments from captured group rows within a Running fixture, while completed-run maintenance is rejected.
- Evidence identity, source summaries and definition regression assertions.

Fixtures use synthetic run/user/app IDs. Some scope tests write Access Control fixtures; run them only in the isolated developer sandbox with the prescribed test isolation. Never modify real user grants to make an automated test pass.

## Full Analysis integration checks

Use deliberately prepared sandbox identities and record their captured Role/App/Scope, assignment companies and exact/wildcard grants.

1. Run Full Analysis for a test identity whose only qualifying source is one SUPER identity. Inspect the new run's wildcard row and expected count of one.
2. Add a distinct qualifying source in the test setup and run a new analysis. Expect two where both identities contribute. The first run must retain its original count and evidence.
3. Give the same identity through direct and group routes, then run a new analysis. Expect one contributing identity with appropriate combined attribution.
4. Compare exact-object and Object ID 0 entries for the target table. Each qualifying identity counts once even if both representations grant access.
5. Check target-company and blank-company assignments. Another named company's grant must not qualify for this target. A read-only identity can count without supplying Modify evidence.
6. After changing controlled live group membership/permissions, run a new Full Analysis. Browse both completed runs and confirm the older captured values remain unchanged; refreshing its display must not regenerate data.
7. Verify Finished status, completion timestamp, counters, run number and evidence only after the pipeline completes. Use the transaction suite for injected failure coverage rather than trying to repair a failed run manually.

Compare stored values and identities, not assumed totals based on permission-set display names. Existing historical inconsistencies are not corrected automatically. Source counts are not a complete assessment of security filters, entitlements or executable business-process access.

Compilation and source inspection do not execute these integration checks. Record actual sandbox results and version information separately.
