local EventHelpers = require "castle.systems.eventhelpers"
local Comps = require "castle.components"
local inspect = require "inspect"

Comps.define("controller_state", {
  'match_id', '', -- joystick id event matcher
  'value', {},    -- map of control names to current value
  'pressed', {},  -- map of control names to "pressed" state
  'held', {},     -- map of control names to "held" state
  'released', {}, -- map of control names to "released" state
})


return defineQuerySystem("controller_state",
  function(e, estore, input, res)
    local con = e.controller_state

    -- reset "pressed" and "released" state from last update:
    for action, _ in pairs(con.pressed) do
      con.pressed[action] = nil
    end
    for action, _ in pairs(con.released) do
      con.released[action] = nil
    end

    EventHelpers.on(input.events, "controller", function(evt)
      if evt.id == con.match_id then
        con.value[evt.action] = evt.value
        if evt.value == 0 then
          con.released[evt.action] = true
          con.held[evt.action] = nil
        else
          con.pressed[evt.action] = not con.held[evt.action]
          con.held[evt.action] = true
        end
        return true -- consume event
      end
    end)
  end)
