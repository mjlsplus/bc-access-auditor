# Experimental 1.0.0.0 release checklist

This is an experimental MIT-licensed open-source release. It is not production-certified or audit-certified, and it carries no guaranteed support commitment.

## Recorded validation

- Normal and Tests builds passed for an exact temporary copy of the public snapshot using BC 28 symbols and runtime 15. CodeCop, UICop and PerTenantExtensionCop completed with zero errors: Normal had 77 warnings and 127 informational diagnostics; Tests had 135 warnings and 143 informational diagnostics. The builds were not warning-free.
- Repository permission/schema static checks passed for both packages. Normal excludes executable test codeunits while retaining compatibility schema.
- SHA-256 comparison confirmed that all 120 production AL files, all 10 test AL files, `app.json` and `AppSourceCop.json` are byte-for-byte identical to the source revision previously reported to have achieved **229/229 BC runtime tests passed**.
- The 229/229 result is historical runtime evidence supplied by the maintainer, not a new execution against this documentation-only public snapshot. The hash comparison establishes source identity; it does not independently reproduce or verify the historical execution. Runtime authorization and environment-specific behavior are not certified by these checks.
- Final inventory and local Markdown link checks passed. Sample configuration assets matched their recorded hashes; generated packages and diagnostics were kept outside the public snapshot.

## Publication checklist

- [SECURITY.md](../SECURITY.md) contains the verified private reporting route, `mbarski@mjlsplus.com`. GitHub Private Vulnerability Reporting is optional and may be enabled after publication.
- Inspect the final file inventory and staged changes for secrets, customer data, local connection metadata, generated packages and internal artifacts. Do not force-add ignored files.
- Verify the manifest identity: BC Access Auditor, publisher MJLS Plus, app ID `4d8adf71-a8a6-4c10-b1a5-9b7cf4e0d3a1`, version `1.0.0.0`, application/platform BC 28 and runtime 15. Verify the MIT license and copyright attribution.
- Verify the [nine-control sample configuration](../review-assets/README.md) remains unchanged and is described as adaptable demo risk indicators.
- Build reproduction instructions are in the [README](../README.md). Retain the actual build/analyzer results, including the remaining warnings, with release evidence.
- Retain the passing `python tests/Check-PermissionModel.py` results. Source exposure can still include test source even though Normal excludes executable tests.
- Preserve the historical runtime evidence separately from the source comparison and new build results. Use [Validation.md](Validation.md) when reproducing sandbox checks; do not describe unexecuted checks as passed. Keep sensitive runtime evidence private.
- Verify the final source inventory and SHA-256 of the Normal release artifact. The helper overwrites `.build/BCAA-performance-Normal.app`; check the exact artifact before attaching it to a release. Do not attach the Tests package, symbols or private logs.
- After final review, initialize the public repository with commit `Initial open-source release 1.0.0.0` and tag the reviewed commit `v1.0.0.0`.
- Release notes must state experimental limitations and distinguish executed checks from pending validation. Do not claim production readiness or guaranteed support.
