local Explosion = require "modules.asteroids.entities.explosion"

local M = {}

-- Reduces hp by damage (if entity has a health component).
-- Returns true if the hp has been reduced to 0 or below
function M.damageEntity(e, damage)
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

function M.generateBulletStrike(bullet, contact, roid)
  local x, y = contact.x, contact.y
  local size = 0.5
  local factor = 2
  local expl = Explosion.explosion(roid:getParent(), { size = size, x = x, y = y, animSpeed = factor })
  selfDestructEnt(expl, 1.0) -- timeout the explosion
end

function M.bulletHitsRoid(bullet, contact, roid)
  M.generateBulletStrike(bullet, contact, roid)
  if M.damageEntity(roid, 1) then
    M.destroyRoid(roid)
  end
  bullet:destroy()
end

function M.destroyRoid(roid)
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
  selfDestructEnt(expl, 3.0)
end

function M.generateShipStrike(ship, contact, roid)
  local x, y = contact.x, contact.y
  local size = 0.5
  local factor = 2
  local expl = Explosion.explosion(roid:getParent(), { size = size, x = x, y = y, animSpeed = factor })
  selfDestructEnt(expl, 1.0) -- timeout the explosion
end

function M.shipHitsRoid(ship, contact, roid)
  M.generateShipStrike(ship, contact, roid)
  -- if M.damageEntity(roid, 1) then
  --   M.destroyRoid(roid)
  -- end
  -- bullet:destroy()
end

return M
