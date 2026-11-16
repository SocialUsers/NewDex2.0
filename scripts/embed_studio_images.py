"""Embed original Studio UI images without resizing or repainting their pixels."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]
IMAGES = {
    "explorer/loadingSpinner": "Lua/Explorer/Light/Standard/loadingSpinner.png",
    "native/explorer/indent_guide": "Lua/Explorer/Light/Standard/indentGuide.png",
    **{"native/status/package/" + theme + "/" + name: "Shared/Packages/" + theme + "/Standard/PackageStatus_" + name + ".png"
       for theme in ("Dark", "Light") for name in ("AutoupdateOff_Old", "AutoupdateOn_Old", "Modified_AutoupdateOff", "Modified_AutoupdateOn", "UpdateAvailable_Old", "UpdateAvailable_Modified")},
    **{"native/status/warning/" + theme: "Shared/Alerts/" + theme + "/Standard/Warning.png" for theme in ("Dark", "Light")},
    "native/folder/tint/Dark": "Shared/InsertableObjects/Dark/Standard/CustomFolder.png",
    "native/folder/tint/Light": "Shared/InsertableObjects/Light/Standard/CustomFolder.png",
    "native/package/autoupdate": "Shared/Packages/Light/Standard/PackageLink_AutoupdateOn.png",
    **{"native/filter/" + key: "Lua/Explorer/Light/Standard/" + name + ".png"
       for key, name in {"anchor": "anchor", "lock": "lock", "transparency": "transparency",
                         "material": "material", "mesh": "meshPart", "texture": "texture",
                         "tag": "tag", "help": "help"}.items()},
    "native/explorer/checked": "Lua/Explorer/Dark/Standard/checkBox_checked.png",
    "native/explorer/unchecked": "Lua/Explorer/Dark/Standard/checkBox_unchecked.png",
    "native/sidebar/left": "Lua/SystemArrows/Dark/Standard/DoubleChevronLeft.png",
    "native/editor/previous": "Lua/FindReplaceAll/Dark/Standard/ArrowUp.png",
    "native/editor/next": "Lua/FindReplaceAll/Dark/Standard/ArrowDown.png",
    "native/editor/match_case": "Lua/FindReplaceAll/Dark/Standard/MatchCase.png",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, default=ROOT.parent / "studio_svg_textures.zip")
    args = parser.parse_args()
    target = ROOT / "studio_assets.lua"
    source = target.read_text(encoding="utf-8")
    rows, identities = [], {}
    with zipfile.ZipFile(args.archive) as archive:
        for key, path in IMAGES.items():
            raw = archive.read("studio_svg_textures/" + path)
            assert raw.startswith(b"\x89PNG\r\n\x1a\n"), path
            width, height = struct.unpack(">II", raw[16:24])
            identities[key] = {"path": path, "sha256": hashlib.sha256(raw).hexdigest(),
                               "width": width, "height": height}
            source = re.sub(r'\n\t\["' + re.escape(key) + r'"\] = "[^"\n]*",', "", source)
            literal = '"' + "".join("\\" + str(byte).zfill(3) for byte in raw) + '"'
            rows.append('\n\t["' + key + '"] = ' + literal + ',')
    # Retired splitter recreations have no runtime callers after native extraction.
    for key in ("cursor/split_horizontal", "cursor/split_vertical", "native/add"):
        source = re.sub(r'\n\t\["' + re.escape(key) + r'"\] = "[^"\n]*",', "", source)
    assert "\n} }" in source
    target.write_text(source.replace("\n} }", "".join(rows) + "\n} }"), encoding="utf-8", newline="\n")
    fixture = {"archiveSha256": hashlib.sha256(args.archive.read_bytes()).hexdigest(), "assets": identities}
    (ROOT / "tests/fixtures/native-ui-assets.json").write_text(json.dumps(fixture, indent=2) + "\n", encoding="utf-8")
    print("Embedded " + str(len(identities)) + " original UI images without changing their bytes")


if __name__ == "__main__":
    main()
