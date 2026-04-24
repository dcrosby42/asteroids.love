# asteroids.love — Agent Crash Course

This is for an LLM agent about to work on the asteroids.love game. **Read [docs/context/castle.md](castle.md) first.** Castle is the framework underneath this game and you must be fluent in it. Live and die by castle: do not invent state-management, scenegraph, resource, or input systems — castle has them all.

If something seems missing, **assume castle has it before reinventing**. Open `vendor/castle/`, search, and confirm. The two big design rules: 1) state lives in the Estore (or in `world.input`/`res`), nowhere else; 2) drawing/input/audio go through castle's pipelines.

## Repo orientation

- `main.lua` (project root) bootstraps castle, hands control to `modules/root`.
- `modules/root.lua` is a `castle.modules.switcher` over `{asteroids, joystick_debug}`. F1/F2 swap. Cmd+R hot-reloads.
- `modules/asteroids/` is the game ECS module. Built from `modules/asteroids/resources.lua` via `GameModule.newFromFile`.
- `modules/joystick_debug/init.lua` is a 50-line plain Castle Module (no ECS) — useful as a reference for non-ECS modules.
- `vendor/castle/` is the framework. First-party. Edit when needed.
- Other `vendor/` libs: `inspect`, `vector-light` (used as `Vec` for math), `mydebug`, `garbagecollect`, `SUIT`, `sti`, `parkmiller`, `msgpack`. Globals are loaded via `castle/helpers.lua` and `castle/ecs/ecshelpers.lua`.

