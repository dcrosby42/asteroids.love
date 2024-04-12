local Easing = require "castle.tween.normfuncs"
local EasingFuncs = require "castle.tween.easing"
local inspect = require "inspect"

-- Apply the individual tween component
local function applyTween(e, tween)
  local timer = e.timers[tween.timer]
  if not timer then
    error("tween timer'" .. tween.timer .. "' not found")
  end
  local easingFunc = EasingFuncs[tween.easing]
  if not easingFunc then
    error("tween easing func '" .. tween.easing .. "' not found")
  end

  local comp
  if type(tween.comp) == 'string' then
    -- For supporting component-by-type, eg, "tr"
    comp = e[tween.comp]
  elseif type(tween.comp) == 'table' then
    -- For supporting component-by-name, eg, {"timers","fader"}
    comp = e[tween.comp[1]][tween.comp[2]]
  end
  if not comp then
    error("tween comp " .. inspect(tween.comp) .. " not found")
  end

  local duration = tween.duration
  local t = math.min(timer.t, duration)
  local from = tween.from
  local to = tween.to
  if type(from) == "table" then
    -- assume list of numbers: (eg, color)
    for i = 1, #from do
      -- Standard easing func signature: (t, b, c, d)
      --   t = elapsed time
      --   b = begin
      --   c = change == ending - beginning
      --   d = duration (total time)
      comp[tween.prop][i] = easingFunc(t, from[i], to[i] - from[i], duration)
    end
  else
    -- normal numeric values:
    comp[tween.prop] = easingFunc(t, from, to - from, duration)
  end

  if t >= duration then
    comp[tween.prop] = tween.to
    tween.finished = true
  end
end

-- Remove the given tween component from the given Entity
local function removeTween(e, tween)
  if tween.killtimer then
    -- Remove the associated timer component by name, if present
    local timer = e.timers[tween.timer]
    if timer then
      e:removeComp(timer)
    end
  end
  -- Remove the tween comp
  e:removeComp(tween)
end

-- tween.apply(e): Process an Entity's tweens, driven by timers, to update
-- properties of various components over time.
-- Easing functions are specified by name in the tween component.
return function(e)
  if not e.tweens then
    return
  end
  if not e.timers then
    error("entity with tween should also have timers!")
  end
  for _, tween in pairs(e.tweens) do
    if tween.finished then
      removeTween(e, tween)
    else
      applyTween(e, tween)
    end
  end
end
