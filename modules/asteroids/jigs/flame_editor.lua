local EventHelpers = require "castle.systems.eventhelpers"
local Ship = require "modules.asteroids.entities.ship"
local Workbench = require "modules.asteroids.entities.workbench"
local Menu = require "modules.asteroids.jigs.menu"

local FlameEditorJig = {}

local function setShipFlamePic(flamePicId, estore)
  estore:seekEntity(hasTag("ship_flame"), function(e)
    e.pic.id = flamePicId
    return true
  end)
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

local matchShipFlame = hasTag("ship_flame")

function FlameEditorJig.init(parent, estore, res)
  local jig = parent:newEntity({
    { "name", { name = "flame_editor" } },
  })
  -- local world = Workbench.basicWorld(jig, res, E)
  Workbench.dev_background(jig, res)
  local ship = Ship.ship(jig, res)
  -- show ship flame: (it's there, but its alpha is 0)
  estore:seekEntity(matchShipFlame, function(flameE)
    flameE.pic.color[4] = 1
    return true
  end)

  local menu = Workbench.flameMenu(estore, res)
  jig:newComp("state", { name = "menu_eid", value = menu.eid })
end

function FlameEditorJig.finalize(jigE, estore)
  -- since the menu is parented higher up in the estore, we have to find and kill it
  local menuEid = jigE.states.menu_eid.value
  if menuEid then
    local menu = estore:getEntity(menuEid)
    if menu then
      menu:destroy()
    end
  end
end

function FlameEditorJig.update(estore, input, res)
  local menu = estore:getEntityByName("flame_menu")
  local choices = Workbench.Flames
  if menu then
    adjustFlamePosition(estore, input, res)

    local changed = true
    if menu.keystate.pressed.j then
      Menu.incrementMenuSelection(menu, choices, -1, estore)
      changed = true
    end
    if menu.keystate.pressed.k then
      Menu.incrementMenuSelection(menu, choices, 1, estore)
      local picId = Menu.getMenuChoice(menu, choices)
      setShipFlamePic(picId, estore)
    end
    if changed then
      local picId = Menu.getMenuChoice(menu, choices)
      setShipFlamePic(picId, estore)
    end
  end
end

return FlameEditorJig
