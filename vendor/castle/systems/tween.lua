local Tween = require "castle.tween"

return defineUpdateSystem("tween", function(e, estore, input, res)
  Tween.apply(e)
end)
