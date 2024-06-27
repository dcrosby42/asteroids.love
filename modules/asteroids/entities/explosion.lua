local Explosion = {}

Explosion.DebrisExplosionCount = 6

function Explosion.explosion(parent, opts)
  opts.x = opts.x or 0
  opts.y = opts.y or 0
  opts.size = opts.size or 1
  opts.animSpeed = opts.animSpeed or 1
  opts.r = randomFloat(0, 2 * math.pi)
  local animId
  if opts.animId then
    -- custom pic reference
    animId = opts.animId
  elseif opts.num then
    -- indexed explosion
    animId = "debris_explosion_" .. tostring(opts.num)
  else
    -- random explosion
    animId = "debris_explosion_" .. tostring(randomInt(1, Explosion.DebrisExplosionCount))
  end
  local expl = parent:newEntity({
    { "tag", { name = "explosion" } },
    { "tr",  { x = opts.x, y = opts.y, r = opts.r } },
    { "anim", {
      name = "splode",
      id = animId,
      sx = opts.size,
      sy = opts.size,
      cx = 0.5,
      cy = 0.5,
      onComplete = "selfDestruct",
    } },
    { "timer", { name = "splode", countDown = false, factor = opts.animSpeed } },
  })
  nameEnt(expl, opts.name)
  return expl
end

return Explosion
