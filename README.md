<h1 align="center">
  <img src="docs/dex-cover.png" width="760" alt="Dex Explorer">
</h1>

<p align="center">An in-game Explorer for Roblox</p>

<p align="center">
  <a href="#run-dex"><strong>Run Dex</strong></a>
  &nbsp;·&nbsp;
  <a href="#tools">Tools</a>
  &nbsp;·&nbsp;
  <a href="#performance">Performance</a>
  &nbsp;·&nbsp;
  <a href="docs/mcp/SETUP.md">Dex MCP</a>
  &nbsp;·&nbsp;
  <a href="docs/PLUGINS.md">Plugins</a>
  &nbsp;·&nbsp;
  <a href="BUILDING.md">Build from source</a>
</p>

## Run Dex

Paste this into your executor.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wooxps/dex-explorer/main/loader.lua"))()
```

<p align="center">
  <img src="docs/explorer-preview.webp" width="760" alt="Dex Explorer showing search results and properties for a selected pumpkin in Roblox">
</p>

## What changed

Explorer reuses rows when you scroll through large search results. Docked windows keep their layout when you reopen Dex.

The Script Editor has Luau autocomplete and shows types on hover. Ctrl-click jumps to a definition, and the editor indents code as you type or paste.

## Tools

- **Explorer and Properties.** Find objects by name, class, tag, or property. For example, `is:BasePart and Anchored=false` finds unanchored parts. Select several objects to edit their properties together.
- **Find in Place.** Search across scripts and click a result to jump to that line. Replace All edits the matching text in the editor tabs.
- **Console.** Filter client logs or run a Luau command.
- **Asset Manager and 3D Viewer.** Preview images, sounds, meshes, and animations. See which objects use an asset or open a model in its own 3D view.
- **Input Macros.** Record keyboard and mouse input. Edit the timing, change the speed, or play it on a loop. **F8** stops it.

<details>
<summary>More tools</summary>

- Pick a part or UI element on screen to find it in Explorer. Use the transform handles to move, rotate, or resize it.
- Right-click an object to find references or watch changes to its properties, attributes, and children.
- Use **Save Instance** to export objects, or **Reconstructor** to review inferred paths and the evidence behind them.

</details>

## Plugins and Dex MCP

[Plugins](docs/PLUGINS.md) can add buttons to the Dex menu, open their own windows, and add shortcuts or right-click actions.

[Dex MCP](docs/mcp/SETUP.md) lets you use Dex from Codex or another MCP client. You can turn off individual commands and see the result of each call in **Activity**.

Script source, file saves, and input playback depend on your executor.

## Performance

Median of three Luau CLI runs on an Intel i7-12700H using test data.

| Test | Time |
| :--- | :--- |
| Explorer search with 70,000 matches | **1.55 s** CPU time on the first search, **0.1 ms** for the exact same query again. [Test](tests/search_engine.spec.luau) |
| Eight filters in a 20,000-asset list | **1,193 ms → 61 ms** with cached sort order, about **20× faster** than sorting again for each filter. [Test](tests/asset_query.spec.luau) |
| Syntax highlighting for 10 edits in a 10,000-line script | **205 ms** for full highlighting passes, **0.03 ms** for incremental updates. [Test](tests/editor_highlight_checks.py) |

## Credits

Developed by [Wooxps](https://github.com/wooxps).

Based on [Dex++ by Chillz](https://github.com/AZYsGithub/DexPlusPlus) and [Moon's Dex](https://github.com/LorekeeperZinnia/Dex). [MIT License](LICENSE).
