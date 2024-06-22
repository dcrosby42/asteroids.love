local Vec = require 'vector-light'
local Ship = require "modules.asteroids.entities.ship"
local Explosion = require "modules.asteroids.entities.explosion"
local Roids = require "modules.asteroids.entities.roids"

local State = require "castle.state"
local ViewportHelpers = require "castle.ecs.viewport_helpers"
local findOwningViewportCam = ViewportHelpers.findOwningViewportCamera

local Cooldown = require "modules.asteroids.systems.cooldown"

local inspect = require "inspect"

local min = math.min
local sin = math.sin
local pi = math.pi

local TestFlightJig = {}



-- Use keystate to set ship_controller values
local function updateShipController_keyboard(ship)
  local con = ship.ship_controller

  local turn = 0
  if ship.keystate.held.left then
    turn = turn - 1
  end
  if ship.keystate.held.right then
    turn = turn + 1
  end
  con.turn = turn

  local accel = 0
  if ship.keystate.held.up then
    accel = accel + 1
  end
  con.accel = accel

  if ship.keystate.held.space then
    con.fire_gun = 1
  else
    con.fire_gun = 0
  end
end


-- Use controller_state (joystick) to update ship_controller values
local function updateShipController_gamepad(ship, input)
  local conState = ship.controller_state
  local shipCon = ship.ship_controller

  shipCon.turn = conState.value.leftx or 0
  shipCon.accel = -(conState.value.lefty or 0)
  if conState.held.face1 then
    shipCon.fire_gun = 1
  else
    shipCon.fire_gun = 0
  end
end

local ShipFlameQuery = Query.create({ tag = "ship_flame" })

-- Apply ship_controller inputs to the ship
local function applyShipController(ship, estore, input, res)
  local spinSpeed = pi * 1.5

  local con = ship.ship_controller

  -- Control direction and thrust
  if con.turn ~= 0 then
    ship.tr.r = ship.tr.r + (con.turn * spinSpeed * input.dt)
  end
  if con.accel > 0 then
    -- accelerate under thrust
    local speed = 6
    local dx, dy = Vec.mul(con.accel * speed * input.dt, Vec.rotate(ship.tr.r, 0, -1))
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

  -- Fire control
  if con.fire_gun > 0 then
    if Cooldown.isReady(ship, "lasers") then
      -- FIRE
      -- left gun
      Ship.fireBullet(ship, "left", "ship_bullets_04", -1500)
      -- right gun
      local bullet = Ship.fireBullet(ship, "right", "ship_bullets_04", -1500)
      -- (pin the sound to the right bullet... prolly should be its own, but for now let's just mooch off the laser's natural lifespan)
      bullet:newComp("sound", { sound = "laser_small" })

      Cooldown.trigger(ship, "lasers")
    end
  end

  -- Show ship flame only when thrust active
  local shipFlame = estore:queryFirstEntity(ShipFlameQuery)
  if shipFlame then
    if con.accel > 0 then
      shipFlame.pic.color[4] = 1
    else
      shipFlame.pic.color[4] = 0
    end
    return true
  end
end

-- (testing: motion should be a different system) Apply velocity to get motion
local function moveShip(ship)
  ship.tr.x = ship.tr.x + ship.vel.dx
  ship.tr.y = ship.tr.y + ship.vel.dy
end

local function moveShipBullets(estore, input, res)
  for _, e in ipairs(estore:indexLookup("byTag", "ship_bullet")) do
    e.tr.x = e.tr.x + (e.vel.dx * input.dt)
    e.tr.y = e.tr.y + (e.vel.dy * input.dt)
  end
end

local function moveRoids(estore, input, res)
  for _, e in ipairs(estore:indexLookup("byTag", "roid")) do
    e.tr.x = e.tr.x + (e.vel.dx * input.dt)
    e.tr.y = e.tr.y + (e.vel.dy * input.dt)
    e.tr.r = e.tr.r + (e.vel.angularvelocity * input.dt)
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
  -- roid.radius.debug = true

  roid.vel.angularvelocity = randomFloat(-pi / 2, pi / 2)
  roid.vel.dx = randomFloat(-30, 30)
  roid.vel.dy = randomFloat(-30, 30)

  return roid
end

local function generateRoidField(jig, numRoids, min, max)
  local kinds = { "small", "medium", "medium_large", "large", "huge" }
  for i = 1, numRoids do
    local x = randomInt(min, max)
    local y = randomInt(min, max)
    local sizeCat = pickRandom(kinds)
    addRoid(jig, sizeCat, x, y)
  end
