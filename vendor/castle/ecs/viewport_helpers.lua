local M = {}

-- Given an entity in a "scene graph" hierarchy, walk upward looking for
-- a viewport entity.  Once found, lookup the associated camera entity currently
-- associated with the viewport.
function M.findOwningViewportAndCamera(e)
  error("viewport_helpers.findOwningViewportAndCamera(): DECOMMISSIONED. This won't work anymore.")
  if not e then
    return nil, nil
  elseif e.viewport then
    local camName = e.viewport.camera
    if camName then
      -- return the viewport and camera entities
      return e, e:getEstore():getEntityByName(camName)
    end
    -- Foudn viewport but not its camera
    return e, nil
  else
    -- Recurse upward
    print("!! CROZ DEBUG " .. entityDebugString(e))
    return M.findOwningViewportAndCamera(e:getParent())
  end
end

-- Convenience: like findOwningViewportAndCamera, but just return the camera
function M.findOwningViewportCamera(e)
  error("viewport_helpers.findOwningViewportCamera(): DECOMMISSIONED. This won't work anymore.")
  local _, camera = M.findOwningViewportAndCamera(e)
  return camera
end

return M
