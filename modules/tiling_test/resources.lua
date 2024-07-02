return {
  {
    type = "ecs",
    name = "main",
    data = {
      entities = { datafile = "modules/tiling_test/entities.lua" },
      components = {
        data = {
          bgtiler = {
            "picId", "",
            "tilew", 100,
            "tileh", 100,
            "debug", false,
          },
          tile = {
            "tilespace", "",
            "row", 0,
            "col", 0,
          },
        }
        -- datafile = "modules/asteroids/components.lua",
      },
      systems = {
        data = {
          "castle.systems.timer",
          "castle.systems.selfdestruct",
          "castle.systems.anim",
          "castle.systems.physics",
          "castle.systems.sound",
          "castle.systems.touch",
          "castle.systems.touchbutton",
          "castle.systems.tween",
          "castle.systems.keystate",
          "castle.systems.controller_state",
          -- "modules.asteroids.systems.cooldown",
          -- "modules.asteroids.systems.devsystem",
          -- "modules.asteroids.systems.ship_workbench_system",
          "modules.asteroids.systems.camera_dev_system",
          "modules.tiling_test.bg_tester",
          "modules.tiling_test.bg_tiler_system",
        }
      },
      drawSystems = {
        data = {
          "castle.drawing.scenegraph_system",
        }
      },
    },
  },
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
    file = "modules/asteroids/images/bg/backgrounds.res.lua",
  },
  {
    type = "font",
    name = "narpassword",
    data = {
      file = "modules/common/fonts/narpassword.ttf",
      -- choices = { 24, 48, 64 },
      choices = { 64 },
    },
  },
}
