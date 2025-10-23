-- Helpers for manipulating value of "state" components.

local State = {}

---Retrieve the current value of a named state.
---If no such state, nil is returned
---@param e Entity The entity
---@param sname string Name of the state
---@return any value The current value
function State.get(e, sname)
  if e.state[sname] then
    return e.states[sname].value
  end
  return nil
end

---Set a new value for the named state component
---If no such state, nothing happens, nil is returned
---@param e Entity The entity
---@param sname string Name of the state
---@param val any Value of the state
---@return any val The given value
function State.set(e, sname, val)
  if e.states[sname] then
    e.states[sname].value = val
    return val
  end
  return nil
end

---Treat a named state as a boolean and toggle it from true to false or vice-versa.
---@param e Entity The entity
---@param sname string Name of the state to toggle
---@return any newVal
function State.toggle(e, sname)
  local newVal = not State.get(e, sname)
  State.set(e, sname, newVal)
  return newVal
end

return State
