local Vec = require 'vector-light'
local Ship = require "modules.asteroids.entities.ship"
local Explosion = require "modules.asteroids.entities.explosion"
local Roids = require "modules.asteroids.entities.roids"

local min = math.min
local sin = math.sin
local pi = math.pi

local TestFlightJig = {}

local matchShipFlame = hasTag("ship_flame")


local function controlShip(ship, estore, input, res)
  local spinSpeed = pi * 1.5

  -- Control direction and thrust
  if ship.keystate.held.left then
    ship.tr.r = ship.tr.r - (spinSpeed * input.dt)
  end
  if ship.keystate.held.right then
    ship.tr.r = ship.tr.r + (spinSpeed * input.dt)
  end
  if ship.keystate.held.up then
    -- accelerate under thrust
    local speed = 6
    local dx, dy = Vec.mul(speed * input.dt, Vec.rotate(ship.tr.r, 0, -1))
    ship.vel.dx = ship.vel.dx + dx
    ship.vel.dy = ship.vel.dy + dy
  else
    -- auto-brake
    if Vec.len(ship.vel.dx, ship.vel.dy) > 0 then
      local speed = 6
      local dx, dy = Vec.mul(speed * input.dt, Vec.normalize(Vec.mul(-1, ship.vel.dx, ship.vel.dy)))
      ship.vel.dx = min(ship.vel.dx + dx)
      ship.vel.dy = min(ship.vel.dy + dy)
    end
  end
  if ship.keystate.pressed.space then
    Ship.fireBullet(ship, "left", "ship_bullets_04", -1500)
    local bullet = Ship.fireBullet(ship, "right", "ship_bullets_04", -1500)

    bullet:newComp("sound", { sound = "laser_small" })
  end


  -- Show ship flame only when thrust active
  estore:seekEntity(matchShipFlame, function(flameE)
    if ship.keystate.held.up then
      flameE.pic.color[4] = 1
    else
      flameE.pic.color[4] = 0
    end
    return true
  end)

  -- (testing: motion should be a different system) Apply velocity to get motion
  ship.tr.x = ship.tr.x + ship.vel.dx
  ship.tr.y = ship.tr.y + ship.vel.dy
end

local function controlShipBullets(estore, input, res)
  -- estore:walkEntities(allOf(hasTag("ship_bullet"), hasComps("tr", "vel")), function(e)
  --   e.tr.x = e.tr.x + (e.vel.dx * input.dt)
  --   e.tr.y = e.tr.y + (e.vel.dy * input.dt)
  -- end)
  for _, e in ipairs(estore:indexLookupAll("byTag", "ship_bullet")) do
    e.tr.x = e.tr.x + (e.vel.dx * input.dt)
    e.tr.y = e.tr.y + (e.vel.dy * input.dt)
  end
end

local function addRoid(parent, sizeCat, x, y, opts)
  opts = opts or {}
  local roid = Roids.random(parent, {
    sizeCat = sizeCat,
    x = x,
    y = y,
  })
  nameEnt(roid, opts.name)
  return roid
end

local function destroyRoid(roid)
  roid:removeComp(roid.health) -- avoid repeat destruction events

  -- Set the roid to remove itself
  selfDestructEnt(roid, 0.2)

  -- Generate explosion
  local x, y = roid.tr.x, roid.tr.y
  local size = 2.5
  local factor = 0.8
  local expl = Explosion.explosion(roid:getParent(),
    { name = "roidsplode", size = size, x = x, y = y, animSpeed = factor })
  expl:newComp("sound", { sound = "medium_explosion_1" })
  -- timeout the explosion
  selfDestructEnt(expl, 2.0)
end


function TestFlightJig.init(parent, estore, res)
  local jig = parent:newEntity({
    { "name",     { name = "test_flight" } },
    { "tag",      { name = "jig" } },
    { "keystate", { handle = { "b" } } },
  })

  Ship.dev_background_nebula_blue(jig, res)
  Ship.dev_background_starfield1(jig, res)

  addRoid(jig, "large", -300, 200, { name = "r1" })

  local ship = Ship.ship(jig, res)
  ship:newComp("keystate", { handle = { "left", "right", "up", "down", "space" } })
end

local function generateBulletStrike(bullet, roid)
  local x, y = bullet.tr.x, bullet.tr.y
  local size = 0.5
  local factor = 2
  local expl = Explosion.explosion(roid:getParent(), { size = size, x = x, y = y, animSpeed = factor })
  -- expl:newComp("sound", { sound = "medium_explosion_1" })
  -- timeout the explosion
  selfDestructEnt(expl, 1.0)
end

-- Reduces hp by damage (if entity has a health component).
-- Returns true if the hp has been reduced to 0 or below
local function dealDamage(e, damage)
  if e.health then
    e.health.hp = e.health.hp - damage
    if e.health.hp <= 0 then
      return true
    end
  end
  return false
end

local function bulletHitsRoid(bullet, roid)
  generateBulletStrike(bullet, roid)
  if dealDamage(roid, 1) then
    destroyRoid(roid)
  end
end

local function collideBulletsAndRoids(jig)
  local bullets = {}
  local roids = {}
  do
    jig:walkEntities(nil, function(e)
      if e.tags and e.tags.roid then
        table.insert(roids, e)
      elseif e.tags and e.tags.ship_bullet then
        table.insert(bullets, e)
      end
    end)
  end

  local roidsHit, bulletsRemoved = {}, {}
  for i = 1, #bullets do
    local bullet = bullets[i]
    if not bulletsRemoved[bullet.eid] then
      for j = 1, #roids do
        local roid = roids[j]
        local range = bullet.radius.radius + roid.radius.radius
        local dist = Vec.dist(
          roid.tr.x + roid.radius.x, roid.tr.y + roid.radius.y,
          bullet.tr.x + bullet.radius.x, bullet.tr.y + bullet.radius.y
        )
        if dist <= range then
          roidsHit[roid.eid] = roid

          bulletHitsRoid(bullet, roid)

          bulletsRemoved[bullet.eid] = true
          bullet:destroy()
        end
      end
    end
  end

  for _, roid in pairs(roidsHit) do
    -- destroyRoid(roid)
  end

  -- for _,roidHit in pairs(hits) do
  --   -- print("hit: zone=" .. tostring(hits[i][3]) .. " dist=" .. tostring(hits[i][4]))
  --   for _,bullet
  --   hits[i][2]:destroy()
  -- end
end

function TestFlightJig.update(estore, input, res)
  local jig = estore:getEntityByName("test_flight")

  local ship = estore:getEntityByName("ship")
  controlShip(ship, estore, input, res)
  controlShipBullets(estore, input, res)
  -- Animate ship flame
  estore:seekEntity(matchShipFlame, function(flameE)
    flameE.pic.sy = 0.75 + sin(flameE.timer.t * 4 * pi * 2) * 0.1
    return true
  end)


  -- remote detonator
  if jig.keystate.pressed.b then
    local roid = estore:getEntityByName("r1")
    if roid then
      destroyRoid(roid)
    end
    print("bang")
  end

  collideBulletsAndRoids(jig)


  -- Camera follow
  local camera = estore:getEntityByName("cam1")
  if camera then
    camera.tr.x = ship.tr.x
    camera.tr.y = ship.tr.y
  end
end

return TestFlightJig
