---
name: optimisal-economy-review
description: Review a Roblox game's economy with Optimisal - currency sources and sinks, inflation, the health score, exploit cases (dupes, uncapped faucets, outlier players) - suggest price, multiplier and drop-rate changes, and contain exploits. Use for economy balance, inflation, currency exploits, or "are players farming X".
---

# Economy review with Optimisal

## Read the economy

- `economy_overview` with `minutes` 60 (now), 1440 (a day) and 10080 (a week): flows per currency
  and source (`grant`, `spend`, `purchase`, `trade`, `blocked`), the health score and its findings,
  and open exploit cases with how much was created beyond normal and by how many players.
- `get_liveops` for the current prices, multipliers and drop rates, and `liveops_history` for
  recent changes that might explain a shift.
- `get_settings` → `detection.currencies` lists each currency's legitimate sources and their
  `max_per_event`. Grants from anywhere else are flagged.

## Balance

Judge the sink ratio (spent ÷ created), growth of the average balance week over week, and how fast
players reach the things they're meant to save for. When suggesting changes:

- Change one or two tunables at a time, within half to double the current value, and say what you
  expect to move and by how much, and how sure you are. Price changes depend on how players
  respond to price; say that it's an assumption unless the data shows it.
- Tunables map by name: `multipliers.<source or currency>`, `drop_rates.<item>`, `prices.<item>`.
- Apply through `liveops_update` (preview, show, `confirm: true` only on a yes). Optimisal's own AI
  rebalancer isn't available to agents.
- Keep server authority: prices and rewards live on the server, clients send intent, every grant
  is validated.

## Exploits

1. For each case in `economy_overview`: what's happening, the excess, players affected, and
   whether it's still going (compare ranges).
2. `economy_contain` previews the case's actions (pause or cap a source, hold a player's grants);
   apply with the person's yes. Containment expires on its own, never touches saved data, and only
   works where the game calls `Optimisal.economy.check` before granting.
3. In the workspace's code, find the grant path for that currency and source. Propose the real fix
   (validation, cooldowns, caps, idempotent purchase handling) and make sure grants call
   `Optimisal.economy.check` first and report with `Optimisal.economy.grant`.
4. `economy_lift` once the fix is live. Restoring player balances is for a person; Optimisal's
   case review list (on the dashboard) shows who gained what.
