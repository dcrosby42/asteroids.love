local Debug = require("mydebug").sub("AirHockey", true, true)
local Estore = require "castle.ecs.estore"
local inspect = require "inspect"


local E = {}

function E.initialEntities(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })

  local estore = Estore:new()

   E.asteroidsGame(estore, res)

  return estore
end

function E.asteroidsGame(estore, res)
  -- E.game_state(estore, res)
  -- E.dev_state(estore, res)

  local viewport = E.viewport(estore, res)

  -- local world = E.world(viewport, res)
  local world = viewport:newEntity({
    {"name", {name="world"}},
  })
  -- E.physicsWorld(world, res)

  -- E.background(world, res)

  E.camera(world, res, "camera1")
  viewport.viewport.camera = "camera1"

  -- E.addReloadButton(estore, res)
end

function E.viewport(parent, res)
  local w, h = res.data.screen_size.width, res.data.screen_size.height
  return parent:newEntity({
    { 'name',     { name = 'viewport' } },
    { 'viewport', { camera = "" } },
    { 'tr',       {} },
    { 'box',      { w = w, h = h, debug = false } }
  })
end

function E.camera(parent, res, name)
  local w, h
  if parent.box then
    w, h = parent.box.w, parent.box.h
  else
    w, h = love.graphics.getDimensions()
  end
  parent:newEntity({
    { 'name', { name = name } },
    { 'tr',   { x = w / 2, y = h / 2 } }
  })
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
