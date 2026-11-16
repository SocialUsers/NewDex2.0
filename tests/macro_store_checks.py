from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--luau', default='luau')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / 'src/Apps/InputMacros/MacroStore.lua').read_text(encoding='utf-8')
fixture = (root / 'tests/macro_store.spec.luau').read_text(encoding='utf-8')
with tempfile.TemporaryDirectory(prefix='dex-macro-store-') as directory:
    script = Path(directory) / 'check.luau'
    script.write_text(fixture.replace('-- PRODUCTION', source), encoding='utf-8')
    subprocess.run([args.luau, str(script)], check=True)
