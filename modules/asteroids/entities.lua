local Debug = require("mydebug").sub("Asteroids", true, true)
local Estore = require "castle.ecs.estore"
local inspect = require "inspect"
local Workbench = require "modules.asteroids.entities.workbench"

local W = require "modules.asteroids.entities.world"


local E = {}

function E.initialEntities(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })

  local estore = Estore:new()

  -- E.asteroidsGame(estore, res)

  Workbench.workbench(estore, res)

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

  -- world:newEntity({
  --   { "name", { name = "roid2" } },
  --   { 'tr',   { x = 0, y = 0, } },
  --   { 'pic', {
  --     -- id = "roid_medium_grey_a1",
  --     id = "roid_large_grey_a1",
  --     -- x = -100,
  --     -- y = -50,
  --     cx = 0.5,
  --     cy = 0.5,
  --     -- sx = 0.5,
  --     -- sy = 0.5,
  --     -- r = math.pi / 4,
  --     debug = false,
  --   } },
  --   { 'timer', { countDown = false, } }
  -- })


  -- E.addReloadButton(estore, res)
end

return E
