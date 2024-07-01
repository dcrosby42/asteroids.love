local Ship = require "modules.asteroids.entities.ship"
local Workbench = require "modules.asteroids.entities.workbench"
local Menu = require "modules.asteroids.jigs.menu"

local BulletEditorJig = {}

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

function BulletEditorJig.init(parent, estore, res)
  local jig = parent:newEntity({
    { "name",     { name = "bullet_editor" } },
    { "keystate", { handle = { "up", "down", "left", "right", ",", "." } } },
  })
  Workbench.dev_background(jig, res)

  local ship = Ship.ship(jig, res)
  Ship.fireBullet(ship, "left", "ship_bullets_04", -1500)
  Ship.fireBullet(ship, "right", "ship_bullets_04", -1500)

  local menu = Workbench.bulletMenu(estore, res)
  jig:newComp("state", { name = "menu_eid", value = menu.eid })
end

function BulletEditorJig.finalize(jigE, estore)
  -- since the menu is parented higher up in the estore, we have to find and kill it
  local menuEid = jigE.states.menu_eid.value
  if menuEid then
    local menu = estore:getEntity(menuEid)
    if menu then
      menu:destroy()
    end
  end
end

function BulletEditorJig.update(estore, input, res)
  local jig = estore:getEntityByName("bullet_editor")
  adjustBulletPositions(jig)
  adjustBulletSize(jig)

  local menu = estore:getEntityByName("bullet_menu")
  local choices = Workbench.Bullets
  -- print("gm")
  if menu then
    local changed = false
    if menu.keystate.pressed.j then
      Menu.incrementMenuSelection(menu, choices, -1, estore)
      changed = true
    end
    if menu.keystate.pressed.k then
      Menu.incrementMenuSelection(menu, choices, 1, estore)
      changed = true
    end
    if changed then
      local picId = Menu.getMenuChoice(menu, choices)
      setShipBulletPic(picId, estore)
    end
  end
end

return BulletEditorJig
