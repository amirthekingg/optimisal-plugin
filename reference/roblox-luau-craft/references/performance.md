# Performance

Source: Creator Docs > Performance optimization (identify, improve), Multithreading, Native code generation.

## Diagnose before optimizing

1. Reproduce on target hardware (low-end phone matters most).
2. Developer Console (F9): Memory (LuaHeap, InstanceCount, PlaceScriptMemory), Network, Scripts.
3. MicroProfiler (Ctrl+F6) for frame spikes. Wrap suspect code in `debug.profilebegin("Label")` / `debug.profileend()` to see it by name.
4. Studio Assistant's `rbx-perf-profiling` skill can interpret MicroProfiler dumps; `rbx-scene-analysis` audits memory and leaks.

Don't guess. Measure, change one thing, measure again.

## Script CPU

- RunService frame events (`Heartbeat`, `PreSimulation`, `PostSimulation`, `PreRender`, `PreAnimation`) run every frame. Use only for things that truly must (camera, visual interpolation). Everything else: events, or a throttled loop:

```lua
local ACCUMULATE_SECONDS = 0.25
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < ACCUMULATE_SECONDS then
		return
	end
	elapsed = 0
	updateNearbyEnemies()
end)
```

- Spread big jobs across frames with `task.wait()` between chunks.
- Deep clones / serialization of big tables are expensive. Don't do them per frame or per remote call.
- CPU-heavy pure computation that doesn't touch the DataModel: Parallel Luau (`Actor` + `task.desynchronize()`), split by logical unit; prefer more actors than cores. Must `task.synchronize()` before writing to instances.
- Hot math-heavy server modules: add `--!native` (native code generation). Measure; it helps compute-bound code, not API-bound code.

## Memory leaks

- Undisconnected connections keep their closures and everything they reference alive.
- `Player` objects/characters aren't auto-destroyed unless `Workspace.PlayerCharacterDestroyBehavior` is enabled, so `CharacterAdded` connections leak per join on long-lived servers.
- Per-player tables that never clear on leave.
- Watch for steadily rising LuaHeap or InstanceCount in a server that's been up for hours.

## Network / replication

- Send state changes, not state every frame.
- Send the delta (the one item bought), not the whole inventory.
- Throttle input-driven remotes.
- Visual effects (explosions, spell VFX, view models) are created on clients; the server only decides outcomes and broadcasts a small event.
- Never tween on the server; tween on clients (server tweens replicate every frame and jitter).
- Creating/destroying huge instance trees at runtime is network-heavy; chunk it. Enable StreamingEnabled for big maps.
- Strip leftover animation editor data from rigs before publishing.

## Physics / humanoids

- Anchor anything that doesn't need to move.
- Use `CollisionFidelity` Box/Hull for complex meshes that don't need precise collision.
- Disable unused Humanoid states on NPCs; for crowds consider non-Humanoid NPCs.
