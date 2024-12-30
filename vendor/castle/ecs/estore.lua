local Comp = require 'castle.ecs.component'
local Entity = require 'castle.ecs.entity'
local Indexer = require 'castle.ecs.indexer'
require 'castle.ecs.debughelpers'



local Estore = {}

function Estore:new(o)
  o = o or {
    eidCounter = 1,
    cidCounter = 1,
    comps = {},
    ents = {},
    caches = {},
    indexConfigs = Indexer.DefaultConfigs,
    indexes = {},
    enableIndexing = true,
    _root = { _root = true, _children = {} },
    _reorderLockout = false,
  }
  setmetatable(o, self)
  self.__index = self
  if o.enableIndexing then
    o.indexes = Indexer.initIndexes(o.indexConfigs)
  end
  return o
end

function Estore:nextEid()
  local eid = "e" .. self.eidCounter
  self.eidCounter = self.eidCounter + 1
  return eid
end

function Estore:nextCid()
  local cid = "c" .. self.cidCounter
  self.cidCounter = self.cidCounter + 1
  return cid
end

local addChildEntityTo -- defined below

function Estore:_makeEnt(eid)
  local e = Entity:new({
    eid = eid,
    _estore = self,
    _parent = nil,
    _children = {},
  })
  self.ents[eid] = e
  addChildEntityTo(self._root, e)
  return e
end

function Estore:newEntity(compList, subs)
  local eid = self:nextEid()
  local e = self:_makeEnt(eid)

  if compList then
    for _, cinfo in ipairs(compList) do
      local ctype, data = unpack(cinfo)
      self:newComp(e, ctype, data)
    end
  end

  if subs then for _, childComps in ipairs(subs) do e:newChild(childComps) end end
  return e
end

-- Alias for Estore:newEntity
function Estore:buildEntity(compList, subs)
  return self:newEntity(compList, subs)
end

function Estore:destroyEntity(e)
  if not e then return end
  if e._destroyed then return end

  -- Destroy child entities. (Careful to iterate on a shallow copy of the _children list)
  for _, childEnt in ipairs(lcopy(e._children)) do
    self:destroyEntity(childEnt)
  end

  -- Collect components for destruction
  local compsToRemove = {}
  for _, comp in pairs(self.comps) do
    -- sanity check: ensure all our components actually consider this entity its owner:
    if comp.eid == e.eid then
      table.insert(compsToRemove, comp)
    end
  end

  -- Destroy the Components
  for _, comp in ipairs(compsToRemove) do
    self:removeComp(comp)
  end

  -- (for added safety; in most cases this will already have been handled by removal of the "parent" comp)
  self:_deparent(e)

  e._destroyed = true
end

-- Claim a comp from its object pool and (optionally) initialize with values from given data.
-- Once initialized, the comp is then added via Estore:addComp(e,comp)... see those docs for more info.
function Estore:newComp(e, typeName, data)
  local compType = assert(Comp.types[typeName],
    "No component type '" .. typeName .. "'")
  local comp = compType.cleanCopy(data)
  return self:addComp(e, comp)
end

-- Attaches a component to an entity.
-- The component will be added to:
--   - the internal component cache (keyed by cid)
--   - the entity's singular reference for this type of component (for the first comp of any given type)
--   - the entity's collection for this comp type, keyed by name or pseudoname (a string representing the number of this comp)
-- The component will be modified:
--   - comp.eid will be set to the entity's eid
--
-- Eg:
--   Given comp={type="imgsprite", cid=42, name="hat"} and e={eid=100}
--   When  estore.addComp(e,comp)
--   Then  e.imgsprite == comp
--         e.imgsprites.hat == comp
--         comp.eid == 100
--
-- Another eg:
--   Given comp with no name
--   When  estore.addComp(e,comp)
--   Then  e.imgsprite == comp
--         e.imgsprites["1"] == comp
--         comp.eid == 100
function Estore:addComp(e, comp)
  if not self.ents[e.eid] then
    -- shenanigans... if while modifying an entity, it becomes empty of comps,
    -- it may have gotten cleaned out of the ents cache.
    self.ents[e.eid] = e
  end

  -- Officially relate this comp to its entity
  comp.eid = e.eid

  -- Assign the next cid (if not already set):
  if not comp.cid or comp.cid == '' then comp.cid = self:nextCid() end
  -- Index the comp by cid
  self.comps[comp.cid] = comp

  -- Special handling for "parent" component type.
  -- Adding a "parent" comp to an entity engenders some internal
  if comp.type == "parent" then
    self:_linkEntityToParent(e, comp)
  end

  -- Which "convenience sets" to add this component to within the entity:
  local key = comp.type   -- singular key
  local keyp = key .. "s" -- plural key

  if not e[key] then
    -- (first component of this type within this entity)
    e[key] = comp
    e[keyp] = {}
  end
  -- Figure out how best to key the comp within the set:
  local compKey = comp.name
  if compKey == nil or compKey == '' then
    compKey = comp.cid
  end
  -- Link to the comp from the plural set
  e[keyp][compKey] = comp

  -- update the auxiliary entity indexes based on this comp (if applicable)
  self:_indexComp(comp)

  return comp
