require "castle.ecs.ecshelpers"
local Debug = require("mydebug").sub("draw_physics_entities", false, false)

local function drawPhysicsDebugShapes(e, res)
  if not (e.body and debugDraw(e.body, res)) then return end
  local cache = e:getEstore():getCache("physics")

  local obj = cache[e.body.cid]
  if not obj then
    -- NB: This isn't always a big deal; entities created by systems during an
    -- update may have been added AFTER the physics system has had a chance
    -- generate and cache a corresponding physics body. In normal cases this is
    -- cleared up by the next tick.
    Debug.println(
      "!! No physics object in cache for body.cid=" ..
      e.body.cid .. " entity=" .. entityDebugString(e))
    return
  end

  love.graphics.setColor(e.body.debugDrawColor)
  love.graphics.setLineWidth(1)
  for _, shape in ipairs(obj.shapes) do
    if shape:type() == "CircleShape" then
      -- CircleShape needs special handling
      local r = shape:getRadius()
      love.graphics.circle("line", 0, 0, r)
    elseif shape:type() == "ChainShape" then
      -- ChainShapes don't form a loop; use `line()`
      -- DELETEME love.graphics.line(obj.body:getWorldPoints(shape:getPoints()))
      love.graphics.line(shape:getPoints())
    else
      -- Otherwise assume we can draw a polygon of getPoints.
      -- (Eg, rectangle shapes)
      love.graphics.polygon("line", shape:getPoints())
      local x, y = obj.body:getWorldCenter()
      love.graphics.points(x, y)
    end
    -- love.graphics.points(0, 0)

    -- cirlce at 0,0 in this entity's transform
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.circle("line", 0, 0, 5)

    -- red,green axes @ x,y
    local len = 15
    love.graphics.setColor(1, 0, 0)
    love.graphics.line(0, 0, len, 0)
    love.graphics.setColor(0, 1, 0)
    love.graphics.line(0, 0, 0, len)
  end
end

return drawPhysicsDebugShapes
