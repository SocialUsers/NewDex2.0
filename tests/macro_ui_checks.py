from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--luau', default='luau')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
fixture = (root / 'tests/macro_ui.spec.luau').read_text(encoding='utf-8')
for token, path in {
    '-- BRIDGE_UI': 'src/Apps/AIBridge/Components/BridgeUI.lua',
    '-- INPUT_MACROS': 'src/Apps/InputMacros/InputMacros.lua',
}.items():
    fixture = fixture.replace(token, (root / path).read_text(encoding='utf-8'))
mock = (root / 'tests/roblox_mock.luau').read_text(encoding='utf-8')
lib = (root / 'src/Shared/Lib.lua').read_text(encoding='utf-8')
fixture = fixture.replace('-- WINDOW_CLOSE', lib[lib.index('\t\tfuncs.Close ='):lib.index('\t\tfuncs.Destroy =')])
with tempfile.TemporaryDirectory(prefix='dex-macro-ui-') as folder:
    harness = Path(folder) / 'macro_ui.luau'
    harness.write_text(mock + '\n' + fixture, encoding='utf-8')
    subprocess.run([args.luau, str(harness)], check=True)