end

-- Detach a component from the given entity.
-- This method is invoked just before component removal, or before transferring to another entity.
-- The comp will remain in the comps cache, and will NOT be released back to its object pool.
function Estore:detachComp(e, comp)
  if e then
    local key = comp.type
    local keyp = key .. "s"
    local plural = e[keyp]

    -- Remove comp from the plural ref table:
    if plural then
      for k, c in pairs(plural) do
        if c.cid == comp.cid then plural[k] = nil end
      end
    end

    -- If this comp was the singular comp ref, pick a different comp (or nil) to replace it:
    local noMoreOfThisType = false
    if e[key] and e[key].cid == comp.cid then
      local _, val = next(e[keyp], nil) -- pluck any comp from the plural ref
      e[key] = val                      -- will either be another comp or nil, if there weren't any more
      if not val then
        -- This was the last comp of its type in this entity
        e[keyp] = nil -- remove the plurals ref map
        noMoreOfThisType = true
      end
    end

    self:_deindexComp(comp, noMoreOfThisType) -- de-index the comp (removes eid from any indexes created by this comp)

    if comp.type == "parent" then
      self:_deparent(e)
    end

    -- Check if the entity is now devoid of comps; if so, remove the entity
    local compkeycount = 0
    for k, v in pairs(e) do
      if k:byte(1) ~= 95 then -- k doesn't start with _
        compkeycount = compkeycount + 1
      end
    end
    if compkeycount <= 1 then
      -- eid is only remaining key, meaning we have no comps... EVAPORATE THE ENTITY
      self.ents[e.eid] = nil
    end
  end
  -- disassociate the comp from this entity
  comp.eid = ''
end

-- Remove the comp from its entity and the estore.
-- The comp will be removed from the comps cache and released back to its object pool.
function Estore:removeComp(comp)
  if comp.eid == nil or comp.eid == '' then
    print("!! Estore:removeComp BAD EID comp=" .. Comp.debugString(comp))
    return
  end

  self:detachComp(self.ents[comp.eid], comp)

  self.comps[comp.cid] = nil -- uncache
  comp.cid = ''
  Comp.release(comp)
end

function Estore:transferComp(eFrom, eTo, comp)
  self:detachComp(eFrom, comp)
  self:addComp(eTo, comp)
end

function Estore:getEntity(eid)
  return self.ents[eid]
end

function Estore:getComp(cid)
  return self.comps[cid]
end

function Estore:getCompAndEntityForCid(cid)
  local comp = self.comps[cid]
  if comp then
    local ent = self.ents[comp.eid]
    return comp, ent
  else
    return nil, nil
  end
end

-- Iterate all Entities by walking the parent-child tree in preorder fashion.
-- (Ie, match/process the given node, then the child nodes from first to last)
-- IF a node IS matched AND the processing of that node returns false (explicitly), the children are NOT processed.
function Estore:walkEntities(matchFn, doFn)
  for _, e in ipairs(self._root._children) do self:walkEntity(e, matchFn, doFn) end
end

-- Match/process the given node, then the child nodes from first to last).
-- IF a node IS matched AND the processing of that node returns explicitly false, the children are NOT processed.
-- (If children nodes supress processing their own children, this does not prevent processing of their own peers.)
function Estore:walkEntity(e, matchFn, doFn)
  if (not matchFn) or matchFn(e) then -- execute doFn if either a) no matcher, or b) matcher provided and returns true
    if doFn(e) == false then return end
  end
  self:walkChildren(e, matchFn, doFn)
end

-- Iterate the children of an entity, passing each to self:walkEntity
function Estore:walkChildren(e, matchFn, doFn)
  for _, ch in ipairs(e._children) do
    self:walkEntity(ch, matchFn, doFn)
  end
end

function Estore:walkEntities2(matchFn, doFn)
  for _, e in ipairs(self._root._children) do
    self:walkEntity2(e, matchFn, doFn)
  end
end

