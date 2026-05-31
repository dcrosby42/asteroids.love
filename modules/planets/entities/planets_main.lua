local Estore = require "castle.ecs.estore"
local Cam = require "modules.common.entities.camera"

local Debug = require("mydebug").sub("Planets", true, true)
local inspect = require "inspect"

-- convenience: get screen dim and plunk into res.data.screen_size
local function storeScreenSizeInRes(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })
end

local Facts = {
  earth = {
    diameter_km = 12742,
    pic_id = "earth",
    pic_size = 1600,
  },
  moon = {
    diameter_km = 3474,
    distance_from_earth_km = 384400,
    pic_id = "moon",
    pic_size = 800,
  },
}

-- SCALE = 1 / 10 -- 1 pixel = 10 km
SCALE = 0.5 -- 1 pixel = 5km
EARTH_SCALE = SCALE
MOON_SCALE = SCALE * (Facts.earth.pic_size / Facts.moon.pic_size) *
    (Facts.moon.diameter_km / Facts.earth.diameter_km)


local E = {}

local function newScene(parent, sceneName)
  return parent:newEntity({
    { "name", { name = sceneName } },
  })
end

local function addFullViewport(parent, res, sceneName, cameraName)
  local screen_w, screen_h = res.data.screen_size.width, res.data.screen_size.height
  return parent:newEntity({
    { "name", { name = "viewport" } },
    { 'viewport', {
      scene = sceneName,   -- the scene to render within the viewport
      camera = cameraName, -- the name of the camera object to render viewpoint from
      blockout = true,     -- whether the viewport's screen boundaries are used to stencil out (remove) overflowing scene
      -- bgcolor = { 0, 0.4, 0 }, -- optional bg color
      -- use_bgcolor = false,     -- enable/disable optional bg color
    } },
    -- Our convention is to center viewports on their coords.
    { 'tr', {
      x = screen_w / 2, -- mid screen
      y = screen_h / 2,
    } },
    { 'box', {
      w = screen_w, -- full screen
      h = screen_h,
      cx = 0.5,     -- centered on coord tr.x
      cy = 0.5,     -- centered on coord tr.y
    } },
  })
end

local function addSpaceBackground(parent)
  -- scene1: first child: space background
  local spaceBG = parent:newEntity({
    { "name", { name = "space_bg" } },
  })
  -- paralax stars n stuff in space background:
  spaceBG:newEntity({
    { "tilingBackground", {} },
    { "pic",              { id = "nebula_blue" } },
    { "paralax",          { px = 0.25, py = 0.25 } },
  })
  spaceBG:newEntity({
    { "tilingBackground", {} },
    { "pic",              { id = "starfield_1" } },
    { "paralax",          { px = 0.75, py = 0.75 } },
  })
  return spaceBG
end

local function addPlanets(world)
  world:newEntity({
    { 'name', { name = "earth" } },
    { "pic", {
      cx = 0.5,
      cy = 0.5,
      id = "earth",
      sx = EARTH_SCALE,
      sy = EARTH_SCALE,
      debug = false,
    } },
    { 'tr',   {} },
  })

  world:newEntity({
    { 'name', { name = "moon" } },
    { "pic", {
      cx = 0.5,
      cy = 0.5,
      sx = MOON_SCALE,
      sy = MOON_SCALE,
      id = "moon",
      debug = false,
    } },
    { 'tr',   {} },
  })
end

function E.initialEntities(res)
  storeScreenSizeInRes(res)

  -- do
  --   local ePicRes = res.pics:get("earth")
  --   local mPicRes = res.pics:get("moon")
  --   Debug.println("earth size: " .. tostring(ePicRes.image:getWidth()) .. ", " .. (ePicRes.image:getHeight()))
  --   Debug.println("moon size: " .. tostring(mPicRes.image:getWidth()) .. ", " .. (mPicRes.image:getHeight()))
  -- end


  local estore = Estore:new()

  local vp_scene_name = "scene1"
  local camera_name = "camera1"
  -- local screen_w, screen_h = res.data.screen_size.width, res.data.screen_size.height

  local main_scene = newScene(estore, "main_scene")

  addFullViewport(main_scene, res, vp_scene_name, camera_name)

  -- deleteme
  -- main_scene:newEntity({
  --   { "circle", {
  --     x = screen_w / 2,
  --     y = screen_h / 2,
  --     r = 25,
  --     color = { 1, 0, 0 },
  --   } }
  -- })

  --
  -- The Scene - what the main viewport sees.  Background scene, World scene
  --
  local scene1 = newScene(estore, "scene1")

  addSpaceBackground(scene1)


  --
  -- World scene: interactive stuff like ship, roids, camera
  --
  local world = scene1:newEntity({
    { "name", { name = "world1" } },
  })

  -- Add physics
  -- world:newEntity({
  --   { 'name',         { name = "physics_world" } },
  --   { 'physicsWorld', { allowSleep = false } },
  -- })

  addPlanets(world)

  -- Add camera
  local camera = Cam.camera(world, res, camera_name)
  -- camera:addComp("follower", {targetname = "playership"})
  Cam.camera_dev_controller(world, camera_name)

  return estore
end

return E
