local U = require "utils"
local withTransform = require("castle.drawing.with_transform")
local BGColorSystem = require("castle.drawing.bgcolor_system")
local ViewportHelpers = require "castle.ecs.viewport_helpers"
local findOwningViewportCam = ViewportHelpers.findOwningViewportCamera
local G = love.graphics
local newTransform = love.math.newTransform

local DrawFuncs = {
  require('castle.drawing.draw_screengrid_entity'),
  require('castle.drawing.draw_pic_entities'),
  require('castle.drawing.draw_anim_entities'),
  require('castle.drawing.draw_geom_entities'),
  require('castle.drawing.draw_button_entities'),
  require('castle.drawing.draw_physics_entities'),
  require('castle.drawing.draw_label_entities'),
  require('castle.drawing.draw_sound_entities'),
  require('castle.drawing.draw_touch_debugs'),
}

local function trToTransform2(tr)
  return newTransform(tr.x, tr.y, tr.r, tr.sx, tr.sy, tr.cx, tr.cy)
end

local function computeEntityTransform2(e, relativeToEnt)
  if e == nil or e.eid == nil then
    -- _root node in estore has no eid nor transform, must stop here
    return newTransform()
  end
  if relativeToEnt and e.eid == relativeToEnt.eid then
    -- computation halts at specified ancestor entity, when given
    return newTransform()
  end

  -- Compute a love2d Transform for the entity based on its tr component.
  -- The transform is recursively derived up to the root ancestor entity.
  local transform = computeEntityTransform2(e:getParent(), relativeToEnt)
  if e.tr then
    transform:apply(trToTransform2(e.tr))
  end
  -- DELETEME
  -- if e.viewport then
  --   -- Viewports, in addition to their own transform, apply further transformation
  --   -- based on their cameras (when they have cameras)
  --   local camE = e:getEstore():getEntityByName(e.viewport.camera)
  --   transform:apply(viewportCameraTransform(e, camE))
  -- end
  return transform
end

local drawViewport2

local function drawEntity2(e, res)
  local transform = computeEntityTransform2(e)
  G.push()
  G.applyTransform(transform)

  if e.viewport then
    drawViewport2(e, res)
  end
  for i = 1, #DrawFuncs do
    DrawFuncs[i](e, res)
  end

  local childs = e:getChildren()
  for i = 1, #childs do
    drawEntity2(childs[i], res)
  end

  G.pop()
end

local function startBlockoutStencil(box)
  G.stencil(function()
    G.rectangle("fill", box.x, box.y, box.w, box.h)
  end, "replace", 1)
  -- Only allow rendering on pixels which have a stencil value greater than 0.
  G.setStencilTest("greater", 0)
end

local function stopBlackoutStencil()
  G.setStencilTest()
end

---@param e Entity
drawViewport2 = function(e, res)
  local scene = e:getEstore():getEntityByName(e.viewport.scene)
  if not scene then
    error("drawViewport2: bad scene_name " .. tostring(e.viewport.scene))
    -- error("drawViewport2: bad scene_name " .. tostring(e.viewport.scene_name)
    --   .. "; viewport: " .. U.as_lua(e.viewport))
  end
  if e.viewport.blockout and e.box then
    startBlockoutStencil(e.box)
  end

  -- Generate view "projection" based on camera (if found)
  local camera = e:getEstore():getEntityByName(e.viewport.camera)
  if camera then
    local viewProjection = computeEntityTransform2(camera):inverse()
    G.push()
    G.applyTransform(viewProjection)
  end

  -- Draw the actual scene
  -- EDraw.draw_entity(state, scene, vp_ent)
  drawEntity2(scene, res)

  if camera then
    G.pop()
  end

  if e.viewport.blockout and e.box then
    stopBlackoutStencil()
  end

  -- Draw a highlight border around the viewport
  -- if e.viewport.border and e.rect then
  -- Draw.rect(e.rect, "line", C.white)
  -- Draw.circle(0, 0, 2, "fill", C.red)
  -- end
end


---@param estore Estore
return function(estore, res)
  BGColorSystem(estore, res)

  local main_scene = estore:getEntityByName("main_scene")
  drawEntity2(main_scene, res)
end
