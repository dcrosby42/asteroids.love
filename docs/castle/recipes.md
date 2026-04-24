# Castle Recipes

Working examples answering "how do I…?" — drawn from this project's actual code.

## Bootstrapping a new module

The simplest possible Castle Module — no ECS, no resources:

```lua
-- modules/hello/init.lua
local M = {}

function M.newWorld() return { msg = "hello", ticks = 0 } end

function M.updateWorld(w, action)
  if action.type == "tick" then w.ticks = w.ticks + 1 end
  return w
end

function M.drawWorld(w)
  love.graphics.print(w.msg .. " ticks=" .. w.ticks, 50, 50)
end

return M
```

To run it as the root, edit [`main.lua`](../../main.lua):

```lua
Castle.module_name = "modules/hello"
```

To run it alongside other modules, add it to the switcher in [`modules/root.lua`](../../modules/root.lua):

```lua
local ModuleMap = {
  asteroids = GM.newFromFile("modules/asteroids/resources.lua"),
  hello = require("modules/hello"),
}
```

## Bootstrapping a new ECS module

A minimum `resources.lua`:

```lua
-- modules/foo/resources.lua
return {
  { type = "ecs", name = "main",
    data = {
      entities    = { datafile = "modules/foo/entities.lua" },
      components  = { datafile = "modules/foo/components.lua" },
      systems     = { data = {
        "castle.systems.timer",
        "castle.systems.keystate",
        "modules.foo.systems.mover",
      } },
      drawSystems = { data = { "castle.drawing.scenegraph_system2" } },
    },
  },
  { type = "settings", name = "resource_loader",
    data = { realize_on_module_load = true },
  },
}
```

`entities.lua` returns a table with `initialEntities(res) -> Estore`:

```lua
-- modules/foo/entities.lua
local Estore = require "castle.ecs.estore"

local E = {}
function E.initialEntities(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })

  local estore = Estore:new()
  estore:newEntity({
    { "name", { name = "main_scene" } },  -- scenegraph_system2 looks for this
    { "tr",   {} },
    { "label",{ text = "hello world", x = 50, y = 50 } },
  })
  return estore
end
return E
```

`components.lua` returns extra component definitions (or `{}` if none):

```lua
-- modules/foo/components.lua
return {
  velocity = { 'dx', 0, 'dy', 0 },
  health   = { 'hp', 100 },
}
```

## Defining a custom component type

Two equivalent ways:

```lua
-- 1. Inline in your system file
local Comps = require "castle.components"
Comps.define("score", { 'value', 0, 'multiplier', 1 })

-- 2. Add to the components datafile referenced by resources.lua
-- modules/foo/components.lua
return {
  score = { 'value', 0, 'multiplier', 1 },
}
```

Then on any entity:

```lua
parent:newEntity({
  { "score", { value = 100 } },
})

-- Read/write
e.score.value = e.score.value + 10
```

## Writing an update system

```lua
-- modules/foo/systems/mover.lua
local Vec = require "vector-light"

return defineQuerySystem(
  { "tr", "velocity" },          -- query: any entity with both
  function(e, estore, input, res)
    e.tr.x = e.tr.x + e.velocity.dx * input.dt
    e.tr.y = e.tr.y + e.velocity.dy * input.dt
  end
)
```

Then add `"modules.foo.systems.mover"` to your `systems.data` list in `resources.lua`.

## Reacting to keyboard input

Two patterns. The component-driven way:

```lua
-- create the entity that listens
estore:newEntity({
  { "name",     { name = "input_capture" } },
  { "keystate", { handle = { "space", "escape" } } },
})

-- somewhere in a system
local e = estore:getEntityByName("input_capture")
if e.keystate.pressed.space then …
if e.keystate.held.escape  then …
```

The event-driven way:

```lua
local EventHelpers = require "castle.systems.eventhelpers"

return function(estore, input, res)
  EventHelpers.handleKeyPresses(input.events, {
    ["space"] = function(evt) fire(estore) end,
    ["r"]     = function(evt) reset(estore) end,
  })
end
```

(Note: events not in any `keystate.handle` list pass through unconsumed; events in a handled list with `consume=false` *also* pass through. So in many setups you can use both patterns simultaneously.)

## Spawning a temporary entity (fire & forget)

```lua
local Explosion = require "modules.asteroids.entities.explosion"

local function bulletHitsRoid(bullet, contact, roid)
  local expl = Explosion.explosion(roid:getParent(), {
    x = contact.x, y = contact.y, size = 0.5, animSpeed = 2,
  })
  selfDestructEnt(expl, 1.0)   -- vanishes after 1s

  bullet:destroy()
end
```

