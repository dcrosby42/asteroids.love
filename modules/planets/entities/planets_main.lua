local Estore = require "castle.ecs.estore"
local Cam = require "modules.common.entities.camera"

local Debug = require("mydebug").sub("Planets", true, true)
local inspect = require "inspect"

-- convenience: get screen dim and plunk into res.data.screen_size
local function storeScreenSizeInRes(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })
end

local SolObjects = {
  {
    name = "earth",
    label = "Earth",
    diameter_km = 12742,
    distance_from_earth_km = 0,
    pic_id = "earth",
    pic_size = 1600,
    camera_zoom = 0.4,
  },
  {
    name = "moon",
    label = "Luna",
    diameter_km = 3474,
    distance_from_earth_km = 384400,
    pic_id = "moon",
    pic_size = 800,
    camera_zoom = 0.2,
  },
}


-- SCALE = 1 / 10 -- 1 pixel = 10 km
local PX_KM = 0.2 -- pixels-per-km, 1 pixel = 5km

-- Planel pic size adjust.  The pngs I got aren't automatically relativeley sized to each other
local function computeEarthRelativeObjectScale(earth, object)
  return PX_KM * (earth.pic_size / object.pic_size) * (object.diameter_km / earth.diameter_km)
end


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

local function addPlanets(world, objects)
  local objectsByName = keyBy(objects, "name")
  local earth = objectsByName["earth"]

  for i = 1, #objects do
    local obj = objects[i]
    local x_loc = PX_KM * obj.distance_from_earth_km
    local size = computeEarthRelativeObjectScale(earth, obj)
    world:newEntity({
      { 'name', { name = obj.name } },
      { 'tag',  { name = "planet" } },
      { "pic", {
        cx = 0.5,
        cy = 0.5,
        sx = size,
        sy = size,
        id = obj.pic_id or obj.name,
        debug = false,
      } },
      { 'tr', {
        x = x_loc,
        y = 0,
      } },
      { 'state', {
        name = "object_info",
        value = obj,
      } },
    })
  end
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

  -- addPlanets(world)
  addPlanets(world, SolObjects)

  -- Add camera
  local camera = Cam.camera(world, res, camera_name)
  -- camera:addComp("follower", {targetname = "playership"})
  local controller = Cam.camera_dev_controller(world, camera_name)
  controller.states.debug.value = true
  local keys = controller.keystate.handle
  keys[#keys + 1] = "tab"

  return estore
end

return E
