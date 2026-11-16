from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'src/Apps/Console/Console.lua').read_text(encoding='utf-8')
fixture = (ROOT / 'tests/console_performance_fixture.luau').read_text(encoding='utf-8')
with tempfile.TemporaryDirectory() as directory:
    script = Path(directory) / 'check.luau'
    script.write_text(fixture.replace('-- PRODUCTION', source), encoding='utf-8')
    subprocess.run([str(ROOT / '.tools/bin/luau.exe'), str(script)], check=True)
