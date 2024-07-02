local Workbench = require "modules.asteroids.entities.workbench"
local Roids = require "modules.asteroids.entities.roids"
local Explosion = require "modules.asteroids.entities.explosion"
local Menu = require "modules.asteroids.jigs.menu"
local State = require "castle.state"
local TweenHelpers = require "castle.tween.tween_helpers"
local inspect = require('inspect')



local function mkSplode(parent, n, x, y)
  local factor = 0.7
  local s = 3
  local animId = "debris_explosion_" .. tostring(n)
  local explosion = Explosion.explosion(parent, {
    animId = animId,
    x = x,
    y = y,
    size = s,
    animSpeed = factor,
  })
  explosion:newComp("name", { name = animId })
  explosion:newComp("label", {
    text = animId,
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

local function addRoid(parent, estore)
  local roid = Roids.random(parent, { sizeCat = "large", name = "target_roid", x = -200, y = -200 })
  roid:newComp("vel", {
    dx = 1,
    dy = 1,
    angularvelocity = 0.03,
  })
  -- Remove lingering explosion:
  local splode = estore:getEntityByName("roidsplode")
  if splode then splode:destroy() end
end

local function killRoid(parent, estore)
  local roid = estore:getEntityByName("target_roid")
  if roid then
    -- Set the roid to remove itself
    selfDestructEnt(roid, 0.2)

    -- Generate explosion
    local x, y = roid.tr.x, roid.tr.y
    local size = 2.5
    local factor = 0.8
    local expl = Explosion.explosion(parent, { name = "roidsplode", size = size, x = x, y = y, animSpeed = factor })
    expl:newComp("sound", { sound = "medium_explosion_1" })

    selfDestructEnt(expl, 2.0)
  end
end

local function moveRoid(roid)
  if roid.vel then
    roid.tr.x = roid.tr.x + roid.vel.dx
    roid.tr.y = roid.tr.y + roid.vel.dy
    roid.tr.r = roid.tr.r + roid.vel.angularvelocity
  end
end

-- Experimental roid detonator:
table.insert(Tabs, 1, {
  enter = function(jig, estore)
    local e = jig:newEntity({
      { "name", { name = "nukeit" } },
    })
    addRoid(e, estore)
    -- Roids.random(e, { sizeCat = "medium" })
    -- Explosion.explosion(e, { size = 1, x = 0, y = 0, animSpeed = 1.5 })
    -- local x, y = -500, 0
    -- local s = 1
    -- for i = 1, 10 do
    --   Explosion.explosion(e, { size = s, x = x, y = y })
    --   x = x + 150
    -- end
  end,
  leave = function(jig, estore)
    local e = estore:getEntityByName("nukeit")
    if e then e:destroy() end
  end
})

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
    { "keystate", { handle = { "left", "right", "space" } } },
    { "state",    { name = "tab", value = tabIdx } },
  })

  Workbench.dev_background_nebula_blue(jig, res)
  Workbench.dev_background_starfield1(jig, res)

  Tabs[tabIdx].enter(jig, estore)

  return jig
end

function Jig.finalize(jigE, estore)
end

function Jig.update(estore, input, res)
  -- slow-rotate the explosions
  local jig = estore:getEntityByName("explosion_browser")
  handleTabSwitch(jig, estore)

  local roid = estore:getEntityByName("target_roid")
  if roid then
    moveRoid(roid)
  end
  if jig.keystate.pressed.space then
    local nukeit = estore:getEntityByName("nukeit")
    if nukeit then
      if roid then
        killRoid(nukeit, estore)
      else
        addRoid(nukeit, estore)
      end
    end
  end


  -- jig:walkEntities(hasTag("explosion"), function(e)
  --   e.tr.r = e.tr.r + 0.002
  -- end)

  -- Pan the camera
  -- local cam = estore:getEntityByName("camera1")
  -- if cam then
  --   cam.tr.x = cam.tr.x - 0.3
  --   cam.tr.y = cam.tr.y - 0.3
  -- end
end

return Jig
