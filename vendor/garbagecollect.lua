local Debug = (require('mydebug')).sub("garbagecollect")
local GC = {}
local Thresh = 1
local State = {
  t=0,
  lastGC=0,
  requested=false,
}

function GC.ifNeeded(dt)
  State.t = State.t + dt
  if State.requested and State.t - State.lastGC > Thresh then
    collectgarbage()
    State.lastGC = State.t
    State.requested = false
    Debug.println("collectgarbage() called; debounce threshold is "..Thresh)
  end
end

function GC.request()
  State.requested = true
end

return GC
