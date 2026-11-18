<h1 align="center">
  <img src="docs/dex-cover.png" width="760" alt="Dex Explorer">
</h1>

<p align="center">An in-game Explorer for Roblox</p>

<p align="center">
  <a href="https://luau.org/"><img src="https://img.shields.io/badge/language-Luau-5e6ad2?style=flat-square" alt="Language: Luau"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-64748b?style=flat-square" alt="License: MIT"></a>
  <a href="https://github.com/wooxps/dex-explorer/issues/new"><img src="https://img.shields.io/badge/GitHub-report%20an%20issue-64748b?style=flat-square&amp;logo=github" alt="Report an issue"></a>
</p>

<p align="center">
  <a href="#run-dex"><strong>Run Dex</strong></a>
  &nbsp;·&nbsp;
  <a href="#tools">Tools</a>
  &nbsp;·&nbsp;
  <a href="#performance">Performance</a>
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

## Tools

| Tool | What you can do |
| :--- | :--- |
| **Explorer & Properties** | Search by name, class, or property and edit several objects at once. Right-click to highlight an object, view a player, or find references. |
| **Script Editor** | Write Luau with autocomplete and auto-formatting. Hover for types and docs, or Ctrl-click to open a definition. |
| **Find in Place** | Search scripts, then click a result to open the matching line. Replace text across editor tabs. |
| **Asset Manager** | Preview and download images, sounds, meshes, and animations. Click a reference to select the object that uses an asset. |
| **3D Viewer** | Inspect parts and models in a separate viewport. Orbit, pan, and zoom without moving the game camera. |
| **Selection & Transform** | Pick parts or UI elements on screen, then move, rotate, or resize them. |
| **Console** | Client logs with message filters and a Luau command bar. |
| **Input Macros** | Record keyboard and mouse input, edit delays, adjust playback speed, and loop recordings. **F8** stops recording or playback. |
| **Save Instance** | Export objects with UniversalSynSaveInstance or your executor's `saveinstance`. |
| **Reconstructor** | Build an inferred object tree from script paths and tracebacks. |
| **Plugins** | Add your own tools, right-click actions, and shortcuts. [Plugin guide](docs/PLUGINS.md). |
| **Dex MCP** | Use Dex from Codex or another MCP client. [Setup](docs/mcp/SETUP.md). |

For example, search `is:BasePart and Anchored=false` in Explorer to find unanchored parts.

Script source, downloads, and input playback depend on your executor. Find in Place can only search source available to the client.

## Performance

| Task | Measured time |
| :--- | :--- |
| First Explorer search with 70,000 matches | **1.6 seconds** |
| Repeat the same search with no object changes | **0.04 ms**, compared with **126 ms** in Moon's Dex (**over 1,000× faster**) |
| Eight filter changes across 20,000 assets | **0.06 seconds**, compared with **1.2 seconds** when sorting after every change |
| Update code colors after ten edits in a 10,000-line script | **Under 1 ms** total, compared with about **0.2 seconds** when recoloring the entire file |

<details>
<summary>Test details</summary>

Tested with sample data on an Intel i7-12700H. Times vary by game, executor, and hardware.

First-search, asset-filter, and highlighting times are medians of three runs. Repeat-search times are medians of five batches using the same unchanged tree in both versions.

- [70,000-match search fixture](tests/search_engine.spec.luau)
- [Asset filter test](tests/asset_query.spec.luau)
- [Script highlighting test](tests/editor_highlight_checks.py)

</details>

## Documentation

| Guide | Contents |
| :--- | :--- |
| [Plugins](docs/PLUGINS.md) | Installation, a first plugin, package fields, and the plugin API |
| [Dex MCP](docs/mcp/SETUP.md) | Server setup, pairing, permissions, and troubleshooting |
| [Building](BUILDING.md) | Local builds, tests, source layout, and publishing |

[Report a bug](https://github.com/wooxps/dex-explorer/issues/new) with the steps to reproduce it, your executor, and the error text. For UI bugs, include a screenshot or recording.

## Credits

Developed by [Wooxps](https://github.com/wooxps).

Based on [Dex++ by Chillz](https://github.com/AZYsGithub/DexPlusPlus) and [Moon's Dex](https://github.com/LorekeeperZinnia/Dex). [MIT License](LICENSE).
