local Coll = require "modules.asteroids.collision_categories"
local Roids = {}

Roids.PicIds = {
  "roid_small_grey_01",
  "roid_small_red_01",

  "roid_small_grey_02",
  "roid_small_red_02",

  "roid_medium_grey_01",
  "roid_medium_red_01",

  "roid_medium_grey_02",
  "roid_medium_red_02",

  "roid_medium_grey_03",
  "roid_medium_red_03",

  "roid_large_grey_01",
  "roid_large_red_01",

  "roid_large_grey_02",
  "roid_large_red_02",

  "roid_large_grey_03",
  "roid_large_red_03",
}

-- Reasonable scaling ranges:
--   small: 0.5 thru 1.5
--   medium: 0.3 thru 1.75
--   large: 0.15 thru 2.75

-- Normalizing scale factors that make medium and large roids similar-sized to smalls:
local ScaleMed2Small = 0.5
local ScaleLarge2Small = 0.2
local ScaleMed2Lg = 2.4 -- note this is a stretch, 1.75 is kinda the max, but hey, more roids!

local SpriteConfigs = {}
SpriteConfigs.small = {
  { picId = "roid_small_grey_01",  size = 1 },
  { picId = "roid_small_grey_02",  size = 1 },
  { picId = "roid_medium_grey_01", size = ScaleMed2Small },
  { picId = "roid_medium_grey_02", size = ScaleMed2Small },
  { picId = "roid_medium_grey_03", size = ScaleMed2Small },
  { picId = "roid_large_grey_01",  size = ScaleLarge2Small },
  { picId = "roid_large_grey_02",  size = ScaleLarge2Small },
  { picId = "roid_large_grey_03",  size = ScaleLarge2Small },
}

SpriteConfigs.medium = lmap(deepclone(SpriteConfigs.small), function(cfg)
  cfg.size = 2 * cfg.size
  return cfg
end)

SpriteConfigs.medium_large = lmap(deepclone(SpriteConfigs.small), function(cfg)
  cfg.size = 3 * cfg.size
  return cfg
end)
-- (drop the first two, smalls don't scale up to 3x nicely)
table.remove(SpriteConfigs.medium_large, 1)
table.remove(SpriteConfigs.medium_large, 1)

SpriteConfigs.large = {
  { picId = "roid_medium_grey_01", size = ScaleMed2Lg },
  { picId = "roid_medium_grey_02", size = ScaleMed2Lg },
  { picId = "roid_medium_grey_03", size = ScaleMed2Lg },
  { picId = "roid_large_grey_01",  size = 1 },
  { picId = "roid_large_grey_02",  size = 1 },
  { picId = "roid_large_grey_03",  size = 1 },
}

SpriteConfigs.huge = {
  { picId = "roid_large_grey_01", size = 2.75 },
  { picId = "roid_large_grey_02", size = 2.75 },
  { picId = "roid_large_grey_03", size = 2.75 },
}

local LargeRadius = 65
local SizeCatRadiusMap = {
  small = LargeRadius * ScaleLarge2Small,
  medium = LargeRadius / ScaleMed2Lg,
  medium_large = 3 * LargeRadius * ScaleLarge2Small,
  large = LargeRadius,
  huge = 2.75 * LargeRadius,
}
local function radiusForSizeCat(sizeCat)
  return SizeCatRadiusMap[sizeCat]
end


local SizeCatHPMap = {
  small = 1,
  medium = 2,
  medium_large = 3,
  large = 6,
  huge = 12,
}
local function hpForSizeCat(sizeCat)
  return SizeCatHPMap[sizeCat]
end


function Roids.roid(parent, opts)
  opts = opts or {}
  if not opts.picId then
    error("Roids.roid: picId is required")
  end
  opts.size = opts.size or 1
  opts.color = opts.color or { 1, 1, 1 }
  opts.x = opts.x or 0
  opts.y = opts.y or 0
  opts.radius = opts.radius or 65
  opts.hp = opts.hp or 6
  opts.debugHit = not not opts.debugHit
  opts.debugBody = not not opts.debugBody
  opts.mass = opts.mass or (math.pi * opts.radius * opts.radius)
  local roid = parent:newEntity({
    { "tag", { name = "roid" } },
    { 'tr',  { x = opts.x, y = opts.y, } },
    { "vel", {} },
    { 'pic', {
      id = opts.picId,
      cx = 0.5,
      cy = 0.5,
      sx = opts.size,
      sy = opts.size,
      color = opts.color,
      debug = false,
    } },
    { 'radius', { radius = opts.radius, debug = opts.debugHit } }, -- hit circle radius
    { "health", { hp = opts.hp } },
    -- phys:
    { 'body', {
      mass = opts.mass,
      friction = 0.8,
      restitution = 0.9,
      debug = opts.debugBody,
      categories = Coll.Roids,
      mask = bit.bor(Coll.Roids, Coll.Lasers, Coll.Ships),
    } },
    { 'force',       {} },
    { 'circleShape', { radius = opts.radius } },
  })
  if opts.name then
    roid:newComp("name", { name = opts.name })
  end
  return roid
end

function Roids.isRoid(e)
  return e and e.tags and e.tags.roid
end

function Roids.random(parent, opts)
  opts = shallowclone(opts)
  local cat = SpriteConfigs[opts.sizeCat]
  if not cat then
    error("Roids.random: invalid sizeCat " .. tostring(opts.sizeCat))
  end
  local cfg = pickRandom(cat)
  opts.size = cfg.size
  opts.picId = cfg.picId
  opts.radius = radiusForSizeCat(opts.sizeCat)
  opts.hp = hpForSizeCat(opts.sizeCat)
  opts.sizeCat = nil
  return Roids.roid(parent, opts)
end

return Roids
