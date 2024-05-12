local Debug = require("mydebug").sub("AirHockey", true, true)
local Estore = require "castle.ecs.estore"
local inspect = require "inspect"
local Ship = require "modules.asteroids.entities.ship"

local W = require "modules.asteroids.entities.world"


local E = {}

function E.initialEntities(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })

  local estore = Estore:new()

  -- E.asteroidsGame(estore, res)

  Ship.workbench(estore, res)

  return estore
end

function E.asteroidsGame(estore, res)
  -- E.game_state(estore, res)
  -- E.dev_state(estore, res)


  local world, viewport = W.basicWorldAndViewport(estore, res)

  -- E.physicsWorld(world, res)
  -- E.background(world, res)

  -- world:newEntity({
  --   { "name", { name = "roid1" } },
  --   { 'tr',   { x = 100, y = 100, } },
  --   { 'anim', {
  --     id = "large_grey_a1",
  --     -- x = -100,
  --     -- y = -50,
  --     cx = 0.5,
  --     cy = 0.5,
  --     -- sx = 0.5,
  --     -- sy = 0.5,
  --     -- r = math.pi / 4,
  --     -- debug = true,
  --     timer = "roidtimer"
  --   } },
  --   { 'timer', {
  --     name = "roidtimer",
  --     countDown = false,
  --     factor = 0.1,
  --   } }
  -- })

  world:newEntity({
    { "name", { name = "roid2" } },
    { 'tr',   { x = 400, y = 100, } },
    { 'pic', {
      id = "roid_medium_grey_a1",
      -- id = "roid_large_grey_a1",
      -- x = -100,
      -- y = -50,
      cx = 0.5,
      cy = 0.5,
      -- sx = 0.5,
      -- sy = 0.5,
      -- r = math.pi / 4,
      debug = false,
    } },
    { 'timer', { countDown = false, } }
  })


  -- E.addReloadButton(estore, res)
end

-- function E.physicsWorld(estore, res)
--   return estore:newEntity({
--     { 'name',         { name = "physics_world" } },
--     { 'physicsWorld', { allowSleep = false } }, -- no gravity
--   })
-- end

-- function E.background(estore, res)
--   if DEBUG_HIDE_BACKGROUND then return nil end
--   local pic_id = "rink1"
--   local scrw = res.data.screen_size.width
--   local scrh = res.data.screen_size.height
--   local imgW, imgH = res.pics[pic_id].rect.w, res.pics[pic_id].rect.h
--   local sx, sy = scrw / imgW, scrh / imgH
--   estore:newEntity({
--     { 'name', { name = "background" } },
--     { 'pic',  { id = pic_id, sx = sx, sy = sy } },
--     -- { 'sound', { sound = "city", loop = true } },
--     -- { 'sound', { sound = "enterprise", loop = true, } },
--   })

--   estore:newEntity({
--     { 'rect', { x = 0, y = 0, w = scrw, h = scrh, color = { 0, 1, 0 } } }
--   })
-- end


return E
