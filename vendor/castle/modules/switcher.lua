local ResourceLoader = require 'castle.resourceloader'

local M = {}

M.newWorld = function(opts)
  local modules = opts.modules
  local current = opts.current or 1
  if not modules[current] then
    current = tkeys(modules)[1]
  end
  local w = {}

  w.instances = tmap(modules, function(_key, module)
    return memoize0(function()
      local state = module.newWorld()
      return { module = module, state = state }
    end)
  end)
  w.current = current

  return w
end

M.updateWorld = function(w, action)
  if action.type == "castle.switcher" then w.current = action.index end

  local inst = w.instances[w.current]() -- gets or creates-on-demand an instance of the module at the current index
  local sidefx
  inst.state, sidefx = inst.module.updateWorld(inst.state, action)
  return w, sidefx
end

M.drawWorld = function(w)
  local inst = w.instances[w.current]()
  inst.module.drawWorld(inst.state)
end

return M
