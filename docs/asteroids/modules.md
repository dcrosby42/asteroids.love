# Module Index

Every Lua file under [`modules/asteroids/`](../../modules/asteroids), grouped by role.

## Top-level

| File | Purpose |
|------|---------|
| [`resources.lua`](../../modules/asteroids/resources.lua) | The manifest. ECS config, settings, resource_file references, sounds, fonts. |
| [`entities.lua`](../../modules/asteroids/entities.lua) | Defines `E.initialEntities(res)`, the bootstrap function the ECS resource loader calls when the module first activates. Currently delegates to `SceneBased.populate`. |
| [`components.lua`](../../modules/asteroids/components.lua) | Project-defined component types (`health`, `cooldown`, `ship_controller`). Pulled in by the `components` block of resources.lua. |
| [`battle_helpers.lua`](../../modules/asteroids/battle_helpers.lua) | Combat helpers used by jigs: `damageEntity`, `bulletHitsRoid`, `destroyRoid`, `shipHitsRoid`, plus the strike-explosion generators. |
| [`collision_categories.lua`](../../modules/asteroids/collision_categories.lua) | Bitmask constants (`Coll.Ships=1`, `Coll.Roids=2`, `Coll.Lasers=4`) for Box2D filterData. |

## Entity factories — `modules/asteroids/entities/`

Each file exports a table with constructor functions. They take `(parent, res, opts?)` and return the new entity.

| File | Exports |
|------|---------|
| [`scene_based.lua`](../../modules/asteroids/entities/scene_based.lua) | `populate(estore, res)` — builds the **active** scene tree (main_scene → viewport → scene1 → space_bg + world1 → camera, physics_world, ship). |
| [`world.lua`](../../modules/asteroids/entities/world.lua) | `basicWorldAndViewport`, `viewport`, `camera`, `camera_dev_controller`. The "world plumbing" factories used by both scene_based and (legacy) workbench paths. |
| [`ship.lua`](../../modules/asteroids/entities/ship.lua) | `Ship.ship(parent, res)` constructor; `Ship.fireBullet(ship, side, picId, speed)`. Plus the local `transformToLocAndDir(transf)` helper used to derive bullet spawn position/direction from the muzzle's transform. |
| [`roids.lua`](../../modules/asteroids/entities/roids.lua) | `Roids.roid(parent, opts)`, `Roids.random(parent, opts)`, `Roids.isRoid(e)`. Sprite catalog by size (`SpriteConfigs.{small,medium,medium_large,large,huge}`), normalized scale factors, hit-radius-by-category map, hp-by-category map. |
| [`explosion.lua`](../../modules/asteroids/entities/explosion.lua) | `Explosion.explosion(parent, opts)`. Picks a random `debris_explosion_N` anim (or honors `opts.num` / `opts.animId`). |
| [`workbench.lua`](../../modules/asteroids/entities/workbench.lua) | Older "workbench" entry point and dev backgrounds: `Workbench.workbench`, `Workbench.dev_background`, `Workbench.dev_background_nebula_blue`, `Workbench.dev_background_starfield1`, `Workbench.dev_background_starfield2`, `Workbench.flameMenu`, `Workbench.bulletMenu`. Plus `Workbench.Flames` (list of 11 flame pic ids) and `Workbench.Bullets` (list of 12 bullet pic ids). Used by jigs. |
| [`NOTES.txt`](../../modules/asteroids/entities/NOTES.txt) | ASCII sketch of the intended scene_based estore layout. |

## Systems — `modules/asteroids/systems/`

| File | What it does |
|------|--------------|
| [`cooldown.lua`](../../modules/asteroids/systems/cooldown.lua) | The `cooldown` component plus its system. Exports `Cooldown.isReady(e, name)` and `Cooldown.trigger(e, name)`. Returned table also has `.system`. |
| [`ship_controller.lua`](../../modules/asteroids/systems/ship_controller.lua) | Reads `keystate` → `ship_controller` comp; applies turn (`tr.r += turn*spinSpeed*dt`), thrust (impulse along facing dir), auto-brake (decelerate vel toward zero), fire (cooldown-gated, spawns left+right bullets via `Ship.fireBullet`). Animates ship_flame alpha. |
| [`camera_dev_system.lua`](../../modules/asteroids/systems/camera_dev_system.lua) | `camera_dev_controller`-tagged entities; reads `[ ]` (rotate), `- =` (zoom), `0` (reset), `w/a/s/d` (pan). Calls `TweenHelpers.addTweens` for each transform change. Optional debug visualization (orange dot + label) gated on `state.debug`. |
| [`boxthinger.lua`](../../modules/asteroids/systems/boxthinger.lua) | Defines `boxthing` component. Listens for arrow-key keystate to rotate (`SpinSpeed=0.05`) and translate (`MoveSpeed=10`) any entity carrying it. Active in resources.lua but no entity in the active scene currently has the `boxthing` comp — leftover plumbing. |
| [`devsystem.lua`](../../modules/asteroids/systems/devsystem.lua) | Empty function returning `function(estore, input, res) end`. Currently disabled in resources.lua. |
| [`ship_workbench_system.lua`](../../modules/asteroids/systems/ship_workbench_system.lua) | Jig dispatcher. Watches a `ship_workbench` entity's `state.jig`; on init creates the default jig (`test_flight`); on number-key press transitions to a different jig (`Jigs[name].finalize` → `current entity:destroy()` → `Jigs[new].init`). Currently disabled in resources.lua. |

