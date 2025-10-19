local Estore = require "castle.ecs.estore"
local W = require "modules.asteroids.entities.world"
local Roids = require "modules.asteroids.entities.roids"

local Comp = require 'castle.components'

Comp.define("background", Comp._PicAttrs)

local E = {}

local adjustViewportForDebug

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
  local viewport = W.viewport(estore, res, "camera1")
  local bgLayer = viewport:newEntity({
    { "name", { name = "bgLayer" } },
  })

  bgLayer:newEntity({
    { 'background', { -- id cx cy sx sy color debug
      -- id = "testpic",
      id = "testpic2",
      debug = true,
      -- id = "starfield_1",
      -- debug = false,
      -- sx = 0.3,
      -- sy = 0.3,
    } },
  })

  local world = viewport:newEntity({
    { "name", { name = "world1" } },
  })
  local camera = W.camera(world, res, "camera1")

  -- Camera Dev Controller
  local camera_ctrl = W.camera_dev_controller(parent, viewport.viewport.camera)

  if debug then
    camera_ctrl.states.debug.value = true
    adjustViewportForDebug(viewport, res)
  end

  local r1 = Roids.random(world, { sizeCat = "large", x = 0, y = 0, })
  local r2 = Roids.random(world, { name = "duder", sizeCat = "medium_large", x = 200, y = 0, })
  local r3 = Roids.random(world, { sizeCat = "medium", x = 350, y = 0, })

  -- r2.parent.order = 101
  camera.parent.order = 100
  world:resortChildren()

  return estore
end

-- Makes the viewport entity more visibly evident by giving border and bg color,
-- as well as making its shape smaller than the window so we can observe its edge
-- behavior.
function adjustViewportForDebug(viewport, res)
  -- make the viewport inset from the screen edge
  local w, h = res.data.screen_size.width, res.data.screen_size.height
  local hmargin = math.floor(w * 0.1)
  local vmargin = hmargin
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
