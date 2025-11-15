local Comps = require "castle.components"

Comps.define("boxthing", {})

local SpinSpeed = 0.05
local MoveSpeed = 10

return defineQuerySystem(
  "boxthing",
  function(e, estore, input, res)
    if e.keystate.held["left"] then
      e.tr.r = e.tr.r - SpinSpeed
    end
    if e.keystate.held["right"] then
      e.tr.r = e.tr.r + SpinSpeed
    end
    if e.keystate.held["up"] then
      e.tr.y = e.tr.y - MoveSpeed
    end
    if e.keystate.held["down"] then
      e.tr.y = e.tr.y + MoveSpeed
    end
  end)