Or for a sound that auto-cleans up after its duration:

```lua
expl:newComp("sound", { sound = "medium_explosion_1" })
```

The sound system removes the comp once `playtime > duration`.

## Tweening properties

```lua
local TweenHelpers = require "castle.tween.tween_helpers"

TweenHelpers.tweenit(camera, "zoom",
  { tr = { sx = 2.0, sy = 2.0 } },
  { duration = 0.5, easing = "outQuint" }
)
```

The first `compProps` arg is `{ compType = { propName = targetValue, … } }`. You can tween multiple comps in one call:

```lua
TweenHelpers.tweenit(menu_cursor, "move",
  { tr = { x = 200 }, pic = { color = {1, 0, 0, 1} } },
  { duration = 0.3 }
)
```

Available easings come from [`vendor/castle/tween/easing.lua`](../../vendor/castle/tween/easing.lua) (linear, outQuint, inQuad, etc.).

## Building a viewport with a camera

```lua
-- main_scene
--   viewport (with reference to scene1 and camera1)
-- scene1
--   world1
--     camera1 (named tr inside scene1)
--     other stuff…

local main_scene = estore:newEntity({ { "name", { name = "main_scene" } } })

local viewport = main_scene:newEntity({
  { "name",     { name = "viewport" } },
  { "viewport", { scene = "scene1", camera = "camera1", blockout = true } },
  { "tr",       { x = 0, y = 0 } },
  { "box",      { w = 1024, h = 768, cx = 0, cy = 0 } },
})

local scene1 = estore:newEntity({ { "name", { name = "scene1" } } })
local world1 = scene1:newEntity({ { "name", { name = "world1" } } })

local camera1 = world1:newEntity({
  { "name", { name = "camera1" } },
  { "tag",  { name = "camera" } },
  { "tr",   { x = 0, y = 0, sx = 1, sy = 1 } },
})
```

The `scenegraph_system2` will:

1. Walk to `main_scene`, recurse into `viewport`.
2. Recognize `viewport`, look up `scene1` and `camera1` by name.
3. Apply `camera1`'s **inverse** transform to project world → screen.
4. Stencil-clip to the viewport's box.
5. Draw `scene1` and everything below it.

Move/zoom the camera by writing to `camera1.tr.x/y/sx/sy`. The asteroids project tweens it via [`camera_dev_system`](../../modules/asteroids/systems/camera_dev_system.lua).

## Camera follow

```lua
-- target entity
ship:newEntity({ "followable", { targetname = "playership" } })

-- follower entity
camera:newComp("follower", { targetname = "playership" })
```

The built-in [`follower`](../../vendor/castle/systems/follower.lua) system copies `tr.x/y` from the matching `followable` entity. (Note the system is currently flagged TODO — works but uses `tr` directly without smoothing.)

## Adding a tiling, parallax-scrolling background

```lua
local space_bg = scene1:newEntity({ { "name", { name = "space_bg" } } })

space_bg:newEntity({
  { "tilingBackground", {} },
  { "pic",              { id = "nebula_blue" } },
  { "paralax",          { px = 0.25, py = 0.25 } },  -- slow background
})

space_bg:newEntity({
  { "tilingBackground", {} },
  { "pic",              { id = "starfield_1" } },
  { "paralax",          { px = 0.75, py = 0.75 } },  -- faster foreground stars
})
```

Lower parallax = farther/slower. The image is tiled exactly enough to cover the visible viewport area, no more.

## Self-pacing animations

```lua
ship:newEntity({
  { "tag",   { name = "ship_flame" } },
  { "tr",    { y = 30 } },
  { "pic",   { id = "ship_flame_06", color = {1,1,1,0} } },
  { "timer", { name = "flame", reset = 1, countDown = false, loop = true } },
})

-- in a system, modulate based on the timer:
local flame = estore:queryFirstEntity(Query.create({ tag = "ship_flame" }))
flame.pic.sy = 0.75 + math.sin(flame.timer.t * 4 * math.pi * 2) * 0.1
```

For frame-by-frame anims, use the `anim` component:

```lua
parent:newEntity({
  { "tr",    { x = x, y = y } },
  { "anim",  { name = "splode", id = "debris_explosion_1",
               sx = 2, sy = 2, cx = 0.5, cy = 0.5,
               onComplete = "selfDestruct" } },
  { "timer", { name = "splode", countDown = false, factor = 0.8 } },
})
```

