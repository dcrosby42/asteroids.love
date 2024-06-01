local function newState()
  return { deps = {}, stack = {} }
end

local M = { state = newState(), opts = { debug = false } }

local function log(...)
  if not M.opts.debug then return end
  local str = "castle.ModuleLoader:"
  local n = select('#', ...)
  if n > 0 then
    for i = 1, n do
      local v = select(i, ...)
      str = str .. " " .. tostring(v)
    end
  end
  print(str)
end

local function push_require_dep(m, name)
  local deps = m.state.deps
  local node = deps[name]
  if not node then
    node = { name = name, deps = {} }
    deps[name] = node
  end
  local stack = m.state.stack
  if #stack > 0 then stack[#stack].deps[name] = node end
  stack[#stack + 1] = node
end

local function pop_require_dep(m)
  m.state.stack[#m.state.stack] = nil
end

local original_require = require

require = function(name)
  log("require: " .. name) -- XXX
  push_require_dep(M, name)
  local loaded = original_require(name)
  pop_require_dep(M)
  return loaded
end

M.load = function(module_name)
  local module = require(module_name)
  M.debug_dependencies()
  return module
end

local function walk_deps(node, fn)
  if not node.deps then return end
  for _, depnode in pairs(node.deps) do
    fn(node.name, depnode.name)
    walk_deps(depnode, fn)
  end
end

M.list_deps_of = function(name)
  local list = {}
  walk_deps(M.state.deps[name], function(modname, depmodname)
    list[#list + 1] = depmodname
  end)
  return list
end

M.uncache_package = function(name)
  package.loaded[name] = nil
end


-- (recursive dep tree log helper)
local function debug_deps_tree(deps, ind)
  if deps then
    ind = ind or ""
    for name, node in pairs(deps) do
      log(ind .. name)
      debug_deps_tree(node.deps, ind .. "  ")
    end
  end
end

-- Recursively print the dependency tree(s) created by tracking "requires" during module loading
M.debug_dependencies = function()
  if not M.opts.debug then return end
  log("ModuleLoader.debug_dependencies:")
  debug_deps_tree(M.state.deps)
end

return M
