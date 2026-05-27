local Switcher = require('castle.modules.switcher')
local GM = require('castle.ecs.gamemodule')

local ModuleMap = {
  asteroids = GM.newFromFile("modules/asteroids/resources.lua"),
  planets = GM.newFromFile("modules/planets/resources.lua"),
  joystick_debug = require("modules/joystick_debug")
}

local function ifKeyPressed(action, key, fn)
  if action and
      action.type == "keyboard" and
      action.state == "pressed" and
      action.key == key then
    fn()
  end
end

local M = {}

function M.newWorld()
  local w = {}
  w.switcher = Switcher.newWorld({ modules = ModuleMap, current = "planets" })
  return w
end

function M.updateWorld(w, action)
  ifKeyPressed(action, "f1", function()
    action = { type = "castle.switcher", index = "asteroids" }
  end)
  ifKeyPressed(action, "f2", function()
    action = { type = "castle.switcher", index = "planets" }
  end)
  ifKeyPressed(action, "f3", function()
    action = { type = "castle.switcher", index = "joystick_debug" }
  end)
  local sidefx
  w.switcher, sidefx = Switcher.updateWorld(w.switcher, action)
  return w, sidefx
end

function M.drawWorld(w)
  Switcher.drawWorld(w.switcher)
end

return M
