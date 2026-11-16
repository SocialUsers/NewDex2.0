# Dex MCP

Dex MCP lets Codex or another MCP client use Dex tools. The connection to Roblox runs on your PC. Your MCP client may send tool results to its model provider.

## Set up the server

Install [Node.js](https://nodejs.org/) 22 or newer, then run these commands from the repo root.

```powershell
cd mcp
npm ci --ignore-scripts
npm run build
```

Add `mcp/dist/dex-mcp.mjs` as a stdio server in your MCP client. Replace the example paths below with the full paths on your PC.

### Codex

Add this to `%USERPROFILE%\.codex\config.toml`.

```toml
[mcp_servers.dex_mcp]
command = 'C:\Program Files\nodejs\node.exe'
args = ['C:\Tools\Dex\mcp\dist\dex-mcp.mjs']
```

### Claude Desktop

Add this to your MCP configuration.

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

Reload the MCP servers or restart the client. The client starts the Dex MCP server.

## Pair Dex

1. Open **Dex MCP** from the Dex menu in Roblox.
2. Ask your MCP client to run `dex_create_pairing` and show the full code.
3. Click **Paste & Connect**, or enter the code and click **Connect**. Each code works once and expires after two minutes.
4. Ask the client to show your current selection. If you have several Roblox sessions open, use `dex_list_sessions` to pick one.

**Inspect** starts on. **Edit objects** allows changes to objects. **Run code** runs Luau with executor permissions. In **Commands**, you can turn individual tools on or off. In **Activity**, click a call to see its details.

## Troubleshooting

- If the tools are missing, check both paths in your MCP configuration and restart the client.
- If Dex cannot connect, check that your executor supports HTTP and WebSockets.
- After restarting the server, get a new pairing code. After updating Dex MCP, rebuild the bundle and reload your MCP client.

Run `npm test` from `mcp` to check the server. See the [Executor MCP license](../../mcp/third-party/executor-mcp/LICENSE) for the adapted tools.
