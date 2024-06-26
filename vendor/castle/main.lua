-- Enable loading a dir as a package via ${package}/init.lua
local dir = arg[1]
package.path = package.path .. ";" .. dir .. "/?/init.lua"
package.path = package.path .. ";" .. dir .. "/vendor/?.lua"
package.path = package.path .. ";" .. dir .. "/vendor/?/init.lua"

local MyDebug = require 'mydebug'
MyDebug.setup()

local ModuleLoader = require "castle.moduleloader"
local GC = require 'garbagecollect'

local soundmanager = require 'castle.soundmanager'

local showDebugLog = false
local Debug = MyDebug.sub("castle.main", true, true)
local JoystickDebug = MyDebug.sub("castle.main.joystick", false, false)

local Joystick = require "castle.joystick"
local DefaultConfig = {
  width = love.graphics.getWidth(),
  height = love.graphics.getHeight(),
}

local Config = DefaultConfig

local Castle = {}

local RootModule
local world, errWorld

INITIAL_FONT = love.graphics.getFont()

local function setErrorMode(err, traceback)
  print("!! CAUGHT ERROR !!")
  print(err)
  print(traceback)
  errWorld = {
    err = err,
    traceback = traceback, -- debug.traceback()
  }
end

local function clearErrorMode()
  errWorld = nil
end

local function loadItUp(opts)
  opts = opts or {}
  Config = tcopy(DefaultConfig)
  if Castle.module_name then
    RootModule = ModuleLoader.load(Castle.module_name)
  elseif Castle.module then
    RootModule = Castle.module
  end
  if not RootModule then
    error("Please specify Castle.module_name or Castle.module")
  end
  if not RootModule.newWorld then
    error("Your module must define a .newWorld() function")
  end
  if not RootModule.updateWorld then
    error("Your module must define an .updateWorld() function")
  end
  if not RootModule.drawWorld then
    error("Your module must define a .drawWorld() function")
  end

  if opts.doOnload ~= false then
    if Castle.onload then Castle.onload() end
    local w, h = love.graphics.getDimensions()
    Config.width = w
    Config.height = h
    Debug.println("castle.onload -> screen size: " .. tostring(w) .. "," .. tostring(h))
    Debug.println("castle.onload -> dpi scale: " .. tostring(love.graphics.getDPIScale()))
  end

  world = RootModule.newWorld(opts.newWorldOpts)
  clearErrorMode()
end

local function reloadRootModule(newWorldOpts)
  love.audio.stop()
  if Castle.module_name then
    local names = ModuleLoader.list_deps_of(Castle.module_name)
    for i = 1, #names do ModuleLoader.uncache_package(names[i]) end
    ModuleLoader.uncache_package(Castle.module_name)

    ok, err = xpcall(function()
      loadItUp({ doOnload = false, newWorldOpts = newWorldOpts })
    end, debug.traceback)
    if ok then
      print("castle.main: Reloaded root module.")
      clearErrorMode()
    else
      print("castle.main: RELOAD FAIL!")
      setErrorMode(err, debug.traceback())
    end
  end
end

CLI_ARGS = {}

function love.load(args)
  CLI_ARGS = args
  loadItUp()
end

local function updateWorld(action)
  if errWorld then
    if action.type == "keyboard" and action.state == "pressed" then
      if action.key == "r" and action.gui then reloadRootModule() end
    end
    return
  end
  if not RootModule then return end
  local newworld, sidefx
  local ok, err = xpcall(function()
    newworld, sidefx = RootModule.updateWorld(world, action)
  end, debug.traceback)
  if ok then
    if newworld then world = newworld end
    if sidefx then
      local reloadEffect = lfindby(sidefx, "type", "castle.reloadRootModule")
      if reloadEffect then
        reloadRootModule(reloadEffect.opts)
      end
      if lfindby(sidefx, "type", "castle.toggleDebugLog") then
        showDebugLog = not showDebugLog
      end
    end
  else
    setErrorMode(err, debug.traceback())
  end
end

local tickAction = { type = "tick", dt = 0 }
function love.update(dt)
  tickAction.dt = dt
  updateWorld(tickAction)
  GC.ifNeeded(dt)
  tickAction.dt = 0
end

local function drawErrorScreen(w)
  love.graphics.reset()
  love.graphics.setBackgroundColor(0.5, 0, 0)
  love.graphics.setFont(INITIAL_FONT)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("!! CAUGHT ERROR !!\n\nHIT 'R' TO RELOAD\n\n" .. w.err ..
    "\n\n(inside castle)" .. w.traceback, 0, 0)
end

function love.draw()
  if errWorld then
    drawErrorScreen(errWorld)
  else
    local ok, err = xpcall(function()
      RootModule.drawWorld(world)
    end, debug.traceback)
    if not ok then
      setErrorMode(err, debug.traceback())
    end
    -- Maintenance of ongoing sound state.  Notably: stop/remove unmaintained sounds:
    soundmanager.cleanup()
  end
end

