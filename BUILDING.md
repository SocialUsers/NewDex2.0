# Build and test Dex

Run these commands from the repo root. `python build.py` also opens an interactive menu.

```powershell
python build.py setup
python build.py test
python build.py build
python build.py output
```

Setup installs Luau, StyLua, and Selene. The build writes `out.lua` by default. Run that file in your executor to try your changes. Use `python build.py watch` to rebuild when you save.

| Path | What lives there |
| --- | --- |
| [main.lua](main.lua) | Startup, settings, and the tool menu |
| [src/Apps](src/Apps) | Individual Dex tools |
| [src/Shared](src/Shared) | Shared UI and runtime code |
| [src/Runtime](src/Runtime) | Module loader |
| [mcp](mcp) | Dex MCP server |
| [tests](tests) | Tests and fixtures |

Give each Luau module a unique filename. To build the modular runtime locally, run `python scripts/package_runtime.py`. Its files go in `dist/github`.

To view performance counters and recent slow frames, call `getgenv().DexPlus.Main.Performance.Snapshot()` in a running Dex session. Slow-frame timings include the entire Roblox client.

## Third-party licenses

- [Luau](docs/LUAU-LICENSE.txt)
- [UniversalSynSaveInstance](docs/USSI-LICENSE.txt)
- [React Lua](src/Packages/React/THIRD_PARTY_NOTICES.md)
- [Luau RegEx](src/Packages/Regex/LICENSE)
