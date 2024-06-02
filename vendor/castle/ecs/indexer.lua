local Debug = require("mydebug").sub("Indexer", false, false)

local Indexer = {}

Indexer.DefaultConfigs = {
  { name = "byName", compType = "name", propName = "name" },
  { name = "byTag",  compType = "tag",  propName = "name" },
}

-- initialize the multimaps
function Indexer.initIndexes(configs)
  local maps = {
    __types = {},
  }
  for i = 1, #configs do
    maps[configs[i].name] = {}
    maps.__types[configs[i].compType] = true
  end
  return maps
end

function Indexer.indexComp(configs, maps, comp)
  if not maps.__types[comp.type] then return end
  for i = 1, #configs do
    local cfg = configs[i]
    if comp.type == cfg.compType then
      -- We're indexing entities based on this component type.
      -- Get the key based on configured property name:
      local key = comp[cfg.propName]
      -- Get the value set from the multimap
      local list = maps[cfg.name][key]
      if not list then
        -- multimap init-on-first-use
        list = {}
        maps[cfg.name][key] = list
      end
      -- Append the target entity eid to the multimap
      table.insert(list, comp.eid)
      Debug.println("Add: " .. cfg.name .. " " .. cfg.compType .. "." ..
        cfg.propName .. ": " .. key .. " -> " .. comp.eid)
    end
  end
end

function Indexer.deindexComp(configs, maps, comp)
  if not maps.__types[comp.type] then return end
  for i = 1, #configs do
    local cfg = configs[i]
    if comp.type == cfg.compType then
      -- We're indexing entities based on this component type.
      -- Get the key based on configured property name:
      local key = comp[cfg.propName]
      -- Get the value set from the multimap
      local list = maps[cfg.name][key]
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

return Indexer
