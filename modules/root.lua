local Switcher = require('castle.modules.switcher')
local GM = require('castle.ecs.gamemodule')

local ModuleMap = {
  asteroids = GM.newFromFile("modules/asteroids/resources.lua"),
}

local M = {}

function M.newWorld()
  local w = {}
  w.switcher = Switcher.newWorld({ modules = ModuleMap, current = "asteroids" })
  return w
end

function M.updateWorld(w, action)
  -- ifKeyPressed(action, "f1", function()
  --   action = { type = "castle.switcher", index = "asteroids" }
  -- end)
  local sidefx
  w.switcher, sidefx = Switcher.updateWorld(w.switcher, action)
  return w, sidefx
end

function M.drawWorld(w)
  Switcher.drawWorld(w.switcher)
end

return M
