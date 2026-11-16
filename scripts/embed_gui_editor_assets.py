"""Embed unmodified installed UIEditor assets; never launches Studio."""
from pathlib import Path
import hashlib,json,re,struct
ROOT=Path(__file__).resolve().parents[1]
STUDIO=Path.home()/'AppData/Local/Roblox/Versions/version-7aaa6838d36c4448'
source=(ROOT/'studio_assets.lua').read_text(encoding='utf-8')
records={}
for path in sorted((STUDIO/'StudioContent/textures/StudioUIEditor').glob('*.png')):
    data=path.read_bytes()
    key='native/gui-editor/'+path.stem
    source=re.sub(r'\n\t\["'+re.escape(key)+r'"\] = "[^"\n]*",','',source)
    source=source.replace('\n} }','\n\t["'+key+'"] = "'+''.join('\\%03d'%b for b in data)+'",\n} }')
    w,h=struct.unpack('>II',data[16:24])
    records[key]={'path':path.relative_to(STUDIO).as_posix(),'sha256':hashlib.sha256(data).hexdigest(),'width':w,'height':h}
assert len(records)==14
(ROOT/'studio_assets.lua').write_text(source,encoding='utf-8',newline='\n')
(ROOT/'tests/fixtures/gui-editor-assets.json').write_text(json.dumps({'studioVersion':STUDIO.name,'assets':records},indent=2)+'\n',encoding='utf-8')
