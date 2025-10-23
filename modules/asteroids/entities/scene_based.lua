local W = require "modules.asteroids.entities.world"

local SB = {}

function SB.populate(estore, res)
  local scene_name = "scene1"
  local camera_name = "camera1"
  local screen_w, screen_h = res.data.screen_size.width, res.data.screen_size.height

  -- main_scene
  --   viewport{scene1,camera1}
  -- scene1
  --  space_bg
  --    repeating image thinger
  --  world1
  --    ...most stuff...
  --    camera1
  --    workbench

  local main_scene = estore:newEntity({
    { "name", { name = "main_scene" } },
  })
  local viewport = main_scene:newEntity({
    { "name", { name = "viewport" } },
    { 'viewport', {
      scene = scene_name,
      camera = camera_name,

    } },
    { 'tr',   {} },
    { 'box',  { w = screen_w, h = screen_h, debug = false } }
  })

  local scene1 = estore:newEntity({
    { "name", { name = "scene1" } },
  })
  local space_bg = scene1:newEntity({
    { "name", { name = "space_bg" } },
  })
  local world1 = scene1:newEntity({
    { "name", { name = "world1" } },
  })
  local camera1 = world1:newEntity({
    { 'name', { name = camera_name } },
    -- { 'tag',  { name = 'camera' } },
    { 'tr',   { x = 0, y = 0 } }
  })

  local workbench = world1:newEntity({
    { "name",     { name = "ship_workbench" } },
    { "state",    { name = "jig", value = "" } },
    { "state",    { name = "debug_draw", value = false } },
    { "state",    { name = "camera_name", value = camera_name } },
    { "keystate", { handle = { "1", "2", "3", "4", "5", "6" } } },
  })

  W.camera_dev_controller(estore, camera_name)
end

return SB