--
-- INPUT EVENT HANDLERS
--
local function applyKeyboardModifiers(action)
  for _, mod in ipairs({ "ctrl", "shift", "gui" }) do
    action[mod] = false
    action["l" .. mod] = false
    action["r" .. mod] = false
    if love.keyboard.isDown("l" .. mod) then
      action["l" .. mod] = true
      action[mod] = true
    elseif love.keyboard.isDown("r" .. mod) then
      action["r" .. mod] = true
      action[mod] = true
    end
  end
end

local function toKeyboardAction(state, key)
  local keyboardAction = {
    type = "keyboard",
    action = "",
    key = "",
    ctrl = false,
    lctrl = false,
    rctrl = false,
    shift = false,
    lshift = false,
    rshift = false,
    gui = false,
    lgui = false,
    rgui = false,
  }
  keyboardAction.state = state
  keyboardAction.key = key
  applyKeyboardModifiers(keyboardAction)
  return keyboardAction
end
function love.keypressed(key, _scancode, _isrepeat)
  updateWorld(toKeyboardAction("pressed", key))
end

function love.keyreleased(key, _scancode, _isrepeat)
  updateWorld(toKeyboardAction("released", key))
end

local mouseAction = {
  type = "mouse",
  state = nil,
  x = 0,
  y = 0,
  dx = 0,
  dy = 0,
  button = 0,
  isTouch = 0,
  ctrl = false,
  lctrl = false,
  rctrl = false,
  shift = false,
  lshift = false,
  rshift = false,
  gui = false,
  lgui = false,
  rgui = false,
}

local function toMouseAction(s, x, y, b, it, dx, dy)
  mouseAction.state = s
  mouseAction.x = x
  mouseAction.y = y
  mouseAction.button = b
  mouseAction.isTouch = it
  mouseAction.dx = dx
  mouseAction.dy = dy
  applyKeyboardModifiers(mouseAction)
  return mouseAction
end

function love.mousepressed(x, y, button, isTouch, dx, dy)
  updateWorld(toMouseAction("pressed", x, y, button, isTouch))
end

function love.mousereleased(x, y, button, isTouch)
  updateWorld(toMouseAction("released", x, y, button, isTouch))
end

function love.mousemoved(x, y, dx, dy, isTouch)
  updateWorld(toMouseAction("moved", x, y, nil, isTouch, dx, dy))
end

local touchAction = {
  type = "touch",
  state = nil,
  id = "",
  x = 0,
  y = 0,
  dx = 0,
  dy = 0,
}
local function toTouchAction(s, id, x, y, dx, dy)
  touchAction.state = s
  touchAction.id = tostring(id)
  touchAction.x = x
  touchAction.y = y
  touchAction.dx = dx
  touchAction.dy = dy
  return touchAction
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  updateWorld(toTouchAction("pressed", id, x, y, dx, dy))
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  updateWorld(toTouchAction("moved", id, x, y, dx, dy))
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  updateWorld(toTouchAction("released", id, x, y, dx, dy))
end

local joystickAction = {
  type = "joystick",
  joystickId = 0,
  instanceId = 0,
  controlType = "",
  control = "",
  value = 0,
  controlMap = Joystick.DefaultControlMap,
}
local function toJoystickAction(joystick, controlType, control, value, controlMap)
  controlMap = controlMap or Joystick.getControlMapForJoystick(joystick)

  joystickAction.joystickId, joystickAction.instanceId = joystick:getID()
  joystickAction.name = joystick:getName()
  joystickAction.controlType = controlType
  joystickAction.control = control
  joystickAction.value = (value or 0)
  if controlType == "button" then
    joystickAction.controlName = controlMap.buttonNames[control]
  elseif controlType == "axis" then
    joystickAction.controlName = controlMap.axisNames[control]
  end
  return joystickAction
end

local function joydbg(joystick, msg)
  local id, inst = joystick:getID()
  JoystickDebug.println(joystick:getName() .. " " .. id .. " " .. inst .. ": " .. msg)
end

function love.joystickaxis(joystick, axis, value)
  local controlMap = Joystick.getControlMapForJoystick(joystick)
  value = Joystick.groomAxisValue(controlMap, axis, value)
  joydbg(joystick, "axis " .. axis .. " " .. tostring(value))
  updateWorld(toJoystickAction(joystick, "axis", axis, value, controlMap))
end

function love.joystickpressed(joystick, button)
  joydbg(joystick, "pressed " .. button)
  updateWorld(toJoystickAction(joystick, "button", button, 1))
end

function love.joystickreleased(joystick, button)
  joydbg(joystick, "released " .. button)
  updateWorld(toJoystickAction(joystick, "button", button, 0))
end

function love.textinput(text)
  updateWorld({ type = "textinput", text = text })
end

function love.resize(w, h)
  Debug.println("castle.main: love.resize(" .. tostring(w) .. "," .. tostring(h) .. ")")
  updateWorld({ type = "resize", w = w, h = h })
end

return Castle
