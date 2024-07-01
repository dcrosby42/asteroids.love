local Vec = require 'vector-light'
local Workbench = require "modules.asteroids.entities.workbench"
local Ship = require "modules.asteroids.entities.ship"
local Menu = require "modules.asteroids.jigs.menu"
local State = require "castle.state"
local TweenHelpers = require "castle.tween.tween_helpers"
local Cooldown = require "modules.asteroids.systems.cooldown"
local Roids = require "modules.asteroids.entities.roids"
local Coll = require "modules.asteroids.collision_categories"
local inspect = require "inspect"
local Battle = require "modules.asteroids.battle_helpers"
local Query = require "castle.ecs.query"

local ViewportHelpers = require "castle.ecs.viewport_helpers"
local findOwningViewportCam = ViewportHelpers.findOwningViewportCamera

local USCon = require "modules.asteroids.jigs.update_ship_controller"


local pi = math.pi
local sin = math.sin

local BulletQuery = Query.create({ tag = "ship_bullet" })


local Jig = {
  name = "test_flight"
}

local function addRoid(parent, sizeCat, x, y, opts)
  opts = opts or {}
  local roid = Roids.random(parent, {
    sizeCat = sizeCat,
    x = x,
    y = y,
    -- debugBody = true,
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


function Jig.init(parent, estore, res)
  local jig = parent:newEntity({
    { "name",     { name = Jig.name } },
    { "tag",      { name = "jig" } },
    { "keystate", { handle = { "return" } } },
    { "state",    { name = "control_mode", value = "keyboard" } },
  })

  jig:newEntity({
    { 'name',         { name = "physics_world" } },
    { 'physicsWorld', { allowSleep = false } },
  })

  Workbench.dev_background_nebula_blue(jig, res)
  Workbench.dev_background_starfield1(jig, res)

  generateRoidField(jig, 100, -4000, 4000)

  local ship = Ship.ship(jig, res)
  do
    local infos = {
      { "keystate",    { handle = { "left", "right", "up", "down", "space" } } },
      { 'body', {
        mass = 5,
        friction = 0.0,
        restitution = 0.3,
        -- debug = DEBUG_SHIP_BODY,
        categories = Coll.Ships,
        mask = Coll.Roids,
      } },
      { 'force',       {} },
      { 'circleShape', { radius = SHIP_RADIUS } },
    }
    for _, nameAndProps in ipairs(infos) do
      ship:newComp(nameAndProps[1], nameAndProps[2])
    end
    -- ship.vel.dx = 30
  end

  -- Zoom the camera out a bit
  local cam = findOwningViewportCam(jig)
  if cam then
    cam.tr.sx = 1.7
    cam.tr.sy = 1.7
  end

  return jig
end

function Jig.finalize(jigE, estore)
end

local ShipFlameQuery = Query.create({ tag = "ship_flame" })

-- Apply ship_controller inputs to the ship
local function applyShipController(ship, estore, dt)
  -- local spinSpeed = pi * 1.5

  local con = ship.ship_controller

  -- Control direction and thrust
  -- if con.turn ~= 0 then
  --   local spinSpeed = pi * 1.5 * 100
  --   local maxspin = 8
  --   ship.force.angimp = con.turn * spinSpeed
  --   if ship.vel.angularvelocity > maxspin then
  --     ship.vel.angularvelocity = maxspin
  --   elseif ship.vel.angularvelocity < -maxspin then
  --     ship.vel.angularvelocity = -maxspin
  --   end
  -- end
  if con.turn ~= 0 then
    local spinSpeed = pi * 1.5
    ship.tr.r = ship.tr.r + (con.turn * spinSpeed * dt)
  end

  if con.accel > 0 then
    -- accelerate under thrust
    -- local speed = 6
    local speed = 450 * 5
    local dx, dy = Vec.mul(con.accel * speed * dt, Vec.rotate(ship.tr.r, 0, -1))
    ship.force.impx = dx
    ship.force.impy = dy
  else
    -- auto-brake
    if Vec.len(ship.vel.dx, ship.vel.dy) > 0 then
      local speed = 150
      local dx, dy = Vec.mul(speed * dt, Vec.normalize(Vec.mul(-1, ship.vel.dx, ship.vel.dy)))
      ship.vel.dx = ship.vel.dx + dx
      ship.vel.dy = ship.vel.dy + dy
    end
  end

  -- Fire control
  if con.fire_gun > 0 then
    if Cooldown.isReady(ship, "lasers") then
      -- FIRE
      local leftBullet = Ship.fireBullet(ship, "left", "ship_bullets_04", -1500)
      local rightBullet = Ship.fireBullet(ship, "right", "ship_bullets_04", -1500)
      for _, bullet in ipairs({ leftBullet, rightBullet }) do
        local defs = {
          { 'body', {
            mass = 0.5,
            friction = 0.5,
            restitution = 0.9,
            categories = Coll.Lasers,
            mask = Coll.Roids,
            -- debug = true,
          } },
          { 'force',       {} },
          { 'circleShape', { radius = 7 } },
        }
        for _, cdef in ipairs(defs) do
          bullet:newComp(cdef[1], cdef[2])
        end
      end

      -- (pin the sound to the right bullet... prolly should be its own, but for now let's just mooch off the laser's natural lifespan)
      rightBullet:newComp("sound", { sound = "laser_small" })

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

local function collideBulletsAndRoids(estore)
  for _, bullet in ipairs(BulletQuery(estore)) do
    if bullet.contacts then
      for _, contact in pairs(bullet.contacts) do
        local hitE = estore:getEntity(contact.otherEid)
        if Roids.isRoid(hitE) then
          Battle.bulletHitsRoid(bullet, contact, hitE)
          break
        end
      end
    end
  end
end

local function collideShipAndRoids(ship, estore)
  for _, contact in pairs(ship.contacts or {}) do
    local hitE = estore:getEntity(contact.otherEid)
    if Roids.isRoid(hitE) then
      Battle.shipHitsRoid(ship, contact, hitE)
      break -- deleteme?
    end
  end
end


function Jig.update(estore, input, res)
  local jig = estore:getEntityByName(Jig.name)
  local ship = estore:getEntityByName("ship")

  -- Toggle from keyboard to gamepad controlls:
  local controlMode = State.get(jig, "control_mode") or "keyboard"
  if jig.keystate.pressed["return"] then
    controlMode = controlMode == "keyboard" and "joystick" or "keyboard"
    State.set(jig, "control_mode", controlMode)
    print("test_flight: controlMode: ", controlMode)
  end

  -- Apply controller or keybd state to the ship controller comp:
  if controlMode == "joystick" then
    USCon.updateShipController_gamepad(ship.ship_controller, ship.controller_state)
  else
    USCon.updateShipController_keyboard(ship.ship_controller, ship.keystate)
  end


  applyShipController(ship, estore, input.dt)

  -- Animate ship flame
  local shipFlame = estore:queryFirstEntity(ShipFlameQuery)
  if shipFlame then
    shipFlame.pic.sy = 0.75 + sin(shipFlame.timer.t * 4 * pi * 2) * 0.1
  end

  collideBulletsAndRoids(estore)

  collideShipAndRoids(ship, estore)

  -- Camera follow
  local camera = estore:getEntityByName("cam1")
  if camera then
    camera.tr.x = ship.tr.x
    camera.tr.y = ship.tr.y
  end
end

return Jig
