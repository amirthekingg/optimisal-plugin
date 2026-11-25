--!strict
-- Validation helpers for anything that arrives from a client.
-- Remote params are `unknown` until one of these returns them typed.

local Guard = {}

-- Finite number within [min, max]. Rejects NaN and +/-inf.
function Guard.number(value: unknown, min: number, max: number): number?
	if typeof(value) ~= "number" or not math.isfinite(value) then
		return nil
	end
	if value < min or value > max then
		return nil
	end
	return value
end

-- Whole number within [min, max].
function Guard.integer(value: unknown, min: number, max: number): number?
	local n = Guard.number(value, min, max)
	if n == nil or n % 1 ~= 0 then
		return nil
	end
	return n
end

-- String no longer than maxLength (bytes).
function Guard.string(value: unknown, maxLength: number): string?
	if typeof(value) ~= "string" or #value > maxLength then
		return nil
	end
	return value
end

-- Real Instance (not a table pretending to be one) of the given class, inside the expected container.
function Guard.instanceIn(value: unknown, className: string, container: Instance): Instance?
	if typeof(value) ~= "Instance" then
		return nil
	end
	if not value:IsA(className) or not value:IsDescendantOf(container) then
		return nil
	end
	return value
end

-- Key that exists in a server-owned lookup table.
function Guard.oneOf<T>(value: unknown, lookup: { [string]: T }, maxLength: number?): T?
	local key = Guard.string(value, maxLength or 64)
	if key == nil then
		return nil
	end
	return lookup[key]
end

-- Character is alive and its root is within maxDistance studs of position.
function Guard.isNear(player: Player, position: Vector3, maxDistance: number): boolean
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - position).Magnitude <= maxDistance
end

return Guard
