-- local Debug = require 'mydebug'
local inspect = require("inspect")

local function renderValues(tracker)
  local s = ""
  for key, val in pairsByKeys(tracker) do
    s = s .. key .. ": " .. tostring(val) .. "\n"
  end
  return s
end

local M = {}

function M.newWorld()
  local world = {
    -- msg = "..."
    tracker = {},
  }
  return world
end

function M.stopWorld(w)
end

function M.updateWorld(w, action)
  if action.state == 'pressed' and action.key == 'r' and action.gui then
    -- Reload game
    return w, { { type = "castle.reloadRootModule" } }
  end

  if action.type == "joystick" then
    local key =
        action.name .. " "
        .. tostring(action.joystickId) .. " "
        .. tostring(action.instanceId) .. " "
        .. action.controlType .. " "
        .. tostring(action.control) .. " "
        .. "(" .. tostring(action.controlName) .. ")"
    w.tracker[key] = action.value
  end
  return w
end

local graphics = love.graphics

function M.drawWorld(w)
  graphics.print("Joystick Debug")
  graphics.print(renderValues(w.tracker), 50, 50)
end

return M
