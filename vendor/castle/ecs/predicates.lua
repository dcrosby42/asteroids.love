local M = {}

function M.hasComps(...)
  local ctypes = { ... }
  local num = #ctypes
  if num == 0 then
    return function(e)
      return true
    end
  elseif num == 1 then
    return function(e)
      return e[ctypes[1]] ~= nil
    end
  elseif num == 2 then
    return function(e)
      return e[ctypes[1]] ~= nil and e[ctypes[2]] ~= nil
    end
  elseif num == 3 then
    return function(e)
      return e[ctypes[1]] ~= nil and e[ctypes[2]] and e[ctypes[3]] ~= nil
    end
  elseif num == 4 then
    return function(e)
      return e[ctypes[1]] ~= nil and e[ctypes[2]] and e[ctypes[3]] ~= nil and
          e[ctypes[4]] ~= nil
    end
  else
    return function(e)
      for _, ctype in ipairs(ctypes) do if e[ctype] == nil then return end end
      return true
    end
  end
end

function M.hasTag(tagname)
  return function(e)
    return e.tags and e.tags[tagname]
  end
end

function M.hasName(name)
  return function(e)
    return e.name and e.name.name == name
  end
end

function M.allOf(...)
  local matchers = { ... }
  return function(e)
    for _, matchFn in ipairs(matchers) do
      if not matchFn(e) then return false end
    end
    return true
  end
end

function M.matchSpecToFn(matchSpec)
  if type(matchSpec) == "function" then
    return matchSpec
  elseif type(matchSpec) == "string" then
    return hasComps(matchSpec)
  else
    return hasComps(unpack(matchSpec))
  end
end

return M
