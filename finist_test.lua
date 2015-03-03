require("pl.strict")

local finist = require("finist")
local resp = require("lib.resp-6e714a9")

local c = resp.new("127.0.0.1", 6379)

local prepare = function(c)
	c:call("SELECT", "5")
	c:call("FLUSHDB")
end

prepare(c)

-- Usage

-- Create a new fsm with client, fsm name and initial state
local fsm = finist.new(c, "myfsm", "pending")

-- Define events and transitions
fsm:on("approve", "pending", "approved")
fsm:on("cancel", "pending", "cancelled")
fsm:on("cancel", "approved", "cancelled")
fsm:on("reset", "cancelled", "pending")

-- Verify initial state
assert(fsm:state() == "pending")

-- Send an event
fsm:trigger("approve")

-- Verify transition to "approved"
assert(fsm:state() == "approved")

-- Send an event
fsm:trigger("cancel")

-- Verify transition to "cancelled"
assert(fsm:state() == "cancelled")

-- Send an event
fsm:trigger("approve")

-- Verify state remains as "cancelled"
assert(fsm:state() == "cancelled")

-- Create a different fsm with client
local fsm2 = finist.new(c, "myfsm", "pending")

-- Verify state remains as "cancelled"
assert(fsm2:state() == "cancelled")

-- A successful event returns true
local state, changed = fsm:trigger("reset")

assert(changed == true)
assert(state == "pending")

-- An unsuccessful event returns false
local state, changed = fsm:trigger("reset")

assert(changed == false)
assert(state == "pending")

-- Delete an event
fsm:rm("approve")

-- Non existent events return false
local state, changed = fsm:trigger("approve")

assert(changed == false)
assert(state == "pending")

