"""Check compiled BCAA role boundaries; does not prove runtime authorization.

Usage: python tests/Check-PermissionModel.py [normal.app tests.app]
Requires Python 3; reads packages only and never contacts Business Central.
"""

import json
from pathlib import Path
import re
import sys
from zipfile import ZipFile


def require(condition, message):
    if not condition:
        raise ValueError(message)


def properties(obj):
    return {p["Name"]: p["Value"] for p in obj.get("Properties", [])}


def grants(permission_set):
    return {
        (p.get("PermissionObject", 0), p["Id"]): p["Value"]
        for p in permission_set.get("Permissions", [])
    }


def walk_actions(actions):
    for action in actions:
        yield action
        yield from walk_actions(action.get("Actions", []))


def check(path):
    with ZipFile(path) as package:
        symbols = json.loads(package.read("SymbolReference.json"))
    sets = {s["Id"]: s for s in symbols["PermissionSets"]}
    require(set(sets) == {50997, 50998, 50999}, "Unexpected permission sets")
    view, admin, schema = (grants(sets[i]) for i in (50998, 50999, 50997))
    require(properties(sets[50998])["Assignable"] == "1", "VIEW is not assignable")
    require(properties(sets[50999])["Assignable"] == "1", "ADMIN is not assignable")
    require(properties(sets[50997])["Assignable"] == "0", "Schema coverage is assignable")
    require(not properties(sets[50998]).get("IncludedPermissionSets"), "VIEW inherits other grants")
    require(not properties(sets[50997]).get("IncludedPermissionSets"), "Schema coverage inherits grants")
    require(properties(sets[50999]).get("IncludedPermissionSets") == '"BCG AUDIT VIEW"',
            "ADMIN must include only VIEW")
    effective_admin = dict(view)
    for key, value in admin.items():
        effective_admin[key] = effective_admin.get(key, 0) | value

    # Symbol permission masks: direct R/I/M/D/X = 1/2/4/8/16;
    # indirect r/i/m/d/x = 32/64/128/256/512.
    stored = {50520, 50521, 50522, 50523, 50524, 50580, 50582, 50584, 50592, 50593, 50594}
    setup = {50500, 50501, 50502, 50503, 50506}
    retained = {50504, 50505, 50960}
    read_services = {50606, 50611, 50615}
    management = {50507, 50520, 50532, 50540, 50563, 50568, 50575, 50578, 50579, 50586, 50595}
    external_reads = {2000000120, 2000000053, 2000000254, 2000000058, 2000000167}
    definition_pages = {50510, 50511, 50512, 50513, 50514}
    admin_pages = {50517, 50518, 50519, 50530, 50589, 50614}
    for role_name, role in [("VIEW", view), ("ADMIN", effective_admin)]:
        for (kind, number), value in role.items():
            require(number != 0, f"{role_name}: wildcard permission")
            require(kind in (0, 1, 5, 8), f"{role_name}: unexpected object type {kind}")
            require(not (kind in (0, 1) and number in retained), f"{role_name}: retained-schema access")
            require(not (kind == 5 and number in {50613, 50960, 50961, 50972, 50973, 50974, 50975}),
                    f"{role_name}: test/performance codeunit execution")
            require(not (kind == 8 and number == 50960), f"{role_name}: performance page execution")
            if kind == 0:
                if role_name == "VIEW":
                    require(value == 1, "VIEW has direct/indirect writes")
                if not 50500 <= number <= 50999:
                    require(number in external_reads and value == 1, "Unexpected standard data grant")
            else:
                require(value == 16, "Unexpected object permission")
        for number in stored:
            require(role.get((0, number)) == (1 if role_name == "VIEW" else 449),
                    f"{role_name}: missing read or incorrect indirect write grant on {number}")
    require({n for (k, n) in view if k == 5 and 50500 <= n <= 50999} == read_services,
            "VIEW can execute a management codeunit")
    require(all((8, n) not in view for n in admin_pages), "VIEW can execute an admin page")
    require(all(view.get((8, n)) == 16 for n in definition_pages),
            "VIEW missing SoD definition page execution")
    require(all(view.get((0, n)) == 1 for n in {50500, 50501, 50502, 50503}),
            "VIEW must have read-only SoD definition access")
    for page in symbols["Pages"]:
        if page["Id"] in definition_pages:
            require(not properties(page).get("Permissions"), "Definition page must not elevate permissions")
    require(all(view.get((8, n)) == 16 for n in {50594, 50599}),
            "VIEW missing read-only Role Center execution")
    cues = properties(next(p for p in symbols["Pages"] if p["Id"] == 50594))
    require(cues.get("SourceTableTemporary") == "1", "Cues must use temporary data")
    require(all(cues.get(p) == "0" for p in ("Editable", "InsertAllowed", "ModifyAllowed", "DeleteAllowed")),
            "Cues must be read-only")
    # F06: withdraw standalone maintenance in both production and test packages.
    disabled = {
        50589: {'Run Security Group Snapshot', 'Add SUPER/SUPER DATA Wildcards',
                'Repair Security Group SUPER Analysis', 'Recalculate Conflicts',
                'Rebuild Conflict Source Trace', 'Update Result Source Summary',
                'Update Conflict Evidence Summary', 'Update User Access Context', 'Update Current Run Number'},
        50566: {'Run Security Group Snapshot', 'BCG Add Special Wildcards', 'Fix Security Group SUPER Analysis',
                'Recalculate Conflicts', 'Rebuild Conflict Source Trace', 'Update Conflict Result Source Summary',
                'BCGUpdateConflictEvidenceSummaryFromPerms', 'Update User Access Context'},
        50519: {'Update Run Numbers', 'Update Selected Run Number'},
        50526: {'Update Current Run Number'},
        50562: {'Update Source Summary'},
        50570: {'BCGUpdateConflictEvidenceSummary'},
        50577: {'Update User Access Context'},
        50596: {'BCGClearRunDataKeepHeader'},
    }
    for number, names in disabled.items():
        kind = "Pages" if number == 50589 else "PageExtensions"
        obj = next(p for p in symbols[kind] if p["Id"] == number)
        actions = list(walk_actions(obj.get("Actions", [])))
        for change in obj.get("ActionChanges", []):
            actions.extend(walk_actions(change.get("Actions", [])))
        for name in names:
            action = properties(next(a for a in actions if a["Name"] == name))
            require(all(str(action.get(p)).lower() in {"false", "0"} for p in ("Visible", "Enabled")),
                    f"F06 maintenance action remains available: {number}/{name}")
    require(not cues.get("Permissions"), "Cues must not elevate permissions")
    require(all(effective_admin.get((5, n)) == 16 for n in management), "ADMIN missing management execution")
    require(all(effective_admin.get((0, n)) == 15 for n in setup), "ADMIN missing setup access")
    conflicts = next(p for p in symbols["Pages"] if p["Id"] == 50510)
    wizard = properties(next(a for a in walk_actions(conflicts.get("Actions", []))
                             if a["Name"] == "OpenWizard"))
    require(wizard.get("AccessByPermission") == 'tabledata "BCG Setup" = M',
            "Wizard navigation must use ADMIN's direct Setup Modify grant, not indirect Audit Run Modify")
    require(wizard.get("Visible") == "CanManageDefinitions", "Wizard capability visibility was removed")
    require(schema == {(0, n): 1 for n in retained | {50530}}, "Unexpected schema-coverage grants")
    require((0, 50530) not in effective_admin, "Persisted wizard buffer access is unnecessary")
    for table in symbols["Tables"]:
        if properties(table).get("TableType") != "Temporary":
            require((0, table["Id"]) in effective_admin or (0, table["Id"]) in schema,
                    f"Missing schema coverage: {table['Name']}")
    for codeunit in symbols["Codeunits"]:
        elevation = properties(codeunit).get("Permissions", "")
        if codeunit["Id"] in read_services:
            require(not elevation, "VIEW service has elevated permissions")
        if elevation:
            require(codeunit["Id"] in management, "Unexpected elevated codeunit")
            entries = re.findall(r'tabledata\s+"(BCG [^"]+)"\s*=\s*([imd]+)', elevation)
            require(len(entries) == len(elevation.split(",")), "Unexpected elevated permission")
    print(f"PASS {path}: compiled role boundaries and schema coverage; runtime tests still required")


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    paths = [Path(p) for p in sys.argv[1:]] or [
        root / ".build/BCAA-performance-Normal.app",
        root / ".build/BCAA-performance-Tests.app",
    ]
    for package_path in paths:
        check(package_path)
