return function(e, res)
  if not e.screen_grid then return end
  local g = e.screen_grid
  local sx = g.spacex
  local sy = sx
  if g.spacey ~= '' then
    sy = g.spacey
  end

  local w, h = love.graphics.getDimensions()

  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle("rough") -- "smooth" "rough"
  love.graphics.setColor(g.color)
  for i = 0, w, sx do
    love.graphics.line(i, 0, i, h)
  end
  for i = 0, h, sy do
    love.graphics.line(0, i, w, i)
  end

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(INITIAL_FONT)
end
