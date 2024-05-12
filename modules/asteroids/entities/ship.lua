local W = require "modules.asteroids.entities.world"

local Ship = {}

function Ship.workbench(parent, res)
  local world, viewport = W.basicWorldAndViewport(parent, res)
  world:newEntity({
    { "name",     { name = "ship_workbench" } },
    { "state",    { name = "jig", value = "" } },
    { "state",    { name = "debug_draw", value = false } },
    { "keystate", { handle = { "1", "2", "3", "4", "5", "6" } } },
  })
end

function Ship.dev_background(parent, res)
  local picId = "example_background"
  local picw, pich = 1000, 1000
  local offx, offy = -1500, -1500
  local comps = {
    { "name", { name = "devbackground" } },
  }
  for i = 0, 2 do
    local x = offx + (i * picw)
    for j = 0, 2 do
      local y = offy + (j * pich)
      local cmp = { "pic", { id = picId, x = x, y = y } }
      comps[#comps + 1] = cmp
    end
  end
  return parent:newEntity(comps)
end

function Ship.ship(parent, res)
  local ship = parent:newEntity({
    { "tr",   {} },
    { "name", { name = "ship" } },
    { "vel",  {} },
  })
  ship:newEntity({
    { "tag", { name = "ship_flame" } },
    { "tr",  { y = 30 } },
    { 'pic', {
      name = "flame",
      id = "ship_flame_06",
      sx = 0.75,
      sy = 0.75,
      cx = 0.5,
      cy = 0,
    } },
    { "timer", {
      name = "flame",
      reset = 1,
      countDown = false,
      loop = true,
    } },
  })
  ship:newEntity({
    { "tag", { name = "ship_body" } },
    { 'pic', {
      id = "ship_example_05",
      sx = 0.75,
      sy = 0.75,
      cx = 0.5,
      cy = 0.5,
      debug = false,
    } },
  })
  return ship
end

Ship.Flames = { "ship_flame_01", "ship_flame_02", "ship_flame_03", "ship_flame_04", "ship_flame_05", "ship_flame_06",
  "ship_flame_07", "ship_flame_08", "ship_flame_09", "ship_flame_10", "ship_flame_11", }

function Ship.flameMenu(parent, res)
  local w, h = res.data.screen_size.width, res.data.screen_size.height

  local initialSelected = 6
  local menu = parent:newEntity({
    { "tr",       { x = 20, y = h - 80 } },
    { "name",     { name = "flame_menu" } },
    { "state",    { name = "selected", value = initialSelected } },
    { "keystate", { handle = { "j", "k" } } },
    { "label", {
      text = "j,k: select flame | up,down: adjust flame",
      color = { 1, 1, 1 },
      y = -20,
    } }
  })
  local size = 0.5
  local x, y = 0, 0
  for i, picId in ipairs(Ship.Flames) do
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

return Ship
