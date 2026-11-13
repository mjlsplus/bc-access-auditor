# Contributing

BC Access Auditor is experimental open-source software under the MIT license. Contributions are welcome. Prefer focused pull requests with a clear problem, a small change and validation results. Discuss substantial changes first. There is no guaranteed roadmap or support commitment.

Preserve BC 28 / runtime 15 compatibility, object identities, configuration structures, TableData rule semantics and evidence tracing unless a change is explicitly agreed.

Follow the [README](README.md) prerequisites. For code changes, build Normal and Tests with `tests/Build-Performance.ps1 -Mode Normal -Analyze` and `tests/Build-Performance.ps1 -Mode Tests -Analyze`, then run `python tests/Check-PermissionModel.py`. Add or update relevant automated tests and execute them in an isolated BC sandbox as described in [Validation.md](docs/Validation.md). State which checks ran and which did not. For documentation changes, verify instructions and links.

Do not include customer-sensitive data, user/security exports, credentials, tenant or environment identifiers, or generated packages in contributions. Follow [SECURITY.md](SECURITY.md) for private vulnerability reporting.
