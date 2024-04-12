local ResourceLoader = require "castle.resourceloader"
local EcsAdapter = require "castle.ecs.ecsadapter"

-- GameModule: constructor(s) for EcsAdapter based on resource configs
local GameModule = {}

-- Create a new EcsAdapter-type GameModule from a list of typed resource config objects.
-- `loaders` is optional, defaults to castle.ecs.Loaders.
-- And "ecs"-type resource named "main" is expected to be defined in the resource configs.
-- The EcsAdapter is built from a combination of the ecs resource, as
-- well as being given a reference to the over all resources bundle `res`.
function GameModule.newFromConfigs(configs, loaders)
  loaders = loaders or require('castle/ecs/loaders')
  local res = ResourceLoader.buildResourceRoot(configs, loaders)
  local ecs_config = res.ecs.main
  return EcsAdapter({
    name = ecs_config.name,
    create = ecs_config.entities.initialEntities,
    update = ecs_config.update,
    draw = ecs_config.draw,
    loadResources = function()
      return res
    end,
  })
end

-- Create a new EcsAdapter-type GameModule by loading a list of typed resource config objects
-- from the file indicated by `path`.
-- (Convenience wrapper around `newFromConfigs`.)
-- `loaders` is optional, defaults to castle.ecs.Loaders.
function GameModule.newFromFile(path, loaders)
  local configs = ResourceLoader.loadfile(path)()
  return GameModule.newFromConfigs(configs, loaders)
end

return GameModule
