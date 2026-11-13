# BCAA sample/default configuration

These assets contain the existing **nine sample/demo controls** for **BC Access Auditor (BCAA) version 1.0.0.0**. They are intended for development, external review and sandbox testing, and provide a starting point for your own configuration.

**These are risk indicators, not certified audit controls.** A finding indicates a configured combination of TableData permissions; it does not prove that a user performed an action, can complete a business process, or violated a policy. Adapt the controls, severity, recommendations and permission requirements to your own processes, permission model and compensating controls. Validate posting-related risks against actual posting permissions and process controls.

## Files and compatibility

- [BCAACONTROLIMPORT_ConfigurationPackage.rapidstart](BCAACONTROLIMPORT_ConfigurationPackage.rapidstart) is the Business Central Configuration Package, code `BCAACONTROLIMPORT`, named `BCAA Demo SOD Control Setup`. It contains the package table/field definitions and setup records.
- [BCAAControlImportFile_for_ConfigurationPackage.xlsx](BCAAControlImportFile_for_ConfigurationPackage.xlsx) is the Excel/import representation of the same setup records. Use it to inspect or adapt the setup and import it into the corresponding configuration package.

The package declares product version **1.0.0.0** and uses BCAA tables **50500-50503**. Use it with BCAA 1.0.0.0 in a compatible Business Central sandbox; for another BCAA version, check its table/field compatibility before applying. Some original dictionary notes say `Community Preview v0.1`; those descriptive notes have been preserved and are not the package compatibility version.

## Included setup

| Table ID | Setup table | Records |
| --- | --- | ---: |
| 50500 | Conflict Header | 9 |
| 50501 | Conflict Group | 21 |
| 50502 | Rule Dictionary | 31 |
| 50503 | Conflict Group Rule | 32 |

The files contain **setup/control data only**, not customer transactional data, user snapshots, user permission assignments or audit results. References to Customer, Vendor, invoices and journals are table/permission requirements, not business records. The dictionary also includes entries not referenced by these nine controls.

| Control ID | Existing sample control name |
| --- | --- |
| CTRL-001 | Vendor master + payment preparation |
| CTRL-002 | Vendor Bank Account and Purchase Invoice Processing Risk |
| CTRL-003 | Purchase Invoice Processing and Posted Invoice Access Risk |
| CTRL-004 | Customer Master Data and Sales Invoice Processing Risk |
| CTRL-005 | Vendor Master Data and Payment Journal Risk |
| CTRL-006 | Vendor Master Data and Purchase Document Processing Risk |
| CTRL-007 | Item Master Data and Inventory Adjustment Risk |
| CTRL-008 | G/L Account Maintenance and Manual Journal Access |
| CTRL-009 | Sales Order Processing and Posted Shipment Access Risk |

The names describe the intended risk areas; inspect the actual group rules before using them. Each group combines its rules using its existing **Evaluation Logic (ALL/ANY)**. Each rule combines the required operations for its table using **Permission Match Mode (All/Any)** and the per-operation match settings. Importing these assets does not grant or revoke user permissions.

## Import and use in Business Central

1. Install BCAA 1.0.0.0 in an isolated compatible sandbox and select the company where you want the sample setup. Use an account authorized to import configuration packages and maintain BCAA setup.
2. Search for **Configuration Packages**, choose **Import Package**, and select the `.rapidstart` file. Open `BCAACONTROLIMPORT` and inspect its four tables and package records before applying data.
3. If using the Excel version, use **Import from Excel** for that same package before applying. The workbook supplies the same records; importing it in addition to the unchanged package data is unnecessary. Preserve the workbook's package identifiers, headings and structure. Do not refresh its external data connection: the original source URL was cleared during earlier sanitization.
4. Validate and apply the table data in dependency order: **Rule Dictionary (50502), Conflict Header (50500), Conflict Group (50501), Conflict Group Rule (50503)**. Resolve validation errors before continuing. Apply the tables individually in this order; do not rely solely on the exported processing orders, because the dictionary and header both have order 1.
5. Use a clean sample setup: matching keys can update existing records. After applying, verify the counts above, control IDs `CTRL-001` through `CTRL-009`, and the imported group rules. Counts can be higher if you already have other definitions.
6. Review and adapt the sample requirements to your processes before relying on findings. Check both group evaluation logic and per-table permission matching; dictionary changes do not automatically update values already copied into group rules.
7. Run **Full Analysis** and review findings and their detailed permission-source evidence. After changing configuration, run a new Full Analysis to evaluate the revised rules; previous stored findings are not rewritten by importing setup.

See Microsoft's [configuration package import and application guidance](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/apply-company-configuration-packages).

## Asset inspection

The decompressed package and every workbook archive part were inspected, including cell data, comments/authors, XML maps, connections, relationships and embedded metadata. Both representations contain the same setup values after normalizing option labels and Boolean values, and all group/dictionary references resolve.

No customer names, personal usernames, email addresses, tenant IDs, environment names, credentials/secrets, local Windows paths or private operational identifiers were identified. The workbook comment author is `BCAA Demo`, its connection is named `BCAA Demo Import` with an empty URL, and its comments describe field types/options. Nonzero GUIDs are workbook comment-shape identifiers; the setup's performance-dataset GUIDs are zero-valued. No macros, formulas or embedded attachments were found.

No additional sanitization was required for this publication review. Both asset files and all nine control definitions remain unchanged. Archive/XML integrity and data consistency were checked locally; this inspection did not execute an import in Business Central or open the workbook in Excel. Validate the import in your sandbox before using the configuration.
