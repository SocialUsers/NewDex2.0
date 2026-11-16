"""Build the hosted release from the canonical source files (stdlib only).

The bootstrap pin is replaced with the source commit by publish_github.py.
"""
from pathlib import Path
import hashlib
import json
import shutil
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'dist' / 'github'


def package():
    OUT.mkdir(parents=True, exist_ok=True)
    modules = {}
    for path in sorted((ROOT / 'src').rglob('*.lua')):
        if path.stem in modules:
            raise ValueError(f'Duplicate module name {path.stem}: {modules[path.stem]} and {path}')
        modules[path.stem] = path.relative_to(ROOT).as_posix()
    files = {}
    inputs = [ROOT / p for p in modules.values()] + list((ROOT/'src/Packages').rglob('*.luau')) + [ROOT / 'main.lua', ROOT / 'studio_assets.lua']
    for source in inputs:
        path = source.relative_to(ROOT).as_posix()
        # Match .gitattributes: GitHub serves LF even on Windows checkouts.
        data = source.read_bytes().replace(b'\r\n', b'\n')
        files[path] = {'bytes': len(data), 'checksum': zlib.adler32(data), 'sha256': hashlib.sha256(data).hexdigest()}
        target = OUT / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    identity = hashlib.sha256(json.dumps(files, sort_keys=True).encode()).hexdigest()[:20]
    manifest = {'schema': 1, 'release': identity, 'entry': 'main.lua', 'assets': 'studio_assets.lua', 'react': 'src/Packages/React/Loader.luau', 'modules': modules, 'files': files}
    (ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    # Transport stays separate from source layout and per-module cache identity.
    packet = json.dumps({'release': identity, 'files': {
        path: (OUT/path).read_text(encoding='utf-8') for path in files
    }}, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    (OUT/'runtime.json').write_bytes(packet)
    manifest['bundle'] = {'path': 'runtime.json', 'bytes': len(packet),
                          'checksum': zlib.adler32(packet), 'sha256': hashlib.sha256(packet).hexdigest()}
    # Balance by bytes, so a large React package cannot serialize the other files.
    groups = [[] for _ in range(4)]
    sizes = [0]*4
    for path in sorted(files, key=lambda name: files[name]['bytes'], reverse=True):
        group = min(range(4), key=lambda index: sizes[index])
        groups[group].append(path)
        sizes[group] += files[path]['bytes']
    manifest['bundles'] = []
    for index, paths in enumerate(groups):
        data = json.dumps({'release': identity, 'files': {
            path: (OUT/path).read_text(encoding='utf-8') for path in paths
        }}, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
        path = f'runtime-{index}.json'
        (OUT/path).write_bytes(data)
        manifest['bundles'].append({'path': path, 'paths': paths, 'bytes': len(data),
                                   'checksum': zlib.adler32(data), 'sha256': hashlib.sha256(data).hexdigest()})
    manifest_text = json.dumps(manifest, indent=2)+'\n'
    (OUT / 'manifest.json').write_text(manifest_text, encoding='utf-8')
    bootstrap = ROOT / 'src' / 'Runtime' / 'Bootstrap.luau'
    dest = OUT / bootstrap.relative_to(ROOT)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(bootstrap, dest)
    return manifest


def loader(ref):
    assert len(ref) == 40 and all(c in '0123456789abcdef' for c in ref)
    return '''--!strict

local ref="'''+ref+'''"
local base="https://raw.githubusercontent.com/wooxps/dex-explorer/"..ref.."/"
local path="dex-explorer/runtime/"..ref..".lua"
local chunk
if type(readfile)=="function" then
 local ok,data=pcall(readfile,path)
 if ok and type(data)=="string" and #data>0 then
  local compiled,value=pcall(loadstring,data,"@DexExplorer/Bootstrap")
  if compiled and type(value)=="function" then chunk=value end
 end
end
if not chunk then
 local data=game:HttpGet(base.."src/Runtime/Bootstrap.luau")
 assert(type(data)=="string" and #data>0,"Dex Explorer bootstrap download returned no source")
 local problem
 chunk,problem=loadstring(data,"@DexExplorer/Bootstrap")
 assert(chunk,"Dex Explorer bootstrap failed: "..tostring(problem))
 if type(makefolder)=="function" then pcall(makefolder,"dex-explorer") pcall(makefolder,"dex-explorer/runtime") end
 if type(writefile)=="function" then pcall(writefile,path,data) end
end
return chunk()(base)
'''


if __name__ == '__main__':
    manifest = package()
    print(f"Packaged {len(manifest['files'])} files, {sum(f['bytes'] for f in manifest['files'].values()):,} bytes; release {manifest['release']}")
