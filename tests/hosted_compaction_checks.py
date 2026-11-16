"""Prove hosted compaction preserves bytecode, constants and debug line tables."""
import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from compact_hosted_source import compact

cli=argparse.ArgumentParser()
cli.add_argument('--compiler',default=str(ROOT/'.tools/bin/luau-compile.exe'))
args=cli.parse_args()
fixtures=[
 'local x="-- not a comment" -- trim me\n return x',
 'local s=[=[\n    keep indentation\n-- keep this text\n]=]\nreturn s',
 '--!strict\n-- Copyright fixture\nlocal a=1--[=[inline\ncomment]=]+2\nreturn a',
 'return `interpolation {1 + 2}` -- left untouched',
 'return "a\\\n    b"',
]
sources=[p for p in (ROOT/'src').rglob('*') if p.suffix in ('.lua','.luau')]+[ROOT/'main.lua']
def compile_file(path):
 return subprocess.check_output([args.compiler,'--binary','-g1',str(path)])
saved=0
with tempfile.TemporaryDirectory(prefix='dex-compact-') as directory:
 original=Path(directory)/'original.luau'
 reduced=Path(directory)/'reduced.luau'
 for name,text in [(str(p.relative_to(ROOT)),p.read_text(encoding='utf-8')) for p in sources]+[('fixture',s) for s in fixtures]:
  result=compact(text)
  assert result.count('\n')==text.count('\n'),name
  original.write_text(text,encoding='utf-8',newline='\n')
  reduced.write_text(result,encoding='utf-8',newline='\n')
  assert compile_file(original)==compile_file(reduced),name+' changed bytecode or debug lines'
  saved+=len(text.encode())-len(result.encode())
print(f'PASS: {len(sources)} hosted sources retain identical bytecode/constants/debug lines; {saved:,} source bytes removed')
