# High-level Architecture

asteroids.love is composed of three concentric layers:

```
Love2D                            (love.* callbacks)
   │
   └── castle.main                (vendor/castle/main.lua)
         │
         └── modules/root         (Switcher: asteroids | joystick_debug)
               │
               └── modules/asteroids   (ECS module, the actual game)
                     │
                     └── Estore + Systems + Resources
```

`main.lua` (project root) is three lines that hand control to castle:

```lua
local Castle = require "vendor/castle/main"
Castle.module_name = "modules/root"
Castle.onload = function() love.window.setMode(1024, 768, {resizable=true, highdpi=true}) end
```

`modules/root.lua` is a [`castle.modules.switcher`](../../vendor/castle/modules/switcher.lua) wrapping a `ModuleMap`:

```lua
local ModuleMap = {
  asteroids = GM.newFromFile("modules/asteroids/resources.lua"),
  joystick_debug = require("modules/joystick_debug"),
}
```

`modules/asteroids/` is an **ECS module** built declaratively from [`modules/asteroids/resources.lua`](../../modules/asteroids/resources.lua) via [`castle.ecs.gamemodule.newFromFile`](../../vendor/castle/ecs/gamemodule.lua). The manifest names the:

- entity bootstrap (`modules/asteroids/entities.lua` → `initialEntities(res)`)
- additional component types (`modules/asteroids/components.lua`)
- update systems list (built-in + custom)
- draw systems list (`castle.drawing.scenegraph_system2`)
- asset resources (resource_file references for ship/roid/explosion/background images, sounds, fonts)

What you get back is a Castle Module wrapped by [`castle.ecs.ecsadapter`](../../vendor/castle/ecs/ecsadapter.lua); from castle's perspective it's just another module with `newWorld/updateWorld/drawWorld`. From the project's perspective the meaningful state is the ECS `Estore` plus a per-tick `input = {dt, events}` carry.

For the in-depth treatment of each piece, jump to:

- **[design.md](design.md)** — game flow, module/ECS usage, rendering, input, entity lifecycles
- **[modules.md](modules.md)** — index of every file under `modules/asteroids/`
- **[components.md](components.md)** — component catalog
- **[systems.md](systems.md)** — every system, in tick order
- **[entities.md](entities.md)** — entity factories and their structure
- **[resources.md](resources.md)** — asset manifest and resource files

The castle layer underneath is documented separately in [docs/castle/](../castle/README.md). This project's docs assume you've at least skimmed those.
