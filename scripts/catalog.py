"""Writes drivers.json, the list apps read, from the built packages: each driver's name, Mesa version and source,
download link, size and SHA-256. Usage: catalog.py <dir with the .zip and .json files> <release download URL>."""
import hashlib, json, pathlib, sys

folder, base = pathlib.Path(sys.argv[1]), sys.argv[2].rstrip("/")
notes = {b["id"]: b.get("notes", "") for b in json.load(open("builds.json"))}
drivers = []
for info in sorted(folder.glob("*.json")):
    if info.name == "drivers.json":
        continue
    d = json.loads(info.read_text())
    package = folder / f"{d['id']}.zip"
    data = package.read_bytes()
    drivers.append(d | {"notes": notes.get(d["id"], ""), "url": f"{base}/{package.name}", "size": len(data),
                        "sha256": hashlib.sha256(data).hexdigest()})
assert drivers, "no drivers built"
order = list(notes)
drivers.sort(key=lambda d: order.index(d["id"]) if d["id"] in order else len(order))
(folder / "drivers.json").write_text(json.dumps({"schemaVersion": 1, "drivers": drivers}, indent=2) + "\n")
print(json.dumps(drivers, indent=2))
