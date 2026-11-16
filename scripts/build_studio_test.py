"""Package the canonical modules as a Studio Play Solo model; no loadstring/HTTP."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def quoted(value):
    equals = '='
    while ']' + equals + ']' in value:
        equals += '='
    return '[' + equals + '[' + value + ']' + equals + ']'


def build(studio, api, output):
    # Read canonical sources without changing the live release manifest.
    paths = sorted((ROOT / 'src').rglob('*.lua')) + sorted((ROOT / 'src/Packages').rglob('*.luau'))
    paths += [ROOT / 'main.lua', ROOT / 'studio_assets.lua']
    sources = {p.relative_to(ROOT).as_posix(): p.read_text(encoding='utf8') for p in paths}
    modules = {p.stem: p.relative_to(ROOT).as_posix() for p in paths if p.suffix == '.lua' and p.is_relative_to(ROOT / 'src')}
    main = sources['main.lua']
    replacements = {
        'Main.Elevated = pcall(function()\n\t\t\tlocal a = game:GetService("CoreGui"):GetFullName()\n\t\tend)':
        'Main.Elevated = false -- Studio Play Solo uses PlayerGui',
        'env.loadstring = (pcall(loadstring, "local a = 1") and loadstring)\n\t\t\tor (\n\t\t\t\tgame:GetService("RunService"):IsStudio()\n\t\t\t\tand script.Modules:FindFirstChild("Loadstring")\n\t\t\t\tand require(script.Modules:FindFirstChild("Loadstring"))\n\t\t\t)':
        'env.loadstring = nil -- Studio client cannot execute arbitrary source',
        'Main.GetStudioAsset = function(key)':
        'Main.GetStudioAsset = function(key)\n\t\tif StudioTestAssets[key] then return StudioTestAssets[key] end',
    }
    for before, after in replacements.items():
        assert main.count(before) == 1, 'Studio adapter source anchor changed: ' + before
        main = main.replace(before, after)
    sources['main.lua'] = main
    explorer_path = 'src/Apps/Explorer/Explorer.lua'
    explorer = sources[explorer_path]
    before = 'local getDescendants = game.GetDescendants'
    assert explorer.count(before) == 1
    explorer = explorer.replace(before, '''local function getDescendants(root)
        local readable = {}
        for _,object in ipairs(game:GetDescendants(root)) do
            if StudioTestCanReadInstance(object) then readable[#readable+1]=object end
        end
        return readable
    end''')
    before = 'addObject = function(root)'
    assert explorer.count(before) == 1
    explorer = explorer.replace(before, before + '\n\t\tif not StudioTestCanReadInstance(root) then return end')
    sources[explorer_path] = explorer
    visibility_path = 'src/Apps/Explorer/Services/ServiceVisibility.lua'
    before = 'function Visibility.IsService(object)'
    assert sources[visibility_path].count(before) == 1
    sources[visibility_path] = sources[visibility_path].replace(
        before, before + '\n  if not StudioTestCanReadInstance(object) then return false end')

    # Studio's local content provider supports original PNG files without uploads.
    assets = {}
    asset_folder = studio / 'content/textures/DexPlusStudioTest'
    asset_folder.mkdir(parents=True, exist_ok=True)
    for key, encoded in re.findall(r'\["([^"\n]+)"\]\s*=\s*"((?:\\\d{3})+)"', sources['studio_assets.lua']):
        data = bytes(int(n) for n in re.findall(r'\\(\d{3})', encoded))
        assert data.startswith(b'\x89PNG\r\n\x1a\n'), key
        filename = hashlib.sha256(key.encode()).hexdigest()[:20] + '.png'
        (asset_folder / filename).write_bytes(data)
        assets[key] = 'rbxasset://textures/DexPlusStudioTest/' + filename
    assert len(assets) >= 42, 'Original UI asset extraction incomplete'

    xml = ET.Element('roblox', {'version': '4'})
    counter = 0
    compiled = []
    def instance(parent, class_name, name, source=None):
        nonlocal counter
        counter += 1
        item = ET.SubElement(parent, 'Item', {'class': class_name, 'referent': f'RBX{counter}'})
        props = ET.SubElement(item, 'Properties')
        ET.SubElement(props, 'string', {'name': 'Name'}).text = name
        if source is not None:
            ET.SubElement(props, 'ProtectedString', {'name': 'Source'}).text = source
            compiled.append((name, source))
        return item

    starter = '''-- Insert this LocalScript into StarterPlayer > StarterPlayerScripts, then Play.
local runService = game:GetService("RunService")
assert(runService:IsStudio(), "Dex Explorer Studio test build only runs in Studio")
local player = game:GetService("Players").LocalPlayer
assert(player, "Run this as a LocalScript in Play mode")
local playerGui = player:WaitForChild("PlayerGui")
local factories = script:WaitForChild("Modules")
local host = getfenv()
local shared = {}
local context = setmetatable({game=game,oldgame=game,nodes={},script=script,
    cloneref=function(value) return value end,
    getgenv=function() return shared end,
    gethui=function() return playerGui end,
    StudioTestCanReadInstance=function(object)
        local ok = pcall(function()
            local name, class, parent = object.Name, object.ClassName, object.Parent
            local displayName = tostring(object)
        end)
        return ok
    end,
    StudioTestAssets=ASSETS,
}, {__index=host})
local paths = PATHS
local cache, loaded, loading = {}, {}, {}
local function execute(path)
    if loaded[path] then return cache[path] end
    assert(not loading[path], "Circular Studio dependency: "..path)
    local moduleName = assert(paths[path], "Missing path: "..path)
    local module = assert(factories:FindFirstChild(moduleName), path)
    local factory = require(module)
    local environment = setmetatable({script=module}, {__index=context})
    setfenv(factory, environment)
    loading[path] = true
    local ok, value = pcall(factory)
    loading[path] = nil
    if not ok then error("Dex Explorer Studio: "..path..": "..tostring(value), 0) end
    cache[path], loaded[path] = value, true
    return value
end
context.DexRuntime = {Require=execute}
context.EmbeddedModules = {}
for name,path in pairs(MODULES) do
    local modulePath = path
    context.EmbeddedModules[name] = function() return execute(modulePath) end
end
context.StudioAssetData = execute("studio_assets.lua")
context.ReactVendor = execute("src/Packages/React/Loader.luau")
execute("main.lua")
local viewer = shared.DexPlus and shared.DexPlus.Apps.ScriptViewer
if viewer then viewer.OpenDocument("studio-example", "Studio test.luau", SAMPLE) end
print("[Dex Explorer] Studio test ready. Script execution, OS clipboard, decompilation and file saving require executor capabilities and are unavailable here.")
'''
    def table(values):
        return '{' + ','.join('[' + json.dumps(k) + ']=' + json.dumps(v) for k, v in values.items()) + '}'
    names = {path: 'Module_' + str(index) for index, path in enumerate(sources)}
    sample = '''-- Dex Explorer Studio editor test
-- Try right-click, typing, selection, undo/redo, find and folding.
local function greet(name: string)
    local message = "Hello, " .. name
    print(message)
    return message
end

for index = 1, 5 do
    greet("Studio " .. index)
end
'''
    for key, value in [('ASSETS', table(assets)), ('PATHS', table(names)), ('MODULES', table(modules)), ('SAMPLE', quoted(sample))]:
        starter = starter.replace(key, value)
    local_script = instance(xml, 'LocalScript', 'DexPlusStudioTest', starter)
    folder = instance(local_script, 'Folder', 'Modules')
    for path, source in sources.items():
        wrapped = 'return function()\n' + source + '\nend\n'
        module = instance(folder, 'ModuleScript', names[path], wrapped)
        if path == 'main.lua':
            instance(module, 'ModuleScript', 'API', 'return ' + quoted(api.read_text(encoding='utf8')))
            instance(module, 'ModuleScript', 'RMD', 'return ' + quoted((studio / 'ReflectionMetadata.xml').read_text(encoding='utf8')))
    output.parent.mkdir(parents=True, exist_ok=True)
    compiler = ROOT / '.tools/bin/luau-compile.exe'
    check_dir = ROOT / '.build/studio-test-compile'
    check_dir.mkdir(parents=True, exist_ok=True)
    for index, (name, source) in enumerate(compiled):
        target = check_dir / f'{index}_{name}.luau'
        target.write_text(source, encoding='utf8')
        subprocess.run([str(compiler), str(target)], stdout=subprocess.DEVNULL, check=True)
    # Execute the generated launcher with strict Instance argument contracts.
    # Luau assert returns all its arguments: nesting it in FindFirstChild's
    # final argument position would incorrectly pass its message as recursive.
    smoke = '''local calls = 0
local modules = {}
function modules:FindFirstChild(name, recursive)
    assert(type(name)=="string", "Module name must be a string")
    assert(recursive==nil or type(recursive)=="boolean", "Invalid recursive argument")
    calls += 1
    return {Name=name}
end
script = {WaitForChild=function() return modules end}
local player = {WaitForChild=function() return {} end}
game = {GetService=function(_, name)
    if name=="RunService" then return {IsStudio=function() return true end} end
    if name=="Players" then return {LocalPlayer=player} end
    error("Unexpected launcher service: "..name)
end}
require = function(module)
    assert(type(module)=="table", "Expected module instance")
    return function() return {} end
end
''' + starter + '''
assert(calls==3, "Launcher did not initialize its three entry modules")
assert(context.StudioTestCanReadInstance({Name="Folder",ClassName="Folder"}))
local protectedName = setmetatable({Name="Restricted",ClassName="Service"}, {
    __tostring=function() error("PluginOrOpenCloud required") end,
})
assert(not context.StudioTestCanReadInstance(protectedName), "Protected display name was admitted")
local protectedProperties = setmetatable({}, {__index=function() error("Restricted property") end})
assert(not context.StudioTestCanReadInstance(protectedProperties), "Protected properties were admitted")
'''
    smoke_path = check_dir / 'launcher-smoke.luau'
    smoke_path.write_text(smoke, encoding='utf8')
    subprocess.run([str(ROOT / '.tools/bin/luau.exe'), str(smoke_path)], check=True)
    ET.indent(xml)
    ET.ElementTree(xml).write(output, encoding='utf-8', xml_declaration=True)
    parsed = ET.parse(output)
    assert len(parsed.findall('.//ProtectedString')) == len(compiled)
    print(f'Built {output}: {len(sources)} runtime files, {len(compiled)} compiled scripts, {len(assets)} original local images')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--studio-dir', type=Path, required=True)
    parser.add_argument('--api', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/studio/DexPlusStudioTest.rbxmx')
    args = parser.parse_args()
    build(args.studio_dir, args.api, args.output)
