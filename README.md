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
  <a href="#guides">Guides</a>
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

- **Explorer and Properties** let you find objects and edit them together. Search `is:BasePart and Anchored=false` to find unanchored parts.
- **Script Editor** has Luau autocomplete and type hints on hover. Ctrl-click a name to jump to its definition.
- **Find in Place** searches across scripts. Click a match to jump to that line, or use **Replace All** to edit the matches in your tabs.
- **Asset Manager** previews images, sounds, meshes, and animations. It also shows which objects use them. **3D Viewer** lets you inspect a model from any angle.
- **Console** shows client logs and has a Luau command bar.
- **Input Macros** record keyboard and mouse input. Edit delays, change the playback speed, or loop a recording. Press **F8** to stop.

<details>
<summary>More tools</summary>

- Pick parts and UI elements on screen, then move, rotate, or resize them with the transform tools.
- Right-click an object to find references to it or watch it for changes.
- **Save Instance** exports objects to a file. **Reconstructor** shows inferred paths and where they came from.

</details>

## Performance

| Feature | Result |
| :--- | :--- |
| **Finding objects** | **Over 1,000× faster than Moon's Dex** when repeating the same search in a test with 70,000 matches. The first search took **1.6 seconds**. |
| **Filtering assets** | Eight filter changes on 20,000 assets took **0.06 seconds** with the list already sorted and **1.2 seconds** when sorting it each time. |
| **Editing long scripts** | Updating code colors for ten edits in a 10,000-line script took **under 1 ms** total. Coloring the whole file after each edit took about **0.2 seconds**. |

<details>
<summary>Test details</summary>

The first search, asset filters, and script highlighting were each tested three times with sample data on an Intel i7-12700H. The table shows the middle time for each.

The repeat search used the same unchanged tree in both versions. Moon's Dex took 126 ms per search. Dex Explorer reused the previous results in 0.04 ms. Both figures are medians of five batches.

- [70,000-match search fixture](tests/search_engine.spec.luau)
- [Asset filter test](tests/asset_query.spec.luau)
- [Script highlighting test](tests/editor_highlight_checks.py)

</details>

## Guides

- [Install or write a plugin](docs/PLUGINS.md)
- [Set up Dex MCP](docs/mcp/SETUP.md)
- [Build and test Dex](BUILDING.md)

Script source, file saves, and input playback depend on your executor.

## Credits

Developed by [Wooxps](https://github.com/wooxps).

Based on [Dex++ by Chillz](https://github.com/AZYsGithub/DexPlusPlus) and [Moon's Dex](https://github.com/LorekeeperZinnia/Dex). [MIT License](LICENSE).
