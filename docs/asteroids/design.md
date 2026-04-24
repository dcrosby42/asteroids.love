# Detailed Design Guide

This walks through how asteroids.love actually runs: per-tick game flow, how it leverages castle's module/ECS/resource systems, how things get drawn, how input flows in, and the lifecycles of the major user-facing entities.

## 1. Main game flow per tick

Each `love.update(dt)` becomes a `{type="tick", dt}` action that walks down the module stack:

1. [`vendor/castle/main.lua:138`](../../vendor/castle/main.lua#L138) wraps the dt as a tick action and calls `RootModule.updateWorld(world, action)`.
2. [`modules/root.lua`](../../modules/root.lua) inspects f1/f2 keypresses; otherwise forwards the action to the active switcher child.
3. [`castle.modules.switcher`](../../vendor/castle/modules/switcher.lua) dispatches to `asteroids` (default).
4. [`castle.ecs.ecsadapter`](../../vendor/castle/ecs/ecsadapter.lua) routes the tick action to `doTick`:
   - Sets `world.input.dt = dt`.
   - Runs the composed update systems (in order from `resources.lua`).
   - Returns `world.input.events` as `sidefx` (so any events not consumed by systems propagate up).
   - Resets `world.input = {dt=0, events={}}`.
5. Subsequent (non-tick) actions in the same frame land directly on `world.input.events` to be consumed by the next tick.

Each `love.draw` triggers `RootModule.drawWorld(world)` → switcher → ecsadapter → the composed draw systems. There's currently exactly one: [`castle.drawing.scenegraph_system2`](../../vendor/castle/drawing/scenegraph_system2.lua).

The configured update system order (from [`modules/asteroids/resources.lua`](../../modules/asteroids/resources.lua)):

```
castle.systems.timer
castle.systems.selfdestruct
castle.systems.anim
castle.systems.physics
castle.systems.follower
castle.systems.sound
castle.systems.touch
castle.systems.touchbutton
castle.systems.tween
castle.systems.keystate
castle.systems.controller_state
modules.asteroids.systems.cooldown
modules.asteroids.systems.camera_dev_system
modules.asteroids.systems.ship_controller
modules.asteroids.systems.boxthinger
```

(`devsystem` and `ship_workbench_system` are commented out, awaiting jig-mode re-enablement.)

Notable: `keystate` and `controller_state` come **after** gameplay systems. This is by design — the gameplay systems read the *previous* tick's `pressed/held/released`, then the input systems refresh state from accumulated `input.events`. (`pressed` and `released` are reset at the *start* of each `keystate` tick — see [`vendor/castle/systems/keystate.lua:13`](../../vendor/castle/systems/keystate.lua#L13).)

## 2. How this game uses castle's module system

Two of castle's module-layer features are explicitly used here:

- **The Switcher** in `modules/root.lua` lets you flip between the game proper and a joystick diagnostic. F1/F2 keypresses are intercepted at the root level and synthesized into `{type="castle.switcher", index="..."}` actions so the switcher pivots without leaking knowledge into the asteroids module.
- **GameModule.newFromFile** in `modules/root.lua:5` is the supported entry into ECS-module land. It reads `modules/asteroids/resources.lua`, parses configs through the loader pipeline, registers component types, composes systems, and finally hands an `EcsAdapter`-shaped Castle Module back to the switcher.

Hot reload (Cmd+R) and the editor toggle (Esc) come from castle for free; nothing in `modules/asteroids/` re-implements them.

The asteroids module itself does **not** maintain Lua-level globals or static state. All state lives in:

- the ECS `Estore` (entities and components, including parent/child tree)
- the `input` table (dt + per-tick events)
- the `res` resource root (mostly read-only after load)

Anything that *looks* like cross-tick state (current jig name, control mode, selected menu index, cooldown status, etc.) is stored as a `state` component on a named entity, or otherwise as a regular component.

## 3. How this game uses castle's ECS layer

### Entity bootstrap

[`modules/asteroids/entities.lua`](../../modules/asteroids/entities.lua) exports `initialEntities(res)` (this is the function the `ecs` resource loader gave away in `data.entities.initialEntities`). It:

```lua
function E.initialEntities(res)
  local w, h = love.graphics.getDimensions()
  res:get("data"):put("screen_size", { width = w, height = h })

  local estore = Estore:new()
  SceneBased.populate(estore, res)
  return estore
end
```

[`scene_based.populate`](../../modules/asteroids/entities/scene_based.lua#L7) creates the active scene tree (see "scene tree" section below). `E.asteroidsGame` and `Workbench.workbench` are commented-out alternates.

### Components

Built-in component types ship with [`vendor/castle/components.lua`](../../vendor/castle/components.lua). The asteroids module adds three more in [`modules/asteroids/components.lua`](../../modules/asteroids/components.lua) (loaded via the `components` block of `resources.lua`):

- `health { hp = 10 }` — used by asteroids and (in disabled jigs) by ships.
- `cooldown { t = 1, state = "ready" }` — used by ship lasers.
- `ship_controller { dx, dy, turn, accel, fire_gun }` — input-to-ship intent.

Three more are defined inline in [`scenegraph_system2.lua`](../../vendor/castle/drawing/scenegraph_system2.lua):

- `devgrid` — debug coordinate grid.
- `devbg` — debug viewport-tile fill.
- `tilingBackground` — used by space_bg's nebula and starfield entities.

`controller_state` is also a component (defined in [`vendor/castle/systems/controller_state.lua:5`](../../vendor/castle/systems/controller_state.lua#L5)) — defined where it's used since the system owns it.

### Systems

Most gameplay logic is in just two project-defined systems:

- [`ship_controller`](../../modules/asteroids/systems/ship_controller.lua) — reads `keystate` (and indirectly `controller_state` via `update_ship_controller.lua`), maps to the `ship_controller` component, applies turn/thrust/auto-brake, fires bullets through cooldown, animates flame alpha.
- [`cooldown`](../../modules/asteroids/systems/cooldown.lua) — generic cooldown state machine paired with timers.

Plus a couple of dev tools that the live config has disabled or repurposed:

- [`camera_dev_system`](../../modules/asteroids/systems/camera_dev_system.lua) — camera_dev_controller-tagged entities; tweens camera zoom/rotate/pan via TweenHelpers.
- [`boxthinger`](../../modules/asteroids/systems/boxthinger.lua) — debug entity-mover keyed on `boxthing` tag.
- [`devsystem`](../../modules/asteroids/systems/devsystem.lua) — empty stub.
- [`ship_workbench_system`](../../modules/asteroids/systems/ship_workbench_system.lua) — jig dispatcher.

Entity factories live under [`modules/asteroids/entities/`](../../modules/asteroids/entities) and are plain Lua module tables exposing constructor functions. They don't register systems; they're called from `initialEntities`, jigs, or other entity factories.

## 4. How rendering works

A single draw system runs each frame:

```
castle.drawing.scenegraph_system2(estore, res)
```

It expects a top-level entity literally named `"main_scene"`. It:

1. Calls `BGColorSystem` (sets `love.graphics.setBackgroundColor` from a `bgcolor`-bearing entity, if any).
2. Looks up `main_scene` and recursively walks via `drawEntity`.

For each entity, [`drawEntity` (scenegraph_system2.lua:262)](../../vendor/castle/drawing/scenegraph_system2.lua#L262):

1. Computes the entity's full transform via `computeEntityTransform2`, accumulating `tr` from root downward; if the entity has `paralax` and a `viewportEnt` is in scope, modifies the transform.
2. `love.graphics.push()`, `applyTransform`.
3. If the entity has a `viewport` comp, calls `drawViewport2`: looks up `viewport.scene` and `viewport.camera` by name, optionally fills bgcolor, optionally stencils to `box`, applies the camera's INVERSE transform, recursively draws the scene with itself in scope as `viewportEnt`.
4. Runs every registered DrawFunc against the entity.
5. Recurses into children.
6. `love.graphics.pop()`.

DrawFuncs (in scenegraph_system2.lua's order):
`screengrid → pic → anim → geom (box/rect/circle/radius) → button → physics → label → sound (pings soundmanager) → touch_debugs → devGrid → devBg → tilingBackground`.

### The active scene tree

Constructed in [`modules/asteroids/entities/scene_based.lua`](../../modules/asteroids/entities/scene_based.lua):

```
main_scene
├── viewport [name="viewport", viewport{scene="scene1",camera="camera1",blockout=true,
│              bgcolor={0,0.4,0},use_bgcolor=false}, tr (centered), box (screen-sized)]
└── (siblings via the Estore root: scene1 is created at top level too)

scene1                                  <-- viewport.scene = "scene1"
├── space_bg
│   ├── nebula entity   [tilingBackground, pic{nebula_blue}, paralax{0.25, 0.25}]
│   └── stars entity    [tilingBackground, pic{starfield_1}, paralax{0.75, 0.75}]
└── world1
    ├── camera1 (camera_dev_controller created on the parent entity)
    │   [tr{0,0}, follower{targetname="playership"}, name="camera1"]
    ├── physics_world entity [physicsWorld{allowSleep=false}]
    └── ship (built by Ship.ship; see entities.md)
```

The viewport's `box` is screen-sized; with `blockout=true` everything inside is stencil-clipped to that rect. Camera transform is applied as inverse so world-space coords project to screen.

`space_bg` entities use `tilingBackground` so their pics tile to fill the viewport's visible AABB. Their `paralax` factors (0.25 nebula, 0.75 stars) make the stars feel closer than the nebula. (See the parallax caveat in [docs/castle/systems.md](../castle/systems.md).)

### Per-tick draw cost

The DrawFunc chain runs against every entity, but most are no-ops if the relevant component isn't present (`if not ent.devgrid then return end`-style guards). Pic and anim DrawFuncs iterate `e.pics` / `e.anims` so multi-pic entities get all their pics drawn.

There is no manual culling of off-screen entities (yet). Tiling backgrounds bound their work to the viewport AABB, but ordinary `pic`-bearing entities are drawn unconditionally — fine for the small entity counts in play. If counts ever scale up, that's the place to add culling.

## 5. How input works

Three input pathways feed the game.

### Keyboard

[`castle.main` keypressed/keyreleased](../../vendor/castle/main.lua#L207) builds keyboard actions and dispatches them. They flow through `root` → switcher → ecsadapter, where ecsadapter checks for `cmd+r` (reload) and `escape` (editor) and otherwise appends them to `world.input.events`.

The [`keystate`](../../vendor/castle/systems/keystate.lua) system later consumes them per-entity. Each entity that listens declares a `keystate` component with `handle` listing the keys to track:

```lua
{ "keystate", { handle = { "left", "right", "up", "down", "space" } } }
```

After that system runs, the entity sees:

- `e.keystate.pressed.up` — true for one tick after the press.
- `e.keystate.held.up` — true while held.
- `e.keystate.released.up` — true for one tick after release.

The asteroids ship and the camera_dev_controller both use this. `keystate.consume = false` (default), so the same key event reaches every listening entity.

### Joystick

[`castle.main` joystickaxis/pressed/released](../../vendor/castle/main.lua#L320) builds joystick actions, looks up a control map (`PS4 Controller`, `GamePadPro`, `Dualshock`, generic) from [`vendor/castle/joystick.lua`](../../vendor/castle/joystick.lua), and dispatches. ecsadapter routes joystick events through [`castle.ecs.joystickadapter`](../../vendor/castle/ecs/joystickadapter.lua) which converts them to `controller`-type events bound to controller id `"joystick1"`.

The [`controller_state`](../../vendor/castle/systems/controller_state.lua) system reads those events and updates per-entity `controller_state` components whose `match_id == "joystick1"`. The ship has one:

```lua
{ "controller_state", { match_id = "joystick1" } }
```

In test_flight.jig, returning toggles `state.control_mode` between `"keyboard"` and `"joystick"` — only one is sampled per tick (see [`update_ship_controller.lua`](../../modules/asteroids/jigs/update_ship_controller.lua)).

### Touch / mouse

[`castle.main`](../../vendor/castle/main.lua#L247) dispatches touchpressed/moved/released directly. Mouse events are dispatched as `mouse` actions; ecsadapter then wraps non-`isTouch` mouse events into synthetic touch events (id `"mousetouch1"`) so desktop and mobile share one [`touch`](../../vendor/castle/systems/touch.lua) system.

The asteroids module doesn't currently use touch input directly (the disabled jig modes use it via menus). All current gameplay is keyboard or joystick.

## 6. Lifecycle of major entities

### The ship

Constructor: [`Ship.ship(parent, res)`](../../modules/asteroids/entities/ship.lua#L9).

Created once during `scene_based.populate`. Components include (in order): `name="ship"`, `tr`, `vel`, `controller_state`, `keystate`, `ship_controller`, `body` + `force` + `circleShape` (physics), `cooldown` named "lasers", `box` (debug), `pic` (`ship_example_05`).

Three child entities:

- A second `box` child (200×200, debug visualization).
- `gun_muzzle_left` — tagged twice (`gun_muzzle` + `gun_muzzle_left`), `tr {x=-22, y=-9}`. A pure transform sentinel with no visual.
- `gun_muzzle_right` — same, `x=22`.
- `ship_flame` — tagged, has a `pic` (`ship_flame_06`, alpha=0) and a looping `timer` for animating `pic.sy`.

Per-tick lifecycle:

1. `keystate` and `controller_state` capture input.
2. `ship_controller` reads them via [`applyKeystateToShipController`](../../modules/asteroids/systems/ship_controller.lua#L9), packs into `ship_controller` comp.
3. `ship_controller` then [`applyShipController`](../../modules/asteroids/systems/ship_controller.lua#L36):
   - Turns: `tr.r += turn * spinSpeed * dt` (direct, not torque-based).
   - Accel: applies `force.impx/y` along the ship's facing direction.
   - Auto-brake: when no thrust, decelerates via velocity.
   - Fires: if `cooldown.lasers.state == "ready"`, calls `Ship.fireBullet` for left and right muzzles, attaches `body+force+circleShape` to each, and triggers the cooldown.
   - Toggles flame visibility (`shipFlame.pic.color[4] = thrustOn ? 1 : 0`).
4. `physics` syncs `force` impulses into the body, steps the world, syncs `tr/vel` back.

The ship is permanent for the duration of the active scene. Collisions with asteroids generate strike explosions through `Battle.shipHitsRoid` (in `test_flight.lua` jig only — the active scene_based path doesn't yet hook collisions into a battle pipeline, that's TODO).

### Asteroids ("roids")

Constructor: [`Roids.roid(parent, opts)`](../../modules/asteroids/entities/roids.lua#L105) and [`Roids.random(parent, opts)`](../../modules/asteroids/entities/roids.lua#L156).

Components: `tag="roid"`, `tr`, `vel`, `pic` (random sprite from a size category), `radius` (hit circle), `health`, `body+force+circleShape` (physics, with `mass = π·r²`).

In the **active** scene_based path, no roids are spawned by default. Roid spawning happens in the `test_flight` jig:

```lua
generateRoidField(jig, 100, -4000, 4000)
```

Each gets `vel.angularvelocity = randomFloat(-π/2, π/2)`, `vel.dx/dy = randomFloat(-30, 30)`.

Per-tick lifecycle (in jig mode):

1. Physics steps; collisions produce `contact` components on the roid.
2. The jig's `collideBulletsAndRoids` walks all bullet-tagged entities, checks for contacts with roids, and calls [`Battle.bulletHitsRoid`](../../modules/asteroids/battle_helpers.lua#L28).
3. `Battle.bulletHitsRoid` spawns a small strike-explosion at the contact point and applies `damageEntity(roid, 1)`. If hp ≤ 0, calls `Battle.destroyRoid`.
4. `Battle.destroyRoid` removes the `health` comp (so a second collision in the same frame can't double-destroy), schedules `selfDestructEnt(roid, 0.2)`, spawns a sized "splode" explosion entity at the roid's `tr`, attaches a `medium_explosion_1` sound, and times the explosion out at 3.0s.
5. The `selfdestruct` system tears down both the roid and the explosion when their respective timers alarm.

### Bullets

Constructor: [`Ship.fireBullet(ship, side, picId, speed)`](../../modules/asteroids/entities/ship.lua#L115).

Each bullet: `name="ship_bullet_<side>"`, `tag="ship_bullet"`, `tr` placed at the muzzle's transformed point (transformed via `computeEntityTransform`, then rotated by the muzzle's direction), `vel = bulletSpeed × direction`, `pic` (`ship_bullets_04`), `radius`. Then `selfDestructEnt(bullet, 2)` schedules a 2-second self-destruct.

Inside `ship_controller`, after spawn, body+force+circleShape (with `Coll.Lasers` category, `Coll.Roids` mask, mass 0.5) are added so the bullet participates in physics. The right bullet additionally gets a `sound` ("laser_small") component so it makes noise (one bullet plays the sound; both move identically).

Lifecycle: 2-second TTL via `selfDestructEnt`, OR destroyed instantly by `bullet:destroy()` inside `Battle.bulletHitsRoid` upon collision.

### Explosions

Constructor: [`Explosion.explosion(parent, opts)`](../../modules/asteroids/entities/explosion.lua#L5).

Each explosion: `tag="explosion"`, `tr {x, y, r=randomFloat(0,2π)}`, `anim` with `id="debris_explosion_<n>"` (n=1..6, random or specified), `sx/sy=size`, `cx/cy=0.5`, `onComplete="selfDestruct"`, paired with a `timer name="splode" countDown=false factor=animSpeed`.

Lifecycle: `anim` system watches for `timer.t > duration`; with `onComplete=selfDestruct`, fires `estore:destroyEntity(e)`. As a belt-and-suspenders, the *callers* also do `selfDestructEnt(expl, N)` for an absolute upper bound (`Battle.destroyRoid` does 3.0s, strike explosions do 1.0s).

### Scenery (space_bg)

Two entities under `scene1.space_bg`, each with `tilingBackground + pic + paralax`. They never move or update (no `tr` of their own); they exist purely to be drawn each frame, their visible footprint determined dynamically each tick from the viewport's AABB.

### Camera

A single `camera1` entity under `world1`. Has `tr` (initially 0,0) and a `follower {targetname = "playership"}` — although **note**: the active scene_based path doesn't currently install a `followable {targetname="playership"}` on the ship (the line is commented in [`scene_based.lua:92`](../../modules/asteroids/entities/scene_based.lua#L92)). So the camera doesn't actually follow yet in the active scene; it stays at origin until manually panned via the `camera_dev_controller`. The test_flight jig manually copies `ship.tr.x/y` to `camera.tr.x/y` instead.

A sibling entity, the `camera_dev_controller`, listens for `[ ] - = 0 w a s d` keystrokes and feeds them to [`camera_dev_system`](../../modules/asteroids/systems/camera_dev_system.lua) which TweenHelpers-tweens camera zoom/rotation/position.

## 7. Cross-cutting concerns

### Collision categories

[`modules/asteroids/collision_categories.lua`](../../modules/asteroids/collision_categories.lua):

```
Coll.Ships  = 1
Coll.Roids  = 2  (bit 1)
Coll.Lasers = 4  (bit 2)
```

Used as `body.categories` and `body.mask` bitmasks (Box2D filterData). Ships only collide with roids; bullets only collide with roids; roids collide with everything.

### Sound playback

[`modules/asteroids/sounds/`](../../modules/asteroids/sounds) contains two assets: `medium-explosion-40472.mp3` (used by big roid kills) and `laser_small.wav` (used by bullets). Both are declared in `resources.lua` (with explicit volumes). Playback is triggered by attaching a `sound` component to an entity; the `sound` system plus `castle.soundmanager` handle lifecycle and cleanup.

### Resource access pattern

The convention throughout is:

- `res.pics:get("name")` for static images.
- `res.anims:get("name")` for animations.
- `res.sounds:get("name")` for sound resources (volume, duration, file).
- `res.data` for shared data (e.g., `res.data.screen_size = {width, height}` set during `initialEntities`).

All three "set"-style resources are LazyResourceSets (built on first access) but the `realize_on_module_load` setting means they're all built when the module wakes.

## 8. Project state and disabled paths

The active flow is the scene_based path. Currently disabled (commented out in [`resources.lua`](../../modules/asteroids/resources.lua)):

- `modules.asteroids.systems.devsystem` — empty placeholder.
- `modules.asteroids.systems.ship_workbench_system` — the jig dispatcher.

The jig system (when enabled) keys `1` through `5` to switch between five dev playgrounds: `test_flight`, `bullet_editor`, `flame_editor`, `roid_browser`, `explosion_browser`. They live under [`modules/asteroids/jigs/`](../../modules/asteroids/jigs) and are documented in detail in [modules.md](modules.md).

## 9. Where to look next

- For each system's full implementation: [systems.md](systems.md).
- For each entity's full structure: [entities.md](entities.md).
- For component definitions and access patterns: [components.md](components.md).
- For asset-by-asset details: [resources.md](resources.md).
- For underlying castle behavior: [docs/castle/](../castle/README.md).
