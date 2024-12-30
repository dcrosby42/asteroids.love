local Comp = require 'castle.ecs.component'

function entityDebugString(e)
  local s = entityName(e) .. ": " .. "\n"
  for k, v in pairs(e) do
    if tostring(k):byte(1) ~= 95 then
      if v.cid and v.eid then
        local keyp = tostring(k) .. "s"
        if tcount(e[keyp]) == 1 then
          s = s .. "  " .. tostring(k) .. ": " .. Comp.debugString(v) .. "\n"
        else
          s = s .. "  " .. tostring(keyp) .. ": \n"
          for name, comp in pairs(e[keyp]) do
            s = s .. "    " .. tostring(name) .. ": "
            if v.cid == comp.cid then
              s = s .. "*"
            end
            s = s .. Comp.debugString(comp)
            s = s .. "\n"
          end
        end
      end
    end
  end
  return s
end

function entityName(e)
  -- if e.name and e.name.name then
  --   return e.name.name .. " (" .. tostring(e.eid) .. ")"
  -- elseif e.tag and e.tag.name then
  --   return "[tag=" .. e.tag.name .. "] (" .. tostring(e.eid) .. ")"
  -- else
  --   return tostring(e.eid)
  -- end
  local n = ""
  n = n .. tostring(e.eid)
  if e.name and e.name.name and #e.name.name > 0 then
    n = n .. "." .. e.name.name
  end
  if e.tags then
    n = n .. "["
    for tname, _tag in pairs(e.tags) do
      n = n .. tname .. " "
    end
    n = n .. "]"
  end
  return n
end

function entityTreeDebugString(e, indent)
  local chOrder = ""
  if e.parent then
    chOrder = tostring(e.parent.order) .. ": "
  end
  local s = indent .. chOrder .. entityName(e) .. ": \n"
  for _, ch in ipairs(e._children) do
    s = s .. entityTreeDebugString(ch, indent .. "  ")
  end
  return s
end