end

local function destroyRoid(roid)
  roid:removeComp(roid.health) -- avoid repeat destruction events

  -- Set the roid to remove itself soon
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
    { "keystate", { handle = { "return" } } },
    { "state",    { name = "control_mode", value = "keyboard" } },
  })

  Ship.dev_background_nebula_blue(jig, res)
  Ship.dev_background_starfield1(jig, res)

  generateRoidField(jig, 100, -4000, 4000)

  local ship = Ship.ship(jig, res)
  ship:newComp("keystate", { handle = { "left", "right", "up", "down", "space" } })

  -- Zoom the camera out a bit
  local cam = findOwningViewportCam(jig)
  if cam then
    cam.tr.sx = 1.7
    cam.tr.sy = 1.7
  end
end

local function generateBulletStrike(bullet, roid)
  local x, y = bullet.tr.x, bullet.tr.y
  local size = 0.5
  local factor = 2
  local expl = Explosion.explosion(roid:getParent(), { size = size, x = x, y = y, animSpeed = factor })
  selfDestructEnt(expl, 1.0) -- timeout the explosion
end

-- Reduces hp by damage (if entity has a health component).
-- Returns true if the hp has been reduced to 0 or below
local function damageEntity(e, damage)
  if e.health then
    -- Reduce health
    e.health.hp = e.health.hp - damage
    if e.health.hp <= 0 then
      -- signal health depleted
      return true
    end
  end
  -- health not yet depleted:
  return false
end

local function bulletHitsRoid(bullet, roid)
  generateBulletStrike(bullet, roid)
  if damageEntity(roid, 1) then
    destroyRoid(roid)
  end
end

local RoidQuery = Query.create({ tag = "roid" })
local BulletQuery = Query.create({ tag = "ship_bullet" })

local function collideBulletsAndRoids(jig)
  local bullets = jig:getEstore():queryEntities(BulletQuery)
  local roids = jig:getEstore():queryEntities(RoidQuery)

  local bulletsRemoved = {}
  for i = 1, #bullets do
    local bullet = bullets[i]
    if not bulletsRemoved[bullet.eid] then
      for j = 1, #roids do
        local roid = roids[j]
        assert(bullet.radius)
        local range = bullet.radius.radius + roid.radius.radius
        local dist = Vec.dist(
          roid.tr.x + roid.radius.x, roid.tr.y + roid.radius.y,
          bullet.tr.x + bullet.radius.x, bullet.tr.y + bullet.radius.y
        )
        if dist <= range then
          bulletHitsRoid(bullet, roid)

          bulletsRemoved[bullet.eid] = bullet
        end
      end
    end
  end

  for _, bullet in pairs(bulletsRemoved) do
    bullet:destroy()
  end
end



function TestFlightJig.update(estore, input, res)
  local jig = estore:getEntityByName("test_flight")

  local ship = estore:getEntityByName("ship")

  -- Toggle from keyboard to gamepad controlls:
  local controlMode = State.get(jig, "control_mode") or "keyboard"
  if jig.keystate.pressed["return"] then
    controlMode = controlMode == "keyboard" and "joystick" or "keyboard"
    State.set(jig, "control_mode", controlMode)
    print("test_flight: controlMode: ", controlMode)
  end

  if controlMode == "joystick" then
    updateShipController_gamepad(ship, input)
  else
    updateShipController_keyboard(ship)
  end

  applyShipController(ship, estore, input, res)

  moveShip(ship)

  moveShipBullets(estore, input, res)

  moveRoids(estore, input, res)

  -- Animate ship flame
  local shipFlame = estore:queryFirstEntity(ShipFlameQuery)
  if shipFlame then
    shipFlame.pic.sy = 0.75 + sin(shipFlame.timer.t * 4 * pi * 2) * 0.1
  end


  -- -- remote detonator
  -- if jig.keystate.pressed.b then
  --   local roid = estore:getEntityByName("r1")
  --   if roid then
  --     destroyRoid(roid)
  --   end
  --   print("bang")
  -- end

  collideBulletsAndRoids(jig)


  -- Camera follow
  local camera = estore:getEntityByName("cam1")
  if camera then
    camera.tr.x = ship.tr.x
    camera.tr.y = ship.tr.y
  end
end

return TestFlightJig
