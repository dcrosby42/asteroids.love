local Tween = require "castle.tween"

return defineQuerySystem("tween", function(e, estore, input, res)
  Tween.apply(e)
end)
