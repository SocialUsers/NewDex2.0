# Dex Explorer

Dex is an in-game Explorer for Roblox. Browse objects, edit properties, and open the tool menu for script search, asset previews, and input macros.

## Run Dex

Run this in your executor.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wooxps/dex-explorer/main/loader.lua"))()
```

### Build locally

From this folder, run `python build.py build`. Open the file printed by the build in your executor. To find it again, run `python build.py output`.

## Guides

- [Dex MCP setup](docs/mcp/SETUP.md)
- [Install or write a plugin](docs/PLUGINS.md)
- [Build and test Dex](BUILDING.md)

Based on [Dex++ by Chillz](https://github.com/AZYsGithub/DexPlusPlus) and [Moon's Dex](https://github.com/LorekeeperZinnia/Dex). [MIT license](LICENSE).
