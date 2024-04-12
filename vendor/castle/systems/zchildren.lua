local Comp = require 'castle.ecs.component'

Comp.define("zChildren", {})

return defineUpdateSystem(hasComps('zChildren'), function(e, estore, input, res)
  for _, ch in ipairs(e:getChildren()) do
    if ch.pos then
      local x, y = getPos(ch)
      ch.parent.order = y
    end
  end
  e:resortChildren()
end)
