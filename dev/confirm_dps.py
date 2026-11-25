"""Confirm near-tied DPS finalists without reusing the ranking sample."""
import json
import subprocess
import sys
from pathlib import Path

from role_benchmarks import measure

checkout, helper = (Path(arg).resolve() for arg in sys.argv[1:3])
lua = sys.argv[3] if len(sys.argv) > 3 else "lua5.1"
rows = subprocess.check_output([lua, "dev/close_sets.lua"], text=True).splitlines()
entries = []
for index, row in enumerate(rows):
    role, key = row.split()
    entries.append(dict(role=role, gear=list(map(int, key.split(","))), key=key,
                        iterations=6400, seed=930000 + index))
shamans = [e for e in entries if e["role"] in ("enhancement", "elemental")]
# Supplying a revision also supports a source archive without .git.
revision = next(line.split('"')[1] for line in Path("Data.lua").read_text().splitlines()
                if line.startswith("revision="))
shaman_results = iter(json.loads(subprocess.check_output(
    ["node", "dev/refresh.ts", checkout, helper, revision, "--confirm"],
    input=json.dumps(shamans), text=True)))
out = ["local _, ns = ...", "ns.confirmedDPS={}"]
for entry in entries:
    role, key = entry["role"], entry["key"]
    if role in ("balance", "cat"):
        gear = tuple(entry["gear"])
        result = measure(checkout, helper, role, [gear], entry["iterations"], entry["seed"])[gear]
    else:
        result = next(shaman_results)
    out.append(f'ns.confirmedDPS["{role}/{key}"]={{{result["dps"]:.4f},{result["se"]:.4f}}}')
target = Path("ConfirmedDPS.lua")
tmp = target.with_suffix(".tmp")
tmp.write_text("\n".join(out) + "\n")
tmp.replace(target)
print("Confirmed DPS for", len(entries), "distinct sets")
