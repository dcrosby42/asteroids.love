local Vec = require 'vector-light'
local Ship = require "modules.asteroids.entities.ship"

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
  estore:walkEntities(allOf(hasTag("ship_bullet"), hasComps("tr", "vel")), function(e)
    e.tr.x = e.tr.x + (e.vel.dx * input.dt)
    e.tr.y = e.tr.y + (e.vel.dy * input.dt)
  end)
end



function TestFlightJig.init(parent, estore, res)
  local jig = parent:newEntity({
    { "name", { name = "test_flight" } },
    { "tag",  { name = "jig" } },
  })
  Ship.dev_background_nebula_blue(jig, res)
  Ship.dev_background_starfield1(jig, res)
  local ship = Ship.ship(jig, res)
  ship:newComp("keystate", { handle = { "left", "right", "up", "down", "space" } })
end

function TestFlightJig.update(estore, input, res)
  local ship = estore:getEntityByName("ship")
  controlShip(ship, estore, input, res)
  controlShipBullets(estore, input, res)
  -- Animate ship flame
  estore:seekEntity(matchShipFlame, function(flameE)
    flameE.pic.sy = 0.75 + sin(flameE.timer.t * 4 * pi * 2) * 0.1
    return true
  end)

  local camera = estore:getEntityByName("cam1")
  if camera then
    camera.tr.x = ship.tr.x
    camera.tr.y = ship.tr.y
  end
end

return TestFlightJig
