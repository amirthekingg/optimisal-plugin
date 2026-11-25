--!strict
-- Worked example: a server-authoritative shop that follows every rule in this skill.
-- Lives in ServerScriptService/Services. Client sends intent (item id + quantity); server decides everything else.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Guard = require(ServerScriptService.Util.Guard)
local RateLimiter = require(ServerScriptService.Util.RateLimiter)
local DataService = require(ServerScriptService.Services.DataService)

local MAX_QUANTITY = 10
local MAX_SHOP_DISTANCE = 15
local SHOP_COUNTER_TAG = "ShopCounter" -- tag the shop counter part(s) in Studio

type CatalogItem = {
	price: number,
	displayName: string,
}

-- Prices live on the server. The client only ever sees ids and display names.
local CATALOG: { [string]: CatalogItem } = {
	sword_basic = { price = 100, displayName = "Basic Sword" },
	potion_heal = { price = 25, displayName = "Healing Potion" },
}

local ShopService = {}

local purchaseLimiter = RateLimiter.new(3, 1)
local requestPurchase: RemoteEvent
local purchaseResult: RemoteEvent

local function isNearAnyShop(player: Player): boolean
	for _, counter in CollectionService:GetTagged(SHOP_COUNTER_TAG) do
		if counter:IsA("BasePart") and Guard.isNear(player, counter.Position, MAX_SHOP_DISTANCE) then
			return true
		end
	end
	return false
end

local function onRequestPurchase(player: Player, rawItemId: unknown, rawQuantity: unknown)
	-- 1. Rate
	if not purchaseLimiter:consume(player) then
		return
	end

	-- 2-4. Type, size, value
	local item = Guard.oneOf(rawItemId, CATALOG, 32)
	local quantity = Guard.integer(rawQuantity, 1, MAX_QUANTITY)
	if not item or not quantity then
		return
	end

	-- 5. Context
	if not isNearAnyShop(player) then
		purchaseResult:FireClient(player, false, "Too far from the shop")
		return
	end

	local itemId = rawItemId :: string -- safe: validated by Guard.oneOf above
	local totalCost = item.price * quantity
	local success = DataService.trySpendAndGrant(player, totalCost, itemId, quantity)
	purchaseResult:FireClient(player, success, if success then item.displayName else "Not enough coins")
end

local function createRemote(name: string): RemoteEvent
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

function ShopService.start()
	requestPurchase = createRemote("RequestPurchase")
	purchaseResult = createRemote("PurchaseResult")
	requestPurchase.OnServerEvent:Connect(onRequestPurchase)
end

return ShopService
