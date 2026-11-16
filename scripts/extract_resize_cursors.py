"""Extract native 32px diagonal CUR frames without resizing or rotating pixels.

Print an apply_patch payload with --patch; otherwise emit PNGs and provenance.
"""
import argparse
import hashlib
import io
import json
import re
import struct
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

def extract(path):
    raw = path.read_bytes()
    reserved, kind, count = struct.unpack_from('<HHH', raw)
    assert (reserved, kind) == (0, 2), 'Expected Windows CUR'
    for index in range(count):
        entry = struct.unpack_from('<BBBBHHII', raw, 6 + index * 16)
        width, height, colors, zero, hot_x, hot_y, length, offset = entry
        if (width, height) != (32, 32):
            continue
        bitmap = raw[offset:offset + length]
        assert len(bitmap) == length
        single = struct.pack('<HHHBBBBHHII', 0, 2, 1, width, height,
                             colors, zero, hot_x, hot_y, length, 22) + bitmap
        image = Image.open(io.BytesIO(single)).convert('RGBA')
        assert image.size == (32, 32)
        output = io.BytesIO()
        image.save(output, format='PNG')
        return output.getvalue(), {'source': str(path), 'sourceSha256': hashlib.sha256(raw).hexdigest(),
            'entry': index, 'bitmapOffset': offset, 'bitmapBytes': length,
            'width': width, 'height': height, 'hotspot': [hot_x, hot_y],
            'rgbaSha256': hashlib.sha256(image.tobytes()).hexdigest()}
    raise ValueError('No native 32px frame: ' + str(path))

def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--cursor-dir', type=Path, default=Path('C:/Windows/Cursors'))
    cli.add_argument('--output', type=Path, default=ROOT / '.private/diagonal-cursors')
    cli.add_argument('--patch', action='store_true')
    args = cli.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    records = []
    rows = []
    for direction in ('nwse', 'nesw'):
        png, record = extract(args.cursor_dir / ('aero_' + direction + '.cur'))
        record['key'] = 'cursor/windows_resize_' + direction + '_32'
        record['pngSha256'] = hashlib.sha256(png).hexdigest()
        records.append(record)
        (args.output / (direction + '.png')).write_bytes(png)
        rows.append('\t["' + record['key'] + '"] = "' + ''.join('\\%03d' % b for b in png) + '",')
    (args.output / 'manifest.json').write_text(json.dumps(records, indent=2))
    if args.patch:
        source = (ROOT / 'studio_assets.lua').read_text()
        assert all('["' + record['key'] + '"]' not in source for record in records)
        anchor = re.search(r'^\s*\["cursor/studio_resize_diagonal_16"\].*$', source, re.M).group(0)
        print('*** Begin Patch\n*** Update File: ' + (ROOT / 'studio_assets.lua').as_posix())
        print('@@\n ' + anchor.lstrip('\n'))
        for row in rows:
            print('+' + row)
        print('*** End Patch')
    else:
        print(json.dumps(records, indent=2))

if __name__ == '__main__':
    main()
