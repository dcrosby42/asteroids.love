local U = require "utils"
local BGColorSystem = require("castle.drawing.bgcolor_system")
local ViewportHelpers = require "castle.ecs.viewport_helpers"
local min = math.min
local max = math.max
local floor = math.floor
local G = love.graphics
local newTransform = love.math.newTransform
local Comps = require "castle.components"
local drawPicLike = require 'castle.drawing.draw_piclike'

---@param viewport Entity
---@return Entity camera|nil
local function getViewportCamera(viewport)
  return viewport:getEstore():getEntityByName(viewport.viewport.camera)
end

---@param box table
---@return number x
---@return number y
---@return number w
---@return number h
local function boxToXywh(box)
  local cx, cy = box.cx or 0, box.cy or 0
  return box.x - (cx * box.w),
      box.y - (cy * box.h),
      box.w,
      box.h
end

---@param rect table The rect to transform
---@param dest table|nil (optional) The rect into which the results are stored.
---@param transform Transform The Transform to apply
---@return table rect The transformed rect, either a new rect or modified `dest`
local function transformBox(transform, box)
  local dest = {}
  local x, y, w, h = boxToXywh(box)
  dest.x, dest.y = transform:transformPoint(x, y)
  local x2, y2 = transform:transformPoint(x + w, y + h)
  dest.w = x2 - dest.x
  dest.h = y2 - dest.y
  return dest
end


Comps.define("devgrid", {
  "left", 0, "right", 1000, "top", 0, "bottom", 1000,
  "tilew", 100, "tileh", 100,
  "color", { 1, 1, 1 },
  "dot_size", 3,
  "draw_coords", true,
  "draw_coords_y", 0
})

local function drawDevGrid(e, res, _viewportE)
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

local function trToTransform2(tr)
  return newTransform(tr.x, tr.y, tr.r, tr.sx, tr.sy, tr.cx, tr.cy)
end

local applyParalax

-- getEntityParentGlobalTransform(ent, viewport?)
-- getEntityGlobalTransform(ent, viewport?)
-- getEntityLocalTransform(ent, viewport?, parentTransform?)


local function computeEntityTransform2(ent, relativeToEnt, viewportEnt)
  if ent == nil or ent.eid == nil then
    -- _root node in estore has no eid nor transform, must stop here
    return newTransform()
  end
  if relativeToEnt and ent.eid == relativeToEnt.eid then
    -- computation halts at specified ancestor entity, when given
    return newTransform()
  end

  -- Compute a love2d Transform for the entity based on its tr component.
  -- The transform is recursively derived up to the root ancestor entity.
  local transform = computeEntityTransform2(ent:getParent(), relativeToEnt)
  if ent.tr then
    transform:apply(trToTransform2(ent.tr))
  end
  if ent.paralax and viewportEnt then
    transform = applyParalax(ent, transform, viewportEnt)
  end
  return transform
end

---Generate global-space corner points (4 flattened x,y pairs, 8 total values)
---by applying the given Transform to the given rect.
---@param transform any The love2d Transform object
---@param box table The box component
---@return number ulx, number uly,number urx, number ury,number lrx, number lyy,number llx, number lly
local function getTransformedCorners(transform, box)
  local x, y, w, h = boxToXywh(box)
  local ulx, uly = transform:transformPoint(x, y)
  local urx, ury = transform:transformPoint(x + w, y)
  local lrx, lry = transform:transformPoint(x + w, y + h)
  local llx, lly = transform:transformPoint(x, y + h)
  return ulx, uly, urx, ury, lrx, lry, llx, lly
end



--- Get all four corners of the viewport's rectangle, in global space
local function getViewportCornersGlobal(viewportEnt)
  local cameraTransform = computeEntityTransform2(getViewportCamera(viewportEnt))
  return getTransformedCorners(cameraTransform, viewportEnt.box)
end

---Get the bounds of a quadrilateral, given a series of coords.
---@return table bounds The AABB as a rect {x,y,w,h}
local function computeBoundsFromCorners(ulx, uly, urx, ury, lrx, lry, llx, lly)
  local left = min(ulx, urx, lrx, llx)
  local top = min(uly, ury, lry, lly)
  local right = max(ulx, urx, lrx, llx)
  local bottom = max(uly, ury, lry, lly)
  return { x = left, y = top, w = right - left, h = bottom - top }
end

--- Using the viewport and its camera, compute the axis-aligned bounding box of the viewport in global space
---
local function getViewportAABB(viewportEnt, relativeToTransform)
  local aabb = computeBoundsFromCorners(getViewportCornersGlobal(viewportEnt))
  if relativeToTransform then
    -- Express the viewport aabb relative to the given transform param:
    return transformBox(relativeToTransform:inverse(), aabb)
  else
    return aabb
  end
end

-- Determine the 2d range, in tile count, intersected by the given rect
---@param grid table An object describing a grid's tile width/height, e.g. {tw=100,th=50}
---@param box table A rect {x=,y=,w=,h=,relx=,rely=}
---@return integer left tile index
---@return integer top tile index
---@return integer right tile index
---@return integer bottom tile index
local function getIntersectingTileRangeAABB(tw, th, box)
  local x, y, w, h = boxToXywh(box)
  return floor(x / tw),    -- upper left tile x
      floor(y / th),       -- upper left tile y
      floor((x + w) / tw), -- lower right tile x
      floor((y + h) / th)  -- lower right tile y
end

Comps.define("devbg", {})

