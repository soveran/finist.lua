-- Script for updating the fsm by triggering an event.
-- Return the new state and true if a transition occurred,
-- or the current state and false if no transitions
-- were available for the passed event.
local script = [[
	local curr = redis.call("GET", KEYS[1])
	local next = redis.call("HGET", KEYS[2], curr)

	if next then
		redis.call("SET", KEYS[1], next)
		return { next, true }
	else
		return { curr, false }
	end
]]

-- Combine the fsm and event names
local key = function(name, ev)
	return name .. ":" .. ev
end

-- Define a transition from `curr` to `next` given the event `ev`.
-- For example:
--
--   fsm:on("stop", "running", "stopped")
--   fsm:on("start", "stopped", "running")
--
-- It is possible to define many transitions for the same event:
--
--   fsm:on("cancel", "pending", "cancelled")
--   fsm:on("cancel", "approved", "cancelled")
local on = function(self, ev, curr, next)
	self.redis:call("HSET", key(self.name, ev), curr, next)
end

-- Remove transitions for event `ev`
local rm = function(self, ev)
	self.redis:call("DEL", key(self.name, ev))
end

-- Return current state
local state = function(self)
	return self.redis:call("GET", self.name)
end

-- Send the script to redis and return the result
local send = function(self, ev)
	return self.redis:call("EVAL", script, "2", self.name, key(self.name, ev))
end

-- Process an event and return the new state and true
-- if a transition occurred, or the current state and
-- false if no transitions were available.
--
-- Example:
--
--   local changed, state = fsm:trigger("stop")
--
--   if changed then
--   	print("state changed to " .. state) 
--   end
local trigger = function(self, ev)
	local result = send(self, ev)

	if result[2] then
		return true, result[1]
	else
		return false, result[1]
	end
end

-- Methods available for the fsm
local metatable = {
	__index = {
		on = on,
		rm = rm,
		state = state,
		trigger = trigger,
	}
}

-- Return a fsm with name `name` and `init` as the
-- initial state.
local new = function(redis, name, init)
	local self = setmetatable({}, metatable)

	self.name = "finist:" .. name

	self.redis = redis
	self.redis:call("SET", self.name, init, "NX")

	return self
end

return {
	new = new,
}
