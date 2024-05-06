local EventHelpers = require "castle.systems.eventhelpers"
local State = require "castle.state"
local E = require "modules.asteroids.entities"
local Ship = require "modules.asteroids.entities.ship"

local min = math.min
local sin = math.sin
local pi = math.pi
local ZoomFactor = 0.2
local RotFactor = math.pi / 8

local match = hasTag("jig_ship")
local matchShipFlame = hasTag("ship_flame")

local function zoomCameraTo(camera, zoom)
  camera.tr.sx = zoom
  camera.tr.sy = zoom
end

local function zoomCameraIn(camera, factor)
  -- Zooming camera IN means SHRINKING sx,sy
  zoomCameraTo(camera, camera.tr.sx * (1 - factor))
end

local function zoomCameraOut(camera, factor)
  -- Zooming camera OUT means GROWING sx,sy
  zoomCameraTo(camera, camera.tr.sx * (1 + factor))
end

local function controlCamera(jigE, estore, input, res)
  EventHelpers.handleKeyPresses(input.events, {
    ["="] = function(evt)
      local camera = estore:getEntityByName("camera")
      zoomCameraIn(camera, ZoomFactor)
    end,
    ["-"] = function(evt)
      local camera = estore:getEntityByName("camera")
      zoomCameraOut(camera, ZoomFactor)
    end,
    ["0"] = function(evt)
      local camera = estore:getEntityByName("camera")
      zoomCameraTo(camera, 1)
      camera.tr.r = 0
    end,
    ["]"] = function(evt)
      local camera = estore:getEntityByName("camera")
      camera.tr.r = camera.tr.r + RotFactor
    end,
    ["["] = function(evt)
      local camera = estore:getEntityByName("camera")
      camera.tr.r = camera.tr.r - RotFactor
    end,
    ["d"] = function(evt)
      res.data.debug_draw = State.toggle(jigE, "debug_draw")
    end,
  })
end



-- selectFlameInMenu(estore, input, res)
-- local flamePicId = getFlameMenuValue(estore, input, res)
-- setShipFlamePic(flamePicId, estore)
local function selectFlameInMenu(num, estore, input, res)
  local menu = estore:getEntityByName("flame_menu")
  State.set(menu, "selected", num)
end

local function getFlameMenuValue(estore, input, res)
  local menu = estore:getEntityByName("flame_menu")
  local selected = State.get(menu, "selected")
  local value = Ship.Flames[selected]
  return value
end

local function setShipFlamePic(flamePicId, estore)
  estore:seekEntity(hasTag("ship_flame"), function(e)
    e.pic.id = flamePicId
  end)
  return true
end

local function incrementFlameMenuSelection(inc, estore)
  local menu = estore:getEntityByName("flame_menu")
  local selected = State.get(menu, "selected")
  selected = selected + inc
  if selected < 1 then
    selected = #Ship.Flames
  elseif selected > #Ship.Flames then
    selected = 1
  end
  State.set(menu, "selected", selected)

  local cursorE = estore:getEntityByName("menu_cursor")
  cursorE.tr.x = (selected - 1) * 50
end

local function adjustFlamePosition(estore, input, res)
  EventHelpers.handleKeyPresses(input.events, {
    ["up"] = function(evt)
      -- move flame up
      estore:seekEntity(hasTag("ship_flame"), function(e)
        e.tr.y = e.tr.y - 1
        print("flame.tr.y: " .. tostring(e.tr.y))
        return true
      end)
    end,
    ["down"] = function(evt)
      -- move flame down
      estore:seekEntity(hasTag("ship_flame"), function(e)
        e.tr.y = e.tr.y + 1
        print("flame.tr.y: " .. tostring(e.tr.y))
        return true
      end)
    end,
  })
end

local function controlFlameMenu(estore, input, res)
  local flameMenuE = estore:getEntityByName("flame_menu")
  if flameMenuE then
    adjustFlamePosition(estore, input, res)

    local closeMenu = false
    if flameMenuE.keystate.pressed.j then
      incrementFlameMenuSelection(-1, estore)
      local flamePicId = getFlameMenuValue(estore, input, res)
      setShipFlamePic(flamePicId, estore)
    end
    if flameMenuE.keystate.pressed.k then
      incrementFlameMenuSelection(1, estore)
      local flamePicId = getFlameMenuValue(estore, input, res)
      setShipFlamePic(flamePicId, estore)
    end
    if flameMenuE.keystate.pressed["1"] then
      closeMenu = true
    end
    if closeMenu then
      flameMenuE:destroy()
    end
  else
    EventHelpers.onKeyPressed(input.events, "1", function()
      -- "1" key: instantiate flame menu
      Ship.flameMenu(estore, res, E)
    end)
  end
end

local Vec = require 'vector-light'
local function controlShip(estore, input, res)
  local ship = estore:getEntityByName("ship")
  if not ship then return end

  local spinSpeed = pi * 1.5

  -- Control direction and thrust
  if ship.keystate.held.left then
    ship.tr.r = ship.tr.r - (spinSpeed * input.dt)
  end
  if ship.keystate.held.right then
    ship.tr.r = ship.tr.r + (spinSpeed * input.dt)
  end
  if ship.keystate.held.up then
    -- accelerate under thrust
    local speed = 6
    local dx, dy = Vec.mul(speed * input.dt, Vec.rotate(ship.tr.r, 0, -1))
    ship.vel.dx = ship.vel.dx + dx
    ship.vel.dy = ship.vel.dy + dy
  else
    -- auto-brake
    if Vec.len(ship.vel.dx, ship.vel.dy) > 0 then
      local speed = 6
      local dx, dy = Vec.mul(speed * input.dt, Vec.normalize(Vec.mul(-1, ship.vel.dx, ship.vel.dy)))
      ship.vel.dx = min(ship.vel.dx + dx)
      ship.vel.dy = min(ship.vel.dy + dy)
    end
  end

  -- Show ship flame only when thrust active
  estore:seekEntity(matchShipFlame, function(flameE)
    if ship.keystate.held.up then
      flameE.pic.color[4] = 1
    else
      flameE.pic.color[4] = 0
    end
    return true
  end)

  -- Apply velocity to get motion
  ship.tr.x = ship.tr.x + ship.vel.dx
  ship.tr.y = ship.tr.y + ship.vel.dy
end


return function(estore, input, res)
  controlShip(estore, input, res)

  -- Animate ship flame
  estore:seekEntity(matchShipFlame, function(flameE)
    flameE.pic.sy = 0.75 + sin(flameE.timer.t * 4 * pi * 2) * 0.1
    return true
  end)

  controlFlameMenu(estore, input, res)

  -- Camera controls
  estore:seekEntity(match, function(jigE)
    controlCamera(jigE, estore, input, res)
    return true
  end)
end
