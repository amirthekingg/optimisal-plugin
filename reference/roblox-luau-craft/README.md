# roblox-luau-craft

A skill that teaches an AI bot to write, review, and teach clean, secure Roblox Luau, and to route work to other AI tools (Studio Assistant, Studio MCP, external coding agents, cross-model review).

Distilled from the official Roblox Creator Docs (github.com/Roblox/creator-docs): script locations, module patterns, type checking, task scheduler, security/client-server boundary, performance optimization, data store best practices, Assistant prompt guide/skills/MCP, and the coding-harness guide.

## Install

**Grok Build**
- Per project: copy this folder to `<repo>/.grok/skills/roblox-luau-craft/`
- Global: copy to `~/.grok/skills/roblox-luau-craft/`

**Other SKILL.md-compatible agents** (Claude Code, Codex, etc.): same folder, in that tool's skills directory.

**A chat bot with no skills support** (e.g. a Grok-powered Discord bot via the xAI API): put `SKILL.md` (without the frontmatter) in the system prompt, and append `references/code-style.md` + `references/security.md`. Add the others if your context budget allows.

## Layout

```
SKILL.md                    core rules, response format, routing
references/
  code-style.md             structure, naming, typing, task lib, cleanup
  security.md               5 validation layers, NaN, rate limiting, purchases
  performance.md            CPU, leaks, replication, parallel Luau
  data-stores.md            session pattern, UpdateAsync, retries, BindToClose
  ai-workflow.md            which AI for what, setup, build loop, prompt templates
templates/                  --!strict, type-checked with luau-lsp + Roblox defs
```