-- Just like walkEntity, except instead of doFn-then-children, the doFn itself
-- is given a func to execute descent into child entities
function Estore:walkEntity2(e, matchFn, doFn)
  if (not matchFn) or matchFn(e) then
    -- we'll pass this func to doFn such that it can control the timing of descent
    local descend = function()
      for _, ch in ipairs(e._children) do
        self:walkEntity2(ch, matchFn, doFn)
      end
    end
    if doFn(e, descend) == false then return end
  end
end

-- Similar to walkEntities, but with the purpose of finding a particular result then exiting the search immediately.
-- If the doFn() is applied to an Entity and returns explicitly true, the traversal exits and returns true.
function Estore:seekEntity(matchFn, doFn)
  for _, e in ipairs(self._root._children) do
    if self:_seekEntity(e, matchFn, doFn) == true then
      -- doFn returning explicitly true means: seeking should end
      return true
    end
  end
end

-- (recursive step of seekEntity)
function Estore:_seekEntity(e, matchFn, doFn)
  if (not matchFn) or matchFn(e) then -- execute doFn if either a) no matcher, or b) matcher provided and returns true
    if doFn(e) == true then
      -- stop seeking
      return true
    end
  end
  for _, ch in ipairs(e._children) do
    if self:_seekEntity(ch, matchFn, doFn) == true then
      -- stop seeking
      return true
    end
  end
end

-- Bottom-up search.
-- (Eg, reverse draw order... ie, touch-hit detection that aligns with the order of drawing)
function Estore:seekEntityBottomUp(matchFn, doFn, ents)
  if ents == nil then
    ents = self._root._children
  end
  -- Iterate entities in reverse, since later-drawn entities appear on top of earlier-drawn
  for i = #ents, 1, -1 do
    local e = ents[i]
    -- Search children first. (Children would be drawn on top of parents)
    if self:seekEntityBottomUp(matchFn, doFn, e._children) == true then
      -- doFn returning explicitly true means: seeking should end
      return true
    end
    -- Check self after children:
    if (not matchFn) or matchFn(e) then -- execute doFn if either a) no matcher, or b) matcher provided and returns true
      if doFn(e) == true then
        -- stop seeking
        return true
      end
    end
  end
  return false -- keep seeking
end

function Estore:findEntity(matchFn)
  local found
  self:seekEntity(matchFn, function(e)
    found = e
    return true
  end)
  return found
end

function Estore:queryEntities(query)
  return query(self)
end

function Estore:queryFirstEntity(query)
  return query(self)[1]
end

function Estore:getEntityByName(name)
  if not name then error("Estore:getEntityByName: name is required") end
  if name == '' then error("Estore:getEntityByName: name can't be blank") end
  local ent = self:indexLookupFirst("byName", name)
  if ent then
    return ent
  end
  self:seekEntity(hasName(name), function(e)
    ent = e
    return true
  end)
  return ent
end

function Estore:getEntitiesByCompType(compType)
  return self:indexLookup("byCompType", compType)
end

-- Indexed entity lookup, eg ("byName","workbench")
-- Intended for use where the key is expected to match just one entity.
-- If there are indeed several, only the FIRST entity maching the key is returned.
function Estore:indexLookupFirst(indexName, key)
  if self.enableIndexing then
    local eids = Indexer.lookup(self.indexes, indexName, key)
    if eids and #eids > 0 then
      return self.ents[eids[1]]
    end
  end
  return nil
end

-- Indexed entity lookup, eg ("byTag","roid")
-- Returns a list of entities matching the key.
-- Returns empty list for no match
function Estore:indexLookup(indexName, key)
  if self.enableIndexing then
    local eids = Indexer.lookup(self.indexes, indexName, key)
    if eids and #eids > 0 then
      return map(eids, function(eid) return self.ents[eid] end)
    end
  end
  return {}
end

function Estore:getComponentOfNamedEntity(entName, compName)
  -- TODO: refactor in terms of getEntityByName
  local comp
  self:seekEntity(hasName(entName), function(e)
    comp = e[compName]
    if comp then return true end
  end)
  return comp
end

