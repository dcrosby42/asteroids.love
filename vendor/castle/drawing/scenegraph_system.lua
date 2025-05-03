local withTransform = require("castle.drawing.with_transform")
local BGColorSystem = require("castle.drawing.bgcolor_system")
local ViewportHelpers = require "castle.ecs.viewport_helpers"
local findOwningViewportCam = ViewportHelpers.findOwningViewportCamera

local function withStencil(box, callback)
  love.graphics.stencil(function()
    love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
  end, "replace", 1)
  -- Only allow rendering on pixels which have a stencil value greater than 0.
  love.graphics.setStencilTest("greater", 0)

  callback()

  love.graphics.setStencilTest()
end

local DrawFuncs = {
  require('castle.drawing.draw_background_entities'),
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

local function drawEntity(e, res)
  for i = 1, #DrawFuncs do
    DrawFuncs[i](e, res)
  end
end

local function withViewportCameraTransform(vpE, camE, callback)
  local transf = viewportCameraTransform(vpE, camE)
  love.graphics.push()
  love.graphics.applyTransform(transf)
  callback()
  love.graphics.pop()
end

-- DELETEME
--
-- Compute the DRAWABLE location x,y of an entity based on its tr comp,
-- accounting for paralax factors parax,paray (if non-1).
-- Paralax is computed relative to the current location of the camera as determined
-- by the given entity's ancestor viewport, assuming both viewport and camera exist.
-- The x,y offset incurred by paralax is ONLY applied at draw-time, and
-- will affect the drawing of child drawable entities.
--
-- YIKES this ain't great (but it's a start):
--   - If e has an ancestor entity with a viewport component
--   - If the camera entity named by the viewport exists
--   - Assumes the camera's location and the entity's location are "in the same
--     context", ie, at the same scale and offset.
--   - ...offset is computed based on the camera's distance from the entity.
--      - If the camera is interestingly transformed and/or parented, this calc will generate unexpected results.
--      - ...What about multiple renderings from multiple viewports/cams? (this isn't a thing yet... requires indirect viewport.world referencing)
--
-- DELETEME
local function computeLocWithParalax(e, estore)
  if not e.tr then return 0, 0 end
  local x, y = e.tr.x, e.tr.y
  if e.tr.parax ~= 1 or e.tr.paray ~= 1 then
    local camera = findOwningViewportCam(e)
    if camera then
      local dx = camera.tr.x - e.tr.x
      local dy = camera.tr.y - e.tr.y
      local ax = dx * e.tr.parax
      local ay = dy * e.tr.paray
      x = x + ax
      y = y + ay
    end
  end
  return x, y
end


-- Walk the Entity hierarchy and apply drawing functions.
-- Entities with tr components will have their transforms applied as
-- their children are drawn.
return function(estore, res)
  BGColorSystem(estore, res)
  estore:walkEntities2(nil, function(e, continue)
    if e.viewport then
      --
      -- Viewport
      --
      local drawViewport = function()
        local camE = estore:getEntityByName(e.viewport.camera)
        if e.box then
          -- Viewports with boxes can set an opaque bgcolor:
          love.graphics.setColor(e.viewport.bgcolor)
          love.graphics.rectangle("fill", e.box.x, e.box.y, e.box.w, e.box.h)
          -- Viewports with "blockout" flag set true are stencil'd (limited) to drawing inside their boxes
          if e.viewport.blockout then
            withStencil(e.box, function()
              withViewportCameraTransform(e, camE, continue)
            end)
            drawEntity(e, res)
            return
          end
        end
        -- Viewports with NO box, or with box but NO stenciling:
        withViewportCameraTransform(e, camE, continue)
        drawEntity(e, res) -- viewports likely only have a box, if anything, to draw
      end
      if e.tr then
        -- The viewport itself, like any drawable, has a transform:
        withTransform(e.tr.x, e.tr.y, e.tr.r, 0, 0, e.tr.sx, e.tr.sy, drawViewport)
      else
        -- just render it
        drawViewport() -- viewports likely only have a box, if anything, to draw
      end
    elseif e.tr then
      --
      -- Entity with transformation
      --
      -- DELETEME: local x, y = computeLocWithParalax(e, estore)
      withTransform(e.tr.x, e.tr.y, e.tr.r, 0, 0, e.tr.sx, e.tr.sy, function()
        drawEntity(e, res)
        continue()
      end)
    else
      --
      -- Regular (non-transformed) drawing:
      --
      drawEntity(e, res)
      continue()
    end
  end)
end
