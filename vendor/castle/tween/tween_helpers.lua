-- TweenHelpers

local H = {}

function H.addTweens(e, timerName, compProps, opts)
  opts = opts or {}
  local duration = opts.duration or 1
  local killtimer = opts.killtimer == true
  local easing = opts.easing or "linear"
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
          killtimer = killtimer,
        })
      end
    end
  end
end

return H
