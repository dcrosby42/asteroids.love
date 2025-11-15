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
      debug = false,
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
    { 'name',     { name = camera_name } },
    -- { 'tag',  { name = 'camera' } },
    { 'tr',       { x = 0, y = 0 } },
    { 'follower', { targetname = "playership" } }
  })

  W.camera_dev_controller(estore, camera_name)

  local nebula = space_bg:newEntity({
    { "tilingBackground", {} },
    { "pic",              { id = "nebula_blue" } },
    { "paralax",          { px = 0.25, py = 0.25 } },
  })
  local stars = space_bg:newEntity({
    { "tilingBackground", {} },
    { "pic",              { id = "starfield_1" } },
    { "paralax",          { px = 0.75, py = 0.75 } },
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
  world1:newEntity({
    { 'name',         { name = "physics_world" } },
    { 'physicsWorld', { allowSleep = false } },
  })

  local ship = Ship.ship(world1, res)
  -- ship:newComp("followable", { targetname = "playership" })
end

return SB
