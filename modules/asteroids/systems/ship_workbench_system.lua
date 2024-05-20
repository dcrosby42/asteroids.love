local EventHelpers = require "castle.systems.eventhelpers"
local TweenHelpers = require "castle.tween.tween_helpers"
local State = require "castle.state"
local Ship = require "modules.asteroids.entities.ship"
local Vec = require 'vector-light'

local min = math.min
local sin = math.sin
local pi = math.pi

local matchShipFlame = hasTag("ship_flame")


local function getMenuChoice(menu, choices)
  local selected = State.get(menu, "selected")
  return choices[selected]
end

local function setShipFlamePic(flamePicId, estore)
  estore:seekEntity(hasTag("ship_flame"), function(e)
    e.pic.id = flamePicId
    return true
  end)
end

local function incrementMenuSelection(menu, choices, inc, estore)
  local selected = State.get(menu, "selected")
  selected = selected + inc
  if selected < 1 then
    selected = #choices
  elseif selected > #choices then
    selected = 1
  end
  print("menu selected " .. tostring(selected))
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
  if ship.keystate.pressed.space then
    Ship.fireBullet(ship, "left", "ship_bullets_04", -1500)
    Ship.fireBullet(ship, "right", "ship_bullets_04", -1500)
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

  -- (testing: motion should be a different system) Apply velocity to get motion
  ship.tr.x = ship.tr.x + ship.vel.dx
  ship.tr.y = ship.tr.y + ship.vel.dy
end

local function controlShipBullets(estore, input, res)
  estore:walkEntities(allOf(hasTag("ship_bullet"), hasComps("tr", "vel")), function(e)
    e.tr.x = e.tr.x + (e.vel.dx * input.dt)
    e.tr.y = e.tr.y + (e.vel.dy * input.dt)
  end)
end

local JigSystems = {}

function JigSystems.init_test_flight(parent, estore, res)
  local jig = parent:newEntity({
    { "name", { name = "test_flight" } },
    { "tag",  { name = "jig" } },
  })
  Ship.dev_background(jig, res)
  local ship = Ship.ship(jig, res)
  ship:newComp("keystate", { handle = { "left", "right", "up", "down", "space" } })
end

function JigSystems.test_flight(estore, input, res)
  controlShip(estore, input, res)
  controlShipBullets(estore, input, res)
  -- Animate ship flame
  estore:seekEntity(matchShipFlame, function(flameE)
    flameE.pic.sy = 0.75 + sin(flameE.timer.t * 4 * pi * 2) * 0.1
    return true
  end)
end

