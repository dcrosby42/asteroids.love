local Ship = require "modules.asteroids.entities.ship"
local Menu = require "modules.asteroids.jigs.menu"
local State = require "castle.state"
local TweenHelpers = require "castle.tween.tween_helpers"

local Jig = {
  name = "JIGNAME"
}

function Jig.init(parent, estore, res)
  local jig = parent:newEntity({
    { "name", { name = Jig.name } }
    -- { "keystate", { handle = { "up", "down", "left", "right", ",", ".", "c" } } },
  })

  -- Ship.dev_background_nebula_blue(jig, res)
  -- Ship.dev_background_starfield1(jig, res)

  return jig
end

function Jig.finalize(jigE, estore)
end

function Jig.update(estore, input, res)
  local jig = estore:getEntityByName(Jig.name)
end

return Jig
