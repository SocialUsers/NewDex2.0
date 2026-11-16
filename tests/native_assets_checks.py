"""Check source PNG identity and dimensions without an installed Studio."""
from pathlib import Path
import hashlib
import json
import re
import struct

root = Path(__file__).resolve().parents[1]
fixture = json.loads((root / "tests/fixtures/native-ui-assets.json").read_text())
fixture["assets"].update(json.loads((root / "tests/fixtures/quick-action-icons.json").read_text())["assets"])
fixture["assets"].update(json.loads((root / "tests/fixtures/reference-icons.json").read_text()))
fixture["assets"].update(json.loads((root / "tests/fixtures/transform-assets.json").read_text())["assets"])
fixture["assets"].update(json.loads((root / "tests/fixtures/gui-editor-assets.json").read_text())["assets"])
fixture["assets"].update(json.loads((root / "tests/fixtures/scrollbar-assets.json").read_text()))
fixture["assets"].update(json.loads((root / "tests/fixtures/panel-chrome-assets.json").read_text()))
source = (root / "studio_assets.lua").read_text()
for key, identity in fixture["assets"].items():
    matches = re.findall(r'\["' + re.escape(key) + r'"\] = "([^"\n]*)"', source)
    assert len(matches) == 1, key
    raw = bytes(int(value) for value in re.findall(r'\\(\d{3})', matches[0]))
    assert hashlib.sha256(raw).hexdigest() == identity["sha256"], key
    assert struct.unpack(">II", raw[16:24]) == (identity["width"], identity["height"]), key
print("PASS: " + str(len(fixture["assets"])) + " original Studio images retain exact PNG hashes and dimensions", flush=True)
