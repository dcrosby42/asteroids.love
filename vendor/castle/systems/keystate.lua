local EventHelpers = require "castle.systems.eventhelpers"
local Comps = require "castle.components"

local function isHandling(keyst, key)
  return lcontains(keyst.handle, key)
end

return defineUpdateSystem({ "keystate" },
  function(e, estore, input, res)
    local keyst = e.keystate
    for key, _ in pairs(keyst.pressed) do
      keyst.pressed[key] = false
    end
    for key, _ in pairs(keyst.released) do
      keyst.released[key] = false
    end
    EventHelpers.handle(input.events, "keyboard", {
      pressed = function(evt)
        local key = evt.key
        if not isHandling(keyst, key) then return false end
        keyst.pressed[key] = true
        keyst.held[key] = true
        -- return false
      end,
      released = function(evt)
        local key = evt.key
        if not isHandling(keyst, key) then return false end
        keyst.pressed[key] = false
        keyst.held[key] = false
        keyst.released[key] = true
        -- return false
      end,
    })
  end)
