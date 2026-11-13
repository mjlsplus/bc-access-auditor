# Installation and schema compatibility — 1.0.0.0

## Target and package identity

The manifest targets Business Central application/platform **28.0.0.0** and AL runtime **15.0**. BC 28 is the current development target; compatibility with earlier or later major versions is not claimed. Confirm installation, object-range availability and runtime behavior on the specific BC 28 environment used for evaluation.

The declared object range is **50500–50999**. Normal and test-enabled packages use the same application ID, publisher, name and version. They cannot be installed as independent side-by-side apps. Check tenant package registration before uploading a different build with the same identity/version; a fresh environment may not resolve a tenant-level registration conflict.

Use the explicitly built `.build/BCAA-performance-Normal.app` for ordinary evaluation. Root packages and old build artifacts are historical evidence, not a release-selection mechanism. Use the test-enabled package only in an isolated developer sandbox with the required test privileges.

## Earlier schema identities

Earlier development builds used different numeric object and extension-field IDs. Renumbered tables and extension fields have different identities; no migration from those old identities is supplied. A version bump, an ID mapping, or successful compilation does not migrate existing data.

For an installation with old IDs, preserve the original environment, database backup and matching source/packages. Evaluate 1.0.0.0 in a separate clean BC 28 sandbox rather than installing it over the old schema. Do not use ForceSync, uninstall existing data, or rename objects to force an upgrade. Upgrades from other existing builds also require a separately validated path; this guide does not certify one.

Historical renumbering reports and mapping CSVs are not part of the public repository. The source and manifest define the current schema. `BCGSecurityManager.Profile.al` declares a named profile with no numeric object ID.

## Retained schema

Keep all setup, snapshot, result tables and extensions. In particular, do not remove these apparently obsolete or test-related items:

- Tables 50504 `BCG User Permission Demo` and 50505 `BCG Legacy Conflict Result`, marked ObsoleteState Pending.
- Setup table 50506 field 2, `Demo Mode`.
- Wizard Buffer table 50530, including legacy fields 14 and 24.
- `tests/BCGPerfDataset.Table.al` and `BCGPerfRuleOwner.TableExt.al`, intentionally present in normal builds.
- Permission set 50997 `BCG SCHEMA COVERAGE`, internal and nonassignable. It is not an operational user role.

Disabling executable test objects must not remove persisted performance ownership or measurement schema. Keep existing enum values, object/field IDs and empty compatibility objects unless a separate compatibility change is designed and tested.

## Retention and rollback

Keep verified private backups of source, local configuration, dependency versions, historical packages and build evidence outside the working repository. Git ignores do not preserve these files. Record package hashes and the version/environment they belong to.

Restoring source or an older `.app` is not a database rollback. A deployed-environment recovery requires the matching environment/database backup and a validated recovery process. Preserve original installations until installation and data compatibility have been established. No historical artifacts need to be deleted for a clean public repository.
