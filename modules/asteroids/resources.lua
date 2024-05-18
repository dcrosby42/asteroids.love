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
          -- "modules.asteroids.systems.devsystem",
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
    file = "modules/asteroids/images/ships/ship_pics.res.lua",
  },
  {
    type = "pic",
    name = "example_background",
    data = { path = "modules/asteroids/images/example_background.png" },
  },
  -- {
  --   type = "sound",
  --   name = "drop_puck1",
  --   data = { file = "modules/airhockey/sounds/drop_puck1.wav", },
  -- },
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
