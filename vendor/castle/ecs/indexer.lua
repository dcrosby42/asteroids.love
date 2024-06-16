local Debug = require("mydebug").sub("Indexer", false, false)

local Indexer = {}

Indexer.DefaultConfigs = {
  { name = "byName", compType = "name", propName = "name" },
  { name = "byTag",  compType = "tag",  propName = "name" },
  __byCompType = {
    enabled = true,
    indexAllTypes = true,
    -- indexSpecificTypes={},
    -- ? is it useful/safe to narrow the comp types eligible for indexing ?
    -- excludeTypes={"name","tag","parent","state","circle","box","radius"}
  }
}

local function shouldIndexByCompType(configs, compType)
  local cfg = configs.__byCompType
  if cfg and cfg.enabled then
    if cfg.indexAllTypes then
      return true
    end
  end
  return false
end

local function _indexByCompType(byCompType, comp)
  local list = byCompType[comp.type]
  if not list then
    -- init eid list for this comp type
    list = {}
    byCompType[comp.type] = list
  end
  if not lcontains(list, comp.eid) then
    -- (only add an eid once. Entities may contain more than one of a certain comp type)
    table.insert(list, comp.eid)
    Debug.println("Add: byCompType " .. comp.type .. " -> " .. comp.eid)
  end
end

local function _deindexByCompType(byCompType, comp)
  local list = byCompType[comp.type]
  if list then
    local i = lindexof(list, comp.eid)
    if i then
      table.remove(list, i)
      Debug.println("Remove: byCompType " .. comp.type .. " -> " .. comp.eid)
    end
  end
end

-- initialize the multimaps
function Indexer.initIndexes(configs)
  local indexTables = {
    __types = {},    -- set of component types to do indexing for
    byCompType = {}, -- SPECIAL CASE: index of comp types to eids
  }
  for i = 1, #configs do
    indexTables[configs[i].name] = {}
    indexTables.__types[configs[i].compType] = true
  end
  return indexTables
end

function Indexer.indexComp(configs, indexTables, comp)
  if shouldIndexByCompType(configs, comp.type) then
    -- Index eid by comp type:
    _indexByCompType(indexTables.byCompType, comp)
  end

  -- Configured comp-specific eid indexes:
  if not indexTables.__types[comp.type] then return end
  for i = 1, #configs do
    local cfg = configs[i]
    if comp.type == cfg.compType then
      -- We're indexing entities based on this component type.
      -- Get the key based on configured property name:
      local key = comp[cfg.propName]
      -- Get the value set from the multimap
      local list = indexTables[cfg.name][key]
      if not list then
        -- multimap init-on-first-use
        list = {}
        indexTables[cfg.name][key] = list
      end
      if not lcontains(list, comp.eid) then
        -- Append the target entity eid to the multimap
        table.insert(list, comp.eid)
        Debug.println("Add: " .. cfg.name .. " " .. cfg.compType .. "." ..
          cfg.propName .. ": " .. key .. " -> " .. comp.eid)
      end
    end
  end
end

function Indexer.deindexComp(configs, indexTables, comp, lastOfItsType)
  if lastOfItsType then
    -- Special case: when a comp was removed from an ent and there are no more comps of that type in the entity,
    -- this is when we "deindex" the entity according to this type.
    _deindexByCompType(indexTables.byCompType, comp)
  end

  if not indexTables.__types[comp.type] then return end
  for i = 1, #configs do
    local cfg = configs[i]
    if comp.type == cfg.compType then
      -- We're indexing entities based on this component type.
      -- Get the key based on configured property name:
      local key = comp[cfg.propName]
      -- Get the value set from the multimap
      local list = indexTables[cfg.name][key]
      if not list then return end
      -- Find index of this comps entity id in the set
      local myIndex = lindexof(list, comp.eid)
      if myIndex then
        table.remove(list, myIndex)
        Debug.println("Remove:" .. cfg.name .. " " .. cfg.compType .. "." ..
          cfg.propName .. ": " .. key .. " -> " .. comp.eid)
      end
    end
  end
end

function Indexer.reindexAll(configs, comps)
  local maps = Indexer.initIndexes(configs)
  -- loop through all comps, indexing each
  for _, comp in pairs(comps) do
    Indexer.indexComp(configs, maps, comp)
  end
  return maps
end

function Indexer.lookup(indexTables, indexName, key)
  return indexTables[indexName][key]
end

return Indexer
