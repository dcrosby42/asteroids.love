--
-- castle.ecs.loaders
--
-- Extends Castle's base ResourceLoader by adding an "ecs" loader that
-- pulls in entities, componens and systems etc. used for construcing an EcsAdapter module.
--
local R = require "castle.resourceloader"
local inspect = require "inspect"
local Comp = require "castle.components"

local Loaders = R.Loaders.copy()

local function loadSystems(sysConfig)
  local systems = Loaders.getData(sysConfig)
  return composeSystems(systems) -- composeSystems() from ecs.ecshelpers
end

local function mkDrawSystemChain(systems)
  for i, sys in ipairs(systems) do
    if type(sys) == 'table' and #sys > 0 then
      sys = mkDrawSystemChain(sys)
    elseif type(sys) == 'string' then
      sys = resolveSystem(sys, { systemKeys = { "drawSystem" } }) -- resolveSystem from ecs.ecshelpers
    end
    systems[i] = sys
  end
  return makeFuncChain2(systems) -- mkFuncChain2 from castle.helpers
end

local function loadDrawSystems(drawSysConfig)
  local drawSystems = Loaders.getData(drawSysConfig)
  return mkDrawSystemChain(drawSystems)
end

local function loadEntities(eConfig)
  local entities = Loaders.getData(eConfig)
  assert(entities, "loadEntities: failed to load Entities stuff from eConfig: " .. inspect(eConfig))
  assert(entities.initialEntities,
    "loadEntities: expected entities object to contain a function 'initialEntities()'")
  return entities
end

-- Component config block contains either a 'data' key or 'datafile'
-- Data consists of a map of component definitions,
-- where the key is the component type name, and the value is a pair-list of field defs.
-- Eg {data={ pos = {'x',0,'y',0,'real',false}, state = {'value','NIL'}}}
-- "CHEAT" this method doesn't put the definitions in a clever place, it just modifies
-- the global Comp definitions.
local function loadComponents(componentsCfg)
  assert(componentsCfg.data or componentsCfg.datafile,
    "loadEntities: expected 'data' or 'datafile' in config " ..
    inspect(componentsCfg))
  local defs = Loaders.getData(componentsCfg)
  if defs then
    for compType, compDef in pairs(defs) do Comp.define(compType, compDef) end
  end
  return Comp
end

function Loaders.ecs(res, ecsConfig)
  local data = Loaders.getData(ecsConfig)

  local ecs = {
    name = data.name,
    entities = loadEntities(data.entities),
    components = loadComponents(data.components),
    update = loadSystems(data.systems),
    draw = loadDrawSystems(data.drawSystems),
  }

  res:get('ecs'):put(ecsConfig.name, ecs)
end

return Loaders
