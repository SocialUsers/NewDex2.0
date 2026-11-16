"""Dex Explorer build/development utility.

No third-party Python packages are required. Optional native developer tools are
installed into .tools/bin by `python build.py setup` and are never required on
PATH globally.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

BUILDER_VERSION = "2.5.4"
ROOT = Path(__file__).resolve().parent
MODULES_DIR = ROOT / "src"
OUT = ROOT / "out.lua"
BUILD_DIR = ROOT / ".build"
TOOLS_DIR = ROOT / ".tools"
TOOLS_BIN = TOOLS_DIR / "bin"
DIST_DIR = ROOT / "dist"
LOCK_FILE = ROOT / "tools.lock.json"
SETTINGS_FILE = TOOLS_DIR / "builder-settings.json"
CACHE_FILE = BUILD_DIR / "cache.json"
MANIFEST_FILE = BUILD_DIR / "manifest.json"

REQUIRED_INPUTS = [ROOT / "header.lua", ROOT / "studio_assets.lua", ROOT / "main.lua"]
IGNORED_TOP_LEVEL = {".git", ".tools", ".build", "dist", "__pycache__"}

HELPER_NAMES = {
    "luau": "test support",
    "stylua": "code formatter",
    "selene": "code checker",
}


def _enable_terminal_features() -> None:
    if os.name != "nt" or not sys.stdout.isatty():
        return
    try:
        import ctypes

        kernel32 = ctypes.windll.kernel32
        handle = kernel32.GetStdHandle(-11)
        mode = ctypes.c_uint32()
        if kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
            kernel32.SetConsoleMode(handle, mode.value | 0x0004)
        kernel32.SetConsoleTitleW(f"Dex Explorer Builder {BUILDER_VERSION}")
    except Exception:
        try:
            os.system("")
        except Exception:
            pass

class C:
    """Terminal palette. Uses no third-party packages and degrades cleanly."""

    enabled = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None
    reset = "\033[0m" if enabled else ""
    bold = "\033[1m" if enabled else ""
    dim = "\033[2m" if enabled else ""
    white = "\033[97m" if enabled else ""
    gray = "\033[90m" if enabled else ""
    green = "\033[38;2;52;211;153m" if enabled else ""
    yellow = "\033[38;2;251;191;36m" if enabled else ""
    red = "\033[38;2;248;113;113m" if enabled else ""
    cyan = "\033[38;2;34;211;238m" if enabled else ""
    accent = "\033[38;2;217;119;87m" if enabled else ""
    accent2 = "\033[38;2;236;171;147m" if enabled else ""
    selected = "\033[48;2;46;42;40m" if enabled else ""


def _unicode_ok() -> bool:
    if os.environ.get("DEX_ASCII") == "1":
        return False
    encoding = getattr(sys.stdout, "encoding", None) or "utf-8"
    try:
        "╭─│╰✓●›".encode(encoding)
        return True
    except (UnicodeEncodeError, LookupError):
        return False


UNICODE_UI = _unicode_ok()
GLYPH_OK = "✓" if UNICODE_UI else "+"
GLYPH_WARN = "!"
GLYPH_FAIL = "✕" if UNICODE_UI else "x"
GLYPH_INFO = "→" if UNICODE_UI else ">"


def ok(msg: str) -> None:
    print(f"{C.green}{GLYPH_OK}{C.reset} {msg}")


def warn(msg: str) -> None:
    print(f"{C.yellow}{GLYPH_WARN}{C.reset} {msg}")


def fail(msg: str) -> None:
    print(f"{C.red}{GLYPH_FAIL}{C.reset} {msg}", file=sys.stderr)


def info(msg: str) -> None:
    print(f"{C.cyan}{GLYPH_INFO}{C.reset} {msg}")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def human_size(n: int) -> str:
    units = ["B", "KB", "MB", "GB"]
    value = float(n)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.1f} {unit}" if unit != "B" else f"{int(value)} B"
        value /= 1024
    return f"{n} B"


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.replace(temp_name, path)
    finally:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass


def read_json(path: Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def write_json(path: Path, data) -> None:
    atomic_write(path, (json.dumps(data, indent=2, sort_keys=True) + "\n").encode("utf-8"))


def _same_path(a: Path, b: Path) -> bool:
    try:
        return a.resolve(strict=False) == b.resolve(strict=False)
    except OSError:
        return os.path.abspath(str(a)) == os.path.abspath(str(b))


def selected_output() -> Path:
    """Return the actual build destination selected by the user.

    ``out.lua`` is only the default. Once a custom destination is selected, that
    file becomes the sole build artifact used by build status, checks, watch mode,
    and release packaging.
    """
    settings = read_json(SETTINGS_FILE, {})
    raw = settings.get("output_file")
    if not isinstance(raw, str) or not raw.strip():
        return OUT

    expanded = os.path.expandvars(os.path.expanduser(raw.strip()))
    path = Path(expanded)
    if not path.is_absolute():
        path = ROOT / path
    return path.resolve(strict=False)


def _output_display(path: Path | None = None) -> str:
    path = path or selected_output()
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def _validate_output_target(path: Path) -> None:
    target = path.resolve(strict=False)

    if path.exists() and path.is_dir():
        raise ValueError("The output needs to be a file, not a folder.")

    # out.lua is intentionally allowed because it is the normal internal target.
    protected = {Path(__file__).resolve(strict=False), LOCK_FILE.resolve(strict=False)}
    protected.update(src.resolve(strict=False) for src in source_files())
    if target in protected and target != OUT.resolve(strict=False):
        raise ValueError("That path is one of the project source files. Choose a different output file.")


def save_selected_output(path: Path) -> Path:
    target = path.resolve(strict=False)
    _validate_output_target(target)

    settings = read_json(SETTINGS_FILE, {})
    if _same_path(target, OUT):
        settings.pop("output_file", None)
    else:
        settings["output_file"] = str(target)
    write_json(SETTINGS_FILE, settings)
    return target


def modules() -> list[Path]:
    return sorted(MODULES_DIR.rglob("*.lua"), key=lambda p: p.name.lower())


def source_files() -> list[Path]:
    return [ROOT / "header.lua", *modules(), *sorted((ROOT / "src/Packages").rglob("*.luau")), ROOT / "studio_assets.lua", ROOT / "main.lua"]


def offline_react_source() -> str:
    package_root = ROOT / "src/Packages/React"
    driver = package_root / "Loader.luau"
    notices = (package_root / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
    parts = ["--[====[\n", notices, "\n]====]\nlocal DexRuntime = (function()\nlocal factories = {\n"]
    for path in sorted(package_root.glob("*.luau")):
        if path == driver:
            continue
        parts += [f'[{json.dumps(path.relative_to(ROOT).as_posix())}]=function()\n', path.read_text(encoding="utf-8"), "\nend,\n"]
    parts += ['}\nlocal cache={}\nreturn {Require=function(path)\nif not cache[path] then cache[path]=assert(factories[path],path)() end\nreturn cache[path]\nend}\nend)()\nlocal ReactVendor=(function()\n', driver.read_text(encoding="utf-8"), "\nend)()\n"]
    return "".join(parts)


def validate_layout() -> list[str]:
    errors: list[str] = []
    for path in REQUIRED_INPUTS:
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(ROOT)}")
    if not MODULES_DIR.is_dir():
        errors.append("missing src/ directory")
    mods = modules() if MODULES_DIR.is_dir() else []
    if not mods:
        errors.append("no src/**/*.lua files found")
    lowered: dict[str, str] = {}
    for path in mods:
        key = path.stem.lower()
        if key in lowered:
            errors.append(f"module name collision: {lowered[key]} and {path.name}")
        lowered[key] = path.name
        if path.stat().st_size == 0:
            errors.append(f"empty module: {path.name}")
    return errors


def make_output() -> tuple[bytes, list[str]]:
    errors = validate_layout()
    if errors:
        raise RuntimeError("\n".join(errors))
    parts: list[str] = [(ROOT / "header.lua").read_text(encoding="utf-8"), "\n", offline_react_source(), "\n\nlocal EmbeddedModules = {\n"]
    names: list[str] = []
    for module in modules():
        names.append(module.stem)
        parts += [f'["{module.stem}"] = function()\n', module.read_text(encoding="utf-8"), "\nend,\n"]
    parts += ["}\nlocal StudioAssetData = (function()\n", (ROOT / "studio_assets.lua").read_text(encoding="utf-8"), "\nend)()\n", (ROOT / "main.lua").read_text(encoding="utf-8")]
    return "".join(parts).encode("utf-8"), names


def fingerprint(paths: Iterable[Path]) -> str:
    h = hashlib.sha256()
    for path in paths:
        rel = path.relative_to(ROOT).as_posix().encode()
        h.update(len(rel).to_bytes(4, "little"))
        h.update(rel)
        data = path.read_bytes()
        h.update(len(data).to_bytes(8, "little"))
        h.update(data)
    return h.hexdigest()


def build(force: bool = False, quiet: bool = False) -> Path:
    started = time.perf_counter()
    data, module_names = make_output()
    src_fingerprint = fingerprint(source_files())
    cache = read_json(CACHE_FILE, {})
    target = selected_output()
    _validate_output_target(target)

    expected_hash = sha256_bytes(data)
    changed = force or not target.exists() or sha256_file(target) != expected_hash

    # The selected file is the real build output. ``out.lua`` is only used when
    # it is the selected/default destination; custom outputs are not mirrored.
    if changed:
        atomic_write(target, data)

    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    cache.update(
        {
            "source_fingerprint": src_fingerprint,
            "output_sha256": expected_hash,
            "builder_version": BUILDER_VERSION,
            "selected_output": str(target),
        }
    )
    write_json(CACHE_FILE, cache)
    manifest = {
        "builder_version": BUILDER_VERSION,
        "source_fingerprint": src_fingerprint,
        "output_sha256": expected_hash,
        "output_bytes": len(data),
        "output_file": str(target),
        "modules": module_names,
        "module_count": len(module_names),
    }
    write_json(MANIFEST_FILE, manifest)

    if not quiet:
        elapsed = (time.perf_counter() - started) * 1000
        state = "Built" if changed else "Up to date"
        ok(f"{state}: {_output_display(target)} ({human_size(len(data))}, {len(module_names)} modules, {elapsed:.0f} ms)")
    return target


def platform_key() -> str:
    sysname = platform.system().lower()
    machine = platform.machine().lower()
    if sysname == "windows":
        os_name = "windows"
    elif sysname == "darwin":
        os_name = "macos"
    elif sysname == "linux":
        os_name = "linux"
    else:
        os_name = sysname
    arch = "x86_64" if machine in {"amd64", "x86_64"} else "arm64" if machine in {"arm64", "aarch64"} else machine
    return f"{os_name}-{arch}"


def exe_name(name: str) -> str:
    return name + (".exe" if os.name == "nt" else "")


def load_tool_lock() -> dict:
    if not LOCK_FILE.exists():
        raise RuntimeError("tools.lock.json is missing")
    return json.loads(LOCK_FILE.read_text(encoding="utf-8"))


def tool_path(name: str) -> Path | None:
    """Return the builder-managed copy of a helper program.

    Dex Explorer intentionally does not use same-named programs from PATH by
    default. Package managers such as Aftman can expose shims that only work
    when a project-specific manifest is present, which makes a tool look
    installed even though it cannot actually run here. Keeping helper programs
    in .tools/bin also makes builds reproducible across machines.

    Advanced users can opt into PATH fallback with DEX_USE_SYSTEM_TOOLS=1.
    """
    local = TOOLS_BIN / exe_name(name)
    if local.is_file():
        return local

    if os.environ.get("DEX_USE_SYSTEM_TOOLS") == "1":
        found = shutil.which(name)
        return Path(found) if found else None

    return None


def run(
    cmd: list[str | Path],
    *,
    check: bool = True,
    cwd: Path = ROOT,
    label: str | None = None,
) -> subprocess.CompletedProcess:
    if label:
        info(label)
    elif os.environ.get("DEX_VERBOSE") == "1":
        info(" ".join(str(x) for x in cmd))
    return subprocess.run([str(x) for x in cmd], cwd=cwd, check=check)


def download_file(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": "DexExplorer-Builder/2"})
    with urllib.request.urlopen(request, timeout=60) as response, dest.open("wb") as f:
        total = int(response.headers.get("Content-Length") or 0)
        done = 0
        last_pct = -1
        while True:
            block = response.read(1024 * 256)
            if not block:
                break
            f.write(block)
            done += len(block)
            if total and sys.stdout.isatty():
                pct = int(done * 100 / total)
                if pct != last_pct:
                    width = 28
                    filled = min(width, int(width * pct / 100))
                    full, empty = ("━", "─") if UNICODE_UI else ("#", "-")
                    bar = full * filled + empty * (width - filled)
                    print(
                        f"\r    {C.accent}{bar}{C.reset}  {pct:3d}%  "
                        f"{human_size(done):>8} / {human_size(total):<8}",
                        end="",
                        flush=True,
                    )
                    last_pct = pct
        if total and sys.stdout.isatty():
            print()


def install_tool_package(tool: str, force: bool = False) -> bool:
    lock = load_tool_lock()
    spec = lock["tools"].get(tool)
    if not spec:
        fail(f"Unknown helper program: {tool}")
        return False
    key = platform_key()
    package = spec.get("platforms", {}).get(key)
    if not package:
        warn(f"{HELPER_NAMES.get(tool, tool)} is not available automatically for this computer")
        return False
    expected_execs = [TOOLS_BIN / exe_name(x) for x in package["executables"]]
    if not force and all(x.exists() for x in expected_execs):
        ok(f"{HELPER_NAMES.get(tool, tool).capitalize()} is already installed")
        return True

    TOOLS_BIN.mkdir(parents=True, exist_ok=True)
    cache_dir = TOOLS_DIR / "downloads"
    cache_dir.mkdir(parents=True, exist_ok=True)
    archive = cache_dir / package["filename"]
    info(f"Installing {HELPER_NAMES.get(tool, tool)}…")
    try:
        if force or not archive.exists() or sha256_file(archive) != package["sha256"]:
            temp = archive.with_suffix(archive.suffix + ".part")
            temp.unlink(missing_ok=True)
            download_file(package["url"], temp)
            digest = sha256_file(temp)
            if digest.lower() != package["sha256"].lower():
                temp.unlink(missing_ok=True)
                raise RuntimeError(f"checksum mismatch: expected {package['sha256']}, got {digest}")
            os.replace(temp, archive)
        else:
            ok(f"Using verified cached {archive.name}")

        with zipfile.ZipFile(archive) as zf:
            wanted = {exe_name(x).lower(): x for x in package["executables"]}
            extracted = set()
            for member in zf.infolist():
                base = Path(member.filename).name.lower()
                if base not in wanted or member.is_dir():
                    continue
                target = TOOLS_BIN / exe_name(wanted[base])
                with zf.open(member) as src:
                    atomic_write(target, src.read())
                if os.name != "nt":
                    target.chmod(target.stat().st_mode | 0o111)
                extracted.add(wanted[base])
            missing = set(package["executables"]) - extracted
            if missing:
                raise RuntimeError(f"archive did not contain: {', '.join(sorted(missing))}")
        write_json(TOOLS_DIR / f"{tool}.json", {"version": spec["version"], "platform": key, "sha256": package["sha256"]})
        ok(f"{HELPER_NAMES.get(tool, tool).capitalize()} installed")
        return True
    except Exception as exc:
        fail(f"Could not install {HELPER_NAMES.get(tool, tool)}: {exc}")
        return False


def setup_tools(names: list[str], force: bool = False) -> bool:
    results = [install_tool_package(name, force=force) for name in names]
    return all(results)


def ensure_tools(names: list[str], auto_install: bool) -> dict[str, Path]:
    result: dict[str, Path] = {}
    package_for = {"luau": "luau", "luau-compile": "luau", "luau-analyze": "luau", "stylua": "stylua", "selene": "selene"}
    missing_packages = []
    for name in names:
        path = tool_path(name)
        if path:
            result[name] = path
        else:
            pkg = package_for[name]
            if pkg not in missing_packages:
                missing_packages.append(pkg)
    if missing_packages and auto_install:
        setup_tools(missing_packages)
        for name in names:
            path = tool_path(name)
            if path:
                result[name] = path
    return result


def lua_sources(include_tests: bool = False) -> list[Path]:
    """Return files that are valid as standalone Luau compilation units.

    Most tests/*.luau files are intentionally *fragments*: run_checks.py joins
    them with Roblox mocks and selected production code to build the smoke-test
    harness. Compiling those fragments by themselves produces fake syntax
    errors (for example docking_mock.luau opens a block that docking.spec.luau
    closes). The full test suite still executes all of those fragments.
    """
    paths = [ROOT / "header.lua", ROOT / "main.lua", *modules()]
    target = selected_output()
    if target.exists():
        paths.append(target)
    if include_tests:
        # These are the standalone tests. The .luau files are harness fragments
        # and are validated when `run all checks` assembles and executes them.
        paths += sorted((ROOT / "tests").glob("*.lua"))
    return paths


def compile_check(auto_install: bool = True, include_tests: bool = True) -> bool:
    build(quiet=True)
    tools = ensure_tools(["luau-compile"], auto_install)
    compiler = tools.get("luau-compile")
    if not compiler:
        fail("Test support is missing. Run `py build.py` and choose Check setup.")
        return False
    started = time.perf_counter()
    files = lua_sources(include_tests=include_tests)
    errors = 0
    info(f"Checking {len(files)} standalone Luau files…")
    for path in files:
        proc = subprocess.run([str(compiler), str(path)], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        if proc.returncode:
            errors += 1
            fail(f"compile failed: {_output_display(path)}")
            if proc.stderr:
                print(proc.stderr.rstrip())
    if errors:
        fail(f"{errors} file(s) failed to compile")
        return False
    ok(f"No compile errors found in {len(files)} files ({(time.perf_counter()-started):.2f}s)")
    return True


def run_tests(auto_install: bool = True) -> bool:
    tools = ensure_tools(["luau", "luau-compile"], auto_install)
    if "luau" not in tools or "luau-compile" not in tools:
        fail("Test support is missing. Run `py build.py` and choose Check setup.")
        return False
    cmd = [sys.executable, ROOT / "tests" / "run_checks.py", "--luau", tools["luau"], "--compiler", tools["luau-compile"]]
    try:
        run(cmd, label="Running all checks…")
        run([sys.executable, ROOT / "tests" / "runtime_checks.py"], label="Checking hosted module loader…")

        # run_checks.py validates the project source tree. A custom output may
        # live outside that tree, so compile the actual selected build too.
        target = selected_output()
        subprocess.run(
            [str(tools["luau-compile"]), str(target)],
            cwd=ROOT,
            stdout=subprocess.DEVNULL,
            check=True,
        )
        ok("All checks passed")
        return True
    except subprocess.CalledProcessError as exc:
        fail(f"Checks failed with exit code {exc.returncode}")
        return False


def format_sources(auto_install: bool = True, check_only: bool = False) -> bool:
    tools = ensure_tools(["stylua"], auto_install)
    stylua = tools.get("stylua")
    if not stylua:
        fail("Formatting support is missing. Run `py build.py` and choose Check setup.")
        return False
    files = [ROOT / "header.lua", ROOT / "main.lua", *modules()]
    cmd = [stylua, "--syntax", "luau"]
    if check_only:
        cmd += ["--check"]
    cmd += files
    try:
        run(cmd, label="Checking formatting…" if check_only else "Formatting code…")
        ok("Formatting looks good" if check_only else f"Formatted {len(files)} source files")
        return True
    except subprocess.CalledProcessError:
        fail("Formatting needs attention")
        return False


def lint_sources(auto_install: bool = True) -> bool:
    tools = ensure_tools(["selene"], auto_install)
    selene = tools.get("selene")
    if not selene:
        fail("Code issue checker is missing. Run `py build.py` and choose Check setup.")
        return False
    files = [ROOT / "header.lua", ROOT / "main.lua", *modules()]
    config = ROOT / "selene.toml"
    if not config.exists():
        fail("The code checker settings are missing. Re-extract Dex Explorer or restore selene.toml.")
        return False

    # Always pass the project config explicitly. This keeps Selene in Luau/Roblox
    # mode even when the user has a different global Selene/Aftman setup.
    try:
        run([selene, "--config", config, *files], label="Looking for common code mistakes…")
        ok("No common code problems found")
        return True
    except subprocess.CalledProcessError:
        fail("Some code problems were found")
        return False


def benchmark() -> bool:
    script = ROOT / "tests" / "benchmark_search.py"
    if not script.exists():
        fail("Search speed test is missing")
        return False

    tools = ensure_tools(["luau"], auto_install=True)
    luau = tools.get("luau")
    if not luau:
        fail("Search speed test support could not be installed")
        return False

    try:
        run([sys.executable, script, "--luau", luau], label="Running search speed test…")
        ok("Search speed test finished")
        return True
    except subprocess.CalledProcessError:
        fail("Speed test failed")
        return False


def stats() -> None:
    target = build(quiet=True)
    rows = []
    for p in source_files():
        text = p.read_text(encoding="utf-8", errors="replace")
        rows.append((p.relative_to(ROOT).as_posix(), text.count("\n") + 1, p.stat().st_size))
    print(f"{C.bold}Project details{C.reset}")
    for name, lines, size in rows:
        print(f"  {name:<28} {lines:>7,} lines  {human_size(size):>9}")
    output_label = _output_display(target)
    output_text = target.read_text(encoding="utf-8", errors="replace")
    print(f"  {output_label:<28} {output_text.count(chr(10))+1:>7,} lines  {human_size(target.stat().st_size):>9}")
    print(f"\n  Modules: {len(modules())}")
    print(f"  Build output: {output_label}")
    print(f"  Output SHA-256: {sha256_file(target)}")


def create_zip(path: Path, entries: list[tuple[Path, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.unlink(missing_ok=True)
    with zipfile.ZipFile(temp, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for src, arcname in sorted(entries, key=lambda x: x[1].lower()):
            data = src.read_bytes()
            zi = zipfile.ZipInfo(arcname, date_time=(2026, 1, 1, 0, 0, 0))
            zi.compress_type = zipfile.ZIP_DEFLATED
            zi.external_attr = (0o644 & 0xFFFF) << 16
            zf.writestr(zi, data)
    os.replace(temp, path)


def source_package_entries() -> list[tuple[Path, str]]:
    entries = []
    for p in ROOT.rglob("*"):
        if not p.is_file():
            continue
        rel = p.relative_to(ROOT)
        if rel.parts and rel.parts[0] in IGNORED_TOP_LEVEL:
            continue
        if any(part == "__pycache__" for part in rel.parts):
            continue
        entries.append((p, f"Dex Explorer/{rel.as_posix()}"))
    return entries


def release(run_test: bool = True, auto_install: bool = True) -> bool:
    built_output = build(force=True)
    if run_test and not run_tests(auto_install=auto_install):
        fail("Release aborted because tests failed")
        return False
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    release_lua = DIST_DIR / "DexExplorer.lua"
    atomic_write(release_lua, built_output.read_bytes())
    release_manifest = {
        "builder_version": BUILDER_VERSION,
        "sha256": sha256_file(release_lua),
        "bytes": release_lua.stat().st_size,
        "modules": [p.stem for p in modules()],
    }
    write_json(DIST_DIR / "manifest.json", release_manifest)
    release_entries = [(release_lua, "DexExplorer.lua"), (DIST_DIR / "manifest.json", "manifest.json")]
    for optional in [ROOT / "README.md", ROOT / "LICENSE"]:
        if optional.exists():
            release_entries.append((optional, optional.name))
    create_zip(DIST_DIR / "DexExplorer-release.zip", release_entries)
    create_zip(DIST_DIR / "DexExplorer-source.zip", source_package_entries())
    ok(f"Release ready in {DIST_DIR.relative_to(ROOT)}/")
    print(f"  DexExplorer.lua         {human_size(release_lua.stat().st_size)}")
    print(f"  DexExplorer-release.zip {human_size((DIST_DIR/'DexExplorer-release.zip').stat().st_size)}")
    print(f"  DexExplorer-source.zip  {human_size((DIST_DIR/'DexExplorer-source.zip').stat().st_size)}")
    return True


def clean(remove_tools: bool = False) -> None:
    for p in [BUILD_DIR, DIST_DIR]:
        if p.exists():
            shutil.rmtree(p)
            ok(f"Removed {p.name}/")
    for p in ROOT.rglob("__pycache__"):
        if TOOLS_DIR in p.parents:
            continue
        shutil.rmtree(p, ignore_errors=True)
    if remove_tools and TOOLS_DIR.exists():
        shutil.rmtree(TOOLS_DIR)
        ok("Removed .tools/")


def snapshot_watch_files() -> dict[str, tuple[int, int]]:
    candidates = source_files() + [Path(__file__), LOCK_FILE, SETTINGS_FILE]
    return {str(p): (p.stat().st_mtime_ns, p.stat().st_size) for p in candidates if p.exists()}


def watch(auto_test: bool = False, auto_check: bool = False, interval: float = 0.35) -> None:
    build()
    previous = snapshot_watch_files()
    info("Watching source files. Press Ctrl+C to stop.")
    try:
        while True:
            time.sleep(max(0.1, interval))
            current = snapshot_watch_files()
            if current == previous:
                continue
            changed = sorted(set(previous) | set(current), key=str)
            changed = [p for p in changed if previous.get(p) != current.get(p)]
            previous = current
            print()
            info("Changed: " + ", ".join(Path(p).relative_to(ROOT).as_posix() for p in changed if Path(p).exists() or p in previous))
            try:
                build(force=True)
                if auto_check:
                    compile_check(auto_install=True)
                if auto_test:
                    run_tests(auto_install=True)
            except Exception as exc:
                fail(str(exc))
    except KeyboardInterrupt:
        print()
        ok("Watch stopped")


def get_version(path: Path, args: list[str] | None = None) -> str:
    commands = [args or ["--version"], ["-v"], []]
    for suffix in commands:
        try:
            proc = subprocess.run([str(path), *suffix], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=5)
            line = (proc.stdout or "").strip().splitlines()
            if line:
                return line[0][:120]
        except Exception:
            pass
    return "installed"


def doctor(fix: bool = False) -> bool:
    print(f"{C.bold}Checking the project{C.reset}")
    print(f"{C.dim}Looking for anything that could stop the builder from working.{C.reset}")
    print()
    good = True
    errors = validate_layout()
    if errors:
        good = False
        for e in errors:
            fail(e)
    else:
        ok(f"Project files look good ({len(modules())} modules)")

    lock = load_tool_lock()
    helper_messages = {
        "luau": {
            "ready": "Tests are ready",
            "installing": "Tests need a small download — installing it now",
            "missing": "Tests are not ready yet",
            "unsupported": "Tests cannot be set up automatically on this computer",
            "primary": "luau",
        },
        "stylua": {
            "ready": "Code formatting is ready",
            "installing": "Code formatting needs a small download — installing it now",
            "missing": "Code formatting is not ready yet",
            "unsupported": "Code formatting cannot be set up automatically on this computer",
            "primary": "stylua",
        },
        "selene": {
            "ready": "Code issue checker is ready",
            "installing": "Code issue checker needs a small download — installing it now",
            "missing": "Code issue checker is not ready yet",
            "unsupported": "Code issue checker cannot be set up automatically on this computer",
            "primary": "selene",
        },
    }
    for package in ["luau", "stylua", "selene"]:
        messages = helper_messages[package]
        spec = lock["tools"][package]
        path = tool_path(messages["primary"])
        if path:
            ok(messages["ready"])
            continue

        supported = platform_key() in spec.get("platforms", {})
        if supported and fix:
            info(messages["installing"])
            if not install_tool_package(package):
                good = False
        elif supported:
            warn(messages["missing"] + " — choose Check setup")
            good = False
        else:
            warn(messages["unsupported"])
            good = False


    try:
        build(quiet=True)
        ok("DeX builds successfully")
    except Exception as exc:
        fail(f"DeX could not be built: {exc}")
        good = False

    if tool_path("luau-compile"):
        if not compile_check(auto_install=False, include_tests=False):
            good = False
    else:
        warn("Code error checks will be available after the missing setup items are fixed")

    print()
    if good:
        ok("Your setup is ready")
    else:
        warn("Some setup items still need attention")
    return good


def list_project() -> None:
    print("Modules (embedded alphabetically):")
    for i, p in enumerate(modules(), 1):
        print(f"  {i:02d}. {p.name:<22} {human_size(p.stat().st_size):>9}")
    print("\nBuild order:")
    print(f"  header.lua -> EmbeddedModules -> studio_assets.lua -> main.lua -> {_output_display(selected_output())}")


def _terminal_width() -> int:
    # Keep the interface narrow and conversational instead of stretching to the
    # full terminal width. This also makes it look consistent in cmd, PowerShell,
    # Windows Terminal, VS Code, and smaller terminals.
    return max(58, min(82, shutil.get_terminal_size((72, 28)).columns))


def _clear_screen() -> None:
    if not sys.stdout.isatty():
        return
    if C.enabled:
        print("\033[2J\033[H", end="", flush=True)
    elif os.name == "nt":
        os.system("cls")
    else:
        print("\033[2J\033[H", end="", flush=True)


def _hide_cursor() -> None:
    if C.enabled and sys.stdout.isatty():
        print("\033[?25l", end="", flush=True)


def _show_cursor() -> None:
    if C.enabled and sys.stdout.isatty():
        print("\033[?25h", end="", flush=True)


def _truncate(text: str, width: int) -> str:
    if len(text) <= width:
        return text
    if width <= 1:
        return text[:width]
    return text[: width - 1] + ("…" if UNICODE_UI else ".")


def _plain_len(text: str) -> int:
    import re
    return len(re.sub(r"\x1b\[[0-9;]*m", "", text))


def _project_menu_status() -> tuple[str, str, str]:
    errors = validate_layout()
    if errors:
        return GLYPH_FAIL, C.red, "Project needs attention"

    target = selected_output()
    if not target.exists():
        return GLYPH_WARN, C.yellow, "Build needed"

    try:
        cache = read_json(CACHE_FILE, {})
        current = fingerprint(source_files())
        expected_hash = cache.get("output_sha256")
        fresh = (
            bool(expected_hash)
            and cache.get("source_fingerprint") == current
            and sha256_file(target) == expected_hash
        )
        if not expected_hash:
            expected, _ = make_output()
            fresh = sha256_file(target) == sha256_bytes(expected)
    except Exception:
        fresh = False

    if fresh:
        return GLYPH_OK, C.green, "Ready"
    return GLYPH_WARN, C.yellow, "Changes need building"


def _missing_builder_extras() -> int:
    ready = [
        tool_path("luau") is not None and tool_path("luau-compile") is not None,
        tool_path("stylua") is not None,
        tool_path("selene") is not None,
    ]
    return sum(1 for value in ready if not value)


@dataclass(frozen=True)
class MenuItem:
    title: str
    description: str
    action: object | None = None
    key: str = ""
    kind: str = "action"  # action | more | back


def _read_menu_key() -> str:
    """Read a single key without requiring Enter in an interactive terminal."""
    if not sys.stdin.isatty():
        try:
            return input().strip().lower()
        except EOFError:
            return "escape"

    if os.name == "nt":
        import msvcrt

        ch = msvcrt.getwch()
        if ch in ("\x00", "\xe0"):
            code = msvcrt.getwch()
            return {"H": "up", "P": "down", "K": "left", "M": "right", "G": "home", "O": "end"}.get(code, "")
        if ch == "\r":
            return "enter"
        if ch == "\x1b":
            return "escape"
        if ch in ("\x08", "\x7f"):
            return "backspace"
        if ch == "\x03":
            raise KeyboardInterrupt
        return ch

    import termios
    import tty

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == "\x03":
            raise KeyboardInterrupt
        if ch in ("\r", "\n"):
            return "enter"
        if ch in ("\x08", "\x7f"):
            return "backspace"
        if ch == "\x1b":
            import select
            # Arrow keys arrive as ESC + [ + letter. A short timeout keeps a
            # normal Escape press responsive instead of waiting for more input.
            if not select.select([sys.stdin], [], [], 0.06)[0]:
                return "escape"
            second = sys.stdin.read(1)
            if second != "[":
                return "escape"
            if not select.select([sys.stdin], [], [], 0.06)[0]:
                return "escape"
            third = sys.stdin.read(1)
            return {"A": "up", "B": "down", "C": "right", "D": "left", "H": "home", "F": "end"}.get(third, "")
        return ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


def _wait_for_return() -> None:
    print()
    print(f"  {C.dim}Enter to go back{C.reset}", end="", flush=True)
    if not sys.stdin.isatty():
        try:
            input()
        except EOFError:
            pass
        return
    while True:
        if _read_menu_key() in {"enter", "escape"}:
            break
    print()


def _confirm(question: str, default: bool = False) -> bool:
    suffix = "Y/n" if default else "y/N"
    try:
        answer = input(f"  {C.accent}{question}{C.reset} {C.dim}({suffix}){C.reset} ").strip().lower()
    except EOFError:
        return default
    if not answer:
        return default
    return answer in {"y", "yes"}


def _configure_output_file() -> bool:
    current = selected_output()

    print(f"  {C.dim}Current output{C.reset}")
    print(f"  {C.white}{current}{C.reset}")
    print()
    print(f"  {C.dim}Press Enter to keep the current value. Type 'default' to use out.lua in the project folder.{C.reset}")
    print()

    try:
        folder_text = input(f"  {C.accent}Folder{C.reset} [{current.parent}]: ").strip()
        name_text = input(f"  {C.accent}File name{C.reset} [{current.name}]: ").strip()
    except (EOFError, KeyboardInterrupt):
        print()
        warn("No changes made")
        return False

    if folder_text.lower() == "default" or name_text.lower() == "default":
        target = OUT
    else:
        folder_raw = folder_text.strip().strip('"') if folder_text else str(current.parent)
        name = name_text.strip().strip('"') if name_text else current.name

        if not name:
            fail("File name cannot be empty")
            return False
        if "/" in name or "\\" in name:
            fail("Put the folder in the Folder field and only the file name in File name.")
            return False
        if Path(name).suffix == "":
            name += ".lua"

        expanded_folder = os.path.expandvars(os.path.expanduser(folder_raw))
        folder = Path(expanded_folder)
        if not folder.is_absolute():
            folder = ROOT / folder
        target = (folder / name).resolve(strict=False)

    try:
        target = save_selected_output(target)
    except (OSError, ValueError) as exc:
        fail(str(exc))
        return False

    print()
    ok(f"Build output set to {_output_display(target)}")
    if not _same_path(target, OUT):
        print(f"  {C.dim}Future builds will write only to this output file; out.lua is no longer required.{C.reset}")
    return True


def _menu_clean() -> bool:
    if not _confirm("Delete generated build and release files?"):
        print(f"  {C.dim}Nothing was deleted.{C.reset}")
        return True
    clean()
    return True


def _action_screen(item: MenuItem) -> None:
    _clear_screen()
    print()
    mark = "✻" if UNICODE_UI else "*"
    print(f"  {C.accent}{mark}{C.reset} {C.bold}{item.title}{C.reset}")
    print(f"    {C.dim}{item.description}{C.reset}")
    print()


def _run_menu_item(item: MenuItem) -> None:
    _show_cursor()
    _action_screen(item)
    started = time.perf_counter()
    success = True
    try:
        result = item.action() if item.action else True
        if result is False:
            success = False
    except KeyboardInterrupt:
        print()
        warn("Stopped")
        success = False
    except Exception as exc:
        fail(str(exc))
        success = False

    elapsed = time.perf_counter() - started
    print()
    if success:
        print(f"  {C.green}{GLYPH_OK}{C.reset} {C.bold}Finished{C.reset} {C.dim}in {elapsed:.2f}s{C.reset}")
    else:
        print(f"  {C.red}{GLYPH_FAIL}{C.reset} {C.bold}Needs attention{C.reset} {C.dim}· {elapsed:.2f}s{C.reset}")
    _wait_for_return()


def _menu_header(*, submenu: bool = False) -> None:
    width = _terminal_width()
    mark = "✻" if UNICODE_UI else "*"
    cwd = str(ROOT)
    if len(cwd) > width - 6:
        cwd = "…" + cwd[-(width - 7):] if UNICODE_UI else "..." + cwd[-(width - 9):]

    print()
    print(f"  {C.accent}{mark}{C.reset} {C.bold}Dex Explorer{C.reset} {C.dim}v{BUILDER_VERSION}{C.reset}")
    print(f"    {C.dim}{cwd}{C.reset}")

    if not submenu:
        mark_status, color, status = _project_menu_status()
        print()
        print(f"  {color}{mark_status}{C.reset} {status}", end="")
        target = selected_output()
        if target.exists() and status == "Ready":
            print(f" {C.dim}· {target.name} is current{C.reset}")
        elif status == "Changes need building":
            print(f" {C.dim}· source files changed{C.reset}")
        elif status == "Build needed":
            print(f" {C.dim}· {target.name} has not been created yet{C.reset}")
        else:
            print()

        if not _same_path(target, OUT):
            shown = _truncate(str(target), width - 14)
            print(f"    {C.dim}Output · {shown}{C.reset}")



def _filtered_items(items: list[MenuItem], query: str) -> list[MenuItem]:
    if not query:
        return items
    needle = query.casefold().strip()
    if not needle:
        return items
    return [item for item in items if needle in item.title.casefold() or needle in item.description.casefold()]


def _render_menu(items: list[MenuItem], selected: int, query: str, *, submenu: bool = False) -> list[MenuItem]:
    _hide_cursor()
    _clear_screen()
    width = _terminal_width()
    _menu_header(submenu=submenu)

    print()
    if submenu:
        print(f"  {C.bold}More options{C.reset}")
        print(f"  {C.dim}Less common project tools.{C.reset}")
    else:
        print(f"  {C.bold}What would you like to do?{C.reset}")

    if query:
        print()
        print(f"  {C.dim}Filter:{C.reset} {C.white}{query}{C.reset}{C.accent}_{C.reset}")

    visible = _filtered_items(items, query)
    print()
    if not visible:
        print(f"    {C.dim}No matches. Backspace to change your filter.{C.reset}")
    else:
        selected = max(0, min(selected, len(visible) - 1))
        for i, item in enumerate(visible):
            active = i == selected
            pointer = "❯" if UNICODE_UI else ">"
            prefix = f"{C.accent}{pointer}{C.reset}" if active else " "
            title = f"{C.bold}{C.white}{item.title}{C.reset}" if active else item.title
            if item.kind == "back":
                title = f"{C.dim}{item.title}{C.reset}" if not active else f"{C.bold}{item.title}{C.reset}"
            print(f"  {prefix} {title}")

    print()
    if visible:
        item = visible[max(0, min(selected, len(visible) - 1))]
        print(f"    {C.dim}{'↳ ' if UNICODE_UI else '- '}{_truncate(item.description, width - 10)}{C.reset}")
    else:
        print()

    print()
    if query:
        footer = "↑↓ select   Enter open   Backspace edit   Esc clear"
    elif submenu:
        footer = "↑↓ select   Enter open   type to filter   Esc back"
    else:
        footer = "↑↓ select   Enter open   type to filter   Esc exit"
    print(f"  {C.dim}{footer}{C.reset}")
    return visible


def _pick_from_menu(items: list[MenuItem], *, submenu: bool = False) -> tuple[str, MenuItem | None]:
    selected = 0
    query = ""
    while True:
        visible = _render_menu(items, selected, query, submenu=submenu)
        try:
            key = _read_menu_key()
        except KeyboardInterrupt:
            return "exit", None

        if key == "escape":
            if query:
                query = ""
                selected = 0
                continue
            return ("back" if submenu else "exit"), None
        if key in {"left"} and submenu and not query:
            return "back", None
        if key == "up" and visible:
            selected = (selected - 1) % len(visible)
            continue
        if key == "down" and visible:
            selected = (selected + 1) % len(visible)
            continue
        if key == "home" and visible:
            selected = 0
            continue
        if key == "end" and visible:
            selected = len(visible) - 1
            continue
        if key == "backspace":
            if query:
                query = query[:-1]
                selected = 0
            continue
        if key == "enter":
            if visible:
                return "select", visible[max(0, min(selected, len(visible) - 1))]
            continue

        # Printable text becomes a live filter, matching the feel of modern
        # terminal pickers without adding another prompt or dependency.
        if len(key) == 1 and key.isprintable() and not key.isspace():
            query += key
            selected = 0
            continue
        if key == " " and query:
            query += " "
            selected = 0


def interactive_menu() -> int:
    main_items = [
        MenuItem("Build output", "Build the latest source into your chosen output file.", lambda: build() or True, "build"),
        MenuItem("Choose output file…" if UNICODE_UI else "Choose output file...", "Choose the file name and folder used when you build.", _configure_output_file, "output"),
        MenuItem("Watch for changes", "Watch your files and rebuild automatically whenever you save.", lambda: watch() or True, "watch"),
        MenuItem("Run all checks", "Build DeX and run the full test suite to catch breakages.", run_tests, "test"),
        MenuItem("Create a release", "Run the checks and package files that are ready to share.", release, "release"),
        MenuItem("Check setup", "Find setup problems and automatically fix anything the builder is missing.", lambda: doctor(fix=True), "fix"),
        MenuItem("More options…" if UNICODE_UI else "More options...", "Formatting, code checks, speed testing, project details, and cleanup.", None, "more", "more"),
    ]

    more_items = [
        MenuItem("Check code for errors", "Check DeX and the standalone tests for syntax or compile errors.", compile_check, "errors"),
        MenuItem("Format code", "Clean up spacing and code layout automatically.", format_sources, "format"),
        MenuItem("Check formatting", "See whether code formatting needs changes without editing any files.", lambda: format_sources(check_only=True), "format-check"),
        MenuItem("Look for common mistakes", "Scan the source for suspicious code and common mistakes.", lint_sources, "lint"),
        MenuItem("Run search speed test", "Measure Explorer search performance.", benchmark, "speed"),
        MenuItem("Project details", "Show build size, module count, and other project information.", lambda: stats() or True, "info"),
        MenuItem("Files included in the build", "Show which modules are packed into DeX and in what order.", lambda: list_project() or True, "files"),
        MenuItem("Clean generated files", "Remove temporary build files and old release output.", _menu_clean, "clean"),
        MenuItem("Back", "Return to the main menu.", None, "back", "back"),
    ]

    try:
        while True:
            status, item = _pick_from_menu(main_items, submenu=False)
            if status == "exit" or item is None:
                _clear_screen()
                return 0

            if item.kind != "more":
                _run_menu_item(item)
                continue

            while True:
                status, sub_item = _pick_from_menu(more_items, submenu=True)
                if status in {"back", "exit"} or sub_item is None or sub_item.kind == "back":
                    break
                _run_menu_item(sub_item)
    finally:
        _show_cursor()

def make_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Build, test, and package Dex Explorer")
    p.add_argument("--version", action="version", version=f"Dex Explorer builder {BUILDER_VERSION}")
    sub = p.add_subparsers(dest="command")

    b = sub.add_parser("build", help="Build your latest changes to the selected output file")
    b.add_argument("--force", action="store_true")

    w = sub.add_parser("watch", help="Keep building while you edit")
    w.add_argument("--test", action="store_true", help="run full tests after each successful rebuild")
    w.add_argument("--check", action="store_true", help="compile-check after each successful rebuild")
    w.add_argument("--interval", type=float, default=0.35)

    d = sub.add_parser("doctor", help="Check setup and fix problems")
    d.add_argument("--fix", action="store_true", help="install anything that is missing")

    s = sub.add_parser("setup", help="Install anything the builder is missing")
    s.add_argument("--tools", nargs="+", choices=["luau", "stylua", "selene"], default=["luau", "stylua", "selene"])
    s.add_argument("--force", action="store_true", help="redownload and reinstall")

    t = sub.add_parser("test", help="Run all checks")
    t.add_argument("--no-install", action="store_true", help="do not auto-install missing tools")

    ch = sub.add_parser("check", help="Check code for errors")
    ch.add_argument("--no-install", action="store_true")
    ch.add_argument("--source-only", action="store_true")

    f = sub.add_parser("format", help="Automatically clean up code formatting")
    f.add_argument("--check", action="store_true", help="show formatting problems without changing files")
    f.add_argument("--no-install", action="store_true")

    l = sub.add_parser("lint", help="Look for common code mistakes")
    l.add_argument("--no-install", action="store_true")

    r = sub.add_parser("release", help="Test and create files ready to share")
    r.add_argument("--skip-tests", action="store_true")
    r.add_argument("--no-install", action="store_true")

    cl = sub.add_parser("clean", help="Delete generated files")
    cl.add_argument("--tools", action="store_true", help="also remove installed helper programs")

    o = sub.add_parser("output", help="Show or change the build output file")
    o.add_argument("path", nargs="?", help="full file path, for example C:\\Builds\\Dex.lua")
    o.add_argument("--reset", action="store_true", help="use the default out.lua in the project folder")

    sub.add_parser("benchmark", help="Measure Explorer search speed")
    sub.add_parser("stats", help="Show project size and build details")
    sub.add_parser("list", help="Show files included in the build")
    sub.add_parser("menu", help="Open the menu")
    return p


def main(argv: list[str] | None = None) -> int:
    _enable_terminal_features()
    if argv is None:
        argv = sys.argv[1:]
    if not argv:
        return interactive_menu()
    args = make_parser().parse_args(argv)
    command = args.command
    try:
        if command == "build":
            build(force=getattr(args, "force", False))
        elif command == "watch":
            watch(args.test, args.check, args.interval)
        elif command == "doctor":
            return 0 if doctor(args.fix) else 1
        elif command == "setup":
            return 0 if setup_tools(args.tools, args.force) else 1
        elif command == "test":
            return 0 if run_tests(auto_install=not args.no_install) else 1
        elif command == "check":
            return 0 if compile_check(auto_install=not args.no_install, include_tests=not args.source_only) else 1
        elif command == "format":
            return 0 if format_sources(auto_install=not args.no_install, check_only=args.check) else 1
        elif command == "lint":
            return 0 if lint_sources(auto_install=not args.no_install) else 1
        elif command == "release":
            return 0 if release(run_test=not args.skip_tests, auto_install=not args.no_install) else 1
        elif command == "clean":
            clean(remove_tools=args.tools)
        elif command == "output":
            if args.reset:
                target = save_selected_output(OUT)
                ok(f"Build output reset to {_output_display(target)}")
            elif args.path:
                raw = os.path.expandvars(os.path.expanduser(args.path.strip().strip('"')))
                target = Path(raw)
                if not target.is_absolute():
                    target = ROOT / target
                if target.suffix == "":
                    target = target.with_suffix(".lua")
                target = save_selected_output(target)
                ok(f"Build output set to {_output_display(target)}")
            else:
                print(selected_output())
        elif command == "benchmark":
            return 0 if benchmark() else 1
        elif command == "stats":
            stats()
        elif command == "list":
            list_project()
        elif command == "menu":
            return interactive_menu()
        return 0
    except KeyboardInterrupt:
        print()
        warn("Cancelled")
        return 130
    except Exception as exc:
        fail(str(exc))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
