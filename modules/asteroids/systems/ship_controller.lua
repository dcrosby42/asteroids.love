local Cooldown = require "modules.asteroids.systems.cooldown"
local Ship = require "modules.asteroids.entities.ship"
local Query = require "castle.ecs.query"
local Vec = require 'vector-light'
local Coll = require "modules.asteroids.collision_categories"
local pi = math.pi


local function applyKeystateToShipController(ship_controller, keystate)
  local turn = 0
  if keystate.held.left then
    turn = turn - 1
  end
  if keystate.held.right then
    turn = turn + 1
  end
  ship_controller.turn = turn

  local accel = 0
  if keystate.held.up then
    accel = accel + 1
  end
  ship_controller.accel = accel

  if keystate.held.space then
    ship_controller.fire_gun = 1
  else
    ship_controller.fire_gun = 0
  end
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


return defineQuerySystem("ship_controller",
  function(e, estore, input, res)
    applyKeystateToShipController(e.ship_controller, e.keystate)
    applyShipController(e, estore, input.dt)
  end
)
