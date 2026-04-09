#!/usr/bin/env python3
"""
Valida config/cidr-registry.txt contra config/environments.yaml no diretório infra do consumidor.

CLI:
  python3 validate_cidr_registry.py [DIR_INFRA]
Terraform external (stdout JSON, valores string):
  python3 validate_cidr_registry.py --external [DIR_INFRA]

Dependência: PyYAML (pip install -r env/scripts/requirements-cidr.txt).
"""

from __future__ import annotations

import ipaddress
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print(
        "cidr-registry validation: instale dependências: "
        "python3 -m pip install -r env/scripts/requirements-cidr.txt",
        file=sys.stderr,
    )
    sys.exit(1)


def die(msg: str) -> None:
    print(f"cidr-registry validation: {msg}", file=sys.stderr)
    sys.exit(1)


def networks_overlap(
    a: ipaddress.IPv4Network | ipaddress.IPv6Network,
    b: ipaddress.IPv4Network | ipaddress.IPv6Network,
) -> bool:
    af = (int(a.network_address), int(a.broadcast_address))
    bf = (int(b.network_address), int(b.broadcast_address))
    a_lo, a_hi = af
    b_lo, b_hi = bf
    return not (a_hi < b_lo or b_hi < a_lo)


def parse_args() -> tuple[Path, bool]:
    raw = sys.argv[1:]
    external = False
    if "--external" in raw:
        external = True
        raw = [x for x in raw if x != "--external"]
    if not raw:
        return Path.cwd().resolve(), external
    return Path(raw[0]).resolve(), external


def validate_infra(infra_dir: Path) -> int:
    """Retorna número de alocações verificadas (wanted)."""
    registry_path = infra_dir / "config" / "cidr-registry.txt"
    yaml_path = infra_dir / "config" / "environments.yaml"

    if not registry_path.is_file():
        die(f"missing {registry_path}")
    if not yaml_path.is_file():
        die(f"missing {yaml_path}")

    entries: list[dict[str, str]] = []
    for line in registry_path.read_text().splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|", 3)]
        if len(parts) != 4:
            die(f"bad registry line: {line!r}")
        entries.append(
            {
                "cidr": parts[0],
                "project_id": parts[1],
                "environment": parts[2],
                "resource": parts[3],
            }
        )

    data = yaml.safe_load(yaml_path.read_text())
    if not isinstance(data, dict):
        die("environments.yaml: root must be a mapping")
    envs = data.get("environments")
    if not isinstance(envs, list):
        die("environments: missing or not a list in YAML")

    wanted: list[dict[str, str]] = []
    for e in envs:
        if not isinstance(e, dict):
            die("environments: each item must be a mapping")
        name = e.get("name")
        pid = e.get("project_id")
        vpc_cidr = e.get("vpc_cidr")
        if not name or not pid:
            die(f"env entry missing name or project_id: {e!r}")
        if not vpc_cidr:
            die(f"env {name}: missing vpc_cidr")
        wanted.append(
            {
                "cidr": str(vpc_cidr),
                "project_id": str(pid),
                "environment": str(name),
                "resource": "vpc",
            }
        )
        for s in e.get("subnets") or []:
            if not isinstance(s, dict):
                die(f"env {name}: subnet must be a mapping")
            sn = s.get("name")
            sc = s.get("cidr")
            if not sc:
                die(f"env {name}: subnet missing cidr")
            wanted.append(
                {
                    "cidr": str(sc),
                    "project_id": str(pid),
                    "environment": str(name),
                    "resource": f"subnet:{sn}",
                }
            )

    def row_key(r: dict[str, str]) -> tuple[str, str, str, str]:
        return (r["cidr"], r["project_id"], r["environment"], r["resource"])

    entry_set = {row_key(r) for r in entries}

    for w in wanted:
        if row_key(w) not in entry_set:
            exp = "|".join(
                [w["cidr"], w["project_id"], w["environment"], w["resource"]]
            )
            die(
                f"CIDR {w['cidr']} ({w['environment']}/{w['resource']}) not listed in "
                f"cidr-registry.txt (expected row: {exp})"
            )

    for e in envs:
        if not isinstance(e, dict):
            continue
        name = e.get("name")
        vpc_cidr = e.get("vpc_cidr")
        if not vpc_cidr:
            continue
        try:
            vpc_net = ipaddress.ip_network(str(vpc_cidr), strict=False)
        except ValueError as err:
            die(f"env {name}: invalid vpc_cidr {vpc_cidr!r}: {err}")
        for s in e.get("subnets") or []:
            if not isinstance(s, dict):
                continue
            sn = s.get("cidr")
            if not sn:
                continue
            try:
                sub = ipaddress.ip_network(str(sn), strict=False)
            except ValueError as err:
                die(f"subnet {sn} in {name}: invalid cidr: {err}")
            if sub.version != vpc_net.version:
                die(f"subnet {sn} in {name}: address family must match vpc_cidr")
            if not sub.subnet_of(vpc_net):
                die(f"subnet {sn} in {name} is not inside vpc_cidr {vpc_cidr}")

    vpc_rows = [r for r in entries if r["resource"] == "vpc"]
    for i, a in enumerate(vpc_rows):
        for b in vpc_rows[i + 1 :]:
            if a["environment"] == b["environment"]:
                continue
            try:
                na = ipaddress.ip_network(a["cidr"], strict=False)
                nb = ipaddress.ip_network(b["cidr"], strict=False)
            except ValueError as err:
                die(f"invalid CIDR in registry: {err}")
            if networks_overlap(na, nb):
                die(
                    f"VPC CIDR overlap: {a['cidr']} ({a['environment']}) and "
                    f"{b['cidr']} ({b['environment']})"
                )

    return len(wanted)


def main() -> None:
    infra_dir, external = parse_args()
    n = validate_infra(infra_dir)
    if external:
        # data.external exige JSON no stdout; valores devem ser strings.
        print(json.dumps({"valid": "true", "allocations_checked": str(n)}))
    else:
        print(f"cidr-registry validation: OK ({n} allocations checked).")


if __name__ == "__main__":
    main()
