# Security (server authority)

Source: Creator Docs > Scripting > Security (security tactics, client-server boundary, defensive design).

Core law: **never trust the client.** Exploiters can fire any remote with any arguments at any rate, read everything in ReplicatedStorage, and modify anything their client owns (including their character's physics via network ownership).

## The five validation layers (every remote handler)

Apply in this order, cheapest first. Return early on any failure.

1. **Rate**: is this player sending too fast? (token bucket, `templates/RateLimiter.luau`)
2. **Type**: `typeof(arg) == "string"` etc. Params arrive as `unknown`.
3. **Structure/size**: string length caps, table depth/size caps, no tables where an Instance is expected. A table can impersonate an Instance (`{ ClassName = "Folder", Value = 0 }`), so check `typeof(x) == "Instance"` and `x:IsDescendantOf(expectedFolder)`.
4. **Value**: in range, integer when it should be, `math.isfinite(n)` to reject NaN and ±inf. NaN fails every comparison, so `if n < 0 or n > max` silently passes NaN. Always check `isfinite` first.
5. **Context/permission**: is the character alive? Close enough to the shop? Owns the key? Off cooldown? Can afford it (using the SERVER's balance)?

```lua
local function onRequestPurchase(player: Player, itemId: unknown, quantity: unknown)
	if not purchaseLimiter:consume(player) then
		return
	end
	if typeof(itemId) ~= "string" or #itemId > 32 then
		return
	end
	if typeof(quantity) ~= "number" or not math.isfinite(quantity) then
		return
	end
	if quantity < 1 or quantity > 10 or quantity % 1 ~= 0 then
		return
	end
	local item = ItemCatalog[itemId] -- server-side catalog, not a client-sent price
	if not item then
		return
	end
	if not isNearShop(player) then
		return
	end
	DataService.trySpend(player, item.price * quantity)
end
```

## Design rules

- Client sends **intent** ("I want to buy sword", "I fired from here toward there"), never **outcomes** ("give me 500 coins", "I hit Bob for 50").
- Prices, rewards, drop tables, damage values live on the server.
- Combat: client reports origin + hit position/part; server checks origin near server-side character (with latency tolerance), hit position near the hit part, no static geometry between them (raycast against static map only), fire rate, ammo, team, target alive.
- RemoteFunctions: never `InvokeClient` on the server; a malicious client can yield forever or error. Use RemoteEvents for server → client.
- `ProximityPrompt`, `ClickDetector`, `DragDetector`, `Touched` are client-triggerable too. Validate distance and rate on the server in their handlers.
- Client → client communication always goes through the server and gets filtered (`TextService` / `TextChatService` for any user text shown to others).
- Purchases: grant developer products only in `MarketplaceService.ProcessReceipt`, idempotently (record `PurchaseId`, return `PurchaseGranted` only after the data save succeeds).
- Data stores: never write a client-supplied table directly into a data store.
- Don't rely on obscurity (renaming remotes, hiding them). Exploiters see everything.
- Client-side checks are UX only (disable the button), never security.

## Rate limiting

Every client-triggerable server path needs a maximum rate. Especially:
- Anything calling DataStore/Badge/Marketplace APIs (they have their own budgets you'll exhaust).
- Expensive work (cloning big models, pathfinding, raycasts in bulk).
- Exploitable mechanics (teleports, currency, invulnerability).

Use one limiter per remote with limits that fit the feature. Forget the player's bucket on `PlayerRemoving`.

## Review checklist

- [ ] Every `OnServerEvent` / `OnServerInvoke` handler validates all 5 layers
- [ ] No `math.isfinite` gap on any number
- [ ] No string or table without a size cap
- [ ] No server-trusted value comes from the client
- [ ] No secrets/prices/admin lists in ReplicatedStorage
- [ ] No `InvokeClient` from the server
- [ ] ProcessReceipt is idempotent and saves before returning Granted
