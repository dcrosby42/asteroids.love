local Debug = require 'mydebug'
Debug = Debug.sub("TouchButton", false, false)

return function(estore, input, res)
  estore:walkEntities(hasComps('touch', 'button'), function(e)
    local button = e.button
    if button.kind == 'hold' then
      local touch = e.touch
      local timer = e.timers and e.timers.holdbutton

      -- See if the button has been held long enough to trigger:
      if timer and timer.alarm then
        e:removeComp(timer)
        table.insert(input.events, {
          type = button.eventtype,
          state = button.eventstate,
          eid = e.eid,
          cid = button.cid,
        })
        Debug.println("fire event " .. button.eventtype)
      end

      if touch.state == "pressed" then
        e:newComp('timer', { name = "holdbutton", t = button.holdtime })
        Debug.println("begin hold")
      elseif touch.state == "released" then
        if timer then
          e:removeComp(timer)
          Debug.println("aborted")
        end
      end
    end
  end)
end
