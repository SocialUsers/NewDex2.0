"""Embed verified original PNGs from Studio's compiled Qt resource table."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ASSETS = {
    "native/editor/format": ":/RibbonBar/images/RibbonIcons/Home/FormatSelection.png",
}


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("executable", type=Path)
    cli.add_argument("inventory", type=Path)
    args = cli.parse_args()
    raw = args.executable.read_bytes()
    inventory = json.loads(args.inventory.read_text())
    assert hashlib.sha256(raw).hexdigest() == inventory["sourceSHA256"], "Studio build differs from resource inventory"
    resources = {entry["path"]: entry for entry in inventory["resources"]}
    target = ROOT / "studio_assets.lua"
    source = target.read_text()
    fixture_path = ROOT / "tests/fixtures/native-ui-assets.json"
    fixture = json.loads(fixture_path.read_text())
    for key, resource_path in ASSETS.items():
        entry = resources[resource_path]
        data = raw[entry["offset"]:entry["offset"] + entry["storedBytes"]]
        if entry["flags"] & 1:
            size = struct.unpack_from(">I", data)[0]
            data = zlib.decompress(data[4:])
            assert len(data) == size
        assert hashlib.sha256(data).hexdigest() == entry["sha256"]
        assert data.startswith(b"\x89PNG\r\n\x1a\n")
        cursor = 8
        while cursor < len(data):
            size = struct.unpack_from(">I", data, cursor)[0]
            assert cursor + size + 12 <= len(data)
            assert zlib.crc32(data[cursor+4:cursor+8+size]) & 0xffffffff == struct.unpack_from(">I", data, cursor+8+size)[0]
            cursor += size + 12
        assert cursor == len(data)
        width, height = struct.unpack_from(">II", data, 16)
        fixture["assets"][key] = {"path": resource_path, "sha256": entry["sha256"], "width": width, "height": height,
                                   "sourceSHA256": inventory["sourceSHA256"], "fileOffset": entry["offset"]}
        source = re.sub(r'\n\t\["' + re.escape(key) + r'"\] = "[^"\n]*",', "", source)
        literal = '"' + ''.join(f"\\{byte:03d}" for byte in data) + '"'
        assert "\n} }" in source
        source = source.replace("\n} }", f'\n\t["{key}"] = {literal},\n}} }}')
    source = re.sub(r'version = "[^"]+"', 'version = "studio-native-editor-menu-v2-20261020"', source, count=1)
    target.write_text(source, encoding="utf-8", newline="\n")
    fixture_path.write_text(json.dumps(fixture, indent=2) + "\n")
    print(f"Embedded {len(ASSETS)} original editor menu image; hashes and PNG CRCs verified")


if __name__ == "__main__":
    main()