`onComplete` choices:
- `"repeat"` (default): timer loops, animation continues forever.
- `"expire"`: removes anim and timer, leaves the entity.
- `"selfDestruct"`: destroys the entity once duration elapsed.

## Adding a physics body

```lua
local roid = parent:newEntity({
  { "tr",          { x = 100, y = 100 } },
  { "vel",         { dx = 50, angularvelocity = 1 } },
  { "body", {
      mass = 100, friction = 0.8, restitution = 0.9,
      categories = Coll.Roids,
      mask = bit.bor(Coll.Roids, Coll.Lasers, Coll.Ships),
  } },
  { "force",       {} },             -- channel for impulses
  { "circleShape", { radius = 65 } },
})
```

There must be a `physicsWorld`-bearing entity somewhere in the estore for any of this to take effect:

```lua
world1:newEntity({
  { "physicsWorld", { allowSleep = false } },
})
```

Reading collisions:

```lua
for _, contact in pairs(ship.contacts or {}) do
  local hitE = estore:getEntity(contact.otherEid)
  -- contact.x, contact.y, contact.nx, contact.ny available
end
```

`contact` components are added each tick by the physics system; look them up via `e.contacts`.

## Pattern: cooldowns

The cooldown component bundles a state machine + timer:

```lua
{ "cooldown", { name = "lasers", t = 0.1, state = "ready" } }

-- to fire:
if Cooldown.isReady(ship, "lasers") then
  -- spawn bullet…
  Cooldown.trigger(ship, "lasers")  -- adds a 0.1s timer named "lasers"
end
-- the cooldown system flips state back to "ready" when the timer alarms
```

See [`modules/asteroids/systems/cooldown.lua`](../../modules/asteroids/systems/cooldown.lua) and its use in [`ship_controller.lua:75`](../../modules/asteroids/systems/ship_controller.lua#L75).

## Pattern: state machines via the `state` comp

```lua
-- declare with default value
{ "state", { name = "control_mode", value = "keyboard" } }

-- read/write via helpers
local State = require "castle.state"
local mode = State.get(jig, "control_mode")
State.set(jig, "control_mode", "joystick")
State.toggle(jig, "debug_draw")  -- bool
```

Several `state` comps can live on one entity, keyed by name (e.g. `e.states.control_mode`).

## Pattern: switching gameplay modes via "jigs"

The asteroids module's optional `ship_workbench_system` ([`modules/asteroids/systems/ship_workbench_system.lua`](../../modules/asteroids/systems/ship_workbench_system.lua)) implements a "jig" pattern:

- A "workbench" entity carries `{state name="jig" value=…, keystate handle={"1","2","3","4","5"}}`.
- Each numbered key transitions to a different "jig" — a self-contained dev playground.
- Each jig is `{init(parent, estore, res), update(estore, input, res), finalize(jigE, estore)}`.

This is a useful pattern for in-game level/mode switching, not just dev tools.

## Pattern: sound effects on an entity

```lua
expl:newComp("sound", { sound = "medium_explosion_1" })
```

The sound plays once and the comp is auto-removed when its duration is exhausted. For looping music: `{ sound = "name", music = true, loop = true }`.

## Hot-reloading mid-game

Hard-coded triggers:

| Key | What it does |
|-----|------------|
| <kbd>cmd</kbd>+<kbd>r</kbd> | Reload the root module (uncaches all deps, re-`require`s root, rebuilds world) |
| <kbd>esc</kbd> | Toggle SUIT debug editor (paused) |
| <kbd>shift</kbd>+<kbd>esc</kbd> | Close editor, **stay paused** |
| <kbd>F1</kbd>/<kbd>F2</kbd> | Switch between asteroids and joystick_debug (project-specific, defined in [`modules/root.lua`](../../modules/root.lua)) |

You can emit your own reload from a module:

```lua
return w, { { type = "castle.reloadRootModule" } }
```

## Inspecting and debugging

```lua
local inspect = require "inspect"
print(inspect(estore:debugString()))       -- estore-wide dump
print(entityDebugString(e))                 -- single-entity dump (global from ecs.debughelpers)
print(Comp.debugString(comp))               -- single-comp dump

-- enable per-module debug logs
local Debug = require("mydebug").sub("MyModule", true, true)
Debug.println("hi from MyModule")
```

Or wire `mydebug` settings via a manifest entry:

```lua
{ type = "settings", name = "mydebug",
  data = {
    Asteroids = { onConsole = true, onScreen = false },
    Physics   = { onConsole = false },
  },
},
```

The settings loader applies these to `MyDebug` automatically ([resourceloader.lua:679](../../vendor/castle/resourceloader.lua#L679)).
