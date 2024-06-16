Comps = require "castle.components"
State = require "castle.state"
Query = require "castle.ecs.query"


Comps.define('cooldown', {
  "t", 1,
  "state", "ready",
});

local READY = "ready"
local COOLDOWN = "cooldown"
local TRIGGERED = "triggered"

local function _start(e, cooldown, timer)
  if not cooldown then return end
  if timer then
    timer.t = cooldown.t
  else
    e:newComp("timer", { name = cooldown.name, t = cooldown.t })
  end
  cooldown.state = COOLDOWN
end

local function _reset(e, cooldown, timer)
  if not cooldown then return end
  e:removeComp(timer)
  cooldown.state = READY
end

local Cooldown = {}

function Cooldown.isReady(e, name)
  return e.cooldowns and e.cooldowns[name] and e.cooldowns[name].state == READY
end

function Cooldown.trigger(e, name)
  _start(e, e.cooldowns and e.cooldowns[name], e.timers and e.timers[name])
end

local query = Query.create({
  indexLookup = { name = "byCompType", key = "cooldown" }
})

Cooldown.system = defineQuerySystem(
  "cooldown",
  function(e, estore, input, res)
    for _, cooldown in pairs(e.cooldowns) do
      local name = cooldown.name
      local timer = e.timers and e.timers[name]
      if cooldown.state == COOLDOWN and timer and timer.alarm then
        _reset(e, cooldown, timer)
      end
    end
  end)

return Cooldown
