local Ship = require "modules.asteroids.entities.ship"
local Explosion = require "modules.asteroids.entities.explosion"
local Menu = require "modules.asteroids.jigs.menu"
local State = require "castle.state"
local TweenHelpers = require "castle.tween.tween_helpers"
local inspect = require('inspect')



local function mkSplode(parent, n, x, y)
  local factor = 0.7
  local s = 3
  local picId = "debris_explosion_" .. tostring(n)
  local explosion = Explosion.explosion(parent, {
    picId = picId,
    x = x,
    y = y,
    size = s,
    animSpeed = factor,
  })
  explosion:newComp("name", { name = picId })
  explosion:newComp("label", {
    text = picId,
    color = { 1, 1, 1 },
    align = "middle",
    cx = 0.5,
    cy = 0.5,
    y = 150,
    w = 200,
    h = 20,
  })
  return explosion
end

local Jig = {}

local Tabs = {
  -- The first tab: the gallery
  {
    enter = function(jig, estore)
      local w = 300
      local e = jig:newEntity({
        { "name", { name = "splode_overview" } },
      })
      mkSplode(e, 1, -w, -w / 2)
      mkSplode(e, 2, 0, -w / 2)
      mkSplode(e, 3, w, -w / 2)
      mkSplode(e, 4, -w, w / 2)
      mkSplode(e, 5, 0, w / 2)
      mkSplode(e, 6, w, w / 2)
    end,
    leave = function(jig, estore)
      local e = estore:getEntityByName("splode_overview")
      if e then
        e:destroy()
      end
    end
  }
}

-- Add a tab for each explosion anim
for i, n in pairs({ 1, 2, 3, 4, 5, 6 }) do
  local tab = {
    enter = function(jig, estore)
      local e = jig:newEntity({
        { "name", { name = "splode_single" } },
      })
      mkSplode(e, n, 0, 0)
    end,
    leave = function(jig, estore)
      local e = estore:getEntityByName("splode_single")
      if e then
        e:destroy()
      end
    end
  }
  table.insert(Tabs, tab)
end

-- table.insert(Tabs, 1, {
--   enter = function(jig, estore)
--     local e = jig:newEntity({
--       { "name", { name = "tryme" } },
--     })
--     local x, y = -500, 0
--     local s = 1
--     for i = 1, 10 do
--       Explosion.explosion(e, { size = s, x = x, y = y })
--       x = x + 150
--     end
--   end,
--   leave = function(jig, estore)
--     local e = estore:getEntityByName("tryme")
--     if e then
--       e:destroy()
--     end
--   end
-- })

local function handleTabSwitch(jig, estore)
  local flip
  if jig.keystate.pressed.left then
    flip = -1
  elseif jig.keystate.pressed.right then
    flip = 1
  end
  if flip then
    local tabIdx = State.get(jig, "tab")
    local nextIdx = math.mod1(tabIdx + flip, #Tabs)
    local tab = Tabs[tabIdx]
    local nextTab = Tabs[nextIdx]
    if tab and tab.leave then
      tab.leave(jig, estore)
    end
    if nextTab and nextTab.enter then
      nextTab.enter(jig, estore)
      State.set(jig, "tab", nextIdx)
    end
  end
end

function Jig.init(parent, estore, res)
  local tabIdx = 1
  local jig = parent:newEntity({
    { "name",     { name = "explosion_browser" } },
    { "keystate", { handle = { "left", "right" } } },
    { "state",    { name = "tab", value = tabIdx } },
  })

  Ship.dev_background_nebula_blue(jig, res)
  Ship.dev_background_starfield1(jig, res)

  Tabs[tabIdx].enter(jig, estore)

  return jig
end

function Jig.finalize(jigE, estore)
end

function Jig.update(estore, input, res)
  -- slow-rotate the explosions
  local jig = estore:getEntityByName("explosion_browser")
  handleTabSwitch(jig, estore)
  -- jig:walkEntities(hasTag("explosion"), function(e)
  --   e.tr.r = e.tr.r + 0.002
  -- end)

  -- Pan the camera
  -- local cam = estore:getEntityByName("cam1")
  -- if cam then
  --   cam.tr.x = cam.tr.x - 0.3
  --   cam.tr.y = cam.tr.y - 0.3
  -- end
end

return Jig
