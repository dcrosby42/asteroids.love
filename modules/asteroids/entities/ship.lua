local W = require "modules.asteroids.entities.world"
local Vec = require 'vector-light'

local Ship = {}

function Ship.workbench(parent, res)
  local world, viewport = W.basicWorldAndViewport(parent, res)
  W.camera_dev_controller(parent, res, viewport.viewport.camera)
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

function Ship.dev_stars_bg(parent, configs)
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

function Ship.dev_background_nebula_blue(parent, res)
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

function Ship.dev_background_starfield1(parent, res)
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

function Ship.dev_background_starfield2(parent, res)
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

function Ship.ship(parent, res)
  local ship = parent:newEntity({
    { "tr",               {} },
    { "name",             { name = "ship" } },
    { "vel",              {} },
    { "controller_state", { match_id = "joystick1" } },
    { "ship_controller",  {} },
    { "cooldown",         { name = "lasers", t = 0.05, state = "ready" } }
  })
  ship:newEntity({
    { "tag", { name = "gun_muzzle" } },
    { "tag", { name = "gun_muzzle_left" } },
    { "tr",  { x = -22, y = -9 } },
  })
  ship:newEntity({
    { "tag", { name = "gun_muzzle" } },
    { "tag", { name = "gun_muzzle_right" } },
    { "tr",  { x = 22, y = -9 } },
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
      color = { 1, 1, 1, 0 },
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

local function transformToLocAndDir(transf)
  local x, y = transf:transformPoint(0, 0) -- firing point relative to space ship exists in
  local mrx, mry = transf:transformPoint(0, 1)
  local dirx, diry = mrx - x, mry - y
  local r = Vec.angleTo(dirx, diry, 0, 1)
  return x, y, r, dirx, diry
end

-- Create a new ship bullet entity with location and angle based on
-- the location of the muzzle indicated by `side`.
-- Assumes the ship has a child entity named "gun_muzzle_{side}"
function Ship.fireBullet(ship, side, bulletPicId, bulletSpeed)
  local parent = ship:getParent() -- intended parent of new bullet
  local name = "ship_bullet_" .. side
  local bulletE
  ship:seekEntity(hasTag("gun_muzzle_" .. side), function(muzzle)
    local muzzleTx = computeEntityTransform(muzzle, parent)
    local x, y, r, dirx, diry = transformToLocAndDir(muzzleTx)
    local velx, vely = Vec.mul(bulletSpeed, dirx, diry)

    bulletE = parent:newEntity({
      { "name", { name = name } },
      { "tag",  { name = "ship_bullet" } },
      { "tr",   { x = x, y = y, r = r } },
      { "vel",  { dx = velx, dy = vely } },
      { 'pic', {
        name = "bullet",
        id = bulletPicId,
        sx = 1,
        sy = 1,
        cx = 0.5,
        cy = 0.5,
      } },
      { 'radius', { radius = 10, debug = false } }
    })
    selfDestructEnt(bulletE, 2)
    return true
  end)
  return bulletE
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

Ship.Bullets = map({ "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12" },
  function(num) return "ship_bullets_" .. num end)

function Ship.bulletMenu(parent, res)
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
  for i, picId in ipairs(Ship.Bullets) do
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
