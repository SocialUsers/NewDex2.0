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

### Explorer and Properties

Search the object tree by name, class, or property. For example, `is:BasePart and Anchored=false` finds unanchored parts. Select several objects to edit them together in Properties.

Right-click to highlight an object, view a player, listen to a sound, or find references to an object elsewhere in the game.

### Script Editor

Autocomplete works with Luau, Roblox APIs, local tables, and required modules. Hover over a name for its type and documentation, or Ctrl-click to open its definition. The editor also formats code as you type and paste.

**Find in Place** searches across scripts. Click a result to open the script at that line, or replace text across editor tabs. Script access depends on your executor; searches can only include source available to the client.

### Assets and exports

**Asset Manager** lists the game's images, sounds, meshes, and animations. Preview or download an asset, then click one of its references to select the object using it. **3D Viewer** opens parts and models in a separate viewport, with its own camera controls.

**Save Instance** uses UniversalSynSaveInstance by default. Its options are available in the menu, and you can switch to your executor's `saveinstance` if you prefer. File saving requires executor support.

### Other tools

- **Selection and Transform:** Pick parts or UI elements on screen and move, rotate, or resize them.
- **Console:** Read client logs, filter messages, and run Luau in the command bar.
- **Input Macros:** Record keyboard and mouse input, change the timing, and play it back on a loop or at a different speed. Press **F8** to stop. Playback requires executor support.
- **Reconstructor:** Build an inferred object hierarchy from paths found in scripts and tracebacks.

### Plugins

Plugins appear in the main menu alongside the built-in tools. They can open windows, add right-click actions, and register shortcuts. Install a `.dexplugin` file or [write your own plugin](docs/PLUGINS.md).

### Dex MCP

[Dex MCP](docs/mcp/SETUP.md) connects Dex to Codex and other MCP clients. You choose which commands are enabled and whether the client can edit objects or run code. Click a call in the Activity tab to see its arguments and result.

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

## Guides

[Plugins](docs/PLUGINS.md) · [Dex MCP setup](docs/mcp/SETUP.md) · [Building from source](BUILDING.md)

[Report a bug](https://github.com/wooxps/dex-explorer/issues/new) with the steps to reproduce it, your executor, and the error text. For UI bugs, include a screenshot or recording.

## Credits

Developed by [Wooxps](https://github.com/wooxps).

Based on [Dex++ by Chillz](https://github.com/AZYsGithub/DexPlusPlus) and [Moon's Dex](https://github.com/LorekeeperZinnia/Dex). [MIT License](LICENSE).
