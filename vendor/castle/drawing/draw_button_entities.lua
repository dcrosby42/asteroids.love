require "castle.drawing.drawhelpers"
local mk_entity_draw_loop = require 'castle.drawing.mk_entity_draw_loop'

local function drawButtonHighlight(e, button, res)
  local x, y = 0, 0
  if button.shape == "circle" then
    if button.kind == "hold" and e.timers and e.timers.holdbutton then
      -- hold button: draw a "pie chart" highlight based on progress
      local elapsed = button.holdtime - e.timers.holdbutton.t
      if elapsed > 0 then
        local a1 = -math.pi / 2
        local a2 = a1 + (elapsed / button.holdtime) * (2 * math.pi)
        love.graphics.setColor(button.progresscolor)
        love.graphics.arc("fill", x, y, button.progresssize, a1, a2, 30)
      end
    elseif button and button.kind == "tap" and button.touch then
      -- tap button: highlight via full circle when touched
      love.graphics.setColor(button.progresscolor)
      love.graphics.circle("fill", x, y, button.progresssize)
    end
  end
end

return mk_entity_draw_loop('buttons', drawButtonHighlight)
