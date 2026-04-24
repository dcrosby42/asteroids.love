# Systems

Every system the project runs each tick, in execution order. Castle's built-ins are linked to the castle docs; project-defined systems are explained inline.

## Update systems (in resources.lua order)

The systems list from [`modules/asteroids/resources.lua:11`](../../modules/asteroids/resources.lua#L11):

```
1. castle.systems.timer
2. castle.systems.selfdestruct
3. castle.systems.anim
4. castle.systems.physics
5. castle.systems.follower
6. castle.systems.sound
7. castle.systems.touch
8. castle.systems.touchbutton
9. castle.systems.tween
10. castle.systems.keystate
11. castle.systems.controller_state
12. modules.asteroids.systems.cooldown
13. modules.asteroids.systems.camera_dev_system
14. modules.asteroids.systems.ship_controller
15. modules.asteroids.systems.boxthinger
```

(Disabled: `modules.asteroids.systems.devsystem`, `modules.asteroids.systems.ship_workbench_system`.)

### Castle built-ins (1-11)

For full details on each, see [docs/castle/systems.md](../castle/systems.md). Brief recap of what they do here:

1. **timer** — Decrements/increments every `timer` comp; sets `alarm`; emits `event` if non-empty.
2. **selfdestruct** — Destroys entities tagged `self_destruct` whose `timer.self_destruct` alarmed.
3. **anim** — Backfills `anim.duration` from resources; honors `onComplete = "repeat"|"expire"|"selfDestruct"`.
4. **physics** — Single `physicsWorld` entity. Syncs `tr/vel/force` ↔ Box2D bodies, steps the world, attaches `contact` comps on collisions.
5. **follower** — Copies `tr.x/y` from the matching `followable` entity. (Camera entity uses this — but its target `playership` doesn't currently exist on the active ship; see design.md.)
6. **sound** — Removes `sound` comps when their playtime exceeds duration (one-shots).
7. **touch** — Translates `touch` events into `touch` components on `touchable` entities. Not used by the active scene's gameplay.
8. **touchbutton** — Hold-button progress tracking. Not used by active scene.
9. **tween** — Applies `tween` interpolations using their `timer.t`.
10. **keystate** — Refreshes per-entity `pressed/held/released` from `input.events`.
11. **controller_state** — Same for joystick events.

### Project-defined systems (12-15)

#### `modules.asteroids.systems.cooldown`

[`cooldown.lua`](../../modules/asteroids/systems/cooldown.lua)

Defines the `cooldown` component (in [`components.lua`](../../modules/asteroids/components.lua), but the system file also imports it). The system iterates every entity with at least one `cooldown` comp:

```lua
defineQuerySystem("cooldown", function(e, estore, input, res)
  for _, cooldown in pairs(e.cooldowns) do
    local timer = e.timers and e.timers[cooldown.name]
    if cooldown.state == COOLDOWN and timer and timer.alarm then
      _reset(e, cooldown, timer)   -- removes timer, sets state="ready"
    end
  end
end)
```

`Cooldown.isReady(e, name)` reads `e.cooldowns[name].state == "ready"`.
`Cooldown.trigger(e, name)` adds a `timer` named `name` with `t = cooldown.t` and sets state to `"cooldown"`.

The state machine:

```
"ready"  --Cooldown.trigger()-->  "cooldown"
                                       |
                                  timer alarm
                                       |
                                       v
                                   "ready"
```

Used by ship lasers (`name="lasers", t=0.1` → 100ms between shots, see [`ship.lua:31`](../../modules/asteroids/entities/ship.lua#L31)).

#### `modules.asteroids.systems.camera_dev_system`

[`camera_dev_system.lua`](../../modules/asteroids/systems/camera_dev_system.lua)

Runs against entities tagged `camera_dev_controller`. Reads `keystate`, manipulates the named camera entity:

| Key | Action |
|-----|--------|
| `=` | Zoom in (sx,sy *= 1−0.2) |
| `-` | Zoom out (sx,sy *= 1+0.2) |
| `0` | Reset zoom/rot/pan |
| `[` | Rotate by +π/8 |
| `]` | Rotate by −π/8 |
| `w/a/s/d` | Pan ±200 |

All transforms are TweenHelpers-tweened with `duration=0.5, easing="outQuint"` ([`camera_dev_system.lua:18`](../../modules/asteroids/systems/camera_dev_system.lua#L18)).

If `e.states.debug.value == true`, attaches an orange-circle `debugdot` plus a `debuglabel` showing `x,y / r / z`. Currently `debug=false` is the default in [`world.lua:43`](../../modules/asteroids/entities/world.lua#L43).

#### `modules.asteroids.systems.ship_controller`

[`ship_controller.lua`](../../modules/asteroids/systems/ship_controller.lua)

Two-stage system on entities with a `ship_controller` component:

**Stage 1**: [`applyKeystateToShipController`](../../modules/asteroids/systems/ship_controller.lua#L9) reads the entity's `keystate` and writes `ship_controller.{turn, accel, fire_gun}`.

**Stage 2**: [`applyShipController`](../../modules/asteroids/systems/ship_controller.lua#L36):

- **Turn**: `tr.r += turn * (π * 1.5) * dt`. (NB: a torque-based path exists commented-out for "physical" turning; the active code is direct.)
- **Accel**: applies `force.impx/y` along the ship's facing direction (rotated `(0,-1)` by `tr.r`), magnitude `2250 * dt` per accel unit.
- **Auto-brake** (when not accelerating): decelerates `vel` toward zero at 150 units/s.
- **Fire**: if `Cooldown.isReady(ship, "lasers")`:
  - Calls `Ship.fireBullet(ship, "left", "ship_bullets_04", -1500)`.
  - Calls `Ship.fireBullet(ship, "right", "ship_bullets_04", -1500)`.
  - Adds `body+force+circleShape` to each bullet (mass 0.5, `Coll.Lasers` category, `Coll.Roids` mask, radius 7).
  - Right bullet gets a `sound="laser_small"` comp.
  - Calls `Cooldown.trigger(ship, "lasers")`.
- **Flame visibility**: queries the global `ship_flame`-tagged entity (singleton) and toggles `pic.color[4]` between 0 and 1 based on accel.

The flame query is module-local: `local ShipFlameQuery = Query.create({ tag = "ship_flame" })`.

> **Note**: stage 1 keys off keyboard only. The test_flight jig replaces stage 1 with `update_ship_controller_gamepad/keyboard` based on a `state.control_mode` toggle. The active scene_based path is keyboard-only.

#### `modules.asteroids.systems.boxthinger`

[`boxthinger.lua`](../../modules/asteroids/systems/boxthinger.lua)

Defines the `boxthing` component on import. The system runs on all entities with a `boxthing` comp:

```
left/right keystate  →  tr.r ± 0.05
up/down keystate     →  tr.y ± 10
```

No entity in the active scene currently has `boxthing`. The system is a no-op until you add the comp to something. Vestigial.

## Disabled systems

These are commented out in `resources.lua`. Re-enable by uncommenting the appropriate lines.

#### `modules.asteroids.systems.devsystem`

[`devsystem.lua`](../../modules/asteroids/systems/devsystem.lua)

Empty — `function(estore, input, res) end`. Placeholder.

#### `modules.asteroids.systems.ship_workbench_system`

[`ship_workbench_system.lua`](../../modules/asteroids/systems/ship_workbench_system.lua)

The jig dispatcher. Runs against the entity named `"ship_workbench"`. Reads its `state.jig` (current jig name) and `keystate.pressed["1"..."5"]`:

- If `state.jig` is empty: invokes `Jigs[DefaultJigName].init(workbench, estore, res)` (default = `test_flight`) and stores the jig name in state.
- If a digit key is pressed and `JigSelectorMap[key]` exists: looks up the new jig, calls current jig's `finalize(jigE, estore)` (if any), destroys the named jig entity, then calls new jig's `init`. Updates `state.jig`.
- Each tick: calls the current jig's `update(estore, input, res)`.

Mapping:

```lua
JigSelectorMap = {
  ["1"] = "test_flight",
  ["2"] = "bullet_editor",
  ["3"] = "flame_editor",
  ["4"] = "roid_browser",
  ["5"] = "explosion_browser",
}
```

To re-enable the workbench: uncomment its require in `resources.lua`, and switch the `initialEntities` path from `SceneBased.populate` to `Workbench.workbench` (inside [`entities.lua`](../../modules/asteroids/entities.lua#L20)).

## Draw systems

Just one:

```
castle.drawing.scenegraph_system2
```

Documented fully in [docs/castle/systems.md](../castle/systems.md). It renders the entity tree starting from `main_scene`, applying `tr` recursively, recursing into viewports, and running the registered DrawFuncs against each entity:

`screengrid → pic → anim → geom (box/rect/circle/radius) → button → physics → label → sound (pings soundmanager) → touch_debugs → devGrid → devBg → tilingBackground`

Active visual contributors in the scene_based path:

- `pic` — ship body, ship bullets, flame, dev backgrounds (none currently visible since space_bg uses tilingBackground).
- `anim` — explosions (only from jigs / battle helpers).
- `tilingBackground` — nebula + stars under `space_bg`.
- `geom` — `box`, `rect`, `radius`, `circle` debug visualizations (gated on each comp's `debug` flag, mostly off).

DrawFuncs are pure functions; they don't mutate the estore.

## How to add a new system

1. Create the file under [`modules/asteroids/systems/your_system.lua`](../../modules/asteroids/systems).
2. Either:
   - Return `defineQuerySystem(args, fn)` directly.
   - Return `function(estore, input, res) ... end`.
   - Return a table with `system = fn` (or `updateSystem = fn`).
3. Add `"modules.asteroids.systems.your_system"` to `systems.data` in [`resources.lua`](../../modules/asteroids/resources.lua) at the appropriate ordering position.
4. Reload (Cmd+R) — castle uncaches and re-`require`s your system.

For draw systems: add to `drawSystems.data` instead. Use `systemKeys = { "drawSystem" }` if you're returning a table form.
