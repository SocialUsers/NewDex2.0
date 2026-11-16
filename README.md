<h1 align="center">Dex Explorer</h1>

<p align="center">An in-game Explorer and toolkit for Roblox.</p>

<p align="center">
  <a href="#run-dex">Run Dex</a> ·
  <a href="docs/mcp/SETUP.md">Dex MCP</a> ·
  <a href="docs/PLUGINS.md">Plugins</a> ·
  <a href="BUILDING.md">Build from source</a>
</p>

## Run Dex

Paste this into your executor while Roblox is open.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wooxps/dex-explorer/main/loader.lua"))()
```

## Tools

- **Explorer and Properties** to browse the hierarchy, select objects, and edit their properties.
- **Script Editor and Find in Place** to read scripts and jump to search results.
- **Asset Manager and 3D Viewer** to browse assets and preview objects.
- **Input Macros** to record and replay input.

Open the Dex menu to switch tools. Right-click an object in Explorer to see its actions.

## Build locally

Run `python build.py build` from the repo folder. The command prints the path to the file you can run locally. See the [build guide](BUILDING.md) for setup and tests.

## Credits

Based on [Dex++ by Chillz](https://github.com/AZYsGithub/DexPlusPlus) and [Moon's Dex](https://github.com/LorekeeperZinnia/Dex). [MIT license](LICENSE).
