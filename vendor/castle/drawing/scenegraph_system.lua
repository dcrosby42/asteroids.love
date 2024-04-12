local withTransform = require("castle.drawing.with_transform")
local BGColorSystem = require("castle.drawing.bgcolor_system")

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
        drawEntity(e, res)
      end
      if e.tr then
        -- The viewport itself, like any drawable, has a transform:
        withTransform(e.tr.x, e.tr.y, e.tr.r, 0, 0, e.tr.sx, e.tr.sy, drawViewport)
      else
        -- just render it
        drawViewport()
      end
    elseif e.tr then
      --
      -- Entity with transformation
      --
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
