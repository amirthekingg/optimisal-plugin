#!/bin/sh
# Installs Optimisal's agent skills and OAuth-enabled MCP config for one client:
#   integrations/install.sh claude   # Claude Code plugin (skills + HTTP MCP)
#   integrations/install.sh agy      # Antigravity (AGY) plugin (skills + rules + HTTP MCP)
#   integrations/install.sh codex    # Codex skills + HTTP MCP config
#   integrations/install.sh grok     # Grok CLI (skills + HTTP MCP)
#   integrations/install.sh cursor   # Cursor skills (add HTTP MCP in Cursor settings)
# Optional overrides:
#   OPTIMISAL_URL=https://dashboard.optimisal.app
#   OPTIMISAL_AGENT_KEY=opt_agent_... (only if you prefer key auth over OAuth)
set -eu
here=$(cd "$(dirname "$0")" && pwd)
base_url="${OPTIMISAL_URL:-https://dashboard.optimisal.app}"
mcp_url="${base_url%/}/mcp"

link_skills() {
	dest="$1"
	mkdir -p "$dest"
	for s in "$here"/skills/*/; do
		ln -sfn "${s%/}" "$dest/$(basename "$s")"
	done
}

case "${1:-}" in
claude)
	if command -v claude >/dev/null 2>&1; then
		if [ -f "$here/.claude-plugin/marketplace.json" ]; then
			claude plugin marketplace add "$here" || true
		else
			claude plugin marketplace add "$here/.." || true
		fi
		claude plugin install optimisal@optimisal || claude mcp add --transport http optimisal "$mcp_url"
	else
		echo "Claude Code CLI not found. Run inside Claude Code:"
		echo "  /plugin marketplace add amirthekingg/optimisal-plugin"
		echo "  /plugin install optimisal@optimisal"
		echo "Or register MCP directly: claude mcp add --transport http optimisal $mcp_url"
	fi
	;;
agy)
	dest="${AGY_HOME:-$HOME/.gemini/config}/plugins/optimisal"
	mkdir -p "$(dirname "$dest")"
	ln -sfn "$here" "$dest"
	echo "Linked Antigravity (AGY) plugin at $dest. Enable it on the Customizations page."
	;;
codex)
	link_skills "${CODEX_HOME:-$HOME/.codex}/skills"
	link_skills "${HOME}/.agents/skills"
	if command -v codex >/dev/null 2>&1; then
		if [ -n "${OPTIMISAL_AGENT_KEY:-}" ]; then
			codex mcp add optimisal --url "$mcp_url" --bearer-token-env-var OPTIMISAL_AGENT_KEY || true
		else
			codex mcp add optimisal --url "$mcp_url" || true
		fi
	else
		cfg="${CODEX_HOME:-$HOME/.codex}/config.toml"
		mkdir -p "$(dirname "$cfg")"
		if ! grep -q '^\[mcp_servers\.optimisal\]' "$cfg" 2>/dev/null; then
			printf '\n[mcp_servers.optimisal]\nurl = "%s"\n' "$mcp_url" >> "$cfg"
		fi
	fi
	echo "Installed Codex skills and MCP server ($mcp_url)."
	;;
grok)
	link_skills "${GROK_HOME:-$HOME/.grok}/skills"
	if command -v grok >/dev/null 2>&1; then
		if [ -n "${OPTIMISAL_AGENT_KEY:-}" ]; then
			grok mcp add --transport http optimisal "$mcp_url" --header "Authorization: Bearer $OPTIMISAL_AGENT_KEY"
		else
			grok mcp add --transport http optimisal "$mcp_url"
		fi
	else
		echo "Linked skills into ~/.grok/skills. Run: grok mcp add --transport http optimisal $mcp_url"
	fi
	;;
cursor)
	dest="${CURSOR_HOME:-$HOME/.cursor}/skills"
	link_skills "$dest"
	echo "Linked skills into $dest. Add $mcp_url in Cursor (Settings -> Tools & MCP)."
	;;
*)
	echo "usage: $0 claude|agy|codex|grok|cursor" >&2
	exit 2
	;;
esac
