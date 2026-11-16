"""Run Input Macros capture and playback checks against mock Roblox signals and input APIs."""
import argparse
import subprocess
import tempfile
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--luau', default='luau')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
fixture = (root / 'tests/macro_engine.spec.luau').read_text()
module = (root / 'src/Apps/InputMacros/MacroEngine.lua').read_text()
code = fixture.replace(
    '-- MACRO MODULE FIXTURE',
    'local MacroModule = (function()\n' + module
    + '\nend)()\nMacroModule.InitDeps({env = {MacroInput = funcs}, service = service})',
)
with tempfile.TemporaryDirectory(prefix='dex-macro-engine-') as folder:
    harness = Path(folder) / 'macro-engine.luau'
    harness.write_text(code, encoding='utf-8')
    subprocess.run([args.luau, str(harness)], check=True)
