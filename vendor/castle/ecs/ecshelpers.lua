local inspect = require('inspect')

local ResourceLoader = require "castle.resourceloader"

function requireModules(reqs)
  local modules = {}
  for i, req in ipairs(reqs) do
    local module = require(req)
    assert(module, "Cannot require '" .. req .. "'")
    table.insert(modules, module)
  end
  return modules
end

function resolveSystem(s, opts)
  opts = opts or {}
  opts.res = opts.res or ResourceLoader.newResourceRoot()
  opts.systemKeys = opts.systemKeys or { "updateSystem", "system", "System" }
  opts.systemConstructorKeys = opts.systemConstructorKeys or
      { "new", "newSystem", "newUpdateSystem" }
  if type(s) == "string" then s = require(s) end
  if type(s) == "function" then return s end
  if type(s) == "table" then
    for _, key in ipairs(opts.systemKeys) do
      if type(s[key]) == "function" then return s[key] end
    end
    for _, key in ipairs(opts.systemConstructorKeys) do
      if type(s[key]) == "function" then return s[key](opts.res) end
    end
  end
  error("ecshelpers.resolveSystem '" .. tostring(s) ..
    "' cannot be resolved as a System")
end

function composeSystems(systems)
  local rsystems = {}
  for i = 1, #systems do table.insert(rsystems, resolveSystem(systems[i])) end
  return function(estore, input, res)
    for _, system in ipairs(rsystems) do system(estore, input, res) end
  end
end

function composeDrawSystems(systems)
  local rsystems = {}
  for i = 1, #systems do
    table.insert(rsystems,
      resolveSystem(systems[i], { systemKeys = { "drawSystem" } }))
  end
  return function(estore, res)
    for _, system in ipairs(rsystems) do system(estore, res) end
  end
end

function hasComps(...)
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

function hasTag(tagname)
  return function(e)
    return e.tags and e.tags[tagname]
  end
end

function hasName(name)
  return function(e)
    return e.name and e.name.name == name
  end
end

function allOf(...)
  local matchers = { ... }
  return function(e)
    for _, matchFn in ipairs(matchers) do
      if not matchFn(e) then return false end
    end
    return true
  end
end

function addInputEvent(input, evt)
  if not input.events[evt.type] then input.events[evt.type] = {} end
  table.insert(input.events[evt.type], evt)
end

function setParentEntity(estore, childE, parentE, order)
  if childE.parent then estore:removeComp(childE.parent) end
  estore:newComp(childE, "parent", { parentEid = parentE.eid, order = order })
end

local function matchSpecToFn(matchSpec)
  if type(matchSpec) == "function" then
    return matchSpec
  elseif type(matchSpec) == "string" then
    return hasComps(matchSpec)
  else
    return hasComps(unpack(matchSpec))
  end
end

function defineUpdateSystem(matchSpec, fn)
  local matchFn = matchSpecToFn(matchSpec)
  return function(estore, input, res)
    estore:walkEntities(matchFn, function(e)
      fn(e, estore, input, res)
    end)
  end
end

function defineDrawSystem(matchSpec, fn)
  local matchFn = matchSpecToFn(matchSpec)
  return function(estore, res)
    estore:walkEntities(matchFn, function(e)
      fn(e, estore, res)
    end)
  end
end

function getName(e)
  if e.name and e.name.name then
    return e.name.name
  else
    return nil
  end
end

