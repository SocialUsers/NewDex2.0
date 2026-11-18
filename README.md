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

Dex Explorer builds on Dex++ with a Studio-style interface, a Luau editor, custom plugins, and MCP support.

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
| **Explorer & Properties** | Search by name, class, or property. Edit multiple objects, find references, and use object-specific right-click actions. |
| **Script Editor** | Edit Luau with autocomplete, type information, formatting, and Ctrl-click navigation to definitions. |
| **Find in Place** | Search across scripts and open matches at their line. Replace matches in editor tabs. |
| **Asset Manager** | Preview and download images, sounds, meshes, and animations. Jump to the objects that use them. |
| **3D Viewer** | Inspect parts and models in a separate viewport. Orbit, pan, and zoom without moving the game camera. |
| **Selection & Transform** | Pick parts or UI elements on screen, then move, rotate, or resize them. |
| **Console** | Read client output, filter messages, and run Luau from the command bar. |
| **Input Macros** | Record keyboard and mouse input, edit delays, adjust playback speed, and loop recordings. **F8** stops recording or playback. |
| **Save Instance** | Export objects with UniversalSynSaveInstance or your executor's `saveinstance`. |
| **Reconstructor** | Build an inferred object tree from script paths and tracebacks. |
| **Plugins** | Add your own tools, menu actions, and keyboard shortcuts. [Plugin guide](docs/PLUGINS.md). |
| **Dex MCP** | Give an MCP client access to Dex tools, object inspection, client logs, and Luau execution. [Setup](docs/mcp/SETUP.md). |

For example, search `is:BasePart and Anchored=false` in Explorer to find unanchored parts.

Script source, downloads, and input playback depend on your executor. Find in Place can only search source available to the client.

## Performance

| Task | Measured time |
| :--- | :--- |
| First Explorer search with 70,000 matches | **1.6 seconds** |
| Repeat the same search | **0.04 ms**, compared with **126 ms** in Moon's Dex |
| Eight filter changes across 20,000 assets | **0.06 seconds**, compared with **1.2 seconds** when sorting after every change |
| Update code colors after ten edits in a 10,000-line script | **Under 1 ms** total, compared with about **0.2 seconds** when recoloring the entire file |

The repeat-search result is over **1,000× faster than Moon's Dex** in this test. It measures reusing unchanged results, not the first search.

<details>
<summary>Test details</summary>

These are controlled tests with sample data on an Intel i7-12700H. Game size, executor, and hardware affect the results.

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

Found a bug? [Open an issue](https://github.com/wooxps/dex-explorer/issues/new) with the steps to reproduce it, your executor, and any error text. A screenshot or short recording helps with UI bugs.

## Credits

Developed by [Wooxps](https://github.com/wooxps).

Based on [Dex++ by Chillz](https://github.com/AZYsGithub/DexPlusPlus) and [Moon's Dex](https://github.com/LorekeeperZinnia/Dex). [MIT License](LICENSE).
