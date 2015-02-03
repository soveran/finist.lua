Finist
======

Redis based Finite State Machine.

Description
-----------

Finist is a finite state machine that is defined and persisted in
[Redis][redis].

Community
---------

Meet us on IRC: [#lesscode](irc://chat.freenode.net/#lesscode) on
[freenode.net](http://freenode.net/).

Related projects
----------------

* [Finist implemented in Ruby][finist.ruby]
* [Finist implemented in Rust][finist.rust]

Usage
-----

You need to supply a Redis client. There are no restrictions
regarding the type of the Redis client, but it must respond to
`call` and the signature must be identical to that of
[RESP][resp].

```lua
local resp = require("resp")
local client = resp.new("127.0.0.1", 6379)

local finist = require("finist")

-- Initialize with a Redis client, the name of the machine and the
-- initial state. In this example, the machine is called "order" and
-- the initial status is "pending". The Redis client is connected to
-- the default host (127.0.0.1:6379).
local machine = finist.new(resp, "order", "pending")
```

Now you can define the available transitions:

```lua
-- Available transitions are defined with the `on` method
-- `machine:on(<event>, <initial_state>, <final_state>)`
machine:on("approve", "pending", "approved")
machine:on("cancel", "pending", "cancelled")
machine:on("cancel", "approved", "cancelled")
machine:on("reset", "cancelled", "pending")
```

Now that the possible transitions are defined, we can check the
current state:

```lua
machine:state()
# => "pending"
```

And we can trigger an event:

```lua
machine:trigger("approve")
# => true, "approved"
```

The `trigger` method returns two values: the first represents whether
a transition occurred, and the second represents the current state.

Here's what happens if an event doesn't cause a transition:

```lua
machine:trigger("reset")
# => false, "approved"
```

Here's a convenient way to use this flag:

```lua
local changed, state = machine:trigger("reset")

if changed then
  print("State changed to " .. state)
end
```

If you need to remove all the transitions for a given event, you
can use `rm`:

```lua
machine:rm("reset")
```

Note that every change is persisted in Redis.

Installation
------------

You need to have [lsocket](http://www.tset.de/lsocket/) installed,
then just copy finist.lua anywhere in your package.path.

A `packages` file is provided in case you want to use [pac][pac]
to install the dependencies. Follow the instructions in
[pac's documentation][pac] to get started.

[pac]: https://github.com/soveran/pac
[resp]: https://github.com/soveran/resp
[redis]: http://redis.io
[finist.ruby]: https://github.com/soveran/finist
[finist.rust]: https://github.com/badboy/finist
