local Explosion = {}

Explosion.DebrisExplosionCount = 6

function Explosion.explosion(parent, opts)
  opts.x = opts.x or 0
  opts.y = opts.y or 0
  opts.size = opts.size or 1
  opts.animSpeed = opts.animSpeed or 1
  local picId
  if opts.picId then
    picId = opts.picId
  elseif opts.num then
    picId = "debris_explosion_" .. tostring(opts.num)
  else
    picId = "debris_explosion_" .. tostring(math.random(Explosion.DebrisExplosionCount))
  end
  return parent:newEntity({
    { "tag",   { name = "explosion" } },
    { "tr",    { x = opts.x, y = opts.y } },
    { "anim",  { id = picId, sx = opts.size, sy = opts.size, cx = 0.5, cy = 0.5, timer = "splode" } },
    { "timer", { name = "splode", countDown = false, factor = opts.animSpeed } },
  })
end

return Explosion
