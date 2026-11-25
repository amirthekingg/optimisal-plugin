---
name: optimisal-experiments
description: Design, preflight, and analyze Roblox A/B experiments in Optimisal - both in-game player splits (Optimisal.experiments.variant) and scheduled storefront switchbacks (game name, place icon, and page thumbnails). Use for A/B testing titles, icons, thumbnails, shop layouts, or reviewing experiment scorecards and contaminated windows.
---

# Experiments with Optimisal

Optimisal supports two experiment types:
1. **`player_split`**: deterministic in-game FNV-1a player bucketing via `Optimisal.experiments.variant(...)`.
2. **`scheduled_metadata`**: counterbalanced Roblox storefront switchbacks (`ABBA` or `ABAB`) that rotate game **name**, **place icon**, and **detail-page thumbnails** across scheduled windows via Open Cloud.

## Workflow: Storefront Switchback (`scheduled_metadata`)

1. **Check existing tests.** Call `list_experiments` to see what is running or completed. Only one `scheduled_metadata` test can run per game at a time.
2. **Draft the test.** Call `experiment_create` with `kind: "scheduled_metadata"`, `surfaces` (`name`, `icon`, `previews`), `variants` (`display_name`, `icon_asset_id`, `preview_asset_ids`), and schedule settings (`window_hours`, `pattern`, `washout_minutes`, `cycles`). It always previews first and saves as `draft`.
   - Pre-upload all icons and thumbnails in Creator Hub first.
   - `previews` replaces the entire ordered list of thumbnails on Roblox, so include every thumbnail that should stay visible.
3. **Run preflight.** Call `experiment_preflight` to verify Open Cloud connectivity, capture the immutable baseline snapshot, and confirm every icon/preview asset is `Approved` by Roblox moderation.
4. **Owner launch (dashboard only).** Agents cannot start live storefront swaps or ship winners. Tell the owner to review the preflight result and click **Approve and start** in the Optimisal dashboard (`#/experiments`).
5. **Review & clean results.** Call `experiment_results` and `experiment_windows`:
   - Check **paired confidence** (`p_value` and `matched_pairs` vs `min_clean_pairs`).
   - Watch for **clickbait trade-offs**: higher `qPTR` or `visits_per_hour` paired with worse `bounce_rate_pct`, shorter `avg_session_sec`, or lower `d1_rate`.
   - Exclude contaminated windows (outages, YouTuber spikes, or incident overlaps) with `experiment_exclude_window` (preview, then `confirm: true`).
   - Use `experiment_abort` (preview, then `confirm: true`) if a running test needs an emergency stop and immediate baseline restore.
   - Never ship a winner from MCP; tell the owner to click **Ship live** on the winning variant in the dashboard.

## Workflow: In-Game Player Split (`player_split`)

1. **Create the experiment.** Call `experiment_create` with `kind: "player_split"`, `traffic_pct`, and `variants` (preview, then `confirm: true`).
2. **Instrument Luau.** Read `optimisal://guide/sdk` and add `Optimisal.experiments.variant(player, key, "control", variants, trafficPct)` in server code.
3. **Evaluate & control.** Use `experiment_results` to check D1 retention, payer conversion, ARPU, z-score, and error guardrails, and `experiment_status` to pause, resume, or complete the test.
