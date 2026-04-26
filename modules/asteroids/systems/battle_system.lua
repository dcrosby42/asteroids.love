local Query = require "castle.ecs.query"
local Roids = require "modules.asteroids.entities.roids"
local Battle = require "modules.asteroids.battle_helpers"

local BulletQuery = Query.create({ tag = "ship_bullet" })

local function collideBulletsAndRoids(estore)
  for _, bulletE in ipairs(BulletQuery(estore)) do
    if bulletE.contacts then
      for _, contact in pairs(bulletE.contacts) do
        local hitE = estore:getEntity(contact.otherEid)
        if Roids.isRoid(hitE) then
          Battle.bulletHitsRoid(bulletE, contact, hitE)
          break
        end
      end
    end
  end
end

---@param estore Estore
local function collideShipAndRoids(ship, estore)
  for _, contact in pairs(ship.contacts or {}) do
    local hitE = estore:getEntity(contact.otherEid)
    if Roids.isRoid(hitE) then
      Battle.shipHitsRoid(ship, contact, hitE)
      break
    end
  end
end

return function(estore, input, res)
  local ship = estore:getEntityByName("ship")
  if not ship then return end
  collideBulletsAndRoids(estore)
  collideShipAndRoids(ship, estore)
end
