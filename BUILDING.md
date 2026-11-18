[Readme](README.md) / **Building**

# Building Dex Explorer

You need Git and Python 3. The MCP server has its own [Node.js setup](docs/mcp/SETUP.md).

## Build from source

```powershell
git clone https://github.com/wooxps/dex-explorer.git
cd dex-explorer
python build.py build
```

The build writes `out.lua` by default. Run `python build.py output` to see the configured path or pass a new path to change it.

For the interactive builder, run `python build.py` or double-click `build.bat` on Windows.

## Development commands

Run these from the repo root:

| Command | Action |
| :--- | :--- |
| `python build.py build` | Build `out.lua`. |
| `python build.py watch` | Rebuild when a source file changes. Press Ctrl+C to stop. |
| `python build.py test` | Run the Luau tests and hosted-loader checks. |
| `python build.py check` | Check Luau compilation. |
| `python build.py format --check` | Check formatting without changing files. |
| `python build.py lint` | Check for common code errors. |
| `python build.py setup` | Install Luau, StyLua, and Selene under `.tools/bin`. |

The test command downloads Luau if needed. Tool versions are listed in [tools.lock.json](tools.lock.json).

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

To inspect performance in a running Dex session:

```luau
getgenv().DexPlus.Main.Performance.Snapshot()
```

The report contains Dex counters and recent slow frames. Frame timings cover the whole Roblox client.

## Publishing

For maintainers with push access to `wooxps/dex-explorer`:

```powershell
python scripts/publish_github.py --publish --message "Update Dex"
```

The script runs the tests, commits the source, pins `loader.lua` to that commit, and pushes `main`. Git must already be signed in through Git Credential Manager.

Documentation-only changes can be committed and pushed normally.

## Workspace files

Dex Explorer keeps its settings in `dex-explorer/settings.json` inside the executor workspace. Plugins, macros, layouts, and caches also live under `dex-explorer/`.

<details>
<summary>Migrating from an older version</summary>

If an older Dex build stops at a `ShowAttributes` error after using Dex Explorer, close Roblox and rename `DexSettings.json` in the executor workspace to `DexSettings.backup.json`. Reopen Roblox and start the older Dex again to use its defaults.

To bring over your Dex Explorer data, copy files you want to keep from the old `dex/` folder into `dex-explorer/`. Copy your `.dexplugin` files into `dex-explorer/plugins/`, then install them from the menu. If the backed-up settings came from Dex Explorer, you can copy that file to `dex-explorer/settings.json` while Dex is closed.

</details>

## Third-party licenses

- [Luau](docs/LUAU-LICENSE.txt)
- [UniversalSynSaveInstance](docs/USSI-LICENSE.txt)
- [React Lua](src/Packages/React/THIRD_PARTY_NOTICES.md)
- [Luau RegEx](src/Packages/Regex/LICENSE)

---

[Readme](README.md) · [Plugins](docs/PLUGINS.md) · [Dex MCP](docs/mcp/SETUP.md)
