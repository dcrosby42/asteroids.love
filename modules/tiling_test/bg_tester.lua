local W = require "modules.asteroids.entities.world"
local Comps = require "castle.ecs.component"
local ViewportHelpers = require "castle.ecs.viewport_helpers"
-- local Roids = require "modules.asteroids.entities.roids"
-- local Explosion = require "modules.asteroids.entities.explosion"
-- local Menu = require "modules.asteroids.jigs.menu"
-- local State = require "castle.state"
-- local TweenHelpers = require "castle.tween.tween_helpers"
-- local inspect = require('inspect')

local function cameraDbgText(camera)
  local s = tostring(math.round(camera.tr.x)) .. ", " .. tostring(math.round(camera.tr.y))
  s = s .. "\nr: " .. tostring(math.round(camera.tr.r, 2))
  s = s .. "\nz: " .. tostring(math.round(camera.tr.sx, 2))
  return s
end

local function addCameraDebugVis(estore, name)
  -- find the camera
  name = name or "camera1"
  local camera = estore:getEntityByName(name)
  -- add an orange circle
  local color = { 1, 0.5, 0 }
  camera:newComp("circle", { debug = true, r = 10, color = color })
  -- add some info
  camera:newComp("label", { x = 10, y = -15, text = cameraDbgText(camera), color = color })
end

local function updateCameraDebugVis(estore, name)
  name = name or "camera1"
  local camera = estore:getEntityByName(name)
  camera.label.text = cameraDbgText(camera)
end

local M = {}

local function newBox(parent, x, y, w, h)
  local color = { 1, 1, 0 }
  local label = tostring(x) .. ", " .. tostring(y)
  local name = "tilebox_" .. label
  return parent:newEntity({
    { "name",  { name = name } },
    { "tag",   { name = "tilebox" } },
    { "tr",    { x = x, y = y } },
    { "box",   { debug = true, w = w, h = h, color = color } },
    { "label", { text = label, color = color } },
  })
end

local function newGrid(parent)
  local tw, th = 320, 240
  for i = -4, 4 do
    local x = i * tw
    for j = -4, 4 do
      local y = j * th
      newBox(parent, x, y, tw, th)
    end
  end
end

local function zoomOutFromViewport(viewport, res)
  local w, h = res.data.screen_size.width, res.data.screen_size.height
  local hmargin = 400
  local vmargin = hmargin

  viewport.tr.x = hmargin
  viewport.tr.y = vmargin
  -- viewport.tr.r = math.pi / 4
  viewport.box.w = w - (hmargin * 2)
  viewport.box.h = h - (vmargin * 2)
  viewport.box.debug = true
  viewport.box.color = { 1, 1, 1 }
  viewport.viewport.bgcolor = { 0, 0, 0.2 }
  viewport.viewport.blockout = false
end

function M.initStuff(estore, res)
  local debug = false
  local parent = estore:newEntity({
    { "tag", { name = "bg_tester" } },
  })

  --
  -- World and Viewport
  --
  local world, viewport = W.basicWorldAndViewport(parent, res, { cameraName = "camera1", worldName = "world1" })
  if debug then
    zoomOutFromViewport(viewport, res)
  end

  W.camera_dev_controller(parent, res, viewport.viewport.camera)
  -- addCameraDebugVis(estore)


  -- Boxes
  -- newGrid(world)

  -- Background tiler
  world:newEntity({
    { "name", { name = "tilez" } },
    { "bgtiler", {
      name = "tilez",
      picId = "nebula_blue",
      tilew = 4096,
      tileh = 4096,
      debug = debug
    } },
  })
  world:newEntity({
    { "name", { name = "tilez2" } },
    { "bgtiler", {
      name = "tilez2",
      picId = "starfield_1",
      tilew = 4096,
      tileh = 4096,
      debug = debug
    } },
  })
end

--
-- System
--
M.system = defineQuerySystem(
  { tag = "bg_tester" },
  function(e, estore, input, res)
  end)

return M
