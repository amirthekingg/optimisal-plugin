# Data stores

Source: Creator Docs > Cloud services > Data stores (best practices, error codes and limits, player data and purchasing).

## Design

- Few data stores (e.g. one `PlayerData`), records organized by key.
- One key per player when it fits under 4 MB: `User_{UserId}`. Static, stable patterns only. Never DisplayName or Name (they change). Static patterns also make right-to-be-forgotten processing work.
- Keep data that must change together in the same key.
- Include a `version` field in the saved table so you can migrate schemas.
- Third-party modules (e.g. ProfileStore) are fine; review maintenance status and know how to migrate off. DataStore2 is legacy; don't start new projects on it.

## Session pattern

1. On join: load with retries. If load fails, do NOT give the player a blank profile that will later overwrite real data. Kick with a message or retry; mark the session unsaveable.
2. During play: mutate the in-memory copy only.
3. Save: periodically (with a random initial offset per server so servers don't sync up), on `PlayerRemoving`, on `game:BindToClose`, and at critical checkpoints (purchase processing).
4. On leave: save, then clear the in-memory entry.

## Writes

- Prefer `UpdateAsync` when the write depends on the current value or multiple servers may write the key. Use `SetAsync` only for brand-new keys or full replacement.
- `UpdateAsync` callbacks must be pure and fast: no yielding, no side effects (they may run more than once). Return `nil` to cancel.
- A failed write may still have succeeded on the backend. Design for unknown outcomes (idempotent purchase records).
- Process retries in order per key so an old retry can't overwrite newer data.

## Retries

```lua
--!strict
local MAX_ATTEMPTS = 5
local BASE_DELAY = 1
local MAX_DELAY = 16

local function withRetries<T>(operation: () -> T): (boolean, T | string)
	local lastError = ""
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		lastError = tostring(result)
		if attempt < MAX_ATTEMPTS then
			local delay = math.min(MAX_DELAY, BASE_DELAY * 2 ^ (attempt - 1))
			task.wait(delay + math.random() * delay * 0.5) -- jitter
		end
	end
	return false, lastError
end
```

Don't retry errors caused by invalid requests (bad key, value too large); fix the request.

## BindToClose

```lua
game:BindToClose(function()
	if RunService:IsStudio() then
		return -- optional: skip saves in Studio playtests
	end
	local pending = 0
	for _, player in Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			saveProfile(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)
```

The server has ~30 seconds after shutdown begins. Save in parallel, not sequentially.

## Operations

Use the Data Stores Observability Dashboard and alerts to watch failure rates; Data Stores Manager to inspect individual keys; Open Cloud for bulk fixes. Open Cloud and game servers share the same experience-level request budget.
