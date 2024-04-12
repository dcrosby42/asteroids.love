local mk_entity_draw_loop = require 'castle.drawing.mk_entity_draw_loop'
local setColor = love.graphics.setColor
local circle = love.graphics.circle
local line = love.graphics.line
local touchColor = { 1, 1, 1, 0.5 }
local touchableColor = { 1, 1, 1, 0.5 }
local initColor = { 0.3, 0.3, 1 }
local originColor = { 0, 1, 0 }
local radius = 20

local function drawTouchDebug(e, touch, res)
  if debugDraw(touch, res) then
    local x, y = screenToEntityPt(e, touch.x, e.touch.y)

    -- Draw entity origin dot
    setColor(originColor)
    circle("fill", 0, 0, 2)

    -- Draw touchable target area
    if e.touchable then
      setColor(touchableColor)
      circle("line", e.touchable.x, e.touchable.y, e.touchable.r)
    end

    -- Draw initial contact point
    setColor(initColor)
    circle("line", e.touch.init_ex, e.touch.init_ey, 4)

    line(e.touch.init_ex, e.touch.init_ey, x, y)

    -- Draw current touch spot
    setColor(touchColor)
    circle("fill", x, y, radius)
  end
end

return mk_entity_draw_loop('touchs', drawTouchDebug)
