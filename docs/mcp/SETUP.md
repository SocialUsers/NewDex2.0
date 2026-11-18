[Readme](../../README.md) / **Dex MCP**

# Dex MCP

Use Dex from Codex or another MCP client on the same PC as Roblox.

[Build](#1-build-the-server) · [Configure](#2-configure-your-mcp-client) · [Pair](#3-pair-dex) · [Permissions](#permissions-and-activity) · [Troubleshooting](#troubleshooting)

## 1. Build the server

Install [Node.js](https://nodejs.org/) 22 or newer and clone the repo:

```powershell
git clone https://github.com/wooxps/dex-explorer.git
cd dex-explorer/mcp
npm ci --ignore-scripts
npm run build
```

If you already have the repo, start in its `mcp` folder and run the two npm commands. The server builds to `mcp/dist/dex-mcp.mjs`.

## 2. Configure your MCP client

Add `dex_mcp` as a stdio server. Your MCP client starts it.

Replace `C:\Tools\dex-explorer` with your repo folder. Change the Node path if needed.

### Codex

Add this to `%USERPROFILE%\.codex\config.toml`.

```toml
[mcp_servers.dex_mcp]
command = 'C:\Program Files\nodejs\node.exe'
args = ['C:\Tools\dex-explorer\mcp\dist\dex-mcp.mjs']
```

### Claude Desktop

Open `%APPDATA%\Claude\claude_desktop_config.json` and add the `dex_mcp` entry under `mcpServers`.

```json
{
  "mcpServers": {
    "dex_mcp": {
      "command": "C:\\Program Files\\nodejs\\node.exe",
      "args": ["C:\\Tools\\dex-explorer\\mcp\\dist\\dex-mcp.mjs"]
    }
  }
}
```

Save the config, then restart your MCP client or reload its servers.

## 3. Pair Dex

1. In Roblox, open **Dex MCP**, then go to **Connection**.
2. Ask your MCP client to run `dex_create_pairing` and show the full code.
3. Click **Paste & Connect**, or enter the code and click **Connect**. Codes work once and expire after two minutes.
4. Select an object in Explorer, then ask the client: **"Show my current Dex selection."**

If several Roblox sessions are paired, use `dex_list_sessions` to choose one before running commands.

## Permissions and activity

| Permission | Access | Default |
| :--- | :--- | :--- |
| **Inspect** | Read objects and client data. | On while paired |
| **Edit objects** | Change objects in the current Roblox session. | Off |
| **Run code** | Execute Luau with your executor's permissions. | Off |

All commands start enabled. Use **Commands** to disable individual tools. Permissions still apply to enabled commands.

In **Activity**, click a call to inspect its arguments and result. Click the connection status to pause or disconnect.

The connection stays on localhost. Your MCP client may send tool results to its model provider. Logs are client-only; clearing them removes Dex's log buffer, not Roblox Output.

## Troubleshooting

| Problem | Check |
| :--- | :--- |
| Dex tools do not appear | Confirm the Node and `dex-mcp.mjs` paths, then restart or reload your MCP client. |
| Dex cannot connect | Confirm the server is running through your MCP client and your executor supports HTTP and WebSockets. Request a fresh pairing code. |
| A command is denied | Check its switch under **Commands** and its required permission under **Connection**. |

## Updating

Pull the latest repo changes, then run these commands from `mcp`:

```powershell
npm ci --ignore-scripts
npm run build
```

Reload the MCP server in your client and pair Dex again. Run `npm test` from `mcp` to check the server.

Adapted tools retain the [Executor MCP license](../../mcp/third-party/executor-mcp/LICENSE).

---

[Readme](../../README.md) · [Plugins](../PLUGINS.md) · [Building](../../BUILDING.md)
