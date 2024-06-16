return {
  {
    type = "ecs",
    name = "main",
    data = {
      entities = { datafile = "modules/asteroids/entities.lua" },
      components = {
        datafile = "modules/asteroids/components.lua",
      },
      systems = {
        data = {
          "castle.systems.timer",
          "castle.systems.selfdestruct",
          "castle.systems.physics",
          "castle.systems.sound",
          "castle.systems.touch",
          "castle.systems.touchbutton",
          "castle.systems.tween",
          "castle.systems.keystate",
          "castle.systems.controller_state",
          "modules.asteroids.systems.cooldown",
          "modules.asteroids.systems.devsystem",
          "modules.asteroids.systems.ship_workbench_system",
          "modules.asteroids.systems.camera_dev_system",
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
    name = "dev",
    data = { bgmusic = false },
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
  -- {
  --   type = "resource_file",
  --   file = "modules/asteroids/images/asteranims.res.lua",
  -- },
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
    type = "resource_file",
    file = "modules/asteroids/images/bg/backgrounds.res.lua",
  },
  {
    type = "resource_file",
    file = "modules/asteroids/images/explosions/sheets_halved/explosions.res.lua",
    -- file = "modules/asteroids/images/explosions/explosions.res.lua",
  },

  {
    type = "sound",
    name = "medium_explosion_1",
    data = {
      file = "modules/asteroids/sounds/medium-explosion-40472.mp3",
      volume = 0.4,
    },
  },
  {
    type = "sound",
    name = "laser_small",
    data = {
      file = "modules/asteroids/sounds/laser_small.wav",
      volume = 0.5,
    },
  },

  -- {
  --   type = "music",
  --   name = "city",
  --   data = { file = "modules/airhockey/sounds/welcome-to-city.mp3", },
  -- },
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
