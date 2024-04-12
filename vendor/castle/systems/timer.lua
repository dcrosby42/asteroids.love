local function emitEvent(input, timer, e)
  local evt = shallowclone(timer.event)
  evt.sourceComp = timer
  evt.sourceEnt = e
  table.insert(input.events, evt)
end

return function(estore, input, res)
  estore:walkEntities(hasComps('timer'), function(e)
    for _, timer in pairs(e.timers) do
      if timer.countDown then
        if timer.t > 0 then
          -- tick some time off the clock
          timer.alarm = false
          timer.t = timer.t - (input.dt * timer.factor)
        else
          -- Time!
          if not timer.alarm and timer.event ~= '' then
            emitEvent(input, timer, e)
          end
          timer.alarm = true
          if timer.loop then timer.t = timer.reset end
        end
      else -- ...countDown == false (ie, we're counting up)
        timer.t = timer.t + (input.dt * timer.factor)
        if timer.reset and timer.reset > 0 then
          if timer.t >= timer.reset then
            -- Time!
            if not timer.alarm and timer.event ~= '' then
              emitEvent(input, timer, e)
            end
            timer.alarm = true
            if timer.loop then
              timer.t = 0
            else
              timer.t = timer.reset
            end
          end
        end
      end
    end
  end)
end

