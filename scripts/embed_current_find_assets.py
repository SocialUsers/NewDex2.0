"""Bind current installed Studio Find assets, rather than legacy Qt PNG copies."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import struct

ROOT=Path(__file__).resolve().parents[1]
cli=argparse.ArgumentParser(description=__doc__)
cli.add_argument('studio',type=Path)
args=cli.parse_args()
names={
 'previous':'Lua/FindReplaceAll/Dark/Standard/FindPrevious',
 'next':'Lua/FindReplaceAll/Dark/Standard/FindNext',
 'match_case':'Lua/FindReplaceAll/Dark/Standard/MatchCase',
 'whole_word':'Lua/FindReplaceAll/Dark/Standard/MatchWholeWord',
 'regex':'Lua/FindReplaceAll/Dark/Standard/RegularExpression',
 'expand':'Shared/Navigation/Dark/Standard/Expand',
 'close':'Shared/Navigation/Dark/Standard/CloseWidget',
}
target=ROOT/'studio_assets.lua'
source=target.read_text(encoding='utf-8')
fixture_path=ROOT/'tests/fixtures/native-ui-assets.json'
fixture=json.loads(fixture_path.read_text())
for name,relative in names.items():
 path=relative+'@3x.png'
 raw=(args.studio/'content/studio_svg_textures'/path).read_bytes()
 assert raw.startswith(b'\x89PNG\r\n\x1a\n')
 width,height=struct.unpack('>II',raw[16:24])
 key='native/editor/'+name
 source=re.sub(r'\n\t\["'+re.escape(key)+r'"\] = "[^"\n]*",','',source)
 literal='"'+''.join('\\'+str(byte).zfill(3) for byte in raw)+'"'
 source=source.replace('\n} }','\n\t["'+key+'"] = '+literal+',\n} }')
 fixture['assets'][key]={'path':path,'sha256':hashlib.sha256(raw).hexdigest(),'width':width,'height':height}
source=re.sub(r'version = "[^"]+"','version = "studio-current-find-assets-v1-20261023"',source,count=1)
target.write_text(source,encoding='utf-8',newline='\n')
fixture_path.write_text(json.dumps(fixture,indent=2)+'\n',encoding='utf-8')
print('Embedded',len(names),'current Studio assets with original pixels and hashes')
