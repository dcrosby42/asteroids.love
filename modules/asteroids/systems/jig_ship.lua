local EventHelpers = require "castle.systems.eventhelpers"
local State = require "castle.state"
local Ship = require "modules.asteroids.entities.ship"

local ZoomFactor = 0.2
local RotFactor = math.pi / 8

local function zoomCameraTo(camera, zoom)
  camera.tr.sx = zoom
  camera.tr.sy = zoom
end

local function zoomCameraIn(camera, factor)
  -- Zooming camera IN means SHRINKING sx,sy
  zoomCameraTo(camera, camera.tr.sx * (1 - factor))
end

local function zoomCameraOut(camera, factor)
  -- Zooming camera OUT means GROWING sx,sy
  zoomCameraTo(camera, camera.tr.sx * (1 + factor))
end

local function controlCamera(jigE, estore, input, res)
  EventHelpers.handleKeyPresses(input.events, {
    ["="] = function(evt)
      local camera = estore:getEntityByName("camera")
      zoomCameraIn(camera, ZoomFactor)
    end,
    ["-"] = function(evt)
      local camera = estore:getEntityByName("camera")
      zoomCameraOut(camera, ZoomFactor)
    end,
    ["0"] = function(evt)
      local camera = estore:getEntityByName("camera")
      zoomCameraTo(camera, 1)
      camera.tr.r = 0
    end,
    ["]"] = function(evt)
      local camera = estore:getEntityByName("camera")
      camera.tr.r = camera.tr.r + RotFactor
    end,
    ["["] = function(evt)
      local camera = estore:getEntityByName("camera")
      camera.tr.r = camera.tr.r - RotFactor
    end,
    ["d"] = function(evt)
      res.data.debug_draw = State.toggle(jigE, "debug_draw")
    end,
  })
end



-- selectFlameInMenu(estore, input, res)
-- local flamePicId = getFlameMenuValue(estore, input, res)
-- setShipFlamePic(flamePicId, estore)
local function selectFlameInMenu(num, estore, input, res)
  local menu = estore:getEntityByName("flame_menu")
  State.set(menu, "selected", num)
end

local function getFlameMenuValue(estore, input, res)
  local menu = estore:getEntityByName("flame_menu")
  local selected = State.get(menu, "selected")
  local value = Ship.Flames[selected]
  return value
end

local function setShipFlamePic(flamePicId, estore)
  estore:seekEntity(hasTag("ship_flame"), function(e)
    e.pic.id = flamePicId
  end)
  return true
end

local function incrementFlameMenuSelection(inc, estore)
  local menu = estore:getEntityByName("flame_menu")
  local selected = State.get(menu, "selected")
  selected = selected + inc
  if selected < 1 then
    selected = #Ship.Flames
  elseif selected > #Ship.Flames then
    selected = 1
  end
  State.set(menu, "selected", selected)

  local cursorE = estore:getEntityByName("menu_cursor")
  -- print(not not cursorE)
  cursorE.tr.x = (selected - 1) * 50
end

local function controlFlame(jigE, estore, input, res)
  EventHelpers.handleKeyPresses(input.events, {
    ["f"] = function(evt)
      -- toggle flame visibility (alpha)
      estore:seekEntity(hasTag("ship_flame"), function(e)
        if e.pic.color[4] == 0 then
          e.pic.color[4] = 1
        else
          e.pic.color[4] = 0
        end
        return true
      end)
    end,
    ["left"] = function(evt)
      -- select prev flame pic
      incrementFlameMenuSelection(-1, estore)
      local flamePicId = getFlameMenuValue(estore, input, res)
      setShipFlamePic(flamePicId, estore)
    end,
    ["right"] = function(evt)
      -- select next flame pic
      incrementFlameMenuSelection(1, estore)
      local flamePicId = getFlameMenuValue(estore, input, res)
      setShipFlamePic(flamePicId, estore)
    end,
    ["up"] = function(evt)
      -- move flame up
      estore:seekEntity(hasTag("ship_flame"), function(e)
        e.tr.y = e.tr.y - 1
        print("flame.tr.y: " .. tostring(e.tr.y))
        return true
      end)
    end,
    ["down"] = function(evt)
      -- move flame down
      estore:seekEntity(hasTag("ship_flame"), function(e)
        e.tr.y = e.tr.y + 1
        print("flame.tr.y: " .. tostring(e.tr.y))
        return true
      end)
    end,
    -- ["1"] = function(evt)
    --   -- select flame 01
    -- end,
    -- ["2"] = function(evt)
    --   -- select flame 02
    --   selectFlameInMenu(2, estore, input, res)
    --   local flamePicId = getFlameMenuValue(estore, input, res)
    --   setShipFlamePic(flamePicId, estore)
    -- end,
  })
end

local match = hasTag("jig_ship")

return function(estore, input, res)
  estore:seekEntity(match, function(jigE)
    controlCamera(jigE, estore, input, res)
    controlFlame(jigE, estore, input, res)
    return true
  end)
end
