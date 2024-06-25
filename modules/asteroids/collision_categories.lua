local function sbit(n)
  -- "bit" lib is builtin to LuaJIT: https://bitop.luajit.org/
  return bit.lshift(1, n)
end

-- For use in "categories" and "mask" fields, per https://love2d.org/wiki/Fixture:setFilterData
local Coll = {
  Ships = 1,
  Roids = sbit(1),
  Lasers = sbit(2),
}

return Coll
