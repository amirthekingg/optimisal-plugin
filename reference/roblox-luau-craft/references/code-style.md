# Code style and structure

Based on Roblox Creator Docs: Script locations (Recommendations), Module scripts, Type checking, Task scheduler. Formatting follows StyLua defaults (tabs, 120 cols, double quotes), which most Roblox teams use.

## File header and layout order

Every file follows the same order so anyone (human or AI) can scan it:

```lua
--!strict
-- 1. Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 2. Requires
local Config = require(ReplicatedStorage.Shared.Config)

-- 3. Constants
local MAX_STACK_SIZE = 99

-- 4. Types
type InventoryItem = {
	id: string,
	count: number,
}

-- 5. Module table / state
local Inventory = {}
local inventories: { [Player]: { InventoryItem } } = {}

-- 6. Private functions (local function)
local function findItem(items: { InventoryItem }, id: string): InventoryItem?
	for _, item in items do
		if item.id == id then
			return item
		end
	end
	return nil
end

-- 7. Public API (Module.fn)
function Inventory.getCount(player: Player, id: string): number
	local items = inventories[player]
	if not items then
		return 0
	end
	local item = findItem(items, id)
	return if item then item.count else 0
end

-- 8. start() wires events; nothing runs at require time
function Inventory.start()
	Players.PlayerAdded:Connect(function(player)
		inventories[player] = {}
	end)
	Players.PlayerRemoving:Connect(function(player)
		inventories[player] = nil
	end)
end

return Inventory
```

Rule: requiring a module must have no side effects. Connections and loops start in `start()`, called by the single entry script after all modules are required. This prevents load-order bugs.

## Project structure (Rojo / Script Sync)

```
src/
  server/                     -> ServerScriptService
    Main.server.luau          (only entry point: require modules, call start())
    Services/
      ShopService.luau
      DataService.luau
    Util/                     (server-only helpers: Guard, RateLimiter)
      Guard.luau
      RateLimiter.luau
  client/                     -> ReplicatedStorage.Client (RunContext Client entry) or StarterPlayerScripts
    Main.client.luau
    Controllers/
      ShopController.luau
  shared/                     -> ReplicatedStorage.Shared
    Config.luau
    Types.luau
    Remotes.luau              (creates/looks up all remotes in one place)
```

- Server-only code and secrets (item prices, drop rates, admin lists) live in ServerScriptService or ServerStorage, never ReplicatedStorage. Anything in ReplicatedStorage is readable by exploiters.
- Avoid scripts inside Workspace instances. Tag instances (`CollectionService:AddTag` / Studio Tags) and handle them in one module with `GetTagged` + `GetInstanceAddedSignal` / `GetInstanceRemovedSignal`.

## Naming

| Thing | Style | Example |
|---|---|---|
| Services, modules, classes, types | PascalCase | `ShopService`, `type PlayerData` |
| Locals, functions, params | camelCase | `currentWave`, `getCoins()` |
| Constants | SCREAMING_SNAKE | `RESPAWN_SECONDS` |
| Private module members | leading underscore only if exposed on a table | `self._connections` |
| Booleans | question form | `isEquipped`, `canAfford` |
| Remotes | verb + noun | `RequestPurchase`, `InventoryChanged` |

## Types

- `--!strict` everywhere. If a file genuinely can't be strict, `--!nonstrict` with a comment explaining why.
- Annotate every function signature. Let locals infer.
- Shared shapes go in `shared/Types.luau` and are `export type`.
- Use `?` for optional, `::` casts only at trust boundaries after validation (never to silence the checker on client input).
- Prefer `typeof(x) == "Instance" and x:IsA("BasePart")` over `x.ClassName == "Part"`.

## Control flow

Bad:
```lua
remote.OnServerEvent:Connect(function(player, itemId)
	if player.Character then
		if player.Character:FindFirstChild("Humanoid") then
			if player.Character.Humanoid.Health > 0 then
				-- 4 levels deep before real work
			end
		end
	end
end)
```

Good:
```lua
local function getLivingHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return humanoid
end

local function onRequestUse(player: Player, itemId: unknown)
	if typeof(itemId) ~= "string" or #itemId > 64 then
		return
	end
	local humanoid = getLivingHumanoid(player)
	if not humanoid then
		return
	end
	useItem(player, humanoid, itemId)
end

RequestUse.OnServerEvent:Connect(onRequestUse)
```

- Name callbacks (`onRequestUse`) instead of giant anonymous functions; stack traces become readable.
- Remote params are typed `unknown` until validated.

## Scheduling (task library)

| Legacy | Use instead |
|---|---|
| `wait()` / `wait(n)` | `task.wait()` / `task.wait(n)` |
| `spawn(f)` | `task.defer(f)` or `task.spawn(f)` |
| `delay(n, f)` | `task.delay(n, f)` |

- `task.spawn` runs now; `task.defer` runs at the end of the current resumption cycle. Use `task.spawn(onPlayerAdded, player)` when catching up on players who joined before your connection.
- Always handle existing players:

```lua
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
```

- Deferred events are the default signal behavior: handlers run after the firing code yields, not inline. Don't write code that depends on a handler having already run in the same frame.

## Cleanup (no leaks)

- Every `:Connect` result is stored and disconnected, or belongs to an instance that gets `:Destroy()`ed.
- Player objects and characters are NOT destroyed automatically unless `Workspace.PlayerCharacterDestroyBehavior` is enabled. Enable it, or destroy them yourself:

```lua
Players.PlayerRemoving:Connect(function(player)
	task.defer(player.Destroy, player)
end)
```

- Per-player tables: clear the entry on `PlayerRemoving`.
- Use a small cleanup helper (see `templates/Janitor.luau`) for objects that own many connections/instances.

## Misc rules

- Iterate with generalized iteration: `for key, value in tbl do` (no `pairs`/`ipairs` needed).
- `FindFirstChild` when absence is normal; `WaitForChild` (with a timeout on the server) when it will replicate; direct indexing only when it must exist.
- Use `Attributes` for simple per-instance state instead of `IntValue`/`StringValue` children.
- Compound assignment (`x += 1`), `if then else` expressions, string interpolation `` `Coins: {coins}` `` are idiomatic Luau.
- Comments explain why, not what. Delete commented-out code; that's what Git is for.
- No global variables. Ever.