local function drawDevBg(ent, res, viewportEnt)
  if not ent.devbg then return end
  --- Determine the AABB bounds of the viewport relative to the current ent transform
  local relVpBounds = getViewportAABB(viewportEnt, computeEntityTransform2(ent, nil, viewportEnt))

  -- What's the upper-left/lower-right tile numbers intersected by the viewport aabb?
  local tw, th = 100, 100
  local gx1, gy1, gx2, gy2 = getIntersectingTileRangeAABB(tw, th, relVpBounds)

  for tilex = gx1, gx2 do
    for tiley = gy1, gy2 do
      local x, y = tilex * tw, tiley * th
      G.setColor({ 0, 1, 0, 0.25 })
      G.rectangle("fill", x, y, tw, th)
      G.setColor({ 0, 1, 0, 0.5 })
      G.rectangle("line", x, y, tw, th)
    end
  end
end

Comps.define("tilingBackground", {

})

local function drawTilingBackground(ent, res, viewportEnt)
  if not (ent.tilingBackground and ent.pic) then return end

  local pic = shallowclone(ent.pic)
  local picRes = res.pics:get(pic.id)

  --- Determine the AABB bounds of the viewport relative to the current ent transform
  local relVpBounds = getViewportAABB(viewportEnt, computeEntityTransform2(ent, nil, viewportEnt))
  -- What's the upper-left/lower-right tile numbers intersected by the viewport aabb?
  local tw = picRes.rect.w * picRes.sx * pic.sx
  local th = picRes.rect.h * picRes.sy * pic.sy
  local gx1, gy1, gx2, gy2 = getIntersectingTileRangeAABB(tw, th, relVpBounds)

  for tilex = gx1, gx2 do
    for tiley = gy1, gy2 do
      pic.x = tilex * tw
      pic.y = tiley * th
      drawPicLike(pic, picRes, res)
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
  drawDevBg,
  drawTilingBackground,
}


--- paralax factor:
---   -1: reverse full paralax
---   -0.5: reverse half paralax, entity appears to "move" at half speed
---   0: no paralax, apparent motion same as everything else
---   0.5: half paralax, entity appears to "move" at half speed
---   1: full paralax, entity appears affixed to camera
function applyParalax(e, transform, viewportEnt)
  if not viewportEnt then return end
  local cameraEnt = getViewportCamera(viewportEnt)
  if not cameraEnt then return end

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
---@param viewportEnt Entity|nil
local function drawEntity(e, res, viewportEnt, viewProjection)
  local worldTransform = computeEntityTransform2(e, nil, viewportEnt)
  G.push()

  if viewProjection then
    G.replaceTransform(viewProjection:clone():apply(worldTransform))
  else
    G.applyTransform(worldTransform)
  end

  if e.viewport then
    drawViewport2(e, res)
  end

  for i = 1, #DrawFuncs do
    DrawFuncs[i](e, res, viewportEnt)
  end

  local childs = e:getChildren()
  for i = 1, #childs do
    drawEntity(childs[i], res, viewportEnt, viewProjection)
  end

  G.pop()
end



local function startBlockoutStencil(box)
  G.stencil(function()
    G.rectangle("fill", boxToXywh(box))
  end, "replace", 1)
  -- Only allow rendering on pixels which have a stencil value greater than 0.
  G.setStencilTest("greater", 0)
end

local function stopBlackoutStencil()
  G.setStencilTest()
end

---@param viewportEnt Entity
---@param res table
drawViewport2 = function(viewportEnt, res)
  local scene = viewportEnt:getEstore():getEntityByName(viewportEnt.viewport.scene)
  if not scene then
    error("drawViewport2: bad scene_name " .. tostring(viewportEnt.viewport.scene))
  end
  local debug = not not (viewportEnt.box and viewportEnt.box.debug)

  if viewportEnt.viewport.blockout and viewportEnt.box then
    startBlockoutStencil(viewportEnt.box)
  end

  if viewportEnt.viewport.use_bgcolor then
    G.setColor(viewportEnt.viewport.bgcolor)
    -- G.rectangle("fill", e.box.x, e.box.y, e.box.w, e.box.h)
    G.rectangle("fill", boxToXywh(viewportEnt.box))
  end

  -- Generate view "projection" based on camera (if found)
  local viewportScreenTransform = computeEntityTransform2(viewportEnt)
  local cameraEnt = getViewportCamera(viewportEnt)
  local cameraInverse = computeEntityTransform2(cameraEnt):inverse()
  local viewProjection = viewportScreenTransform:clone():apply(cameraInverse)
  -- if cameraEnt then
  --   local viewProjection = computeEntityTransform2(cameraEnt):inverse()
  --   G.push()
  --   G.applyTransform(viewProjection)
  -- end

  -- Draw the actual scene
  -- EDraw.draw_entity(state, scene, vp_ent)
  drawEntity(scene, res, viewportEnt, viewProjection)

  if cameraEnt then
    -- G.pop()
    if debug then
      G.setColor(1, 0.5, 0)
      G.circle("line", 0, 0, 15)
    end
  end

  if debug then
    G.setColor(1, 1, 0)
    G.circle("line", 0, 0, 10)
  end

  if viewportEnt.viewport.blockout and viewportEnt.box then
    stopBlackoutStencil()
  end
end


---@param estore Estore
---@param res table
return function(estore, res)
  BGColorSystem(estore, res)

  local main_scene = estore:getEntityByName("main_scene")
  drawEntity(main_scene, res)
end
