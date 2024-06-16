local EventHelpers = require "castle.systems.eventhelpers"
local Comps = require "castle.components"

local function shouldHandle(keyst, key)
  return lcontains(keyst.handle, key)
end

return defineQuerySystem(
  "keystate",
  function(e, estore, input, res)
    local keyst = e.keystate
    -- reset "pressed" state:
    for key, _ in pairs(keyst.pressed) do
      keyst.pressed[key] = false
    end
    -- reset "released" state:
    for key, _ in pairs(keyst.released) do
      keyst.released[key] = false
    end
    EventHelpers.handle(input.events, "keyboard", {
      pressed = function(evt)
        local key = evt.key
        if not shouldHandle(keyst, key) then return false end
        keyst.pressed[key] = true
        keyst.held[key] = true
        return keyst.consume
      end,
      released = function(evt)
        local key = evt.key
        if not shouldHandle(keyst, key) then return false end
        keyst.pressed[key] = false
        keyst.held[key] = false
        keyst.released[key] = true
        return keyst.consume
      end,
    })
  end)
