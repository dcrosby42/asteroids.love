local function withTransform(x, y, r, rcx, rcy, sx, sy, func)
  love.graphics.push()

  love.graphics.translate(x, y)

  love.graphics.translate(rcx, rcy)
  love.graphics.rotate(r)
  love.graphics.translate(-rcx, -rcy)

  love.graphics.scale(sx, sy)

  func()

  love.graphics.pop()
end

return withTransform
