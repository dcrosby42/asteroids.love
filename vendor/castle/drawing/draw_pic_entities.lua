require "castle.drawing.drawhelpers"
local mk_entity_draw_loop = require 'castle.drawing.mk_entity_draw_loop'
local drawPicLike = require 'castle.drawing.draw_piclike'

local function draw(e, pic, res)
  local picRes = res.pics[pic.id]
  if not picRes then
    error("No pic resource '" .. pic.id .. "'")
  end

  drawPicLike(pic, picRes, res)
end

return mk_entity_draw_loop('pics', draw)
