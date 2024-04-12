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
          "modules.asteroids.systems.devsystem",
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
  --   type = "pic",
  --   name = "puck_blue",
  --   data = { path = "modules/airhockey/images/airhockey_puck_blue.png" },
  -- },
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
