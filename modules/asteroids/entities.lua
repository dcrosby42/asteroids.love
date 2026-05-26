local Debug = require("mydebug").sub("Asteroids", true, true)
local Estore = require "castle.ecs.estore"
local inspect = require "inspect"

local W = require "modules.asteroids.entities.world"
local Ship = require "modules.asteroids.entities.ship"
local Roids = require "modules.asteroids.entities.roids"

-- convenience: get screen dim and plunk into res.data.screen_size
local function storeScreenSizeInRes(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })
end

local E = {}

function E.initialEntities(res)
  storeScreenSizeInRes(res)

  local estore = Estore:new()

  local vp_scene_name = "scene1"
  local camera_name = "camera1"
  local screen_w, screen_h = res.data.screen_size.width, res.data.screen_size.height

  local main_scene = estore:newEntity({
    { "name", { name = "main_scene" } },
  })
  local viewport = main_scene:newEntity({
    { "name", { name = "viewport" } },
    { 'viewport', {
      scene = vp_scene_name,
      camera = camera_name,
      blockout = true,
      bgcolor = { 0, 0.4, 0 },
      use_bgcolor = false,
    } },
    { 'tr', {
      x = screen_w / 2,
      y = screen_h / 2,
      cx = 0,
      cy = 0
    } },
    { 'box', {
      w = screen_w,
      h = screen_h,
      cx = 0.5,
      cy = 0.5,
      debug = false,
    } },
  })


  --
  -- The Scene - what the main viewport sees.  Background scene, World scene
  --
  local scene1 = estore:newEntity({
    { "name", { name = "scene1" } },
  })

  -- scene1: first child: space background
  local space_bg = scene1:newEntity({
    { "name", { name = "space_bg" } },
  })
  -- paralax stars n stuff in space background:
  space_bg:newEntity({
    { "tilingBackground", {} },
    { "pic",              { id = "nebula_blue" } },
    { "paralax",          { px = 0.25, py = 0.25 } },
  })
  space_bg:newEntity({
    { "tilingBackground", {} },
    { "pic",              { id = "starfield_1" } },
    { "paralax",          { px = 0.75, py = 0.75 } },
  })

  --
  -- World scene: interactive stuff like ship, roids, camera
  --
  local world = scene1:newEntity({
    { "name", { name = "world1" } },
  })
  -- Add physics
  world:newEntity({
    { 'name',         { name = "physics_world" } },
    { 'physicsWorld', { allowSleep = false } },
  })

  -- Add camera
  local camera1 = world:newEntity({
    { 'name',     { name = camera_name } },
    -- { 'tag',  { name = 'camera' } },
    { 'tr',       { x = 0, y = 0 } },
    { 'follower', { targetname = "playership" } }
  })
  W.camera_dev_controller(estore, camera_name)


  -- Add roids
  local pi = math.pi
  local kinds = { "small", "medium", "medium_large", "large", "huge" }
  for i = 1, 100 do
    local x = randomInt(-4000, 4000)
    local y = randomInt(-4000, 4000)
    local roid = Roids.random(world, { sizeCat = pickRandom(kinds), x = x, y = y })
    roid.vel.angularvelocity = randomFloat(-pi / 2, pi / 2)
    roid.vel.dx = randomFloat(-30, 30)
    roid.vel.dy = randomFloat(-30, 30)
  end

  -- Add ship
  local ship = Ship.ship(world, res)

  return estore
end

return E
