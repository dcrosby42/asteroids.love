local mk_entity_draw_loop = require 'castle.drawing.mk_entity_draw_loop'
local withTransform = require("castle.drawing.with_transform")

local function drawLabel(e, label, res)
  if label.font then
    -- lookup font and apply it
    local font = res.fonts[label.font]
    if font then
      love.graphics.setFont(font)
    end
  end

  -- ox and oy are computed based on cx and cy, used to both "recenter the box" and as center of rotation
  -- These offsets are optional, and can only be used in context of optional width and height
  local ox, oy = 0, 0
  if label.w > 0 then
    ox = label.cx * label.w
  end
  local texty = 0
  if label.h > 0 then
    oy = label.cy * label.h
    -- texty is the vertical alignment offset.
    if label.valign == "center" or label.valign == "middle" then
      texty = (label.h - love.graphics.getFont():getHeight()) / 2
    elseif label.valign == "bottom" then
      texty = label.h - love.graphics.getFont():getHeight()
    end
  end
  local x, y = label.x - ox, label.y - oy
  if label.align == "middle" then label.align = "center" end

  if debugDraw(e.label, res) then
    -- 0,0 in this entity's transform
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.circle("line", 0, 0, 5)
  end

  withTransform(x, y, label.r, ox, oy, label.sx, label.sy, function()
    if label.shadowcolor then
      -- Draw optional shadow first so it will be underneath
      love.graphics.setColor(label.shadowcolor)
      love.graphics.printf(label.text, label.shadowx, texty + label.shadowy, label.w, label.align)
    end
    -- Draw the label
    love.graphics.setColor(label.color)
    if label.w > 0 then
      love.graphics.printf(label.text, 0, texty, label.w, label.align)
    else
      love.graphics.print(label.text, 0, texty)
    end

    if debugDraw(e.label, res) then
      -- grey img bounding box
      if label.w and label.h then
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("line", 0, 0, label.w, label.h)
      end

      -- red,green axes @ x,y
      if label.w then
        love.graphics.setColor(1, 0, 0)
        love.graphics.line(0, 0, label.w, 0)
      end
      if label.h then
        love.graphics.setColor(0, 1, 0)
        love.graphics.line(0, 0, 0, label.h)
      end

      -- blue center dot
      love.graphics.setColor(0.2, 0.2, 1)
      love.graphics.circle("fill", ox, oy, 3)
    end
  end)

  -- reset
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(INITIAL_FONT)
end

return mk_entity_draw_loop('labels', drawLabel)
