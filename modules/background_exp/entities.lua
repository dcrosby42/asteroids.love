local Estore = require "castle.ecs.estore"
local W = require "modules.asteroids.entities.world"
local Roids = require "modules.asteroids.entities.roids"

local E = {}

local zoomOutFromViewport

function E.initialEntities(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })

  local estore = Estore:new()

  -- local parent = estore:newEntity({
  --   { "tag", { name = "bg_tester" } },
  -- })
  local parent = estore

  local debug = true

  --
  -- World and Viewport
  --
  local world, viewport = W.basicWorldAndViewport(parent, res, { cameraName = "camera1", worldName = "world1" })

  local camera_ctrl = W.camera_dev_controller(parent, viewport.viewport.camera)

  if debug then
    camera_ctrl.states.debug.value = true
    zoomOutFromViewport(viewport, res)
  end

  Roids.random(world, { sizeCat = "large", x = 0, y = 0, })
  Roids.random(world, { sizeCat = "medium_large", x = 200, y = 0, })
  Roids.random(world, { sizeCat = "medium", x = 350, y = 0, })

  -- Background tiler
  -- world:newEntity({
  --   { "name", { name = "tilez" } },
  --   { "bgtiler", {
  --     name = "tilez",
  --     picId = "nebula_blue",
  --     tilew = 4096,
  --     tileh = 4096,
  --     debug = debug
  --   } },
  -- })
  -- world:newEntity({
  --   { "name", { name = "tilez2" } },
  --   { "bgtiler", {
  --     name = "tilez2",
  --     picId = "starfield_1",
  --     tilew = 4096,
  --     tileh = 4096,
  --     debug = debug
  --   } },
  -- })

  return estore
end

-- Makes the viewport entity more visibly evident by giving border and bg color,
-- as well as making its shape smaller than the window so we can observe its edge
-- behavior.
function zoomOutFromViewport(viewport, res)
  -- make the viewport inset from the screen edge
  local w, h = res.data.screen_size.width, res.data.screen_size.height
  local hmargin = math.floor(w * 0.1)
  local vmargin = hmargin
  -- local vmargin = math.floor(h * 0.1)
  -- local vmargin = math.floor(hmargin * (h / w))
  viewport.tr.x = hmargin
  viewport.tr.y = vmargin
  viewport.box.w = w - (hmargin * 2)
  viewport.box.h = h - (vmargin * 2)

  -- blue border and bg
  viewport.box.debug = true
  viewport.box.color = { 0.7, 0.7, 1 }
  viewport.viewport.bgcolor = { 0, 0, 0.2 }

  -- allow overflow to be seen:
  viewport.viewport.blockout = false
end

return E
