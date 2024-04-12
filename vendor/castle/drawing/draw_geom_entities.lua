return function(e, res)
  -- bounds: draw only during debug
  if e.box and e.box.w and e.box.h and debugDraw(e.box, res) then
    local w, h = e.box.w, e.box.h
    local ox = e.box.cx * w
    local oy = e.box.cy * h
    local x, y = e.box.x, e.box.y
    -- draw a yellow rectangle:
    love.graphics.setColor(e.box.color)
    love.graphics.rectangle("line", x - ox, y - oy, w, h)
  end

  if e.rects then
    for _, rect in pairs(e.rects) do
      local x, y, w, h = rect.x, rect.y, rect.w, rect.h
      local ox = rect.cx * w
      local oy = rect.cy * h
      love.graphics.setColor(rect.color)
      love.graphics.rectangle(rect.style, x - ox, y - oy, w, h)
    end
  end

  if e.circles then
    for _, c in pairs(e.circles) do
      love.graphics.setColor(c.color)
      love.graphics.circle(c.style, c.x, c.y, c.r)
    end
  end
end

-- --
-- -- POLYGON
-- --
-- if e.polygonShape then
--   local st = e.polygonLineStyle
--   local pol = e.polygonShape
--   if st and st.draw then
--     love.graphics.setColor(unpack(st.color))
--     love.graphics.setLineWidth(st.linewidth)
--     love.graphics.setLineStyle(st.linestyle)
--     local verts = {}
--     local x, y = e.pos.x, e.pos.y
--     for i = 1, #pol.vertices, 2 do
--       verts[i] = x + pol.vertices[i]
--       verts[i + 1] = y + pol.vertices[i + 1]
--     end
--     if st.closepolygon then
--       table.insert(verts, x + pol.vertices[1])
--       table.insert(verts, y + pol.vertices[2])
--     end
--     love.graphics.line(verts)
--   end
-- end
