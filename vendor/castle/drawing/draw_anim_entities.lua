require "castle.drawing.drawhelpers"
local mk_entity_draw_loop = require 'castle.drawing.mk_entity_draw_loop'
local drawPicLike = require 'castle.drawing.draw_piclike'


local function draw(e, anim, res)
  local animRes = res.anims[anim.id]
  if not animRes then
    error("No anim resource '" .. anim.id .. "'")
  end

  local tname = e.anim.timer
  if not tname or tname == '' then
    tname = e.anim.name
  end
  local timer = e.timers[tname]
  if not timer then
    print("!! MISSING TIMER? anim eid=" ..
      e.eid .. " " .. anim.name .. " anim.cid=" .. anim.cid .. " NO TIMER NAMED '" .. tname .. "'")
    return
  end

  local picRes = animRes.getFrame(timer.t)
  drawPicLike(anim, picRes, res)
end

return mk_entity_draw_loop('anims', draw)
