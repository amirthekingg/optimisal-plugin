---
name: optimisal-instrumentation
description: Add Optimisal telemetry to Roblox game code where it's blind - custom events, onboarding and progression funnels, monetization steps, economy grants and spends, anti-cheat reports, feedback, and LiveOps lookups. Use when someone wants to track something in their game, measure a funnel or purchases, or make a value tunable from Optimisal.
---

# Instrument a game with Optimisal

Read the `optimisal://guide/sdk` resource for the API. The SDK must already be started (see the
optimisal-sdk-setup skill).

## Find the gaps

Use the MCP tools to see what's already measured: `player_stats` (funnels, purchases, feedback),
`economy_overview` (currencies and sources), `get_liveops` (what's tunable). Then read the code for
the moments that matter: first session steps, purchases, currency changes, anything the person
wants to tune without a publish.

## What to add

| Moment | Call |
|---|---|
| Onboarding or progression step | `Optimisal.funnel(player, "onboarding", step, "equip sword", { completed = true })` |
| Purchase flow | `Optimisal.monetization(player, "prompt" / "purchase" / "cancel", kind, productId, { robux = n })` |
| Currency in | `Optimisal.economy.check(...)` first, then grant, then `Optimisal.economy.grant(player, currency, amount, source)` |
| Currency out | `Optimisal.economy.spend(player, currency, amount, "shop:item")` |
| Anti-cheat catch | `Optimisal.security(player, "speed_hack", "short detail")` |
| A/B experiment arm | `Optimisal.experiments.variant(player, "shop_v2", "control", variants, 100)` |
| Anything else | `Optimisal.track("boss_killed", { boss = "dragon" })` |
| A value worth tuning live | `Optimisal.liveops.price/multiplier/dropRate/get(key, currentValue)` |
| Promo code / shop / segment | `Optimisal.liveops.redeemCode(player, code)` · `shop(id)` · `inSegment(player, seg)` |

## Rules

- **The SDK's rules come first.** It never throws or yields, so don't wrap calls in `pcall`, and
  don't add yields around them. Report after the game's own logic succeeds (grant after the save
  path, purchase after `ProcessReceipt` commits).
- **No personal data.** Never put user IDs, names, display names or chat in props; the SDK passes
  the player object and hashes it. Keep props small, flat, and low-cardinality (an item name, not
  a timestamp or GUID).
- **Stable names.** `source` names and event names are how Optimisal groups things; pick
  `snake_case` names and keep them stable. Name sources by faucet (`quest`, `daily_reward`,
  `chest`), not by script.
- **LiveOps defaults** are the game's current values, so behavior doesn't change until someone
  publishes.
- Match the code base's style; where it has none, `--!strict`, services at the top, the `task`
  library, and cleanup on `PlayerRemoving`.
- Finish with how to verify: a playtest in a published place, then `player_stats` or
  `economy_overview` showing the new data.
