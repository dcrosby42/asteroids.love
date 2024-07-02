local Estore = require "castle.ecs.estore"
local inspect = require "inspect"
local BgTester = require "modules.tiling_test.bg_tester"

local E = {}

function E.initialEntities(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })

  local estore = Estore:new()

  BgTester.initStuff(estore, res)

  return estore
end

return E
