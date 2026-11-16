"""Stage development source only; never create or overwrite executor script tabs."""
from pathlib import Path
import shutil
from package_runtime import package, ROOT, OUT

manifest=package()
destination=Path.home()/'AppData/Local/Potassium/workspace/dex/development'
destination.mkdir(parents=True,exist_ok=True)
for path in [*manifest['files'],'manifest.json','src/Runtime/Bootstrap.luau',manifest['bundle']['path'],
             *(part['path'] for part in manifest.get('bundles', []))]:
    target=destination/path
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(OUT/path,target)
print(f'Staged {len(manifest["files"])} source files in the development workspace; executor script tabs were not changed.')
