local W = require "modules.asteroids.entities.world"
local Ship = require "modules.asteroids.entities.ship"

local SB = {}

---@param estore Estore
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
      blockout = true,
      bgcolor = { 0, 0.4, 0 },
      use_bgcolor = false,
    } },
    { 'tr',   { x = screen_w / 2, y = screen_h / 2, cx = 0, cy = 0 } },
    { 'box', {
      w = screen_w,
      h = screen_h,
      -- w = 800,
      -- h = 600,
      cx = 0.5,
      cy = 0.5,
      debug = true,
    } },
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

  W.camera_dev_controller(estore, camera_name)

  local devbg = space_bg:newEntity({
    { "devbg",   {} },
    -- { "paralax", { px = 0.8, py = 0.8 } },
    { "paralax", { px = 0.75, py = 0.75 } },
  })

  -- local devgrid1 = space_bg:newEntity({
  --   { "devgrid", {
  --     tilew = 200,
  --     tileh = 200,
  --     color = { 1, 0.5, 0.5, 0.5 },
  --     draw_coords = true,
  --     draw_coords_y = 12,
  --     dot_size = 3
  --   } },
  --   { "paralax", { px = 0.75, py = 0.75 } },
  -- })
  local devgrid2 = space_bg:newEntity({
    { "devgrid", {
      tilew = 100,
      tileh = 100,
      color = { 1, 1, 1 },
      draw_coords = true,
      dot_size = 3
    } },
    { "paralax", { px = 0.5, py = 0.5 } },
  })

  local devgridFore = world1:newEntity({
    { "devgrid", {
      tilew = 100,
      tileh = 100,
      color = { 1, 1, 0, 0.5 },
      draw_coords = true,
      dot_size = 3
    } },
    { "paralax", { px = -0.25, py = -0.25 } },
  })
  -- local workbench = world1:newEntity({
  --   { "name",     { name = "ship_workbench" } },
  --   { "state",    { name = "jig", value = "" } },
  --   { "state",    { name = "debug_draw", value = false } },
  --   { "state",    { name = "camera_name", value = camera_name } },
  --   { "keystate", { handle = { "1", "2", "3", "4", "5", "6" } } },
  -- })

  -- local Workbench = require "modules.asteroids.entities.workbench"
  -- Workbench.dev_background_nebula_blue(space_bg, res)
  -- Workbench.dev_background_starfield1(space_bg, res)

  local ship = Ship.ship(world1, res)
end

return SB