## Jigs — `modules/asteroids/jigs/`

A "jig" is a self-contained dev/test playground: `{init(parent, estore, res), update(estore, input, res), finalize(jigE, estore)}`. Used only when `ship_workbench_system` is enabled (currently disabled).

| File | Slot | What it demonstrates |
|------|------|----------------------|
| [`test_flight.lua`](../../modules/asteroids/jigs/test_flight.lua) | key `1` | Full play scene: 100-asteroid field over 8000² area, full ship build, keyboard/joystick toggle (return), camera follow, bullet/ship-roid collision via `Battle`. The closest thing to "actual gameplay". |
| [`bullet_editor.lua`](../../modules/asteroids/jigs/bullet_editor.lua) | key `2` | Tweak bullet pic and position: arrows nudge, `,/.` scale, `j/k` switch among 12 bullet sprites via `Workbench.bulletMenu`. |
| [`flame_editor.lua`](../../modules/asteroids/jigs/flame_editor.lua) | key `3` | Tweak ship flame pic and y-offset: up/down nudge y, `j/k` cycle 11 flame sprites via `Workbench.flameMenu`. |
| [`roid_browser.lua`](../../modules/asteroids/jigs/roid_browser.lua) | key `4` | Display each named roid pic; up/down zoom; `j/k` cycle, `c` toggles a multi-row chart of all asteroid sizes. |
| [`explosion_browser.lua`](../../modules/asteroids/jigs/explosion_browser.lua) | key `5` | Tabbed (left/right) browser through 6 debris explosions plus a "nukeit" tab where space spawns a moving roid and (re-)triggers it via `Battle.destroyRoid`. |
| [`menu.lua`](../../modules/asteroids/jigs/menu.lua) | (helper) | `Menu.incrementMenuSelection`, `Menu.getMenuChoice`, `Menu.updateMenu`. The pic-tile menu cursor implementation used by all editor jigs. |
| [`update_ship_controller.lua`](../../modules/asteroids/jigs/update_ship_controller.lua) | (helper) | `M.updateShipController_keyboard(ship_controller, keystate)` and `M.updateShipController_gamepad(ship_controller, controller_state)`. Used by test_flight to switch which input source feeds the controller. |
| [`_jig_template.lua`](../../modules/asteroids/jigs/_jig_template.lua) | (template) | Skeleton for new jigs. |

## Resource manifests — `modules/asteroids/images/` and `modules/asteroids/sounds/`

| File | Role |
|------|------|
| [`images/roidpics.res.lua`](../../modules/asteroids/images/roidpics.res.lua) | 23 roid pic resources: small/medium/large × grey/red/brown × variants. |
| [`images/roidaliases.res.lua`](../../modules/asteroids/images/roidaliases.res.lua) | `picaliases` mapping numeric-suffix names like `roid_small_grey_01` to actual sprite names like `roid_small_grey_a1`. The `Roids` module references the aliased names. |
| [`images/ships/ship_pics.res.lua`](../../modules/asteroids/images/ships/ship_pics.res.lua) | All ship body parts: bodyes (a/b/c), bullets (12), cabins (11), engines (10), example (16 + Bg), flame (11), guns (a 10 + b 10), mines (5), missiles (5 + flame 5), wings (a 10 + b 10). |
| [`images/bg/backgrounds.res.lua`](../../modules/asteroids/images/bg/backgrounds.res.lua) | `example_background`, `starfield_1` through `_4`, `nebula_blue`, `nebula_red`, `nebula_aqua_pink`. |
| [`images/explosions/sheets_halved/explosions.res.lua`](../../modules/asteroids/images/explosions/sheets_halved/explosions.res.lua) | 6 debris explosion picStrips, each producing an anim. Uses helper function `debris_explosion(n)` that emits a `picStrip` config from a numeric arg. |
| [`sounds/laser_small.wav`](../../modules/asteroids/sounds/laser_small.wav) | Bullet-fire sound. |
| [`sounds/medium-explosion-40472.mp3`](../../modules/asteroids/sounds/medium-explosion-40472.mp3) | Roid-destruction sound. |

## Image asset directories (raw)

The actual PNG/sprite-sheet files live under:

- [`modules/asteroids/images/large/`](../../modules/asteroids/images/large) — large roid sprites (brown/grey/red × a1/b1/c1/c4/a3/b3/c3 etc).
- [`modules/asteroids/images/medium/`](../../modules/asteroids/images/medium) — medium roid sprites.
- [`modules/asteroids/images/small/`](../../modules/asteroids/images/small) — small roid sprites.
- [`modules/asteroids/images/bg/`](../../modules/asteroids/images/bg) — background nebulae and starfields.
- [`modules/asteroids/images/explosions/sheets_halved/`](../../modules/asteroids/images/explosions/sheets_halved) — 6 debris-explosion sheet PNGs (`debris_explosion_1.sheet.png` etc).
- [`modules/asteroids/images/ships/`](../../modules/asteroids/images/ships) — Bodyes A/B/C, Bullets, Cabins, Engines, Example, Flame, Guns A/B, Mines, Missiles (+ Missiles/Flame), Wings A/B.

These are all referenced indirectly via the `*.res.lua` manifest files; nothing in the Lua code path-references PNGs directly.