function resolveEntCompKeyByPath(e, path)
  local key = path[#path]
  local cur = e
  for i = 1, #path - 2 do
    if path[i] == "PARENT" then
      cur = cur:getParent()
    else
      cur = cur[path[i]]
    end
  end
  local comp = cur[path[#path - 1]]
  return cur, comp, key
end

local function byOrder(a, b)
  local aval, bval
  if a.parent and a.parent.order then
    aval = a.parent.order
  else
    aval = 0
  end
  if b.parent and b.parent.order then
    bval = b.parent.order
  else
    bval = 0
  end
  return aval < bval
end

function sortEntities(ents, deep)
  table.sort(ents, byOrder)
  if deep then for i = 1, #ents do sortEntities(ents[i]._children, true) end end
end

function tagEnt(e, name)
  e:newComp('tag', { name = name })
end

function nameEnt(e, name)
  if e.name then
    e.name.name = name
  else
    e:newComp('name', { name = name })
  end
end

-- for use with castle.systems.selfdestruct
function selfDestructEnt(e, t)
  tagEnt(e, "self_destruct")
  e:newComp('timer', { t = t, name = 'self_destruct' })
end

-- Return the first Entity matching the given entity predicate.
-- Return nil if not found
function findEntity(estoreOrEnt, filter)
  local found
  estoreOrEnt:seekEntity(filter, function(e)
    found = e
    return true
  end)
  return found
end

-- Return all the Entities matching the given entity predicate.
-- Return empty table if none found
function findEntities(estore, filter)
  local ents = {}
  estore:walkEntities(filter, function(e)
    table.insert(ents, e)
  end)
  return ents
end

-- Given a tr component, return a new love2d transform
function trToTransform(tr, rotx, roty)
  if tr then
    return love.math.newTransform(tr.x, tr.y, tr.r, tr.sx, tr.sy, rotx, roty)
  end
  return love.math.newTransform()
end

-- Compute x,y offset of camera's center to the upper-left corner of the viewport
function computeCameraOffset(vpE, camE)
  local offx, offy = 0, 0
  if vpE and vpE.box then
    offx, offy = vpE.box.w / 2, vpE.box.h / 2
  end
  return love.math.newTransform(0, 0, 0, camE.tr.sx, camE.tr.sy):transformPoint(offx, offy)
end

function viewportCameraTransform(vpE, camE)
  if not camE or not camE.tr then
    return love.math.newTransform()
  end

  -- Start building a "camera transform"
  local tr = camE.tr
  local transf = love.math.newTransform()

  -- Translate the camera's pos to the center of the viewport
  local offx, offy = computeCameraOffset(vpE, camE)
  transf:translate(tr.x - offx, tr.y - offy)

  -- Rotate, centered on the camera:
  transf:translate(offx, offy)
  transf:rotate(tr.r)
  transf:translate(-offx, -offy)

  -- Use camera's scale vars as "zoom"
  transf:scale(tr.sx, tr.sy)

  -- invert the xform, to create the desired viewport-relative effects
  transf = transf:inverse()

  return transf
end

-- Compute the love2d Transform for the given entity by accumulating transformations
-- from the scene root down through the entity.
function computeEntityTransform(e)
  if e == nil or e.eid == nil then
    -- _root node in estore has no eid nor transform, must stop here
    return love.math.newTransform()
  end

  -- Compute a love2d Transform for the entity based on its tr component.
  -- The transform is recursively derived up to the root ancestor entity.
  local transform = computeEntityTransform(e:getParent())
  if e.tr then
    transform:apply(trToTransform(e.tr))
  end
  if e.viewport then
    local camE = e:getEstore():getEntityByName(e.viewport.camera)
    transform:apply(viewportCameraTransform(e, camE))
    -- if camE and camE.tr then
    --   local camTransf = love.math.newTransform(e.box.w / 2 - camE.tr.x, e.box.h / 2 - camE.tr.y, -camE.tr.r, 1, 1)
    --   transform:apply(camTransf)
    -- end
  end
  return transform
end

function computeEntityScaleAndRot(e)
  local xform = computeEntityTransform(e)
end

-- Given a screen-space coordinate pair, return the entity-relative transformed point.
function screenToEntityPt(e, x, y)
  return computeEntityTransform(e):inverseTransformPoint(x, y)
end

-- Subtract vector 0 from vector 1 after inverse-transforming them.
-- (Eg, compute a delta vector based on screen coords as they'd appear in some other transformed context)
-- (Namely, computing dx,dy for dragging entities.)
function subtractInverseTransformed(xform, x1, y1, x0, y0)
  local tx1, ty1 = xform:inverseTransformPoint(x1, y1)
  local tx0, ty0 = xform:inverseTransformPoint(x0, y0)
  return tx1 - tx0, ty1 - ty0
end
