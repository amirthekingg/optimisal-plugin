# Using other AIs to your advantage

Source: Creator Docs > Assistant (overview, prompt guide, skills, MCP) and AI > Build with a coding harness; Studio > Connect to the Roblox Studio MCP server.

The point isn't "use more AI." It's: put each model where it has the most context and the cheapest verification, and keep a human-readable diff between every AI and the live game.

## The toolbox

| Tool | Best at | Why |
|---|---|---|
| **Roblox Studio Assistant** (in Studio) | Anything that needs to see the open place: instance edits, debugging live state, profiling, scene audits, generating meshes/materials/procedural models | It has the data model. Supports bring-your-own-key (Anthropic, OpenAI, Gemini) via Manage API Keys. |
| **Assistant built-in skills** | `rbx-docs-search` (authoritative API lookup), `rbx-debug` (breakpoints, call stacks, locals), `rbx-unit-test` (Jest-Lua/TestEZ), `rbx-perf-profiling` (MicroProfiler), `rbx-scene-analysis` (memory/leaks), `rbx-device-simulator-lua` (UI across devices), `rbx-create-skill` | Purpose-built workflows that beat a generic chat answer. |
| **Studio MCP server** (built into Studio) | Letting an external agent read the game tree, read/edit/grep scripts, run Luau in Edit/Client/Server, playtest, insert/search assets | Quick connect supports Claude Code, Claude Desktop, Codex CLI, Cursor, Gemini CLI, VS Code, Antigravity; any stdio MCP client works. |
| **External coding agent** (Claude Code, Cursor, Codex, Gemini CLI) + **Script Sync or Rojo + Git** | Multi-file features, refactors, consistent architecture across the codebase | Works on real files, produces diffs you can review and revert. |
| **A second, different model** | Code review, security review, "find the bug" | Models have different blind spots. Cross-checking catches more than asking one model twice. |
| **You (this bot)** | Architecture, teaching, writing clean code from scratch, reviewing, writing prompts/specs for the other tools | |

## Recommended setup (from the official coding-harness guide)

1. Project folder with `ServerScriptService/`, `ReplicatedStorage/`, `StarterPlayerScripts/` (or a Rojo project).
2. Studio: enable the Script Sync beta, right-click each service > Script Sync > Sync to the project folder. `.luau` files now appear as scripts.
3. Studio: Assistant > ⋯ > Manage MCP Servers > enable MCP > Quick connect your editor.
4. Verify: ask the agent to read the game tree via MCP and list Workspace.
5. `git init` and commit. Commit after every working step.
6. Keep a `PROJECT.md` (or `AGENTS.md`/`CLAUDE.md`) in the repo root describing architecture and rules; point every agent at it. Paste this skill's non-negotiables into it.

MCP clients can read and modify your open places. Only connect clients you trust, and don't run agents with auto-approve against a place with live data you can't restore.

## The build loop

1. **Spec** (here): turn the idea into a short spec: server/client split, remotes and their payloads, data shape, validation rules, file list.
2. **Build** (external agent via Script Sync/Rojo): one tested phase at a time. Give it the spec and PROJECT.md.
3. **Run** (agent via MCP, or Studio Assistant): playtest, read Output, fix errors.
4. **Review** (second model or this bot): paste the diff, review against `security.md` and the non-negotiables.
5. **Verify** (human): playtest yourself, check Developer Console memory/network, read the diff, commit.

Never skip 4 and 5 for anything touching remotes, currency, purchases, or data stores.

## Prompting rules that work (from the Assistant prompt guide, generalized)

- **Be specific**: exact instance names and paths, the API you want used, the type you're working with. "Add a script that moves `Workspace.Lift` up and down 10 studs with TweenService on the client" beats "make the part move."
- **Edit time vs run time**: AI agents bias toward doing things now, in edit mode. If you want behavior during gameplay, say "add a script that…".
- **Separate instructions from content** with `###` delimiters when pasting code to explain or review.
- **Constrain the output**: "--!strict, task library only, no scripts in Workspace, validate every remote param, return the full file."
- **Use selection** in Studio Assistant to reference objects instead of describing them.
- **One phase per prompt**. Big-bang prompts produce big-bang bugs.
- **Iterate**: models are non-deterministic. Small prompt tweaks and retries are normal.
- **For assets**: describe the object, not the photo (no "white background", "4K", camera angles). Build detail up: `mailbox` → `weathered blue metal mailbox with a red flag`.
- **For procedural models**: name the properties you want editable and how parts should scale.

## Prompt templates to hand the user

**Build a feature (external agent):**
```
Read PROJECT.md. Implement <feature> as ModuleScript(s) with a start() function, required from the existing server/client entry scripts.
Constraints: --!strict, typed signatures, task library only, services via GetService at top, no scripts in Workspace (use CollectionService tags).
Remotes: <name> client->server, payload {<fields + types + limits>}. Validate rate, type, size, isfinite, and context on the server.
When done, use the Roblox MCP to playtest and report Output errors. Don't touch files outside <paths>.
```

**Security review (second model):**
```
Review this Roblox Luau diff as an exploiter would. For every RemoteEvent/RemoteFunction/ProximityPrompt/ClickDetector/Touched handler, list what an attacker can send and what happens. Check: rate limiting, type checks, size caps, NaN/inf (math.isfinite), Instance spoofing with tables, client-trusted values, InvokeClient from server, ProcessReceipt idempotency. Rank by severity. Then give fixed code.
###
<diff>
###
```

**Leak/perf review:**
```
Find memory leaks and per-frame waste in this code: undisconnected connections, per-player tables not cleared on PlayerRemoving, character connections, RunService work that could be event-driven or throttled, server-side tweens, oversized remote payloads.
###
<code>
###
```

**Debug (Studio Assistant):** "Use rbx-debug to find why <symptom> happens in <script path>. Set breakpoints at <function> and report locals."

**Tests (Studio Assistant):** "Use rbx-unit-test to write tests for <ModuleScript path> covering <contract>. Stub DataStoreService."

## Guardrails

- AI-invented APIs exist. If a method looks unfamiliar, check it with `rbx-docs-search` or the Engine API reference before shipping.
- Never paste API keys, Open Cloud keys, webhook URLs, or `.ROBLOSECURITY` cookies into any chat or prompt. Store keys in Studio's Secrets store / `HttpService:GetSecret` for runtime use.
- Don't let an agent write directly to production data stores. Test against a separate place/universe.
- Read every diff touching remotes, purchases, or saves yourself. An AI approving another AI's security code is not a review.
- Turn repeated instructions into skills (Studio Assistant Skills tab, or `rbx-create-skill`) so every session follows the same conventions.
