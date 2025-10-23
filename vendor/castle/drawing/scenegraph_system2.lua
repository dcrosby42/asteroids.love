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

  if e.viewpert then
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
    -- withViewportCameraTransform(e, camE, continue)
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
  --TODO
  -- if vp_ent.viewport.border then
  --   Draw.rect(vp_ent.rect, "line", C.white)
  --   -- Draw.circle(0, 0, 2, "fill", C.red)
  -- end
end


local function withTransform2(transform, callback)
  G.push()
  G.applyTransform(transform)
  callback(transform)
  G.pop()
end

-- ---@param e Entity
-- local function drawEntity(e, res, viewport)
--   local transform = computeEntityTransform(e)
--   withTransform2(transform, function()
--     for i = 1, #DrawFuncs do
--       DrawFuncs[i](e, res, viewport)
--     end

--     local childs = e:getChildren()
--     for i = 1, #childs do
--       drawEntity(childs[i], res, viewport)
--     end
--   end)
-- end

local function withViewportCameraTransform(vpE, camE, callback)
  local transf = viewportCameraTransform(vpE, camE)
  love.graphics.push()
  love.graphics.applyTransform(transf)
  callback()
  love.graphics.pop()
end



---@param estore Estore
return function(estore, res)
  BGColorSystem(estore, res)

  local main_scene = estore:getEntityByName("main_scene")
  drawEntity2(main_scene, res, nil)
end

-- return function(estore, res)
--   BGColorSystem(estore, res)
--   estore:walkEntities2(nil, function(e, continue)
--     if e.viewport then
--       --
--       -- Viewport
--       --
--       local drawViewport = function()
--         local camE = estore:getEntityByName(e.viewport.camera)
--         if e.box then
--           -- Viewports with boxes can set an opaque bgcolor:
--           love.graphics.setColor(e.viewport.bgcolor)
--           love.graphics.rectangle("fill", e.box.x, e.box.y, e.box.w, e.box.h)
--           -- Viewports with "blockout" flag set true are stencil'd (limited) to drawing inside their boxes
--           if e.viewport.blockout then
--             withStencil(e.box, function()
--               withViewportCameraTransform(e, camE, continue)
--             end)
--             drawEntity(e, res)
--             return
--           end
--         end
--         -- Viewports with NO box, or with box but NO stenciling:
--         withViewportCameraTransform(e, camE, continue)
--         drawEntity(e, res) -- viewports likely only have a box, if anything, to draw
--       end
--       if e.tr then
--         -- The viewport itself, like any drawable, has a transform:
--         withTransform(e.tr.x, e.tr.y, e.tr.r, 0, 0, e.tr.sx, e.tr.sy, drawViewport)
--       else
--         -- just render it
--         drawViewport() -- viewports likely only have a box, if anything, to draw
--       end
--     elseif e.tr then
--       --
--       -- Entity with transformation
--       --
--       local x, y = computeLocWithParalax(e, estore)
--       withTransform(x, y, e.tr.r, 0, 0, e.tr.sx, e.tr.sy, function()
--         drawEntity(e, res)
--         continue()
--       end)
--     else
--       --
--       -- Regular (non-transformed) drawing:
--       --
--       drawEntity(e, res)
--       continue()
--     end
--   end)
-- end
