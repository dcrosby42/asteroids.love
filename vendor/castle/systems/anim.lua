return defineQuerySystem(
  { "anim", "timer" },
  function(e, estore, input, res)
    for _, anim in pairs(e.anims) do
      if anim.duration < 0 then
        -- Ensure unset duration props are backfilled from res
        local animRes = res.anims:get(anim.id)
        anim.duration = animRes.duration
      end
      if anim.timer == '' then
        anim.timer = anim.name
      end
      if anim.onComplete == "selfDestruct" then
        local timer = e.timers[anim.timer]
        if timer and timer.t > anim.duration then
          estore:destroyEntity(e)
        end
      end
      if anim.onComplete == "expire" then
        print("b")
        local timer = e.timers[anim.timer]
        if timer and timer.t > anim.duration then
          -- Delete anim and timer
          e:removeComp(anim)
          e:removeComp(timer)
        end
      end
    end
  end)
