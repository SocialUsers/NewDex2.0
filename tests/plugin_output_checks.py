"""Exercise the plugin output UI with the standard mock Roblox host."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
lib = (root / "src/Shared/Lib.lua").read_text(encoding="utf-8")
studio_text = lib[lib.index("\tLib.StudioText ="):lib.index("\tLib.StudioTooltip =")]
parts = [(root / "tests/roblox_mock.luau").read_text(encoding="utf-8"),
         "Lib.StudioFont = Enum.Font.BuilderSans\n" + studio_text]
for name in ["BridgeUI", "PluginOutput"]:
    source = next((root / "src").rglob(name + ".lua")).read_text(encoding="utf-8")
    parts.append(f"local {name}Control = (function()\n{source}\nend)()")
parts.append((root / "tests/plugin_output.spec.luau").read_text(encoding="utf-8"))
with tempfile.TemporaryDirectory(prefix="dex-plugin-output-") as temp:
    script = Path(temp) / "check.luau"
    script.write_text("\n".join(parts), encoding="utf-8")
    subprocess.run([args.luau, str(script)], check=True)
