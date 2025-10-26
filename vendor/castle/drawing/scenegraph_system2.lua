local U = require "utils"
local U = require "utils"
local withTransform = require("castle.drawing.with_transform")
local BGColorSystem = require("castle.drawing.bgcolor_system")
local ViewportHelpers = require "castle.ecs.viewport_helpers"
local findOwningViewportCam = ViewportHelpers.findOwningViewportCamera
local G = love.graphics
local newTransform = love.math.newTransform
local Comps = require "castle.components"

Comps.define("devgrid", {
  "left", 0, "right", 1000, "top", 0, "bottom", 1000,
  "tilew", 100, "tileh", 100,
  "color", { 1, 1, 1 },
  "dot_size", 3,
  "draw_coords", true,
  "draw_coords_y", 0
})

local function drawDevGrid(e, res)
  if not e.devgrid then return end
  local dg = e.devgrid
  G.setColor(dg.color)
  for row = dg.top / dg.tileh, dg.bottom / dg.tileh do
    for col = dg.left / dg.tilew, dg.right / dg.tilew do
      local x, y = col * dg.tilew, row * dg.tileh
      G.circle("fill", x, y, dg.dot_size)
      if dg.draw_coords then
        G.print(tostring(x) .. "," .. tostring(y), x, y + dg.draw_coords_y)
      end
    end
  end
end

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
  drawDevGrid,
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
  return transform
end

--- paralax factor:
---   -1: reverse full paralax
---   -0.5: reverse half paralax, entity appears to "move" at half speed
---   0: no paralax, apparent motion same as everything else
---   0.5: half paralax, entity appears to "move" at half speed
---   1: full paralax, entity appears affixed to camera
local function applyParalax(e, transform, cameraEnt)
  local cameraTransform = computeEntityTransform2(cameraEnt)
  local cx, cy = cameraTransform:transformPoint(cameraEnt.tr.x, cameraEnt.tr.y)
  local ex, ey -- # = transform:transformPoint(e.tr.x, e.tr.y)
  if e.tr then
    ex, ey = transform:transformPoint(e.tr.x, e.tr.y)
  else
    -- cope with entities that lack a tr
    ex, ey = 0, 0
  end
  local dx = (cx - ex)
  local dy = (cy - ey)
  -- Compute "drag along" factor... how much toward the camera to move the bg entity
  local mysterious_correction = 0.5 -- I CANNOT FIGURE OUT WHY I NEED THIS.  Paralax seems 2x as powerful as I think it should be.
  -- Translate to achieve false paralax:
  transform:translate(
    dx * e.paralax.px * mysterious_correction,
    dy * e.paralax.py * mysterious_correction)
  return transform
end

local drawViewport2

---@param e Entity
---@param res table
---@param camera_ent Entity|nil
local function drawEntity2(e, res, camera_ent)
  local transform = computeEntityTransform2(e)
  if e.paralax and camera_ent then
    transform = applyParalax(e, transform, camera_ent)
  end
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
    drawEntity2(childs[i], res, camera_ent)
  end

  G.pop()
end

---@param box table
---@return number x
---@return number y
---@return number w
---@return number h
local function box_to_xywh(box)
  return box.x - (box.cx * box.w),
      box.y - (box.cy * box.h),
      box.w,
      box.h
end

local function startBlockoutStencil(box)
  G.stencil(function()
    G.rectangle("fill", box_to_xywh(box))
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
  local debug = not not (e.box and e.box.debug)

  if e.viewport.blockout and e.box then
    startBlockoutStencil(e.box)
  end

  if e.viewport.use_bgcolor then
    G.setColor(e.viewport.bgcolor)
    -- G.rectangle("fill", e.box.x, e.box.y, e.box.w, e.box.h)
    G.rectangle("fill", box_to_xywh(e.box))
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
  drawEntity2(scene, res, camera)

  if camera then
    G.pop()
    if debug then
      G.setColor(1, 0.5, 0)
      G.circle("line", 0, 0, 15)
    end
  end

  if debug then
    G.setColor(1, 1, 0)
    G.circle("line", 0, 0, 10)
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
