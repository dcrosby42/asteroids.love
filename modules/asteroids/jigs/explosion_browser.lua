local Ship = require "modules.asteroids.entities.ship"
local Menu = require "modules.asteroids.jigs.menu"
local State = require "castle.state"
local TweenHelpers = require "castle.tween.tween_helpers"

local Jig = {}

function Jig.init(parent, estore, res)
  local jig = parent:newEntity({
    { "name", { name = "explosion_browser" } },
    -- { "keystate", { handle = { "up", "down", "left", "right", ",", ".", "c" } } },
  })

  -- Ship.dev_background2(jig, res)
  Ship.dev_background_nebula_blue(jig, res)
  Ship.dev_background_starfield1(jig, res)

  local mkSplode = function(n, x, y)
    n = tostring(n)
    local factor = 0.7
    local s = 3
    local picId = "debris_explosion_" .. n
    return jig:newEntity({
      { "name",  { name = "expl_" .. n } },
      { "tag",   { name = "explosion" } },
      { "tr",    { x = x, y = y } },
      { "anim",  { id = picId, sx = s, sy = s, cx = 0.5, cy = 0.5, timer = "splode" } },
      { "timer", { name = "splode", countDown = false, factor = factor } },
      { "label", {
        text = picId,
        color = { 1, 1, 1 },
        align = "middle",
        -- valign = "bottom",
        cx = 0.5,
        cy = 0.5,
        y = 150,
        w = 200,
        h = 20,
        -- debug = true,
      } },
    })
  end
  local w = 300
  mkSplode(1, -w, -w / 2)
  mkSplode(2, 0, -w / 2)
  mkSplode(3, w, -w / 2)
  mkSplode(4, -w, w / 2)
  mkSplode(5, 0, w / 2)
  mkSplode(6, w, w / 2)

  -- jig:newEntity({
  --   { "name",  { name = "explosion1" } },
  --   { "anim",  { id = "debris_explosion_1", cx = 0.5, cy = 0.5, timer = "splode", debug = false } },
  --   { "timer", { name = "splode", countDown = false } },
  -- })
  -- jig:newEntity({
  --   { "name",  { name = "explosion1" } },
  --   { "anim",  { id = "debris_explosion_2", sx = 1.5, sy = 1.5, cx = 0.5, cy = 0.5, timer = "splode", debug = false, } },
  --   { "timer", { name = "splode", countDown = false, factor = 0.5 } },
  --   { "tr",    { x = 250 } },
  -- })
  return jig
end

function Jig.finalize(jigE, estore)
end

function Jig.update(estore, input, res)
  -- -- slow-rotate the explosions
  -- local jig = estore:getEntityByName("explosion_browser")
  -- jig:walkEntities(hasTag("explosion"), function(e)
  --   e.tr.r = e.tr.r + 0.002
  -- end)

  -- Pan the camera
  -- local cam = estore:getEntityByName("cam1")
  -- if cam then
  --   cam.tr.x = cam.tr.x - 0.3
  --   cam.tr.y = cam.tr.y - 0.3
  -- end
end

return Jig
