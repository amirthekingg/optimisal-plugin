--!strict
-- Minimal cleanup helper. Anything that owns connections, instances, threads, or callbacks
-- gives them to a Janitor and calls :cleanup() when it's done.
--   local janitor = Janitor.new()
--   janitor:add(part.Touched:Connect(onTouched))
--   janitor:add(effect)                -- Instance: destroyed
--   janitor:add(function() ... end)    -- called
--   janitor:cleanup()

type Cleanable = RBXScriptConnection | Instance | thread | () -> ()

export type Janitor = {
	items: { Cleanable },
	add: <T>(self: Janitor, item: T) -> T,
	cleanup: (self: Janitor) -> (),
}

local Janitor = {}

local function add<T>(self: Janitor, item: T): T
	local kind = typeof(item)
	assert(
		kind == "RBXScriptConnection" or kind == "Instance" or kind == "thread" or kind == "function",
		`Janitor can't clean up a {kind}`
	)
	table.insert(self.items, item :: any)
	return item
end

local function cleanItem(item: Cleanable)
	if typeof(item) == "RBXScriptConnection" then
		item:Disconnect()
	elseif typeof(item) == "Instance" then
		item:Destroy()
	elseif typeof(item) == "thread" then
		if coroutine.status(item) ~= "dead" then
			task.cancel(item)
		end
	elseif typeof(item) == "function" then
		item()
	end
end

local function cleanup(self: Janitor)
	local items = self.items
	self.items = {}
	-- Reverse order: undo things in the opposite order they were set up.
	for index = #items, 1, -1 do
		cleanItem(items[index])
	end
end

function Janitor.new(): Janitor
	return {
		items = {},
		add = add,
		cleanup = cleanup,
	}
end

return Janitor
