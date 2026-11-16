"""Extract native QIcon theme assets from a verified installed Qt resource table."""
from pathlib import Path
import argparse,hashlib,json,re,struct,zlib

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('executable',type=Path)
parser.add_argument('inventory',type=Path)
args=parser.parse_args()
raw=args.executable.read_bytes()
inventory=json.loads(args.inventory.read_text())
assert hashlib.sha256(raw).hexdigest()==inventory['sourceSHA256']
table=next(t for t in inventory['tables'] if any(r['path'].startswith(':/icons/Dark/Roblox/') for r in t.get('resources',[])))
# qRegisterResourceData call's R9 points to the data array. Name/tree pointers
# in this same registration were independently matched to the decoded table.
registration=next(ref for ref in table['references'] if ref['kind']=='names')
data_base=next(item['targetOffset'] for item in registration['near'] if item['bytes'].startswith('4c8d0d'))
resources={r['path']:r for r in table['resources']}
names={'replace':'Replace','replace_all':'FindAll','previous':'FindPrevious','next':'FindNext',
 'match_case':'MatchCase','whole_word':'MatchWholeWord','regex':'RegularExpression',
 'expand':'Expand','collapse':'Collapse','close':'CloseWidget','submenu':'ArrowRight',
 'completion/text':'ACText','completion/function':'ACFunction','completion/property':'ACProperty',
 'completion/keyword':'ACKeyword','completion/event':'ACEvent','completion/enum':'ACEnum'}
target=ROOT/'studio_assets.lua'
source=target.read_text(encoding='utf-8')
fixture_path=ROOT/'tests/fixtures/native-ui-assets.json'
fixture=json.loads(fixture_path.read_text())
for name,native in names.items():
 path=':/icons/Dark/Roblox/16/3x/'+native+'.png'
 entry=resources[path];offset=data_base+entry['dataRelative']
 size=struct.unpack_from('>I',raw,offset)[0];data=raw[offset+4:offset+4+size]
 assert len(data)==size
 if entry['flags']&1:
  expanded=struct.unpack_from('>I',data)[0];data=zlib.decompress(data[4:]);assert len(data)==expanded
 assert data.startswith(b'\x89PNG\r\n\x1a\n')
 cursor=8
 while cursor<len(data):
  length=struct.unpack_from('>I',data,cursor)[0]
  assert zlib.crc32(data[cursor+4:cursor+8+length])&0xffffffff==struct.unpack_from('>I',data,cursor+8+length)[0]
  cursor+=length+12
 assert cursor==len(data)
 width,height=struct.unpack_from('>II',data,16)
 key='native/editor/'+name
 source=re.sub(r'\n\t\["'+re.escape(key)+r'"\] = "[^"\n]*",','',source)
 literal='"'+''.join('\\'+str(byte).zfill(3) for byte in data)+'"'
 source=source.replace('\n} }','\n\t["'+key+'"] = '+literal+',\n} }')
 fixture['assets'][key]={'path':path,'sha256':hashlib.sha256(data).hexdigest(),'width':width,'height':height,
  'sourceSHA256':inventory['sourceSHA256'],'fileOffset':offset+4,'dataBase':data_base}
source=re.sub(r'version = "[^"]+"','version = "studio-native-completion-v1-20261023"',source,count=1)
target.write_text(source,encoding='utf-8',newline='\n')
fixture_path.write_text(json.dumps(fixture,indent=2)+'\n',encoding='utf-8')
print('Embedded',len(names),'native QIcon theme images; original PNG bytes and CRCs verified')
