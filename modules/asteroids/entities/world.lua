local W = {}

function W.basicWorldAndViewport(estore, res, opts)
  opts = opts or {}
  opts.cameraName = opts.cameraName or "camera1"
  opts.worldName = opts.worldName or "world1"

  local viewport = W.viewport(estore, res, opts.cameraName)
  local world = viewport:newEntity({
    { "name", { name = opts.worldName } },
  })
  W.camera(world, res, opts.cameraName)
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
  local camera = parent:newEntity({
    { 'name', { name = name } },
    { 'tr',   { x = 0, y = 0 } }
  })
  camera.parent.order = 100
  return camera
end

function W.camera_dev_controller(parent, res, name)
  parent:newEntity({
    { 'name',     { name = name .. "_dev_controller" } },
    { 'tag',      { name = "camera_dev_controller" } },
    { "state",    { name = "camera", value = name } },
    { "keystate", { handle = { "[", "]", "-", "=", "0", "w", "a", "s", "d" } } },
  })
end

return W
