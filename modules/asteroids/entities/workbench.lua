local W = require "modules.asteroids.entities.world"

local Workbench = {}

function Workbench.workbench(parent, res)
  local world, viewport = W.basicWorldAndViewport(parent, res)
  W.camera_dev_controller(parent, res, viewport.viewport.camera)
  world:newEntity({
    { "name",     { name = "ship_workbench" } },
    { "state",    { name = "jig", value = "" } },
    { "state",    { name = "debug_draw", value = false } },
    { "keystate", { handle = { "1", "2", "3", "4", "5", "6" } } },
  })
end

function Workbench.dev_background(parent, res)
  local picId = "example_background"
  local picw, pich = 1000, 1000
  local offx, offy = -1500, -1500
  local comps = {
    { "name", { name = "devbackground" } },
  }
  -- tile-in a few copies of the bg image
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

function Workbench.dev_stars_bg(parent, configs)
  -- config: pic, paralax
  for _, config in ipairs(configs) do
    local picId = config.pic
    local picw, pich = 4096, 4096
    local offx, offy = -(2 * picw), -(2 * pich)
    local comps = {
      { "name", { name = picId } },
      { "tr",   { parax = config.paralax, paray = config.paralax } },
    }
    -- tile-in a few copies of the bg image
    for i = 0, 2 do
      local x = offx + (i * picw)
      for j = 0, 2 do
        local y = offy + (j * pich)
        local cmp = { "pic", { id = picId, x = x, y = y } }
        comps[#comps + 1] = cmp
      end
    end
  end
  -- return parent:newEntity(comps)
end

function Workbench.dev_background_nebula_blue(parent, res)
  local picId = "nebula_blue"
  local picw, pich = 4096, 4096
  local offx, offy = -(2 * picw), -(2 * pich)
  local comps = {
    { "name", { name = "background_nebula" } },
    { "tr",   { parax = 0.5, paray = 0.5 } },
  }
  -- tile-in a few copies of the bg image
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

function Workbench.dev_background_starfield1(parent, res)
  local picId = "starfield_1"
  local picw, pich = 4096, 4096
  local offx, offy = -(2 * picw), -(2 * pich)
  local comps = {
    { "name", { name = "background_starfield_1" } },
    { "tr",   { parax = 1, paray = 1 } },
  }
  -- tile-in a few copies of the bg image
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

function Workbench.dev_background_starfield2(parent, res)
  local picId = "starfield_2"
  local picw, pich = 4096, 4096
  local offx, offy = -(2 * picw), -(2 * pich)
  local comps = {
    { "name", { name = "background_starfield_1" } },
    { "tr",   { parax = 0.5, paray = 0.5 } },
  }
  -- tile-in a few copies of the bg image
  for i = 0, 2 do
    local x = offx + (i * picw)
    for j = 0, 2 do
      local y = offy + (j * pich)
      local cmp = { "pic", { id = picId, x = x, y = y } }
    end
  end
  return parent:newEntity(comps)
end

Workbench.Flames = { "ship_flame_01", "ship_flame_02", "ship_flame_03", "ship_flame_04", "ship_flame_05", "ship_flame_06",
  "ship_flame_07", "ship_flame_08", "ship_flame_09", "ship_flame_10", "ship_flame_11", }

function Workbench.flameMenu(parent, res)
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
  for i, picId in ipairs(Workbench.Flames) do
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

Workbench.Bullets = map({ "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12" },
  function(num) return "ship_bullets_" .. num end)

function Workbench.bulletMenu(parent, res)
  local w, h = res.data.screen_size.width, res.data.screen_size.height

  local initialSelected = 1
  local menu = parent:newEntity({
    { "tr",       { x = 20, y = h - 80 } },
    { "name",     { name = "bullet_menu" } },
    { "state",    { name = "selected", value = initialSelected } },
    { "keystate", { handle = { "j", "k" } } },
    { "label", {
      text = "j,k: select flame | up,down,left,right: adjust position ",
      color = { 1, 1, 1 },
      y = -20,
    } }
  })
  local size = 0.5
  local x, y = 0, 0
  for i, picId in ipairs(Workbench.Bullets) do
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

return Workbench
