local Ship = require "modules.asteroids.entities.ship"
local Menu = require "modules.asteroids.jigs.menu"
local State = require "castle.state"
local TweenHelpers = require "castle.tween.tween_helpers"

-- Reasonable scaling ranges:
--   small: 0.5 thru 1.5
--   medium: 0.3 thru 0.75
--   large: 0.15 thru 2.75
local RoidPics = {
  "roid_small_grey_01",
  "roid_small_red_01",

  "roid_small_grey_02",
  "roid_small_red_02",

  "roid_medium_grey_01",
  "roid_medium_red_01",

  "roid_medium_grey_02",
  "roid_medium_red_02",

  "roid_medium_grey_03",
  "roid_medium_red_03",

  "roid_large_grey_01",
  "roid_large_red_01",

  "roid_large_grey_02",
  "roid_large_red_02",

  "roid_large_grey_03",
  "roid_large_red_03",
}

local Jig = {}

function Jig.newRoidMenu(parent, res)
  local w, h = res.data.screen_size.width, res.data.screen_size.height

  local initialSelected = 1
  local menu = parent:newEntity({
    { "tr",       { x = 20, y = h - 150 } },
    { "name",     { name = "roid_menu" } },
    { "state",    { name = "selected", value = initialSelected } },
    { "keystate", { handle = { "j", "k" } } },
    { "label", {
      text = "Roids! j,k: select",
      color = { 1, 1, 1 },
      y = -20,
    } }
  })
  local choices = RoidPics
  local size = 0.5
  local x, y = 0, 0
  for i, picId in ipairs(choices) do
    x = (i - 1) * 50
    menu:newEntity({
      { "name", { name = "menu-" .. picId } },
      { "tr",   { x = x, y = y } },
      { 'pic', {
        id = picId,
        sx = size,
        sy = size,
        y = 20,
        x = 50 / 2,
        cx = 0.5,
      } },
      { "label", {
        text = tostring(i),
        color = { 1, 1, 1 },
        align = "middle",
        -- cx = 0.5,
        -- y = -40,
        w = 50,
        h = 20,
      } },
    })
  end

  menu:newEntity({
    { "name", { name = "menu_cursor" } },
    { "tr",   { x = (initialSelected - 1) * 50, } },
    { "rect", { w = 50, h = 70, color = { 1, 1, 1, 1 } } }
  })
  return menu
end

function Jig.newRoid(parent, res)
  local s = 1
  parent:newEntity({
    { "name", { name = "the_roid" } },
    { "tag",  { name = "roid" } },
    { 'tr',   { x = 0, y = 0, } },
    { 'pic', {
      -- id = "roid_medium_grey_a1",
      id = "roid_large_grey_a1",
      -- x = -100,
      -- y = -50,
      cx = 0.5,
      cy = 0.5,
      sx = s,
      sy = s,
      -- r = math.pi / 4,
      debug = false,
    } },
    -- { 'timer', { countDown = false, } }
  })
end

function Jig.init(parent, estore, res)
  local jig = parent:newEntity({
    { "name",     { name = "roid_browser" } },
    { "keystate", { handle = { "up", "down", "left", "right", ",", "." } } },
  })
  Ship.dev_background(jig, res)

  Jig.newRoid(jig, res)

  local menu = Jig.newRoidMenu(estore, res)
  jig:newComp("state", { name = "menu_eid", value = menu.eid })
end

function Jig.finalize(jigE, estore)
  -- since the menu is parented higher up in the estore, we have to find and kill it
  local menuEid = State.get(jigE, "menu_eid")
  if menuEid then
    local menu = estore:getEntity(menuEid)
    if menu then
      menu:destroy()
    end
  end
end

local matchRoids = hasTag("roid")

local function moveRoids(jig, input)
  jig:walkEntities(matchRoids, function(e)
    if e then
      e.tr.r = e.tr.r + (0.3 * input.dt)
      -- e.tr.x = e.tr.x + (18 * input.dt)
      -- e.tr.y = e.tr.y + (36 * input.dt)
    end
  end)
end

local function controlRoid(jig)
  local action
  if jig.keystate.pressed.up then
    action = "zoom_in"
  elseif jig.keystate.pressed.down then
    action = "zoom_out"
  end
  if action then
    jig:seekEntity(hasName("the_roid"), function(e)
      local factor = 0.25
      local mul
      if action == "zoom_in" then
        mul = 1 + factor
      elseif action == "zoom_out" then
        mul = 1 - factor
      end
      local s = e.tr.sx * mul
      print("Roid scale: " .. tostring(s))
      TweenHelpers.tweenit(e, "scale", { tr = { sx = s, sy = s } }, { duration = 0.3 })
      -- zoomCameraTo(camera, camera.tr.sx * (1 - factor))

      return true
    end)
  end
end

function Jig.update(estore, input, res)
  local jig = estore:getEntityByName("roid_browser")

  moveRoids(jig, input)
  controlRoid(jig)

  local menu = estore:getEntityByName("roid_menu")
  local choices = RoidPics
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
      local roidE = estore:getEntityByName("the_roid")
      if roidE then
        roidE.pic.id = picId
      end
    end
  end
end

return Jig
