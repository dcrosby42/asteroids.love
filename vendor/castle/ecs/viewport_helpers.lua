local M = {}

function M.findOwningViewportCamera(e)
  if not e then
    return nil
  elseif e.viewport then
    local camName = e.viewport.camera
    if camName then
      return e:getEstore():getEntityByName(camName)
    end
    return nil
  else
    return M.findOwningViewportCamera(e:getParent())
  end
end

return M
