[Readme](../README.md) / **Plugins**

# Plugins

Plugins add tools, menu actions, and shortcuts to Dex. Install a `.dexplugin` package, enable it, and its buttons appear in the main menu.

[Install](#install-a-plugin) · [Create a plugin](#create-a-plugin) · [Package fields](#package-fields) · [API](#plugin-api) · [Actions](#menu-actions-and-shortcuts)

## Install a plugin

1. Open the Dex menu and click **+** next to **Plugins**.
2. Select a package from `dex-explorer/plugins` in your executor workspace. To use a link or paste a package, open **Import From** instead.
3. Click **Review**, then **Install** and **Enable**.

Plugins run with the same access as Dex. Review packages from unfamiliar authors before enabling them. **Copy Source** is available when your executor supports the clipboard.

## Manage installed plugins

Right-click a plugin button to open its menu. On touch screens, tap the ellipsis on the button.

| Action | Result |
| :--- | :--- |
| **Reload** | Restart the installed copy. |
| **Review Local Changes** | Read the original file again and review the changes. |
| **Check for Update** | Fetch the original link and review the changes. |
| **Disable** | Stop the plugin and keep it installed. |
| **Uninstall** | Remove the plugin and its buttons. |
| **Plugin Output** | Open the plugin's logs, warnings, and errors. |

When reviewing an update, click **Update**, then **Enable** to run it.

## Create a plugin

Keep the package details and Luau source in separate files while you work. This example creates a **Hello** button that opens a window.

### 1. Package details

Save as `plugin.json`:

```json
{
  "schema": 1,
  "id": "example.hello",
  "name": "Hello",
  "version": "1.0.0",
  "description": "A first Dex plugin."
}
```

### 2. Luau source

Save as `main.luau`:

```luau
local plugin = ...
local window, content = plugin:CreateWindow("Hello", 320, 200)

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Text = "Hello from Dex"
plugin.Lib.StudioText(label)
label.Parent = content

plugin:RegisterButton("open", function()
    window:Show()
    plugin:Log("Opened Hello")
end)
```

### 3. Build the package

Save as `package.mjs` in the same folder:

```js
import { readFileSync, writeFileSync } from "node:fs";

const manifest = JSON.parse(readFileSync("plugin.json", "utf8"));
manifest.source = readFileSync("main.luau", "utf8");

writeFileSync("hello.dexplugin", JSON.stringify(manifest, null, 2));
```

Run `node package.mjs`, then copy `hello.dexplugin` into `dex-explorer/plugins` and [install it](#install-a-plugin). Click **Hello** in the Dex menu to open the window.

After editing either file, run `node package.mjs` again and use **Review Local Changes** to update the installed copy.

## Package fields

The generated `.dexplugin` file is JSON. Its `source` field contains the Luau from `main.luau`.

| Field | Required | Description |
| :--- | :---: | :--- |
| `schema` | Yes | `1` |
| `id` | Yes | Stable plugin ID, such as `example.hello`. Start with a lowercase letter or digit; use lowercase letters, digits, `.`, `_`, or `-`. |
| `name` | Yes | Plugin name shown in Dex. |
| `version` | Yes | Version string shown during review, such as `1.0.0`. |
| `source` | Yes | UTF-8 Luau source, up to 512 KiB. The packaging step adds this. |
| `author` | No | Author name shown during review. |
| `description` | No | Description shown during review. |
| `icon` | No | Custom icon, such as `rbxassetid://123456`. |
| `startup` | No | `true` runs the entry script when enabled and when Dex starts. Defaults to `false`, which loads it on the first button click. |
| `buttons` | No | Up to 24 button definitions with `id`, `name`, and optional `icon` and `tooltip` fields. |

Without `buttons`, Dex creates one button with ID `open`, using the plugin's name and icon. Keep the plugin ID unchanged when publishing updates.

## Plugin API

Use `local plugin = ...` to get the plugin API.

| Method | What it does |
| --- | --- |
| `plugin:RegisterButton(id, callback)` | Runs the callback when you click a button declared in the package. |
| `plugin:RegisterButton({ ID = id, Name = name, Icon = icon, Tooltip = tip }, callback)` | Adds or updates a button once the plugin loads. Declare buttons in the package to show them before the plugin loads. |
| `plugin:SetButtonActive(id, active)` | Changes whether a toolbar button looks selected. |
| `plugin:RegisterAction(definition, callback)` | Adds a menu action or shortcut. Returns a function that removes it. |
| `plugin:CreateWindow(title, width, height)` | Returns a Dex window and its content frame. Call `window:Show()` to open it. Dex closes and cleans up the window when the plugin stops. |
| `plugin:Track(resource)` | Registers an instance, connection, or cleanup function for Dex to dispose of when the plugin stops. Returns the resource. The entry script can also return a cleanup function. |
| `plugin:GetSetting(key, fallback)` and `plugin:SetSetting(key, value)` | Read and save the plugin's settings. Use JSON values. `SetSetting` returns `false` and an error message if saving fails. |
| `plugin:Log(...)` and `plugin:Warn(...)` | Write a message to **Plugin Output**. |

`plugin.Main`, `plugin.Apps`, `plugin.Lib`, and `plugin.Settings` provide access to Dex internals that can change between releases.

## Menu actions and shortcuts

Call `RegisterAction` from your plugin's entry script. Set `startup` to `true` if the action should be ready as soon as the plugin is enabled.

```luau
local plugin = ...

plugin:RegisterAction({
    ID = "log-path",
    Name = "Log Object Path",
    Surface = "Explorer",
    Shortcut = "Ctrl+Alt+M",
    When = function(context)
        return context.Target ~= nil
    end,
}, function(context)
    plugin:Log(context.Target:GetFullName())
end)

plugin:RegisterAction({
    ID = "comment-selection",
    Name = "Toggle Comment",
    Surface = "Editor",
    When = function(context)
        return context.Editable and context.Selection.Selected
    end,
}, function(context)
    context.Editor.Command("ToggleComment")
end)
```

Give each action a unique lowercase `ID`, a `Name`, and a `Surface`. `Tooltip`, `Shortcut`, and `When` are optional except that `Global` requires a shortcut. If you supply `When`, return a boolean without yielding.

| Surface | Menu and callback context |
| --- | --- |
| `Explorer` | Appears in **Plugins** in the Explorer context menu. `Selection` is an array of selected instances. `Target` is the instance the action applies to, when one is available. |
| `Editor` | Appears in **Plugins** in the Script Editor context menu. The callback receives `Editor`, `Document`, `Script`, `Selection`, `Selections`, and `Editable`. Selection offsets are 1-based UTF-8 byte offsets, with `Last` pointing just past the selection. |
| `Global` | Runs from its shortcut. The callback receives `Surface = "Global"`. |

Use `Ctrl+Alt` or `Alt+Shift` with a letter, number, or function key. You can also add `Shift` to `Ctrl+Alt`. Pick a combination that Dex or Roblox hasn't reserved. A shortcut can be shared between Explorer and Script Editor. Global shortcuts must be unique across both panels.

## Plugin Output

Right-click a plugin button and choose **Plugin Output**. Calls to `plugin:Log`, `plugin:Warn`, `print`, and `warn` appear here, along with errors.

Click a row for details. An error's line number opens its source in the Script Editor. **Clear** removes only that plugin's messages from the current session.

---

[Readme](../README.md) · [Dex MCP](mcp/SETUP.md) · [Building](../BUILDING.md)
