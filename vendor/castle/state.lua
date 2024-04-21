-- Helpers for manipulating value of "state" components.

local State = {}

function State.get(e, sname)
  return e.states[sname].value
end

function State.set(e, sname, val)
  e.states[sname].value = val
  return val
end

function State.toggle(e, sname)
  local newVal = not State.get(e, sname)
  State.set(e, sname, newVal)
  return newVal
end

return State
