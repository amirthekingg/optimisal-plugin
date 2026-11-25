---
name: optimisal-liveops
description: Set up and change a Roblox game's LiveOps through Optimisal - values, prices, multipliers, drop rates, feature flags with percentage rollouts, scheduled events and announcements - and the Luau that reads them. Use for events like double XP or sales, price changes, flag rollouts, announcements, or rolling back a LiveOps change.
---

# LiveOps with Optimisal

LiveOps config is published from Optimisal and reaches every live server within seconds; the game
reads it through the SDK with a default for each lookup. Changing it needs an owner key.

## Workflow

1. **Read first.** `get_liveops` shows what's live, scheduled and its version; `liveops_history`
   what changed recently; `liveops_templates` ready-made events.
2. **Make the change** with the narrowest tool:
   - `liveops_add_event` for a template (double XP, coin rush, world boss, holiday sale, lucky
     hour). It returns the Luau snippet that reads the event.
   - `liveops_update` for anything else: `set` entries (`section`, `key`, `value` as text),
     `remove` as `section.key`, `events`, `announcements`. Event params go in `params_json`.
   - `liveops_rollback` to publish an earlier version again (`liveops_diff` shows what that changes).
3. **Preview, show, confirm.** Every write returns a preview: what would change and
   `based_on_version`. Show the person the changes in plain words. Call again with
   `confirm: true` and that `based_on_version` only after they say yes. If it reports a conflict,
   someone published in between: preview again and show the new changes.
4. **Fix problems the preview lists** (bad keys, times, limits) before confirming.

## Getting it right

- **Times are UTC, RFC 3339** (`2026-11-07T18:00:00Z`). Convert from the person's timezone and say
  both. An announcement can't run long past now; schedule far-off ones closer to the time.
- **Don't stack faucets by accident.** Check events already scheduled for the same window: two XP
  events multiply each other if the game applies both.
- **Flags:** `{"on": true, "rollout": 10}` gives 10% of players, chosen by a hash of flag and
  player, so the same players stay in as the share grows. Ramp 10, 25, 50, 100, checking
  `top_errors` and `game_overview` between steps.
- **Public values** (`public` section) are sent to clients. Never make secrets, server-only
  tuning or anything exploitable public.
- **`guard` is economy containment;** change it only through `economy_contain` and `economy_lift`.
- **The game must read what you publish.** If the workspace has the game's code, check it calls
  the matching lookup with a sensible default, and offer the change if not:

  ```lua
  local price = Optimisal.liveops.price("sword", 100)
  if Optimisal.liveops.flag("new_shop", player, false) then ... end
  local running, p = Optimisal.liveops.event("double_xp")
  local xp = base * (if running then p.xp_mult else 1)
  local ok, msg = Optimisal.liveops.redeemCode(player, code)
  local items = Optimisal.liveops.shop("daily_shop")
  if Optimisal.liveops.inSegment(player, "high_spenders") then ... end
  ```

  Defaults are what the game does without Optimisal, so a missing key never breaks it.
- To A/B test a LiveOps change or storefront name/icon/thumbnails, use `list_experiments` and `experiment_create` (see the `optimisal-experiments` skill).
- Add a short `note` to `liveops_update` saying why; it's kept in the history.