function JigSystems.init_flame_editor(parent, estore, res)
  local jig = parent:newEntity({
    { "name", { name = "flame_editor" } },
  })
  -- local world = Ship.basicWorld(jig, res, E)
  Ship.dev_background(jig, res)
  local ship = Ship.ship(jig, res)
  -- show ship flame: (it's there, but its alpha is 0)
  estore:seekEntity(matchShipFlame, function(flameE)
    flameE.pic.color[4] = 1
    return true
  end)

  local menu = Ship.flameMenu(estore, res)
  jig:newComp("state", { name = "menu_eid", value = menu.eid })
end

function JigSystems.finalize_flame_editor(jigE, estore)
  -- since the menu is parented higher up in the estore, we have to find and kill it
  local menuEid = jigE.states.menu_eid.value
  if menuEid then
    local menu = estore:getEntity(menuEid)
    if menu then
      menu:destroy()
    end
  end
end

function JigSystems.flame_editor(estore, input, res)
  local menu = estore:getEntityByName("flame_menu")
  local choices = Ship.Flames
  if menu then
    adjustFlamePosition(estore, input, res)

    local changed = true
    if menu.keystate.pressed.j then
      incrementMenuSelection(menu, choices, -1, estore)
      changed = true
    end
    if menu.keystate.pressed.k then
      incrementMenuSelection(menu, choices, 1, estore)
      local picId = getMenuChoice(menu, choices)
      setShipFlamePic(picId, estore)
    end
    if changed then
      local picId = getMenuChoice(menu, choices)
      setShipFlamePic(picId, estore)
    end
  end
end

--
-- BULLET EDITOR
--

local function setShipBulletPic(flamePicId, estore)
  estore:walkEntities(hasTag("ship_bullet"), function(e)
    e.pic.id = flamePicId
  end)
end

local function adjustBulletSize(jig)
  local change = 0
  if jig.keystate.pressed[","] then
    change = 0.9
  elseif jig.keystate.pressed["."] then
    change = 1.1
  end
  if change ~= 0 then
    print(change)
    jig:walkEntities(hasTag("ship_bullet"), function(e)
      local s = e.pic.sx
      s = s * change
      e.pic.sx = s
      e.pic.sy = s
      print("bullet size" .. e.name.name .. " " .. tostring(e.pic.sx))
    end)
  end
end

local function adjustBulletPositions(jig)
  local dy = 0
  local dx = 0
  if jig.keystate.pressed.up then
    dy = -1
  end
  if jig.keystate.pressed.down then
    dy = 1
  end
  if jig.keystate.pressed.left then
    dx = -1
  end
  if jig.keystate.pressed.right then
    dx = 1
  end
  if dy ~= 0 or dx ~= 0 then
    jig:walkEntities(hasTag("ship_bullet"), function(e)
      local sign = 1
      if e.name.name == "ship_bullet_left" then
        sign = -1
      end
      e.tr.x = e.tr.x + (sign * dx)
      e.tr.y = e.tr.y + dy
      print("bullet " .. e.name.name .. " " .. tostring(e.tr.x) .. ", " .. tostring(e.tr.y))
    end)
  end
end

function JigSystems.init_bullet_editor(parent, estore, res)
  local jig = parent:newEntity({
    { "name",     { name = "bullet_editor" } },
    { "keystate", { handle = { "up", "down", "left", "right", ",", "." } } },
  })
  Ship.dev_background(jig, res)

  local ship = Ship.ship(jig, res)
  Ship.fireBullet(ship, "left", "ship_bullets_04", -1500)
  Ship.fireBullet(ship, "right", "ship_bullets_04", -1500)

  local menu = Ship.bulletMenu(estore, res)
  jig:newComp("state", { name = "menu_eid", value = menu.eid })
end

function JigSystems.finalize_bullet_editor(jigE, estore)
  -- since the menu is parented higher up in the estore, we have to find and kill it
  local menuEid = jigE.states.menu_eid.value
  if menuEid then
    local menu = estore:getEntity(menuEid)
    if menu then
      menu:destroy()
    end
  end
end

function JigSystems.bullet_editor(estore, input, res)
  local jig = estore:getEntityByName("bullet_editor")
  adjustBulletPositions(jig)
  adjustBulletSize(jig)

  local menu = estore:getEntityByName("bullet_menu")
  local choices = Ship.Bullets
  -- print("gm")
  if menu then
    local changed = false
    if menu.keystate.pressed.j then
      incrementMenuSelection(menu, choices, -1, estore)
      changed = true
    end
    if menu.keystate.pressed.k then
      incrementMenuSelection(menu, choices, 1, estore)
      changed = true
    end
    if changed then
      local picId = getMenuChoice(menu, choices)
      setShipBulletPic(picId, estore)
    end
  end
end

-- map of kbd presses to jigs:
local JigSelectorMap = {
  ["1"] = "test_flight",
  ["2"] = "bullet_editor",
  ["3"] = "flame_editor",
}
local DefaultJigName = "test_flight"
-- local DefaultJigName = "bullet_editor"

local function transitionToJig(jigName, workbench, estore, res)
  local currentJigName = workbench.states.jig.value
  local system = JigSystems[jigName]
  local init = JigSystems["init_" .. jigName]
  if system and init then
    if currentJigName then
      -- destroy current jig
      local jig = estore:getEntityByName(currentJigName)
      if jig then
        local finalize = JigSystems["finalize_" .. currentJigName]
        if finalize then
          finalize(jig, estore)
        end
        jig:destroy()
      end
    end
    -- create new jig entities(s)
    init(workbench, estore, res)
    -- Update the workbench's jig name
    workbench.states.jig.value = jigName
  end
end

return function(estore, input, res)
  local workbench = estore:getEntityByName("ship_workbench")
  if not workbench then return end

  local currentJigName = workbench.states.jig.value
  if not currentJigName or currentJigName == "" then
    -- Create default jig
    transitionToJig(DefaultJigName, workbench, estore, res)
  else
    -- See if a jig selector was pushed
    local jigSelected
    for key, name in pairs(JigSelectorMap) do
      if workbench.keystate.pressed[key] then
        jigSelected = name
      end
    end
    -- (if so) Switch away from current jig to new jig
    if jigSelected then
      transitionToJig(jigSelected, workbench, estore, res)
    end
  end

  -- Update the current jig
  local system = JigSystems[workbench.states.jig.value]
  if system then system(estore, input, res) end
end
