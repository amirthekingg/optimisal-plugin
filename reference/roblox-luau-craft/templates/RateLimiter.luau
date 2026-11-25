--!strict
-- Per-player token bucket. One limiter per remote.
--   local limiter = RateLimiter.new(5, 2) -- burst of 5, refills 2 per second
--   if not limiter:consume(player) then return end
-- Call limiter:forget(player) on PlayerRemoving (or use RateLimiter.autoForget).

local Players = game:GetService("Players")

type Bucket = {
	tokens: number,
	updatedAt: number,
}

export type RateLimiter = {
	capacity: number,
	refillPerSecond: number,
	buckets: { [Player]: Bucket },
	consume: (self: RateLimiter, player: Player) -> boolean,
	forget: (self: RateLimiter, player: Player) -> (),
}

local RateLimiter = {}

local function consume(self: RateLimiter, player: Player): boolean
	local now = os.clock()
	local bucket = self.buckets[player]
	if not bucket then
		bucket = { tokens = self.capacity, updatedAt = now }
		self.buckets[player] = bucket
	end

	local refilled = bucket.tokens + (now - bucket.updatedAt) * self.refillPerSecond
	bucket.tokens = math.min(self.capacity, refilled)
	bucket.updatedAt = now

	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

local function forget(self: RateLimiter, player: Player)
	self.buckets[player] = nil
end

function RateLimiter.new(capacity: number, refillPerSecond: number): RateLimiter
	assert(capacity >= 1, "capacity must be at least 1")
	assert(refillPerSecond > 0, "refillPerSecond must be positive")

	local limiter: RateLimiter = {
		capacity = capacity,
		refillPerSecond = refillPerSecond,
		buckets = {},
		consume = consume,
		forget = forget,
	}

	Players.PlayerRemoving:Connect(function(player)
		limiter:forget(player)
	end)

	return limiter
end

return RateLimiter
