local Query = require "castle.ecs.query"

local BgcolorQuery = Query.create("bgcolor")

return function(estore, res)
  local e = estore:queryFirstEntity(BgcolorQuery)
  if e then
    love.graphics.setBackgroundColor(e.bgcolor.color)
  else
    love.graphics.setBackgroundColor({ 0, 0, 0 })
  end
end
