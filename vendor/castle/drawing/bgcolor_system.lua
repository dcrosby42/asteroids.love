return function(estore, res)
  local e = estore:findEntity(hasComps("bgcolor"))
  if e then
    love.graphics.setBackgroundColor(e.bgcolor.color)
  else
    love.graphics.setBackgroundColor({ 0, 0, 0 })
  end
end
