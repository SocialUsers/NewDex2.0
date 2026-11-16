# Build Dex Explorer

You need Python 3. Run the commands below from the project folder. On Windows, double-click `build.bat` to open the same menu as `python build.py`.

## Build

```powershell
python build.py build
```

The builder prints the path to the build. The default is `out.lua` in the project folder. Run `python build.py output` to see the current path, or pass it a new path to change where builds go.

Use `python build.py watch` to rebuild when you save changes. Press Ctrl+C to stop.

## Run checks

```powershell
python build.py test
```

This runs the Luau tests and checks the hosted loader. It downloads Luau if needed. Run `python build.py setup` to install Luau, StyLua, and Selene under `.tools/bin`. [tools.lock.json](tools.lock.json) lists the versions.

| Command | What it checks |
| --- | --- |
| `python build.py check` | Luau compilation |
| `python build.py format --check` | Formatting |
| `python build.py lint` | Common code errors |

## Source layout

| Path | Contents |
| --- | --- |
| [main.lua](main.lua) | Startup, settings, and the tool menu |
| [src/Apps](src/Apps) | Dex tools |
| [src/Shared](src/Shared) | Shared UI and runtime code |
| [src/Runtime](src/Runtime) | Hosted loader |
| [mcp](mcp) | Dex MCP server |
| [tests](tests) | Tests and fixtures |

Give each `.lua` module under `src` a unique filename. The loader uses the filename without its extension as the module name.

Run `python scripts/package_runtime.py` to generate the hosted files in `dist/github`. This also updates the root `manifest.json`.

In a running Dex session, `getgenv().DexPlus.Main.Performance.Snapshot()` returns counters and recent slow frames. Frame timings cover the whole Roblox client.

## Workspace files

Dex Explorer keeps its settings in `dex-explorer/settings.json` inside the executor workspace. Plugins, macros, layouts, and caches also live under `dex-explorer/`.

If an older Dex build stops at a `ShowAttributes` error after using Dex Explorer, close Roblox and rename the workspace's `DexSettings.json` to `DexSettings.backup.json`. Reopen Roblox and start the older Dex again. This lets it start with its defaults.

To bring over your Dex Explorer data, copy files you want to keep from the old `dex/` folder into `dex-explorer/`. Copy your `.dexplugin` files into `dex-explorer/plugins/`, then install them from the menu. If the backed-up settings came from Dex Explorer, you can copy that file to `dex-explorer/settings.json` while Dex is closed.

## Third-party licenses

- [Luau](docs/LUAU-LICENSE.txt)
- [UniversalSynSaveInstance](docs/USSI-LICENSE.txt)
- [React Lua](src/Packages/React/THIRD_PARTY_NOTICES.md)
- [Luau RegEx](src/Packages/Regex/LICENSE)
