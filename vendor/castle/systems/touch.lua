local EventHelpers = require 'castle.systems.eventhelpers'
local DoDebug = false
local Debug = require('mydebug').sub("Touch", DoDebug, DoDebug)
local inspect = require("inspect")

-- Pre-declare helper funcs (so we can write the system func first)
local touchPressed, touchMoved, touchReleased
local findTouch, cleanupTouches, touchName

local touchSystem = function(estore, input, res)
  cleanupTouches(estore)
  EventHelpers.handle(input.events, 'touch', {
    pressed = function(touchEvt)
      touchPressed(estore, touchEvt)
    end,
    moved = function(touchEvt)
      touchMoved(estore, touchEvt)
    end,
    released = function(touchEvt)
      touchReleased(estore, touchEvt)
      -- Returning false here to preserve touchEvt instead of consuming.
      -- This is defensive of cases where some bad logic has left a
      -- touch component that needs to be cleaned up.
      return false
    end,
  })
end

touchPressed = function(estore, touchEvt)
  -- use bottom-up search to emulate reversed draw-order
  estore:seekEntityBottomUp(hasComps("touchable"), function(e)
    local x, y = touchEvt.x, touchEvt.y

    -- Detect touch intersection:
    local ex, ey = screenToEntityPt(e, touchEvt.x, touchEvt.y)
    local targx, targy = e.touchable.x, e.touchable.y
    local d = math.dist(ex, ey, targx, targy)
    if d > e.touchable.r then
      -- nope!
      return false
    end

    -- Add a new touch component to the entity
    e:newComp('touch', {
      name = touchName(touchEvt.id),
      id = touchEvt.id,
      state = 'pressed',
      init_x = x,
      init_y = y,
      init_ex = ex,
      init_ey = ey,
      prev_x = x,
      prev_y = y,
      x = x,
      y = y,
      debug = DoDebug or e.touchable.debug,
    })
    Debug.println(function() return "Start touch " .. inspect(e.touch) end)
    return true -- signal to seekEntity that we've hit; stop seeking
  end)
end

touchMoved = function(estore, touchEvt)
  local e, touchComp = findTouch(estore, touchEvt.id)
  if e and touchComp and touchComp.state ~= "released" then
    touchComp.state = "moved"
    touchComp.prev_x = touchComp.x
    touchComp.prev_y = touchComp.y
    touchComp.x = touchEvt.x
    touchComp.y = touchEvt.y
    Debug.println(function() return "moved " .. inspect(e.touch) end)
  end
end

touchReleased = function(estore, touchEvt)
  local e, touchComp = findTouch(estore, touchEvt.id)
  if e and touchComp then
    -- NB: state will be set to 'released'; during the next update, the top of
    -- this system will remove the touch component.
    touchComp.state = "released"
    if touchEvt.x ~= touchComp.x or touchEvt.y ~= touchComp.y then
      touchComp.dx = touchEvt.x - touchComp.x
      touchComp.dy = touchEvt.y - touchComp.y
      touchComp.x = touchEvt.x
      touchComp.y = touchEvt.y
    end
    Debug.println(function() return "released " .. inspect(e.touch) end)
  end
end

cleanupTouches = function(estore, touchEvt)
  -- 'released' touches only live for 1 trip around the update loop:
  estore:walkEntities(hasComps('touch'), function(e)
    for _, touchComp in pairs(e.touchs) do
      if touchComp.state == 'released' then
        e:removeComp(touchComp)
      else
        -- Touch components are "idle" between actual touch events
        touchComp.state = 'idle'
      end
    end
  end)
end

touchName = function(id)
  return "touch-" .. tostring(id)
end

findTouch = function(estore, touchId)
  local e = findEntity(estore, function(e)
    return e.touch and e.touch.id == touchId
  end)
  if e then
    if e.touch.id == touchId then
      return e, e.touch
    else
      local touchComp = e.touchs[touchName(touchId)]
      if not touchComp then
        Debug.println("??? findTouch eid=" .. e.eid .. " mishandling touchid=" .. touchId)
        return nil, nil
      else
        return e, touchComp
      end
    end
  else
    return nil, nil
  end
end

return touchSystem
