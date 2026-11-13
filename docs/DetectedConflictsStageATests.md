# Detected Conflicts browsing checks — 1.0.0.0

Use these acceptance cases in an isolated BC 28 sandbox. Record actual results separately; this document is not a runtime-validation certificate.

Use synthetic prepared fixtures or completed Full Analysis runs. Completed runs retain their stored analysis; page refresh must not recalculate or repair them. Prepare special edge-case fixtures only through isolated developer tests, never by editing production results.

## Entry and baseline

Open **Detected Conflicts** through Tell Me. Use **Select Run**, **Finding Filters**, **Refresh**, and **Detailed Findings**. The page and all summary fields must be read-only.

Before browsing, capture a baseline of the existing audit, result, evidence, snapshot, source, and effective-permission records, including their values and SystemModifiedAt. Disable concurrent analysis, setup edits and run deletion while testing the no-write requirement. Capture the same records afterward and compare both row counts and values, not just counts.

The main fixture below is a prepared completed run with a readable Run No. All rows use conflict C1 unless specified otherwise. Give all C1 rows the same stored name. U1/U2 represent distinct User Security IDs. A/B are stored Company Name values.

| Finding | User | Company | Status | Severity | Special source | Group source | Primary source |
|---|---|---|---|---|---|---|---|
| F1 | U1 | A | Open | High | No | No | Direct |
| F2 | U1 | B | Open | High | Yes | Yes | Mixed |
| F3 | U2 | A | Accepted | High | No | Yes | Security Group |

Add another conflict C2 with one Open/Critical finding for U1/A. Add an older completed run containing C1 with a different stored name and severity. Current conflict setup can differ from these stored values; the summary must still use results only.

## Functional cases

| # | Case | Expected result |
|---|---|---|
| 1 | Open independently in a sandbox with no completed numbered run. | Empty summary and selection information; no error, analysis, repair, or writes. Running/Error runs are not selected. |
| 2 | Select a completed run containing no results. | Selected Run No. remains visible; no summary rows and a no-findings message. Refresh remains empty. |
| 3 | Select a fixture containing only F1. | One C1 row: 1 user, 1 finding, 1 company; both source flags false. |
| 4 | Use F1 and F3. | One C1 row: 2 users, 2 findings, 1 company. |
| 5 | Use F1 and F2. | One C1 row: 1 user, 2 findings, 2 companies. |
| 6 | Use F1–F3 and choose All, then Special Permissions. | All: C1 Special=true. Special scope: C1 has 1 user, 1 finding, 1 company (F2). |
| 7 | Use F1–F3 and choose Security Group Based. | C1 has 2 users, 2 findings, 2 companies (F2/F3). Setting only User Has Security Group on F1 must not include F1. |
| 8 | Inspect F2 under Security Group Based. | Mixed contributes because the stored group-source flag is true. Special is independently true. Do not derive either flag from primary-source text. |
| 9 | Select the older completed run; make a newer completed run available; refresh and change filters. | Older Run ID stays selected. Its captured name/severity remain displayed. Reopening independently uses the existing latest-started Finished-run policy. Canceling Select Run retains the previous scope. |
| 10 | Test all five filters with F1–F3 plus C2. | All C1: 2 users/3 findings/2 companies. Open C1: 1/2/2. High includes all F1–F3, including Accepted F3, but excludes Critical C2. Special and Group use cases 6/7. Filters precede aggregation. |
| 11 | Give F1 several evidence rows and compare against its summary before/after a refresh. | F1 still contributes exactly one finding. Evidence rows do not change user/company counts. |
| 12 | Open, switch runs/filters, refresh repeatedly, open Detailed Findings, then close. | Existing persisted data matches the baseline, including SystemModifiedAt. No recalculation or maintenance action is invoked. |

## Additional edge and navigation cases

- **Detailed Findings:** select C1 under each filter. Existing User Conflict Results must have the selected Run ID, Conflict Code, and the same finding predicate. Its included record count must equal Finding Count. Existing evidence navigation and advanced views remain available.
- **Stored inconsistencies:** give C1 different captured names/severities within the same run. Keep one row; show Inconsistent Stored Values and its Summary Note. Use the name from the lowest included result Entry No. and the highest included stored severity. Do not update any source record. Recheck under filters, since only included findings determine these values.
- **Run identity:** two historical runs with identical conflict codes must not be merged. Duplicate Run No. values do not prevent default run selection. The default is an eligible Finished run with a nonblank Run No., ordered by latest Started At and then Run No. for ties. Counts, result retrieval and navigation use the selected Run ID; Run No. remains a display/reference value. Explicit lookup must open only the chosen Run ID, even when another run has the same number.
- **Deleted/unavailable run:** after selecting a run, have a separate administrator delete that deliberately disposable run. Refresh clears the summary and explains that the selection is unavailable; it must not select a different run.
- **Deleted setup/user:** historical rows remain visible without current conflict setup or a live user-name lookup. User GUIDs still determine distinct-user counts.
- **Blank stored company:** if a legacy fixture includes a blank Company Name, it is counted as one distinct stored value, not substituted with the current BC company.
- **Empty filtered scope:** Special/Group/High on a run without matching findings gives an empty summary, without stale rows from the previous filter.
- **Performance:** use a representative large run. Measure initial load and Refresh; inspect SQL telemetry for one indexed filtered result traversal, with no per-conflict count queries, evidence joins, setup joins, or live user-name FlowField reads. Run-header lookup queries are separate from aggregation.
- **Scope:** verify Role Center cues and drill-downs against their declared filters. High Severity excludes Critical, and overlapping cues are not additive. Conflict Review and Affected Users remain stored-data navigation paths; no historical recalculation is invoked.

## Build and static verification

Follow [README build instructions](../README.md) and the [sandbox validation guide](Validation.md). The presentation code should write only temporary buffers, keep run identity in filters, and avoid recalculation, numbering repair or persistent evidence/summary updates.

Compilation and source inspection do not replace executing the functional cases above in Business Central. Count and value comparisons must include SystemModifiedAt, not just visible row counts.
