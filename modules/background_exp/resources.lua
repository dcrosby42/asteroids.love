return {
  {
    type = "ecs",
    name = "main",
    data = {
      entities = { datafile = "modules/background_exp/entities.lua" },
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
      -- (The point of using lazy_load and realize_... below: During dev when there might exist
      -- numerous debug/dev/browse modules waiting for occasional use, we defer the resource loading hit
      -- until we actually engage the module.  Eg, a background browser/debugger loads a lot of heavy resources that
      -- you normally don't need.
      -- In prod/release, this could be useful for confining resource loading  to level-load-time, or to enforce
      -- all-up-front loading at app startup.)
      -- lazy_load means: DO NOT immediately load actual asset data
      lazy_load = {
        pics = true,
        picStrips = true,
        anims = true,
        sounds = true,
      },
      -- Any lazy_load resources are eager-loaded when their game module is loaded.
      -- (as distinct from app startup time or load-on-first-use)
      realize_on_module_load = true,
    },
  },
  {
    type = "resource_file",
    file = "modules/asteroids/images/bg/backgrounds.res.lua",
  },
  {
    type = "resource_file",
    file = "modules/asteroids/images/roidpics.res.lua",
  },
  {
    type = "resource_file",
    file = "modules/asteroids/images/roidaliases.res.lua",
  },
  {
    type = "resource_file",
    file = "modules/asteroids/images/ships/ship_pics.res.lua",
  },
  {
    type = "pic",
    name = "testpic2",
    data = {
      path = "modules/background_exp/testpic2.png",
    },
  },
  {
    type = "pic",
    name = "testpic",
    data = {
      path = "modules/background_exp/testpic.png",
    },
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
