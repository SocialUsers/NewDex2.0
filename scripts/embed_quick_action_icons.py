"""Emit a patch embedding unmodified installed Studio icons for menu actions."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
ASSETS = {
    'explorer': 'Shared/WidgetIcons/Dark/Large/Explorer@2x.png',
    'properties': 'Shared/WidgetIcons/Dark/Large/Properties@2x.png',
    'select': 'Shared/DraggerTools/Dark/Large/Select@2x.png',
    'ui_select': 'Shared/InsertableObjects/Dark/Large/ScreenGui@2x.png',
    'script': 'Lua/ActivityHistory/Dark/Large/Script@2x.png',
    'console': 'Shared/WidgetIcons/Dark/Large/Output@2x.png',
    'save': 'Lua/Localization/Dark/Large/ExportCSV@2x.png',
    'viewer': 'Lua/Terrain/Dark/Large/TerrainBrushTypeCube@2x.png',
    'reconstructor': 'Shared/InsertableObjects/Dark/Standard/ServerScriptService@2x.png',
}

def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--studio-dir', type=Path, required=True)
    cli.add_argument('--manifest', type=Path, required=True)
    args = cli.parse_args()
    base = args.studio_dir / 'content/studio_svg_textures'
    source = (ROOT / 'studio_assets.lua').read_text()
    rows, records = [], {}
    for name, relative in ASSETS.items():
        key = 'menu/tool/' + name
        assert '["' + key + '"]' not in source, 'Do not duplicate an embedded asset'
        raw = (base / relative).read_bytes()
        assert raw.startswith(b'\x89PNG\r\n\x1a\n')
        width, height = struct.unpack('>II', raw[16:24])
        assert width == height and width in (32, 64)
        rows.append('\t["' + key + '"] = "' + ''.join('\\%03d' % b for b in raw) + '",')
        records[key] = {'path': relative, 'sha256': hashlib.sha256(raw).hexdigest(), 'width': width, 'height': height}
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.write_text(json.dumps({'studioVersion': args.studio_dir.name, 'assets': records}, indent=2))
    anchor = re.search(r'^\s*\["menu/settings"\].*$', source, re.M).group(0).lstrip('\n')
    print('*** Begin Patch\n*** Update File: ' + (ROOT / 'studio_assets.lua').as_posix() + '\n@@\n ' + anchor)
    print('\n'.join('+' + row for row in rows))
    print('*** End Patch')

if __name__ == '__main__':
    main()
