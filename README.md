<h1 align="center">Dex Explorer</h1>

<p align="center">An in-game Explorer for Roblox</p>

<p align="center">
  <a href="#run-dex"><strong>Quick Start</strong></a> ·
  <a href="#tools">Tools</a> ·
  <a href="#documentation">Documentation</a> ·
  <a href="LICENSE">MIT License</a>
</p>

## Run Dex

With Roblox open, paste this into your executor.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wooxps/dex-explorer/main/loader.lua"))()
```

Open the Dex menu to switch tools. Right-click an object in Explorer to see its actions.

## Tools

| Tool | What you can do |
| :--- | :--- |
| Explorer & Properties | Browse the hierarchy and edit object properties. |
| Script Editor & Find in Place | Read scripts, search across them, and jump to a match. |
| Asset Manager & 3D Viewer | Browse assets and preview objects. |
| Input Macros | Record and replay input. |

## Documentation

- [Dex MCP](docs/mcp/SETUP.md) for connecting an MCP client.
- [Plugins](docs/PLUGINS.md) for installing or writing plugins.
- [Building](BUILDING.md) for running Dex from source and testing changes.

<details>
<summary>Build locally</summary>

From the repository folder, run:

```sh
python build.py build
```

The build prints the path to the output file.

</details>

## Credits

Based on [Dex++ by Chillz](https://github.com/AZYsGithub/DexPlusPlus) and [Moon's Dex](https://github.com/LorekeeperZinnia/Dex). Released under the [MIT License](LICENSE).
