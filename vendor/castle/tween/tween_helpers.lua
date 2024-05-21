-- TweenHelpers

local H = {}

function H.addTweens(e, timerName, compProps, opts)
  -- proccess options
  opts = opts or {}
  local duration = opts.duration or 1
  local easing = opts.easing or "linear"
  local existingTimer = e.timers and e.timers[timerName]

  -- if timer exists already, clear it and associated tweens out of the way.
  if existingTimer then
    e:removeComp(existingTimer)
    if e.tweens then
      for _, tween in pairs(e.tweens) do
        if tween.timer == timerName then
          e:removeComp(tween)
        end
      end
    end
  end
  e:newComp("timer", { name = timerName, countDown = false })
  for cname, cprops in pairs(compProps) do
    local comp = e[cname]
    if comp then
      for propName, toVal in pairs(cprops) do
        e:newComp('tween', {
          comp = cname,
          prop = propName,
          from = comp[propName],
          to = toVal,
          timer = timerName,
          duration = duration,
          easing = easing,
        })
      end
    end
  end
end

function H.tweenit(e, name, compProps, opts)
  opts = opts or {}
  opts.duration = opts.duration or 0.5
  opts.easing = opts.easing or "outQuint"
  H.addTweens(e, name, compProps, opts)
end

return H
