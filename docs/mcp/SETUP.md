# Dex MCP

Use Dex tools from Codex or another MCP client on the same PC as Roblox. Dex connects to the server on localhost. Your MCP client may send tool results to its model provider.

## 1. Build the server

Install [Node.js](https://nodejs.org/) 22 or newer. Run these commands from the repo root.

```powershell
cd mcp
npm ci --ignore-scripts
npm run build
```

The build writes `mcp/dist/dex-mcp.mjs`.

## 2. Set up your MCP client

Add Dex as a stdio server. Replace the paths below with the full paths to Node and `dex-mcp.mjs` on your PC. Your MCP client starts the server.

### Codex

Add this to `%USERPROFILE%\.codex\config.toml`.

```toml
[mcp_servers.dex_mcp]
command = 'C:\Program Files\nodejs\node.exe'
args = ['C:\Tools\Dex\mcp\dist\dex-mcp.mjs']
```

### Claude Desktop

Open `%APPDATA%\Claude\claude_desktop_config.json` and add the `dex_mcp` entry under `mcpServers`.

```json
{
  "mcpServers": {
    "dex_mcp": {
      "command": "C:\\Program Files\\nodejs\\node.exe",
      "args": ["C:\\Tools\\Dex\\mcp\\dist\\dex-mcp.mjs"]
    }
  }
}
```

Save the config, then restart your MCP client or reload its servers.

## 3. Pair Dex

1. In Roblox, open **Dex MCP**, then go to **Connection**.
2. Ask your MCP client to run `dex_create_pairing` and show the full code.
3. Copy the code and click **Paste & Connect**, or enter it and click **Connect**. Each code works once and expires after two minutes.
4. Select an object in Dex and ask the client to show your selection. If you have several sessions paired, ask it to use `dex_list_sessions` to pick the right one.

## Permissions and activity

**Inspect** is on while paired. **Edit objects** and **Run code** start off. Edit objects allows changes to the current Roblox session. Run code uses your executor permissions.

Use **Commands** to turn individual tools on or off. In **Activity**, click a call to see its result. Open the connection status to pause or disconnect.

## Troubleshooting

- **Tools missing.** Check the Node and `dex-mcp.mjs` paths, then restart your MCP client.
- **Pairing fails.** Check that your executor supports HTTP and WebSockets. Use a new code if the old one expired or the MCP server restarted.
- **Updating Dex MCP.** Run `npm run build` again from `mcp`, then reload the server in your MCP client and pair again.

Run `npm test` from `mcp` to check the server. See the [Executor MCP license](../../mcp/third-party/executor-mcp/LICENSE) for the adapted tools.
