# Reference material for Optimisal's agent skills

Source material for the skills planned in docs/ARCHITECTURE.md §12, "MCP server and
agent skills" (KIN-299). Nothing here is loaded by Optimisal or by an agent as is.
The skills we ship will be written in `integrations/skills/<name>/` and take what
they need from these.

## roblox-luau-craft

A Roblox Luau skill the user shared on 2026-11-03, stored unchanged: `SKILL.md`, five
reference docs (code style, security, performance, data stores, AI workflow) and
seven `--!strict` templates (Guard, RateLimiter, Janitor, DataService, ShopService,
and server and client entry points). It says it's distilled from the Roblox Creator
Docs. We haven't checked each API claim against them, or run the templates in Studio.

What each of our skills takes from it:

| Our skill | What we take |
|---|---|
| `optimisal-incident-triage` | The review order (security, data loss, leaks and performance, correctness, style); the five validation layers for remote handlers (rate, type, size, value with `math.isfinite`, context); the data-store failure modes (blank profile on a failed load, `UpdateAsync` callbacks that yield, `ProcessReceipt` granted before the save); and the leak list (undisconnected connections, per-player tables, characters not destroyed). These are what most incidents turn out to be. |
| `optimisal-instrumentation` | The code-style rules for anything we add to a game: `--!strict`, services at the top, `task` library, no side effects at require time, cleanup on `PlayerRemoving`. Our SDK's own rules (never throw or yield, hashed IDs only) come first. |
| `optimisal-sdk-setup` | The project layout (Rojo or Script Sync, one server entry, modules with `start()`) and the secrets rule (keys in `HttpService:GetSecret`, never in code or chat). |
| `optimisal-economy-review` | Server authority for currency: prices and rewards live on the server, clients send intent, and every grant is validated. Rebalances stay within those rules. |
| All of them | The response shape: restate the goal and where code runs, give complete code, explain the two or three decisions that matter, flag unasked risks, and end with a verification step. |

The templates are also candidates for the coder's pattern library
(`agents/src/optimisal_agents/patterns.py`) and the benchmark tasks
(`agents/benchmarks/tasks/`). `Guard` and `RateLimiter` fit remote-validation fixes;
`DataService` fits the data-store tasks. Each would need a verifier and a task before it's
used.

Where it differs from Optimisal: its AI workflow has an agent edit scripts directly
through Studio MCP or Script Sync. That's fine in a developer's own Studio session.
For a live game, our skills send changes through Optimisal's patch pipeline,
analyzer, sandbox, policy and human approval instead (CLAUDE.md, "Rules"). Our skills
should say so and not copy that part.
