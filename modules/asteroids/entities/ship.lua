-- local W = require "modules.asteroids.entities.world"
local Vec = require 'vector-light'
local Coll = require "modules.asteroids.collision_categories"

local Ship = {}

local SHIP_RADIUS = 40

function Ship.ship(parent, res)
  local ship = parent:newEntity({
    { "name",             { name = "ship" } },
    { "tr",               {} },
    { "vel",              {} },
    -- Control
    { "controller_state", { match_id = "joystick1" } },
    { "keystate",         { handle = { "left", "right", "up", "down", "space" } } },
    { "ship_controller",  {} },
    -- Physics params
    {
      'body', {
      mass = 5,
      friction = 0.0,
      restitution = 0.3,
      categories = Coll.Ships,
      mask = Coll.Roids,
      -- debug = true,
    } },
    { 'force',       {} },
    { 'circleShape', { radius = SHIP_RADIUS } },
    -- State
    { "cooldown",    { name = "lasers", t = 0.1, state = "ready" } },
  })
  ship:newEntity({
    { "tag", { name = "gun_muzzle" } },
    { "tag", { name = "gun_muzzle_left" } },
    { "tr",  { x = -22, y = -9 } },
  })
  ship:newEntity({
    { "tag", { name = "gun_muzzle" } },
    { "tag", { name = "gun_muzzle_right" } },
    { "tr",  { x = 22, y = -9 } },
  })
  ship:newEntity({
    { "tag", { name = "ship_flame" } },
    { "tr",  { y = 30 } },
    { 'pic', {
      name = "flame",
      id = "ship_flame_06",
      sx = 0.75,
      sy = 0.75,
      cx = 0.5,
      cy = 0,
      color = { 1, 1, 1, 0 },
    } },
    { "timer", {
      name = "flame",
      reset = 1,
      countDown = false,
      loop = true,
    } },
  })
  ship:newEntity({
    { "tag", { name = "ship_body" } },
    { 'pic', {
      id = "ship_example_05",
      sx = 0.75,
      sy = 0.75,
      cx = 0.5,
      cy = 0.5,
      debug = false,
    } },
  })
  return ship
end

local function transformToLocAndDir(transf)
  local x, y = transf:transformPoint(0, 0) -- firing point relative to space ship exists in
  local mrx, mry = transf:transformPoint(0, 1)
  local dirx, diry = mrx - x, mry - y
  local r = Vec.angleTo(dirx, diry, 0, 1)
  return x, y, r, dirx, diry
end

-- Create a new ship bullet entity with location and angle based on
-- the location of the muzzle indicated by `side`.
-- Assumes the ship has a child entity named "gun_muzzle_{side}"
function Ship.fireBullet(ship, side, bulletPicId, bulletSpeed)
  local parent = ship:getParent() -- intended parent of new bullet
  local name = "ship_bullet_" .. side
  local bulletE
  ship:seekEntity(hasTag("gun_muzzle_" .. side), function(muzzle)
    local muzzleTx = computeEntityTransform(muzzle, parent)
    local x, y, r, dirx, diry = transformToLocAndDir(muzzleTx)
    local velx, vely = Vec.mul(bulletSpeed, dirx, diry)

    bulletE = parent:newEntity({
      { "name", { name = name } },
      { "tag",  { name = "ship_bullet" } },
      { "tr",   { x = x, y = y, r = r } },
      { "vel",  { dx = velx, dy = vely } },
      { 'pic', {
        name = "bullet",
        id = bulletPicId,
        sx = 1,
        sy = 1,
        cx = 0.5,
        cy = 0.5,
      } },
      { 'radius', { radius = 10, debug = false } }
    })
    selfDestructEnt(bulletE, 2)
    return true
  end)
  return bulletE
end

return Ship