-- When a "parent"-type component is added to an entity, we do some fancy footwork
-- to wire up the entity to its parent and make nice-nice with the siblings
function Estore:_linkEntityToParent(e, comp)
  if e.parent then
    -- Entity already has a parent comp...?
    error(
      "UNACCEPTABLE! only one 'parent' Component per Entity please!\nExisting parent Comonent: " ..
      Comp.debugString(e.parent) .. "\nNew parent Component: " ..
      Comp.debugString(comp) .. "\nThis Entity: " ..
      entityDebugString(e) .. "\nExisting parent: " ..
      tdebug1(e._parent))
  end
  -- Lookup the actual parent entity and keep a shortcut reference in _parent
  local pid = comp.parentEid
  local parentEntity = self.ents[pid]
  if not parentEntity then
    error("Estore:addComp(): couldn't find a parent entity for eid=" ..
      pid .. ", while add comp: " .. Comp.debugString(comp))
  end
  self:_deparent(e) -- (shouldn't be needed, but doesn't hurt to be safe)
  e._parent = parentEntity

  -- Join our sibling entities in our parent entity's _children list:
  local siblings = parentEntity._children

  table.insert(siblings, e)
  local doReorder = true

  -- figure out where the new child entity should be in the ordering of children:
  if not comp.order or comp.order == '' then
    doReorder = false
    if #siblings == 1 then
      -- we're the only child; give us 1 and be done
      comp.order = 1
    else
      local highestOrder = 0
      for i = 1, #siblings - 1 do -- we were placed at the end; stop short of us
        local plink = siblings[i].parent
        if plink.order > highestOrder then
          highestOrder = plink.order
        end
      end
      comp.order = highestOrder + 1
    end
  end
  -- (maybe) rearrange the children in accordance to their stated ordering
  if doReorder and not self._reorderLockout then
    parentEntity:resortChildren()
  end
end

-- Remove the internal linkage that wires the given entity to its parent.
-- (This is invoked when a "parent"=type component gets removed)
function Estore:_deparent(e)
  if not e._parent then return end
  -- Find where this entity lives amongst its siblings:
  local myIndex = lfindindexof(e._parent._children, function(ch) return ch.eid == e.eid end)
  -- Remove this entity from the parent's child list
  if myIndex then
    table.remove(e._parent._children, myIndex)
  end
  e._parent = nil
end

function Estore:setupParent(parentEnt, childEnt)
  if childEnt.parent then self:removeComp(childEnt.parent) end
  self:newComp(childEnt, 'parent', { parentEid = parentEnt.eid })
end

function Estore:_indexComp(comp)
  if self.enableIndexing then
    Indexer.indexComp(self.indexConfigs, self.indexes, comp)
  end
end

function Estore:_deindexComp(comp, noMoreOfThisType)
  if self.enableIndexing then
    Indexer.deindexComp(self.indexConfigs, self.indexes, comp, noMoreOfThisType)
  end
end

function Estore:search(matchFn, doFn)
  self:walkEntities(matchFn, doFn)
end

function Estore:getParent(e)
  return e._parent
end

function Estore:getChildren(e)
  return e._children
end

function Estore:getCache(name)
  if not self.caches[name] then
    self.caches[name] = {}
  end
  return self.caches[name]
end

function Estore:clone(opts)
  opts = opts or {}
  local estore2 = Estore:new()
  estore2.eidCounter = self.eidCounter
  estore2.cidCounter = self.cidCounter
  estore2._reorderLockout = true

  for eid, _ent in pairs(self.ents) do estore2:_makeEnt(eid) end

  local count = 0
  for _cid, comp in pairs(self.comps) do
    -- Clone the Component
    local comp2 = Comp.getType(comp).copy(comp)
    -- Add to the proper Entity, creating new as needed, maintaining expected eid and cid
    local e = estore2.ents[comp.eid]
    if not e then e = estore2:_makeEnt(comp.eid) end
    estore2:addComp(e, comp2) -- note this will rebuild parent/child structures as needed
    count = count + 1
  end
  if opts.keepCaches then estore2.caches = self.caches end
  -- print("cloned "..count.." components")
  estore2._reorderLockout = false
  sortEntities(estore2._root._children, true)
  return estore2
end

function Estore:debugString()
  local s = ""
  s = s .. "-- Estore:\n"
  s = s .. "--- Next eid: e" .. self.eidCounter .. ", Next cid: c" ..
      self.cidCounter .. "\n"
  s = s .. "--- Entities:\n"
  for eid, e in pairs(self.ents) do s = s .. entityDebugString(e) end
  s = s .. "--- Entity Tree:\n"
  for _, ch in ipairs(self._root._children) do
    s = s .. entityTreeDebugString(ch, "  ")
  end
  return s
end

function addChildEntityTo(parEnt, chEnt)
  assert(parEnt, "ERR addChildEntityTo nil parEnt?")
  assert(parEnt._children, "ERR addChildEntityTo parent._children nil?")
  assert(chEnt, "ERR addChildEntityTo nil chEnt?")
  chEnt._parent = parEnt
  table.insert(parEnt._children, chEnt)
end

return Estore
