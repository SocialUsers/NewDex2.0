"""Embed installed, unmodified Studio transform toolbar PNGs."""
from pathlib import Path
import hashlib
import json
import re
import struct

ROOT=Path(__file__).resolve().parents[1]
STUDIO=Path.home()/'AppData/Local/Roblox/Versions/version-7aaa6838d36c4448'
source=(ROOT/'studio_assets.lua').read_text(encoding='utf-8')
records={}
for name in ('Select','Move','Scale','Rotate'):
    path=STUDIO/'content/studio_svg_textures/Shared/Ribbon/Dark/Medium'/f'Ribbon{name}@2x.png'
    data=path.read_bytes()
    assert data.startswith(b'\x89PNG\r\n\x1a\n')
    key='native/transform/ribbon/'+name.lower()
    for stale in (key,'native/transform/'+name.lower()):
        source=re.sub(r'\n\t\["'+re.escape(stale)+r'"\] = "[^"\n]*",','',source)
    row='\n\t["'+key+'"] = "'+''.join('\\%03d'%b for b in data)+'",'
    source=source.replace('\n} }',row+'\n} }')
    width,height=struct.unpack('>II',data[16:24])
    records[key]={'path':path.relative_to(STUDIO).as_posix(),'sha256':hashlib.sha256(data).hexdigest(),'width':width,'height':height}
(ROOT/'studio_assets.lua').write_text(source,encoding='utf-8',newline='\n')
(ROOT/'tests/fixtures/transform-assets.json').write_text(json.dumps({'studioVersion':STUDIO.name,'assets':records},indent=2)+'\n',encoding='utf-8')
