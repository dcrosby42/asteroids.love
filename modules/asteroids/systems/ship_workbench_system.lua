local EventHelpers = require "castle.systems.eventhelpers"
local State = require "castle.state"
local Ship = require "modules.asteroids.entities.ship"
local Vec = require 'vector-light'

local min = math.min
local sin = math.sin
local pi = math.pi
local ZoomFactor = 0.2
local RotFactor = math.pi / 8

local matchWorkbench = hasTag("jig_ship")
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

local function controlCamera(camera, estore, input, res)
  EventHelpers.handleKeyPresses(input.events, {
    ["="] = function(evt)
      zoomCameraIn(camera, ZoomFactor)
    end,
    ["-"] = function(evt)
      zoomCameraOut(camera, ZoomFactor)
    end,
    ["0"] = function(evt)
      zoomCameraTo(camera, 1)
      camera.tr.r = 0
    end,
    ["]"] = function(evt)
      camera.tr.r = camera.tr.r + RotFactor
    end,
    ["["] = function(evt)
      camera.tr.r = camera.tr.r - RotFactor
    end,
    -- ["d"] = function(evt)
    --   res.data.debug_draw = State.toggle(workbenchE, "debug_draw")
    -- end,
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
end

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

-- local function controlJig(workbench, estore, input, res)
-- end

local JigSystems = {}

function JigSystems.init_test_flight(parent, estore, input, res)
  local jig = parent:newEntity({
    { "name", { name = "test_flight" } },
  })
  Ship.dev_background(jig, res)
  local ship = Ship.ship(jig, res)
  ship:newComp("keystate", { handle = { "left", "right", "up", "down" } })
end

function JigSystems.test_flight(estore, input, res)
  controlShip(estore, input, res)
  -- Animate ship flame
  estore:seekEntity(matchShipFlame, function(flameE)
    flameE.pic.sy = 0.75 + sin(flameE.timer.t * 4 * pi * 2) * 0.1
    return true
  end)
end

function JigSystems.init_flame_editor(parent, estore, input, res)
  local jig = parent:newEntity({
    { "name", { name = "flame_editor" } },
  })
  -- local world = Ship.basicWorld(jig, res, E)
  Ship.dev_background(jig, res)
  Ship.ship(jig, res)

  local menu = Ship.flameMenu(estore, res)
  jig:newComp("state", { name = "menu_eid", value = menu.eid })
end

function JigSystems.finalize_flame_editor(jigE, estore)
  local menuEid = jigE.states.menu_eid.value
  if menuEid then
    local menu = estore:getEntity(menuEid)
    if menu then
      menu:destroy()
    end
  end
end

function JigSystems.flame_editor(estore, input, res)
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
    end)
  end
end

local JigSelectorMap = {
  ["1"] = "flame_editor",
  ["2"] = "test_flight",
}

return function(estore, input, res)
  local workbench = estore:getEntityByName("ship_workbench")
  if not workbench then return end

  local jigName = workbench.states.jig.value

  -- See if a jig selector was pushed
  local jigSelected
  for key, name in pairs(JigSelectorMap) do
    if workbench.keystate.pressed[key] then
      jigSelected = name
    end
  end
  -- (if so) Switch away from current jig to new jig
  if jigSelected then
    local system = JigSystems[jigSelected]
    local init = JigSystems["init_" .. jigSelected]
    if system and init then
      -- destroy current jig
      local jig = estore:getEntityByName(jigName)
      if jig then
        local finalize = JigSystems["finalize_" .. jigName]
        if finalize then
          finalize(jig, estore)
        end
        jig:destroy()
      end
      -- create new jig entities(s)
      init(workbench, estore, input, res)
      -- Update the workbench's jig name
      workbench.states.jig.value = jigSelected
    end
  end

  -- Update the current jig
  local system = JigSystems[workbench.states.jig.value]
  if system then system(estore, input, res) end

  -- Apply inputs to camera:
  local camera = estore:getEntityByName("cam1")
  if camera then
    controlCamera(camera, estore, input, res)
  end

  -- controlJig(workbench, estore, input, res)
  -- controlFlameMenu(estore, input, res)
end
