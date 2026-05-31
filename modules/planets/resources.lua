return {
  {
    type = "ecs",
    name = "main",
    data = {
      entities = { datafile = "modules/planets/entities/planets_main.lua" },
      -- components = {
      --   datafile = "modules/asteroids/components.lua",
      -- },
      systems = {
        data = {
          "castle.systems.timer",
          "castle.systems.selfdestruct",
          "castle.systems.anim",
          -- "castle.systems.physics",
          "castle.systems.follower",
          "castle.systems.sound",
          -- "castle.systems.touch",
          -- "castle.systems.touchbutton",
          "castle.systems.tween",
          "castle.systems.keystate",
          -- "castle.systems.controller_state",
          "modules.planets.systems.camera_dev_system",
        }
      },
      drawSystems = {
        data = {
          "castle.drawing.scenegraph_system2",
        }
      },
    },
  },
  -- {
  --   type = "settings",
  --   name = "dev",
  --   data = { bgmusic = false },
  -- },
  {
    type = "settings",
    name = "resource_loader",
    data = {
      -- lazy_load means: DO NOT immediately load actual asset data
      lazy_load = {
        pics = true,
        picStrips = true,
        anims = true,
        sounds = true,
      },
      -- Any lazy_load resources are eager-loaded when their game module is loaded.
      -- (as distinct from app startup time)
      realize_on_module_load = true,
    },
  },
  {
    type = "resource_file",
    file = "modules/planets/images/planets.res.lua",
  },
  {
    type = "resource_file",
    file = "modules/asteroids/images/bg/backgrounds.res.lua",
  },
  -- {
  --   type = "font",
  --   name = "narpassword",
  --   data = {
  --     file = "modules/common/fonts/narpassword.ttf",
  --     -- choices = { 24, 48, 64 },
  --     choices = { 64 },
  --   },
  -- },
}
