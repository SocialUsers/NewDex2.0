# Plugins

Plugins add tools to the Dex menu. A `.dexplugin` file contains JSON with the plugin's details and Luau code. Plugins run with the same access as Dex, so enable packages from authors you trust.

## Install a plugin

1. Open the Dex menu and click **+** next to **Plugins**.
2. Choose a `.dexplugin` file from `dex-explorer/plugins` in your executor workspace. For an HTTPS link or the contents of a package, use **Import From**.
3. Click **Review** to check the package details. Use **Copy Source** if you want to read the code and your executor supports clipboard access.
4. Click **Install**, then **Enable**. The plugin's buttons appear under **Plugins**.

## Update or reload

Right-click a plugin button to open its menu. On touch screens, tap the ellipsis on the button.

- **Reload** restarts the installed copy.
- **Review Local Changes** reads the package from disk again. **Check for Update** does the same for a package installed from a link. Click **Update**, then **Enable** to run the new copy.
- **Disable** stops the plugin and leaves it installed. **Uninstall** removes it from Dex.

## Write a plugin

Save this example as `hello.dexplugin` in UTF-8 and install it. Click **Hello** in the Dex menu to write a message to **Plugin Output**.

```json
{
  "schema": 1,
  "id": "example.hello",
  "name": "Hello",
  "version": "1.0.0",
  "source": "local plugin = ...\nplugin:RegisterButton(\"open\", function()\n    plugin:Log(\"Hello from Dex\")\nend)"
}
```

### Package fields

| Field | Meaning |
| --- | --- |
| `schema` | Use `1`. |
| `id` | Starts with a lowercase letter or digit. Use lowercase letters, digits, `.`, `_`, and `-`. Keep the ID the same across updates. |
| `name`, `version` | Name and version shown during review. |
| `source` | Luau code as a UTF-8 JSON string, up to 512 KiB. |
| `author`, `description`, `icon` | Optional. Use a Roblox asset ID for the icon, such as `rbxassetid://123456`. |
| `startup` | Optional. Set to `true` to run the plugin when you enable it and when Dex opens. Otherwise, it runs when you click its button. |
| `buttons` | Optional list of up to 24 buttons, each with an `id`, a `name`, and an optional `icon` and `tooltip`. The default button has ID `open` and uses the plugin's name. |

### Keep the source in a separate file

Save your package fields in `plugin.json` and your code in `main.luau`. Run this in their folder with Node.js to copy the code into the package.

```sh
node -e "
const fs = require('node:fs');
const pkg = JSON.parse(fs.readFileSync('plugin.json', 'utf8'));
pkg.source = fs.readFileSync('main.luau', 'utf8');
fs.writeFileSync('hello.dexplugin', JSON.stringify(pkg, null, 2));
"
```

For example, this `main.luau` opens a window when you click the default button.

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
end)
```

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

## Add a menu action or shortcut

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

Right-click a plugin button and choose **Plugin Output** to see its logs, warnings, and errors. This includes calls to `print` and `warn` from the plugin. Click a row for details, or click a line number to open the source that produced the message. **Clear** removes that plugin's messages from the current session.
