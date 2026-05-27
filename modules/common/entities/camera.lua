local Cam = {}

function Cam.camera(parent, res, name)
  if not name or name == "" then
    name = "camera"
  end
  return parent:newEntity({
    { 'tag',  { name = 'camera' } },
    { 'name', { name = name } },
    { 'tr',   { x = 0, y = 0 } }
  })
end

function Cam.camera_dev_controller(parent, name)
  return parent:newEntity({
    { 'name',     { name = name .. "_dev_controller" } },
    { 'tag',      { name = "camera_dev_controller" } },
    { "state",    { name = "camera", value = name } },
    { "state",    { name = "debug", value = false } },
    { "keystate", { handle = { "[", "]", "-", "=", "0", "w", "a", "s", "d" } } },
  })
end

return Cam
