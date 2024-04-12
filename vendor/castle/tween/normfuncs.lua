local Funcs = {}

function Funcs.linear(a, b, t)
  return a + (t * (b - a))
end

return Funcs
