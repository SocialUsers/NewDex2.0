"""Fetch pinned Wally packages and emit an offline Luau module-tree bundle."""
from pathlib import Path
import hashlib
import io
import json
import re
import tomllib
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / 'vendor' / 'react'
PINS = {'jsdotlua/react': '17.2.1', 'jsdotlua/react-roblox': '17.2.1',
        'jsdotlua/luau-polyfill': '1.2.7', 'jsdotlua/symbol-luau': '1.0.1'}

def get(url):
    request = urllib.request.Request(url, headers={'Wally-Version': '0.3.2'})
    with urllib.request.urlopen(request, timeout=45) as response:
        return response.read()

def fetch_packages():
    queue = [('jsdotlua/react', '17.2.1'), ('jsdotlua/react-roblox', '17.2.1')]
    packages = {}
    while queue:
        name, version = queue.pop(0)
        if name in packages:
            continue
        version = PINS.get(name, version)
        blob = get(f'https://api.wally.run/v1/package-contents/{name}/{version}')
        folder = VENDOR / name.replace('/', '__')
        folder.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(io.BytesIO(blob)) as archive:
            for member in archive.infolist():
                target = (folder / member.filename).resolve()
                if not target.is_relative_to(folder.resolve()):
                    raise RuntimeError('Unsafe archive path')
            archive.extractall(folder)
        config = tomllib.loads((folder / 'wally.toml').read_text())
        packages[name] = {'version': version, 'archive_sha256': hashlib.sha256(blob).hexdigest(),
                          'dependencies': config.get('dependencies', {})}
        for dependency in config.get('dependencies', {}).values():
            dep_name, constraint = dependency.split('@')
            found = re.search(r'\d+\.\d+\.\d+', constraint)
            if not found:
                raise RuntimeError(f'Unresolved version {dependency}')
            queue.append((dep_name, PINS.get(dep_name, found.group(0))))
        print(f'{name}@{version}', flush=True)
    (VENDOR / 'lock.json').write_text(json.dumps(packages, indent=2))

def bundle():
    packages = json.loads((VENDOR / 'lock.json').read_text())
    factories = []
    aliases = {}
    for name, info in sorted(packages.items()):
        folder = VENDOR / name.replace('/', '__')
        project = json.loads((folder / 'default.project.json').read_text()) if (folder / 'default.project.json').exists() else None
        source_root = folder / project['tree']['$path'] if project else folder
        if not any(source_root.rglob('*.lua')) and not any(source_root.rglob('*.luau')) and (folder / 'init.lua').exists():
            source_root = folder
        package_id = name.split('/')[-1]
        for source in sorted(source_root.rglob('*')):
            if source.suffix not in ('.lua', '.luau') or '.spec.' in source.name:
                continue
            relative = source.relative_to(source_root)
            components = list(relative.parts)
            stem = source.stem
            components[-1] = stem
            if stem == 'init':
                components.pop()
            module_id = '/'.join([package_id, *components])
            factories.append((module_id, source.read_text(encoding='utf-8-sig')))
        for alias, spec in info['dependencies'].items():
            actual = spec.split('@')[0].split('/')[-1]
            if alias != actual:
                aliases[alias] = actual
    notices = ['Third-party React Lua packages. Original copyright and license notices follow.']
    for name, info in sorted(packages.items()):
        license_path = VENDOR / name.replace('/', '__') / 'LICENSE'
        if license_path.exists():
            notices.extend([f'\n{name}@{info["version"]}\n', license_path.read_text(encoding='utf-8')])
    apache = VENDOR / 'Apache-2.0.txt'
    if apache.exists():
        notices.extend(['\nApache-2.0 license for source files marked with that license\n', apache.read_text()])
    notice = '\n'.join(notices)
    (VENDOR / 'THIRD_PARTY_NOTICES.md').write_text(notice, encoding='utf-8')
    lines = ['-- Generated from pinned Wally packages; see vendor/react/lock.json.\n',
             '--[====[\n'+notice+'\n]====]\n',
             'local ReactVendor = (function()\nlocal factories = {}\n']
    for name, source in factories:
        lines.extend([f'factories[{json.dumps(name)}] = function()\n', source, '\nend\n'])
    lines.append('''
local nodes, cache, loading = {}, {}, {}
local methods = {}
function methods:WaitForChild(name)
    local child = self[name]
    assert(child, "Missing bundled React module " .. self.Path .. "/" .. name)
    return child
end
function methods:FindFirstChild(name) return rawget(self, name) end
function methods:GetFullName() return self.Path end
local function node(path)
    if nodes[path] then return nodes[path] end
    local parentPath, name = path:match("^(.*)/([^/]+)$")
    name = name or path
    local value = setmetatable({Name=name, Path=path}, {__index=methods})
    nodes[path] = value
    if parentPath then value.Parent=node(parentPath) value.Parent[name]=value
    elseif path~="" then value.Parent=node("") value.Parent[name]=value end
    return value
end
for path in pairs(factories) do node(path) end
''')
    for alias, actual in aliases.items():
        lines.append(f'node("")[{json.dumps(alias)}] = node({json.dumps(actual)})\n')
    lines.append('''
local function bundledRequire(module)
    if type(module)=="string" then module=node(module) end
    local path=module.Path
    if cache[path]~=nil then return cache[path] end
    assert(not loading[path], "Circular React dependency " .. path)
    local factory=factories[path]
    assert(factory, "No React module factory " .. path)
    loading[path]=true
    setfenv(factory,setmetatable({script=module,require=bundledRequire},{__index=getfenv()}))
    local ok, result=pcall(factory)
    loading[path]=nil
    if not ok then error(result,2) end
    cache[path]=result
    return result
end
return {require=bundledRequire, versions={React="17.2.1", ReactRoblox="17.2.1"}}
end)()
''')
    (ROOT / 'react_vendor.lua').write_text(''.join(lines), encoding='utf-8')
    print(f'Bundled {len(factories)} modules', flush=True)

if __name__ == '__main__':
    if not (VENDOR / 'lock.json').exists():
        fetch_packages()
    bundle()
