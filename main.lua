local Castle = require "vendor/castle/main"

Castle.module_name = "modules/root"
Castle.onload = function()
  love.window.setMode(600, 800, {
    fullscreen = false,
    resizable = true,
    highdpi = true,
  })
end

-- Notes on window sizes:
-- ipad pro dimensions: 1024 x 1366 | ratio: x=1 y=1.333
-- air maximized: [castle.main] love.resize(1710,1040) | 1.644
-- air greenbutton fs: [castle.main] love.resize(1710,1069)
-- air fullscreen: 1710 x 1069 | 1.5999
