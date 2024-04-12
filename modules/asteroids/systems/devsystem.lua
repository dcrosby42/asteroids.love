return function(estore, input, res)
  local r2 = estore:getEntityByName("roid2")
  r2.tr.r = r2.tr.r + 0.05
  r2.tr.x = r2.tr.x + 0.3
  r2.tr.y = r2.tr.y + 0.6
end
