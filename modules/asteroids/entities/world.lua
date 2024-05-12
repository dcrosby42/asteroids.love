local W = {}

function W.basicWorldAndViewport(estore, res)
  local viewport = W.viewport(estore, res, "cam1")
  local world = viewport:newEntity({
    { "name", { name = "world" } },
  })
  W.camera(world, res, "cam1")
  return world, viewport
end

function W.viewport(parent, res, cameraName)
  local w, h = res.data.screen_size.width, res.data.screen_size.height
  return parent:newEntity({
    { 'name',     { name = 'viewport' } },
    { 'viewport', { camera = cameraName } },
    { 'tr',       {} },
    { 'box',      { w = w, h = h, debug = false } }
  })
end

function W.camera(parent, res, name)
  if not name or name == "" then
    name = "camera"
  end
  parent:newEntity({
    { 'name', { name = name } },
    { 'tr',   { x = 0, y = 0 } }
  })
end

return W
