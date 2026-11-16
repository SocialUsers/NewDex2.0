# Plugins

A `.dexplugin` file contains Luau code and the settings for its menu buttons. Plugins run with access to Dex, Roblox, and your executor. Only enable plugins you trust.

## Install a plugin

1. Open the Dex menu and click **+** next to **Plugins**.
2. Choose a file from `dex/plugins` in your executor workspace. To use a link or paste a package, open **Import From**.
3. Click **Review** to see the package details. Click **Copy Source** if you want to read the code, then **Install**.
4. Click **Enable** to allow the plugin to run. Its buttons appear under **Plugins**. Most plugins load on the first click.

Right-click a plugin button, or tap its ellipsis on touch, to manage the plugin. **Reload** restarts the installed version. To pick up edits to a local file, choose **Review Local Changes**. For a plugin installed from a link, choose **Check for Update**. Enable the new version after reviewing it.

## Create a plugin

Save this as `hello.dexplugin` in UTF-8. The `source` field holds the Luau code as a JSON string.

```json
{
  "schema": 1,
  "id": "example.hello",
  "name": "Hello",
  "version": "1.0.0",
  "author": "Example",
  "description": "Opens a small Dex window.",
  "source": "local plugin = ...\nlocal window, content = plugin:CreateWindow(\"Hello\", 320, 200)\nlocal label = Instance.new(\"TextLabel\")\nlabel.Size = UDim2.fromScale(1, 1)\nlabel.BackgroundTransparency = 1\nlabel.Text = \"Hello from Dex\"\nplugin.Lib.StudioText(label)\nlabel.Parent = content\nplugin:RegisterButton(\"open\", function() window:Show() end)"
}
```

To keep the code in a separate file while you work, put the manifest in `plugin.json` and the code in `main.luau`. Run this command from their folder to build the package.

```text
node -e "const fs=require('fs'); const p=JSON.parse(fs.readFileSync('plugin.json','utf8')); p.source=fs.readFileSync('main.luau','utf8'); fs.writeFileSync('my-tool.dexplugin',JSON.stringify(p,null,2));"
```

| Field | Meaning |
| --- | --- |
| `schema` | Package format. Use `1`. |
| `id` | Stable lowercase ID using letters, digits, `.`, `_`, and `-`. Keep it the same across updates. |
| `name`, `version` | Display name and version shown during review. |
| `source` | UTF-8 Luau source, up to 512 KiB. |
| `author`, `description`, `icon` | Optional. Icons accept a Roblox asset ID such as `rbxassetid://123456`. |
| `startup` | Optional. Set to `true` when the plugin needs to start as soon as it is enabled or Dex opens. |
| `buttons` | Optional array with `id`, `name`, and optional `icon` and `tooltip` for each button. The default is one `open` button named after the plugin. |

## Plugin API

Use `local plugin = ...` at the top of your source to get the plugin API.

| Method | Behavior |
| --- | --- |
| `plugin:RegisterButton(id, callback)` | Bind a declared button to a function. |
| `plugin:RegisterButton({ ID = id, Name = name, Icon = icon, Tooltip = tip }, callback)` | Add a button once the plugin loads. Declare launch buttons in the package so users can see them before it loads. |
| `plugin:SetButtonActive(id, active)` | Set a button's selected appearance. |
| `plugin:RegisterAction(definition, callback)` | Add an Explorer or Script Editor context action, with an optional shortcut. Returns a function that unregisters it. |
| `plugin:CreateWindow(title, width, height)` | Return a Dex window and its content frame. Call `window:Show()` to open it. |
| `plugin:Track(resource)` | Clean up an instance, connection, or callback on disable, reload, uninstall, and Dex shutdown. Returns the resource. The entry script can also return a cleanup function. |
| `plugin:GetSetting(key, fallback)` and `plugin:SetSetting(key, value)` | Read or save JSON-compatible settings for this plugin. `SetSetting` returns success and an error message when saving fails. |
| `plugin:Log(...)` and `plugin:Warn(...)` | Write messages to this plugin's Output window. |

`plugin.Main`, `plugin.Apps`, `plugin.Lib`, and `plugin.Settings` expose Dex internals that can change between releases. Call `Track` for any instances, connections, or cleanup callbacks Dex should handle when the plugin stops.

### Dex actions

Register actions in your plugin's entry script. Set `startup` to `true` in the package if the actions should be available as soon as the plugin is enabled. Actions go away when the plugin stops.

```lua
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

Supply a unique lowercase `ID`, a `Name`, and a `Surface`. `Tooltip`, `Shortcut`, and `When` are optional. `When` should return a boolean without yielding.

| Surface | Where it appears and what the callback receives |
| --- | --- |
| `Explorer` | The **Plugins** actions in Explorer. `Selection` is the selected instance array and `Target` is the relevant instance, if any. |
| `Editor` | The **Plugins** actions in the Script Editor. Context includes `Editor`, `Document`, `Script`, `Selection`, `Selections`, and `Editable`. Offsets in `Selection` and `Selections` are 1-based UTF-8 byte offsets with an exclusive `Last`. |
| `Global` | A shortcut with no menu entry. Context includes `Surface = "Global"`. `Shortcut` is required. |

Shortcuts accept `Ctrl+Alt` or `Alt+Shift` with a letter, number, or function key. You can add `Shift` to `Ctrl+Alt`. Dex rejects reserved chords and duplicate shortcuts in the same panel. Explorer and Script Editor actions can use the same shortcut.

### Plugin Output

Open **Plugin Output** from the plugin button menu to see messages, errors, and calls to `print` or `warn`. Click a row for details or a linked line number to open the source that produced the error. **Clear** removes that plugin's messages from the current session.
