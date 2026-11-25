--!strict
-- Session-buffered player data: load once, mutate in memory, save periodically / on leave / on shutdown.
-- No session locking here. For games with trading or Robux purchases, use a maintained module with
-- session locking (e.g. ProfileStore) or add your own lock before shipping.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DATA_STORE_NAME = "PlayerData"
local KEY_PREFIX = "User_"
local SCHEMA_VERSION = 1
local AUTOSAVE_SECONDS = 180
local MAX_ATTEMPTS = 5
local MAX_RETRY_DELAY = 16

export type PlayerData = {
	version: number,
	coins: number,
	inventory: { [string]: number },
}

local DataService = {}

local store = DataStoreService:GetDataStore(DATA_STORE_NAME)
local sessions: { [Player]: PlayerData } = {}

local function defaultData(): PlayerData
	return { version = SCHEMA_VERSION, coins = 0, inventory = {} }
end

local function keyFor(player: Player): string
	return `{KEY_PREFIX}{player.UserId}`
end

-- pcall with exponential backoff + jitter. Returns ok, result-or-error.
local function withRetries<T>(operation: () -> T): (boolean, any)
	local lastError: any = nil
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < MAX_ATTEMPTS then
			local delay = math.min(MAX_RETRY_DELAY, 2 ^ (attempt - 1))
			task.wait(delay + math.random() * delay * 0.5)
		end
	end
	return false, lastError
end

local function migrate(raw: any): PlayerData
	local data = defaultData()
	if typeof(raw) ~= "table" then
		return data
	end
	data.coins = if typeof(raw.coins) == "number" then raw.coins else 0
	data.inventory = if typeof(raw.inventory) == "table" then raw.inventory else {}
	return data
end

local function load(player: Player)
	local ok, result = withRetries(function()
		return store:GetAsync(keyFor(player))
	end)

	if not ok then
		-- Never hand out a blank profile on a failed load: it would overwrite real data on save.
		warn(`DataService: load failed for {player.UserId}: {result}`)
		player:Kick("We couldn't load your data. Please rejoin.")
		return
	end

	if player.Parent then
		sessions[player] = migrate(result)
	end
end

local function save(player: Player)
	local data = sessions[player]
	if not data then
		return
	end

	local ok, result = withRetries(function()
		return store:UpdateAsync(keyFor(player), function(_old)
			-- Pure and fast: no yields, no side effects. May run more than once.
			return data
		end)
	end)

	if not ok then
		warn(`DataService: save failed for {player.UserId}: {result}`)
	end
end

function DataService.get(player: Player): PlayerData?
	return sessions[player]
end

-- Atomically (in memory) spend coins and grant an item. Returns false if not loaded or can't afford.
function DataService.trySpendAndGrant(player: Player, cost: number, itemId: string, quantity: number): boolean
	local data = sessions[player]
	if not data or cost < 0 or data.coins < cost then
		return false
	end
	data.coins -= cost
	data.inventory[itemId] = (data.inventory[itemId] or 0) + quantity
	return true
end

local function autosaveLoop()
	-- Random offset so every server doesn't save on the same second.
	task.wait(math.random() * AUTOSAVE_SECONDS)
	while true do
		for player in sessions do
			task.spawn(save, player)
		end
		task.wait(AUTOSAVE_SECONDS)
	end
end

local function onPlayerRemoving(player: Player)
	save(player)
	sessions[player] = nil
end

local function onClose()
	if RunService:IsStudio() then
		return
	end
	local pending = 0
	for player in sessions do
		pending += 1
		task.spawn(function()
			save(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end

function DataService.start()
	Players.PlayerAdded:Connect(load)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	game:BindToClose(onClose)
	task.spawn(autosaveLoop)
end

return DataService
