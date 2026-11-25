# Optimisal MCP & Agent Skills

Connect **Claude Code**, **Codex**, and **Antigravity (AGY)** to Optimisal at `https://dashboard.optimisal.app/mcp` using browser OAuth (no manual agent key required).

## Quick Install

### Claude Code
From GitHub (plugin + skills + OAuth MCP):
```text
/plugin marketplace add amirthekingg/optimisal-plugin
/plugin install optimisal@optimisal
```
Or MCP server only:
```sh
claude mcp add --transport http optimisal https://dashboard.optimisal.app/mcp
```

### Antigravity (AGY)
- **Windows (PowerShell):** `.\integrations\install.ps1 -Client agy`
- **macOS / Linux:** `./integrations/install.sh agy`
- **Or CLI MCP only:** `agy mcp add --transport http optimisal https://dashboard.optimisal.app/mcp`

Then open **Customizations** in Antigravity and enable **Optimisal** (or sign in via OAuth when prompted).

### Codex
- **Windows (PowerShell):** `.\integrations\install.ps1 -Client codex`
- **macOS / Linux:** `./integrations/install.sh codex`
- **Or CLI MCP only:** `codex mcp add optimisal --url https://dashboard.optimisal.app/mcp`

If using an agent key instead of OAuth in `~/.codex/config.toml`:
```toml
[mcp_servers.optimisal]
url = "https://dashboard.optimisal.app/mcp"
bearer_token_env_var = "OPTIMISAL_AGENT_KEY"
```

## Publishing to Official Marketplaces

| Directory | Submission Portal | Pre-Submit Validation & Packaging |
| --- | --- | --- |
| **Claude Code Official Directory** | **[claude.ai/directory/manage](https://claude.ai/directory/manage)** | `claude plugin validate ./integrations` and `claude --plugin-dir ./integrations` |
| **OpenAI Codex / ChatGPT Directory** | **OpenAI Developer Platform → Plugins → Upload new or existing plugin** (requires verified org/developer identity + test cases) | Zip `integrations/` (`.codex-plugin/plugin.json`, `.mcp.json`, `skills/`) and upload |
| **Google Antigravity Marketplace** | **Antigravity Marketplace Plugin Submission Form** at **[antigravity.google](https://antigravity.google)** | `agy plugin validate --strict ./integrations` |

All three also work immediately from GitHub (`https://github.com/amirthekingg/optimisal-plugin`):

| Platform | Manifests & Files | Notes |
| --- | --- | --- |
| **Claude Code** | `.claude-plugin/marketplace.json`, `integrations/.claude-plugin/plugin.json`, `integrations/.mcp.json`, `integrations/skills/*` | Users install directly via `/plugin marketplace add amirthekingg/optimisal` or submit the repo to Anthropic's official plugin directory. |
| **Antigravity (AGY)** | `integrations/plugin.json`, `integrations/mcp_config.json`, `integrations/assets/logo.svg`, `integrations/rules/AGENTS.md`, `integrations/skills/*` | Uses `mcp_config.json` with OAuth discovery at `https://dashboard.optimisal.app/.well-known/oauth-protected-resource`. |
| **Codex** | `integrations/.codex-plugin/plugin.json`, `integrations/codex.toml`, `integrations/skills/*` | Skills install to `~/.codex/skills` and `~/.agents/skills`; HTTP MCP uses `url = "https://dashboard.optimisal.app/mcp"`. |

### Pre-Publish Verification
1. Verify `https://dashboard.optimisal.app/.well-known/oauth-protected-resource` returns HTTP 200 with `authorization_servers` pointing to your live host.
2. Validate JSON manifests (`integrations/.mcp.json`, `integrations/mcp_config.json`, `integrations/plugin.json`, `integrations/.claude-plugin/plugin.json`, `integrations/.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`).
3. Test local install with `.\integrations\install.ps1 -Client all` (Windows) or `./integrations/install.sh <client>` (macOS/Linux).

## Privacy & License
- [Privacy Policy](https://optimisal.app/legal/privacy)
- License: [MIT](./LICENSE)
