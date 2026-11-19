<p align="center">
  <img src="docs/dex-cover.png" width="760" alt="Dex Explorer">
</p>

<p align="center">An in-game Explorer for Roblox</p>

<p align="center">
  <a href="https://luau.org/"><img src="https://img.shields.io/badge/language-Luau-5e6ad2?style=flat-square" alt="Language: Luau"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-64748b?style=flat-square" alt="License: MIT"></a>
</p>

<p align="center">
  <a href="#run-dex"><strong>Run Dex</strong></a>
  &nbsp;·&nbsp;
  <a href="docs/USAGE.md">User guide</a>
  &nbsp;·&nbsp;
  <a href="docs/PLUGINS.md">Plugins</a>
  &nbsp;·&nbsp;
  <a href="docs/mcp/SETUP.md">Dex MCP</a>
</p>

## Run Dex

Paste this into your executor.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wooxps/dex-explorer/main/loader.lua"))()
```

<p align="center">
  <a href="docs/explorer-preview.webp">
    <img src="docs/explorer-preview.webp" width="760" alt="Explorer search results and the Properties panel in Roblox">
  </a>
</p>

## Features

- [Explorer and Properties](docs/USAGE.md#explorer-and-properties) with searches by class or property, editing several objects at once, and actions such as highlighting objects or viewing players.
- [Script Editor](docs/USAGE.md#script-editor) with Luau autocomplete, types and docs on hover, formatting, and navigation to definitions.
- [Find in Place](docs/USAGE.md#find-in-place) to search scripts and open a result at its line.
- [Asset Manager and 3D Viewer](docs/USAGE.md#assets-and-3d-previews) to preview assets, download them, and see where they're used.
- [Save Instance](docs/USAGE.md#save-instance) with UniversalSynSaveInstance by default and an option to use the executor's version.
- [Input Macros](docs/USAGE.md#input-macros) to record and replay keyboard and mouse input, with speed, timing, and loop controls.
- [Plugins](docs/PLUGINS.md) for adding tools, menu actions, and shortcuts.
- [Dex MCP](docs/mcp/SETUP.md) for using Dex from Codex and other MCP clients.

Also includes [Transform Tools](docs/USAGE.md#transform-tools), a [Console](docs/USAGE.md#console), and a [Reconstructor](docs/USAGE.md#reconstructor).

## Performance

Local scan benchmarks with 60,600 simulated objects:

| Search | Before | After | Less time |
| :--- | ---: | ---: | ---: |
| Cold scan | 72.1 ms | 61.0 ms | **15%** |
| New search using an existing tree | 44.6 ms | 40.6 ms | **9%** |
| Filtered scan, with two thirds of the tree hidden | 63.2 ms | 19.6 ms | **69%** |

<details>
<summary>Benchmark details</summary>

Median of nine runs per version, alternating between [7bf94c1](https://github.com/wooxps/dex-explorer/commit/7bf94c1e83d2) and [7293899](https://github.com/wooxps/dex-explorer/commit/7293899c2d84) in one Luau process.

Measured locally on an Intel Core i7-12700H.

These measure time spent scanning and building results in the Luau CLI. Sorting, frame waits and UI rendering are excluded. They do not measure full search time or FPS in Roblox.

The filtered test hides 400 of 600 branches. Results vary by game, executor, hardware and how much of the tree is visible.

[Run the benchmark](BUILDING.md#performance-reports) · [Benchmark source](tests/benchmark_explorer_scan.py)

</details>

## Documentation

- [User guide](docs/USAGE.md)
- [Installing and writing plugins](docs/PLUGINS.md)
- [Dex MCP setup](docs/mcp/SETUP.md)
- [Building from source](BUILDING.md)

## Help

[Report a bug](https://github.com/wooxps/dex-explorer/issues/new) with the steps to reproduce it, your executor, and the error text. For UI bugs, include a screenshot or recording.

## Credits

Developed by [Wooxps](https://github.com/wooxps).

Based on [Dex++ by Chillz](https://github.com/AZYsGithub/DexPlusPlus) and [Moon's Dex](https://github.com/LorekeeperZinnia/Dex). [MIT License](LICENSE).