The active gameplay path is **scene_based**. The older **workbench/jigs** path is currently disabled (commented out in resources.lua's systems list). Don't move logic from one to the other casually; they're orthogonal modes.

## Boot flow

`love.load` → `castle.main:loadItUp` → `Castle.module_name = "modules/root"` → `modules/root.M.newWorld()` builds a switcher world → switcher lazily instantiates `asteroids` (the default) → `GameModule.newFromFile("modules/asteroids/resources.lua")` parses the manifest, registers components, composes systems, builds the resource root → `EcsAdapter.newWorld` calls `entities.lua → E.initialEntities(res)` → that calls `SceneBased.populate(estore, res)` which builds the scene tree.

Each tick: `love.update(dt)` → `{type="tick", dt}` action → root → switcher → ecsadapter → `world.input.dt = dt` → composed update systems run in order → `world.input.events` returned as sidefx and reset. Non-tick actions (keyboard/mouse/touch/joystick) are appended to `world.input.events` between ticks; `keystate`/`controller_state`/`touch` systems consume them next tick.

Each draw: `love.draw` → root → switcher → ecsadapter → composed draw systems. There's exactly one: `castle.drawing.scenegraph_system2`. It walks the entity tree starting from the entity named `"main_scene"`.

## Scene tree (active)

Built by `SceneBased.populate` (`modules/asteroids/entities/scene_based.lua`):

- `main_scene` (root)
  - `viewport` (child of main_scene). Has a `viewport{scene="scene1",camera="camera1",blockout=true,bgcolor={0,0.4,0},use_bgcolor=false}`, a `tr` centered on screen, a `box` of screen dimensions.
- `scene1` (sibling of main_scene at estore root — referenced by viewport.scene by name, NOT parented under viewport)
  - `space_bg` (child of scene1)
    - nebula entity: `tilingBackground + pic{nebula_blue} + paralax{0.25,0.25}`
    - stars entity: `tilingBackground + pic{starfield_1} + paralax{0.75,0.75}`
  - `world1` (child of scene1)
    - `camera1`: `tr + follower{targetname="playership"} + name="camera1"`. NOTE: ship doesn't currently have `followable`, so follow is inactive in the live scene. Camera stays at origin until panned via camera_dev_controller.
    - `physics_world`: `physicsWorld{allowSleep=false}`
    - the ship (built via `Ship.ship(world1, res)`)
- `camera_dev_controller` (sibling at root): tagged `camera_dev_controller`, has keystate for `[ ] - = 0 w a s d`, references `camera1` by name.

Drawing: scenegraph_system2 starts at `main_scene`. The viewport entity's `drawViewport2` resolves `scene1` and `camera1` by name, applies the camera's INVERSE transform (so world coords project to screen), stencil-clips to the viewport's box, and recursively draws scene1's tree in viewport scope. Children-of-children inherit transform composition.

Parallax: applied during `computeEntityTransform2` for entities with a `paralax` comp when a `viewportEnt` is in scope. There's a `mysterious_correction = 0.5` factor in `applyParalax` that's flagged as unexplained; preserve it.

## Modules: project-defined files

Entity factories (under `modules/asteroids/entities/`):
- `scene_based.lua` — `populate(estore, res)`. The active entry.
- `world.lua` — `basicWorldAndViewport`, `viewport`, `camera`, `camera_dev_controller` factories.
- `ship.lua` — `Ship.ship(parent, res)`, `Ship.fireBullet(ship, side, picId, speed)`.
- `roids.lua` — `Roids.roid(parent, opts)`, `Roids.random(parent, opts)`. Size cats: small/medium/medium_large/large/huge with hp 1/2/3/6/12, radii 13/27/39/65/179.
- `explosion.lua` — `Explosion.explosion(parent, opts)`. Picks `debris_explosion_<1..6>` random or by `opts.num`/`opts.animId`.
- `workbench.lua` — older entry, dev backgrounds, `flameMenu`/`bulletMenu`, `Workbench.Flames`/`Workbench.Bullets` lists.

Systems (under `modules/asteroids/systems/`):
- `cooldown.lua` — `cooldown` component & system + `Cooldown.isReady/trigger`. Pairs with `timer`.
- `ship_controller.lua` — keystate → ship_controller comp → turn/thrust/brake/fire. Gates fire on `lasers` cooldown. Animates ship_flame alpha.
- `camera_dev_system.lua` — keystate-driven camera tweens via TweenHelpers.
- `boxthinger.lua` — defines `boxthing` comp; rotates+translates entities carrying it. Vestigial.
- `devsystem.lua` — empty stub. Disabled.
- `ship_workbench_system.lua` — jig dispatcher. Disabled.

Other:
- `entities.lua` — exports `E.initialEntities(res)`.
- `components.lua` — exports `health`, `cooldown`, `ship_controller` definitions for the components datafile loader.
- `battle_helpers.lua` — `damageEntity`, `bulletHitsRoid`, `destroyRoid`, `shipHitsRoid`, plus strike/destruction explosion generators with sounds.
- `collision_categories.lua` — `Coll.Ships=1, Roids=2, Lasers=4` bitmasks.
- `resources.lua` — the manifest.

Jigs (under `modules/asteroids/jigs/`, only active when workbench is enabled): `test_flight` (full play scene), `bullet_editor`, `flame_editor`, `roid_browser`, `explosion_browser`, plus helpers `menu.lua` and `update_ship_controller.lua`. The dispatcher maps keys 1-5 to these.

## Components in use

Built-in (from castle): `tag, name, tr, paralax, state, box, radius, timer, followable, follower, viewport, pic, anim, rect, circle, label, sound, tween, physicsWorld, vel, body, force, joint, circleShape, contact, keystate, button, touchable, touch, parent`. Plus `controller_state` (defined in its own system file). Plus drawing-side `devgrid, devbg, tilingBackground` (defined in scenegraph_system2).

Project-added (from `modules/asteroids/components.lua`):
- `health { hp = 10 }` — roids.
- `cooldown { t = 1, state = "ready" }` — pairs with a same-named timer.
- `ship_controller { dx, dy, turn, accel, fire_gun }` — input intent.

Plus inline in `boxthinger.lua`: `boxthing {}`.

Reuse first. Don't define new types unless you genuinely need new shape. Component data is dumb; behavior goes in systems.

## Entity composition reference

Ship (`Ship.ship`): `name="ship"` + `tr + vel + controller_state{match_id="joystick1"} + keystate{handle={left,right,up,down,space}} + ship_controller + body{mass=5,Coll.Ships,mask=Coll.Roids,debug=true} + force + circleShape{radius=40} + cooldown{name="lasers",t=0.1} + box{w=100,h=100,debug=true} + pic{ship_example_05,sx=0.75,cx=0.5,cy=0.5,debug=true}`. Children: an unnamed debug box(200×200), `gun_muzzle_left` and `gun_muzzle_right` (just tags + tr offsets), `ship_flame` (tag + tr + pic{ship_flame_06,alpha=0} + looping timer).

Bullet (`Ship.fireBullet`): name=`ship_bullet_<side>` + tag=`ship_bullet` + tr (placed/rotated at muzzle) + vel (direction × speed) + pic{`ship_bullets_04`} + radius{10} + selfDestructEnt(2.0). After return, ship_controller adds `body{mass=0.5,Coll.Lasers,mask=Coll.Roids} + force + circleShape{7}`. Right bullet additionally gets `sound{laser_small}`.

Roid (`Roids.random`): tag=`roid` + tr + vel + pic{random from sizeCat catalog, scaled} + radius (per-sizeCat) + health (per-sizeCat) + body{Coll.Roids,mask=Coll.Roids|Coll.Lasers|Coll.Ships,friction=0.8,restitution=0.9,mass=π·r²} + force + circleShape.

Explosion (`Explosion.explosion`): tag=`explosion` + tr{random rotation} + anim{`debris_explosion_<n>`,onComplete=selfDestruct} + timer{name="splode",countDown=false,factor=animSpeed}. Battle helpers also call `selfDestructEnt` for upper-bound TTL and (for roid kills) attach `sound{medium_explosion_1}`.

## Per-tick gameplay flow

Active scene (the simple one):

1. `timer` ticks all timers.
2. `selfdestruct` removes alarm-fired self-destruct entities.
3. `anim` ticks anim durations; `onComplete=selfDestruct` destroys explosion entities at end.
4. `physics` syncs `tr/vel/force` ↔ Box2D bodies, steps the world, attaches `contact` components on collision begin.
5. `follower` copies `followable.targetname`-matched entity's `tr.x/y` (currently no-op for camera since ship has no followable).
6. `sound` removes finished one-shot sound comps.
7. `touch`, `touchbutton` — no-ops in active scene.
8. `tween` interpolates `tween` comps via their timers.
9. `keystate` refreshes per-entity press/held/released from input events.
10. `controller_state` does the same for joystick events.
11. `cooldown` (project) flips state→ready when matching timer alarms.
12. `camera_dev_system` (project) tweens camera transform on key presses.
13. `ship_controller` (project) reads keystate, applies turn/thrust/brake, fires bullets via cooldown, toggles flame visibility.
14. `boxthinger` (project) — no entity has the comp, no-op.

Then draw: scenegraph_system2 walks main_scene → viewport → (resolves scene1) → recursively renders space_bg + world1 + ship.

## Input pipeline

Keyboard: castle.main → keyboard action → ecsadapter intercepts cmd+r/escape → appends to `world.input.events` → `keystate` system fans events out to per-entity `keystate` comps based on their `handle` lists. Default `consume=false`, so multiple entities can respond to the same key.

Joystick: castle.main → joystick action with `controlMap` → ecsadapter routes to `joystickadapter.appendControllerEvents` which emits `controller`-type events with id `"joystick1"` → `controller_state` system updates per-entity comps with matching `match_id`.

Touch/Mouse: castle.main → touch or mouse action → ecsadapter wraps non-isTouch mouse as synthetic touch event with id `"mousetouch1"` → `touch` system fans to entities with `touchable` (using `seekEntityBottomUp` for draw-order-correct hit testing).

To add a new keyboard listener: put `{ "keystate", { handle = {"a","b"} } }` on an entity and read `e.keystate.{pressed,held,released}.<key>` in a system. Or use `EventHelpers.handleKeyPresses(input.events, {key=fn})` in a system that doesn't need per-entity dispatch.

## Resources & assets

Manifest `modules/asteroids/resources.lua`. Settings: `lazy_load={pics,picStrips,anims,sounds}`, `realize_on_module_load=true` — assets get built when the asteroids module wakes up (not at boot), and once awake all are warm.

Resource files referenced (each is a `resource_file` entry):
- `images/roidpics.res.lua` — 23 raw roid sprites (small/medium/large × grey/red/brown × variants).
- `images/roidaliases.res.lua` — `picaliases` mapping `roid_<size>_<color>_<NN>` numeric names to raw `_a1`/`_b1`/`_c1`/etc. names. The `Roids.PicIds` list uses the aliased names.
- `images/ships/ship_pics.res.lua` — ~117 ship part pics: bodyes A/B/C, bullets, cabins, engines, example, flame, guns A/B, mines, missiles + missiles flame, wings A/B.
- `images/bg/backgrounds.res.lua` — `example_background`, `starfield_1..4`, `nebula_blue` (sx=2,sy=2), `nebula_red`, `nebula_aqua_pink`.
- `images/explosions/sheets_halved/explosions.res.lua` — 6 picStrips → 6 anims, each 192×192 tiles, frame duration 2/60s. (sibling `images/explosions/explosions.res.lua` is for the non-halved variant; current manifest uses sheets_halved.)

Sounds (declared inline in resources.lua):
- `medium_explosion_1` → `sounds/medium-explosion-40472.mp3`, volume 0.4. Used by `Battle.destroyRoid`.
- `laser_small` → `sounds/laser_small.wav`, volume 0.5. Used by ship bullet fire.

Font: `narpassword` (size 64) at `modules/common/fonts/narpassword.ttf`.

In-use pics: `ship_example_05` (ship body), `ship_flame_06` (flame), `ship_bullets_04` (bullets), `nebula_blue` and `starfield_1` (backgrounds), `debris_explosion_<1..6>` (anims).

## State that survives across ticks

- The Estore (entities + components + parent/child tree).
- The resource root (mostly read-only after load; can be mutated, e.g. `res.data:put("screen_size", ...)`).
- `world.input.events` accumulating between ticks (cleared at end of each tick).
- The `world.editor` substructure (history, GUI state).

That's it. Don't keep gameplay state in module-local Lua variables. Cross-tick gameplay state goes on entities — a `state` component on a named entity is the standard pattern.

## How to do common things in this codebase

- **Add a new system**: file under `modules/asteroids/systems/`, return `defineQuerySystem(args, fn)` or a plain `function(estore, input, res)`. Register in `resources.lua` systems.data list at the right ordering position.
- **Add a new entity type**: factory function in `modules/asteroids/entities/<name>.lua`, return `function newX(parent, opts) parent:newEntity({...}) end`. Call from `scene_based.populate` (or wherever appropriate).
- **Add a new component type**: append to `modules/asteroids/components.lua` returned table, or call `Comps.define("name", {...})` inline in a system file. Don't shadow built-ins.
- **Add a sound**: `{ type = "sound", name = "x", data = { file = "...", volume = 0.5 } }` in `resources.lua`. Trigger via `e:newComp("sound", { sound = "x" })` on any entity — auto-removed when done.
- **Add a temp visual effect**: build entity with `anim{onComplete=selfDestruct}` + paired `timer`, optionally a `sound`, optionally `selfDestructEnt(e, N)` for upper bound.
- **Schedule a tween**: `TweenHelpers.tweenit(e, "name", { tr = { sx = 2 } }, { duration = 0.5, easing = "outQuint" })`.
- **Read input**: declare keystate/controller_state on the entity that should listen. Read `e.keystate.pressed.<key>` in a system.
- **Find an entity**: `estore:getEntityByName("...")` (indexed) for singletons; `Query.create({tag="..."})` cached at file scope for collections.
- **Reload mid-game**: just press Cmd+R. Or emit `{type="castle.reloadRootModule"}` as sidefx.

## Things to NOT do

- Don't write a custom scenegraph or transform stack. Use scenegraph_system2 and add a DrawFunc if you need custom drawing.
- Don't use `castle.drawing.scenegraph_system` (the old v1 — uses decommissioned helpers).
- Don't call `castle.ecs.viewport_helpers.findOwningViewportCamera` — it throws DECOMMISSIONED.
- Don't manage `love.audio.Source`s manually. Use `sound` components.
- Don't iterate `estore.ents` or `.comps` directly to find things. Use `getEntityByName`, `queryEntities`, `walkEntities`/`seekEntity` with predicates.
- Don't put gameplay state in module-local Lua vars. Put it on a named entity (use `state` comps, custom comps, etc.).
- Don't compute `dt` from `love.timer`; only read `input.dt` inside a system.
- Don't bypass `Estore:newEntity`/`newComp` — the object pool, indexes, and parent-linkage all live behind these methods.
- Don't redefine built-in component types or shadow castle helpers. Read `vendor/castle/components.lua` and `vendor/castle/ecs/ecshelpers.lua` first.
- Don't move logic between scene_based and jigs path without understanding both. They're orthogonal modes.
- Don't add features outside the resources.lua-driven pipeline. New systems get listed in `systems.data`; new assets go in a `resource_file` referenced from the manifest.
- Don't change `mysterious_correction = 0.5` in `applyParalax` without understanding why it's there. The author flagged it as unexplained but functional.

## Known caveats / TODOs

- Camera follow is wired (camera has `follower{targetname="playership"}`) but the ship's `followable` line is commented out in `scene_based.lua:92`. Active scene's camera doesn't track the ship; only camera_dev_controller keys move it. test_flight jig manually copies ship.tr → camera.tr each tick instead.
- The active scene_based path doesn't spawn roids, doesn't hook collisions, doesn't run a full battle pipeline. Combat lives in the test_flight jig (currently disabled). Wiring it into the live scene is a known TODO.
- `Workbench.dev_background_starfield2` has a buggy inner loop missing the `comps[#comps+1] = cmp` line — the iteration produces no pic comps. Use `dev_background_starfield1` or `tilingBackground` instead.
- `boxthinger` is in the systems list but no entity has the comp. Either wire one up or remove from the list.
- `follower` system has a TODO note about extinct 'pos' component (it actually works on `tr` now, not `pos` — the comment is stale).

## Files to read on first contact

`modules/asteroids/resources.lua` (the spine), `modules/asteroids/entities.lua` (boot), `modules/asteroids/entities/scene_based.lua` (the live scene), `modules/asteroids/entities/ship.lua` (representative entity factory), `modules/asteroids/systems/ship_controller.lua` (representative system), `modules/asteroids/battle_helpers.lua` (canonical "what happens on impact"), `modules/asteroids/collision_categories.lua`, `modules/asteroids/components.lua`. Then for deeper understanding: `vendor/castle/drawing/scenegraph_system2.lua` (rendering), `vendor/castle/ecs/estore.lua` (data model), `vendor/castle/ecs/ecsadapter.lua` (lifecycle).

## Final reminder

Castle is the framework. **Use it, don't fight it.** When the user asks for a feature: think in terms of components + systems + resource configs. Want a new enemy? Add a factory under `modules/asteroids/entities/`, give it standard physics/visual/health components, register pics in a `*.res.lua`, spawn from scene_based or a system. Want a new effect? Build an entity with `anim{onComplete=selfDestruct}` + timer + sound. Want a new control? Add a keystate or controller_state comp to the relevant entity, write a system that reads it. The framework rewards going with the grain.

Re-read **[docs/context/castle.md](castle.md)** if you forget how a primitive works.
