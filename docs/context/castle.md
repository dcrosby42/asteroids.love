# Castle: Agent Crash Course

This is for an LLM agent about to read or write code in this repo. **Castle is the project's own Love2D framework**, vendored at `vendor/castle/`. Treat it as first-party. Do not vendor alternatives, don't write your own ECS/state/resource mechanics, don't bypass it. When the user asks for game features, **express them in castle's idioms** (modules, components, systems, resource configs).

## Repo shape

- `main.lua` boots `vendor/castle/main` and points `Castle.module_name = "modules/root"`.
- `modules/root.lua` is a `castle.modules.switcher` over child modules. F1/F2 swap.
- `modules/asteroids/` is the active game (an ECS module).
- `vendor/castle/` is the engine. Edit it freely if needed; do not treat as third-party.
- Other `vendor/` libs are standalone (`inspect`, `vector-light`, `mydebug`, `garbagecollect`, `SUIT`, `sti`, `parkmiller`, `msgpack`).
- `vendor/castle/helpers.lua` and `vendor/castle/ecs/ecshelpers.lua` install **globals** (`tcopy`, `lmap`, `lfilter`, `randomInt`, `math.dist`, `defineQuerySystem`, `hasTag`, `computeEntityTransform`, `selfDestructEnt`, etc.). If you see a function used without `require`, it's from there. Don't redefine.

## Module layer

A castle Module is `{ newWorld(opts) -> world, updateWorld(world, action) -> world, sidefx?, drawWorld(world) }`. Modules own no state; `world` is the only state and only `updateWorld` mutates it. The shape of `world` is private. Any valid `world` may be passed at any time.

`vendor/castle/main.lua` attaches all `love.*` callbacks and converts each into an `action`:

- `tick`: `{type="tick", dt}` (every frame from `love.update`)
- `keyboard`: `{type="keyboard", state="pressed"|"released", key, ctrl/shift/gui flags}`
- `mouse`: `{type="mouse", state, x, y, button, isTouch, dx, dy}` (auto-converted to a `touch` event with id `"mousetouch1"` inside EcsAdapter for non-isTouch desktops)
- `touch`: `{type="touch", state="pressed"|"moved"|"released", id, x, y, dx, dy}`
- `joystick`: `{type="joystick", joystickId, instanceId, controlType="axis"|"button", control, controlName, value, controlMap}`
- `textinput`: `{type="textinput", text}`
- `resize`: `{type="resize", w, h}`

`updateWorld` may return `(world, sidefx)` where `sidefx` is a list of `{type=...}` tables. `castle.main` honors two: `castle.reloadRootModule` (hot reload) and `castle.toggleDebugLog`. Submodules use sidefx to signal upward (e.g., the switcher passes a child's sidefx through).

Hot reload: `vendor/castle/moduleloader.lua` wraps `require` to track dep trees; on `castle.reloadRootModule` it uncaches everything and re-`require`s the root. Default key: `cmd+r` (gui+r). Intercepted in `vendor/castle/ecs/ecsadapter.lua:56`.

Switcher: `castle.modules.switcher.newWorld({modules=mapName2Module, current=name})`. Children are lazy-instantiated (`memoize0`). A `{type="castle.switcher", index=name}` action flips current. Only the current module receives ticks/draws.

ECS as a module: `castle.ecs.gamemodule.newFromFile(path)` reads a resources manifest and returns a Castle Module wrapped via `castle.ecs.ecsadapter`. The adapter turns Love2D events into `world.input.events` (a queue), runs the ECS update each tick with `(estore, input, res)`, and returns `world.input.events` as sidefx (so events bubble up through nested modules). It also handles editor toggle (`escape` opens a paused SUIT editor; `shift+escape` keeps paused on close), `gui+r` reload, and joystick→controller event mapping (via `castle.ecs.joystickadapter`, mapped to controllerId `"joystick1"`).

When writing a non-ECS module: just return `{newWorld, updateWorld, drawWorld}`. See `modules/joystick_debug/init.lua` (50 lines, no ECS, no resources).

## ECS layer

Estore (`vendor/castle/ecs/estore.lua`) holds entities and components plus a parent/child tree (`_root._children`). It also maintains three indexes via `castle.ecs.indexer`: `byName` (on `name.name`), `byTag` (on `tag.name`), and `byCompType` (every comp type indexed by default). Every entity exposes shorthands: `e.tr` is the FIRST `tr` component, `e.trs` is `{[name or cid] -> comp}`. Likewise `e.timers.flame`, `e.cooldowns.lasers`, `e.states.debug_draw`. Plural key falls back to cid when comp has no `name`. Components carry built-in fields `cid`, `eid`, `type`, `name`.

Component definition (`vendor/castle/ecs/component.lua`): `Comps.define("type", {'field', default, 'field', default, ...})`. This registers an object pool of pre-built protos; `Estore:newComp(e, type, data)` pulls a clean copy and merges `data`. Built-in `parent` (auto-managed; carries `parentEid`, `order`) and `name` (the indexed name). The big catalog is `vendor/castle/components.lua`: `tag, tr, paralax, state, box, radius, timer, followable, follower, viewport, bgcolor, pic, anim, rect, circle, label, sound, tween, physicsWorld, vel, body, force, joint, rectangleShape, circleShape, chainShape, polygonShape, polygonLineStyle, contact, keystate, button, touchable, touch, screen_grid`. Project code may add more; the asteroids module declares `health, cooldown, ship_controller` via the components datafile; draw code adds `devgrid, devbg, tilingBackground` at module-load time inline. **Always reuse existing component types where they fit before defining new ones.**

Entity construction:

```lua
local e = parent:newEntity({
  { "name", { name = "ship" } },
  { "tr",   { x = 100, y = 100 } },
  { "pic",  { id = "ship_example_05", cx=0.5, cy=0.5 } },
})
e:newComp("vel", { dx = 5 })
e:removeComp(e.vel)
e:destroy()                        -- recursive on children
```

`Entity:newEntity` is an alias for `:newChild`; both inject a `parent` comp pointing at self and link the trees. To attach an existing entity to a new parent: `parent:addChild(child)`.

Estore traversal (use these, don't iterate raw tables):
- `walkEntities(matchFn, doFn)` — preorder DFS; return `false` from `doFn` to skip subtree.
- `walkChildren(e, ...)`, `walkEntity(e, ...)`, `walkEntities2(...)` (variant where `doFn` gets a `descend` callback).
- `seekEntity(matchFn, doFn)` / `seekEntityBottomUp` — short-circuit on `doFn` returning true; bottom-up is reverse draw order (use for hit-testing).
- `findEntity(matchFn)`, `getEntityByName("..")`, `getEntitiesByCompType("..")`, `queryEntities(query)`, `queryFirstEntity(query)`.

Predicates (globals from `ecshelpers`): `hasComps("a","b")`, `hasTag("foo")`, `hasName("ship")`, `allOf(p1,p2)`. Use these instead of writing inline filters.

Queries (`vendor/castle/ecs/query.lua`): `Query.create(args)` accepts a string (compType lookup), a function (filter), an array (compTypes), or a table with `tag`/`comp`/`comps`/`indexLookup`/`filter`. Cache the query at file scope:

```lua
local BulletQuery = Query.create({ tag = "ship_bullet" })
for _, b in ipairs(BulletQuery(estore)) do ... end
```

A Query object is callable; `q(estore)` runs it.

Systems are `function(estore, input, res)`. Always prefer `defineQuerySystem(args, fn)` (returned to module so `composeSystems` can resolve):

```lua
return defineQuerySystem(
  { "tr", "vel" },
  function(e, estore, input, res)
    e.tr.x = e.tr.x + e.vel.dx * input.dt
    e.tr.y = e.tr.y + e.vel.dy * input.dt
  end
)
```

A system file may also export `{system=fn}`, `{updateSystem=fn}`, or a constructor under `new`/`newSystem` — `resolveSystem` (`ecshelpers.lua:17`) finds it. Listed in resources.lua under `systems.data` as a `require`-style path string. Order matters; gameplay systems come after `keystate`/`controller_state`/`physics` in conventional ordering — but actually in this project gameplay is BEFORE input systems because `keystate` resets `pressed` at start-of-tick (so gameplay reads last tick's presses then keystate refreshes). Match the existing order in `modules/asteroids/resources.lua` unless you have a specific reason.

Draw systems are `function(estore, res)` (no `input`). Same registration pattern; resolved with `systemKeys = { "drawSystem" }`. The asteroids module uses one: `castle.drawing.scenegraph_system2`. Composition uses `makeFuncChain2` (3-arg systems get the rest of the chain as third param — useful for transform push/pop wrappers).

`world.input` carries `{dt, events}`. Events are consumed via `castle.systems.eventhelpers`:

```lua
EventHelpers.handle(input.events, "keyboard", {
  pressed = function(evt) ... return false end,  -- false = don't consume
  released = function(evt) ... end,
})
EventHelpers.handleKeyPresses(input.events, {
  ["space"] = function(evt) fire() end,
})
EventHelpers.on(input.events, "controller", function(evt) ... return true end)  -- true = consume
```

State helper (`vendor/castle/state.lua`): `State.get(e, name)`, `State.set(e, name, val)`, `State.toggle(e, name)`. Operates on `state` components keyed by `name`. Used heavily in jigs and dev controllers.

`Estore:clone({keepCaches=bool})` deep-clones the whole store (used by editor history). Object-pool–backed cleanCopy makes this cheap.

## Resources

Resources flow from a manifest file (e.g., `modules/asteroids/resources.lua`). It returns a list of typed configs. Each config has `type` and either `data` (inline) or `datafile` (path to lua file returning the data). Some carry a `file` for `resource_file` recursion.

Loader types (`vendor/castle/resourceloader.lua` plus `vendor/castle/ecs/loaders.lua`):

- `ecs` (one entry, name="main"): `data.entities = {datafile=...}` (file must export `initialEntities(res) -> Estore`); `data.components = {datafile=...}` (file returns map `{typeName = {field, default, ...}}`); `data.systems.data = {require_paths}`; `data.drawSystems.data = {require_paths}`.
- `settings`: stored in `res.settings:get(name)`. `name="resource_loader"` controls `lazy_load = {pics=true, picStrips=true, anims=true, sounds=true}` and `realize_on_module_load = true|false`. `name="mydebug"` toggles per-module `MyDebug` flags.
- `data`: opaque lua data into `res.data:put(name, ...)`.
- `resource_file` (`{type="resource_file", file=path}`): inlines another manifest file. Used to split asset lists.
- `pic`: `{type="pic", name, data={path, rect?, sx?, sy?}}` → `res.pics:get(name)` returns `{filename, image, quad, rect, sx, sy, duration, frameNum}`.
- `picStrip`: `{type="picStrip", name, data={path, picWidth, picHeight, picOptions, count?, pics?, anims?}}`. Slices a sheet; can publish individual `pics[name]=index` lookups and `anims[name]=animSpec` into `res.anims`.
- `picaliases`: `{type="picaliases", data={alias=picId, ...}}` (aliases must point at already-loadable pics; supports lazy targets).
- `anim`: `{type="anim", name, data={path_prefix, frame_duration, sx, sy, pics={...}}}`.
- `sound` / `music`: `{type="sound", name, data={file, volume?, music?, duration?}}`. Music streams; sounds load SoundData and auto-detect duration.
- `font`: `{type="font", name, data={file, choices={size_or_{name,size}, ...}}}`. Auto-creates `<name>_default` and `<name>_<choice>` keys in `res.fonts`.

`res` access from systems and entity factories:

```lua
local picRes = res.pics:get("ship_example_05")
local animRes = res.anims:get("debris_explosion_1")
local frame = animRes.getFrame(timer.t)
res.data:put("screen_size", { width=w, height=h })
local size = res.data.screen_size            -- direct access also works after :put
```

Lazy load + realize_on_module_load = "all assets built when this module wakes up, but not at app boot". This is the asteroids default. Toggle either via the `resource_loader` settings entry.

`getData(cfg)` supports two transforms via cfg keys: `expandDatafiles=true` recursively swaps `{datafile=path}` placeholders, `dataconverter={require="mod", func="fn"}` post-transforms loaded data. Use these to keep data files small and modular.

## Drawing

Single active draw system: `castle.drawing.scenegraph_system2`. It expects a `main_scene` entity at the top of the tree; from there it recurses with `drawEntity(e, res, viewportEnt)`. Each entity:

1. `computeEntityTransform2(ent, relativeTo, viewportEnt)` — accumulates `tr` from root down. If ent has `paralax` AND a `viewportEnt` is in scope, `applyParalax` modifies the transform.
2. `love.graphics.push()` and apply.
3. If ent has a `viewport` comp, `drawViewport2` resolves `viewport.scene` and `viewport.camera` by name; optionally fills bgcolor; optionally stencils to `box`; applies the camera's INVERSE transform; recursively draws the scene with the viewport in scope.
4. Runs registered DrawFuncs over the entity. In order: screengrid, pic, anim, geom (box/rect/circle/radius), button, physics, label, sound (pings soundmanager), touch_debugs, devgrid, devbg, tilingBackground.
5. Recurse into children.
6. `love.graphics.pop()`.

Viewport pattern (see `modules/asteroids/entities/scene_based.lua`):
- `main_scene` holds a `viewport` entity referencing `scene = "scene1", camera = "camera1"` by name. Scene and camera live elsewhere in the estore.
- `scene1` holds `space_bg` (tiling backgrounds with parallax), `world1` (the world entities), and the `camera1` entity.
- The viewport entity has a `box` whose `w/h` defines the viewport rect; combined with `blockout=true` it stencils.

`paralax` component: `{px, py}`. 1=locked-to-camera, 0=move-with-world, 0.5=half-speed background, negative=anti-camera. Implementation has a `mysterious_correction = 0.5` factor flagged unexplained in code; preserve it when modifying. Don't roll your own parallax — use this component.

`tilingBackground` component (zero-arg) combined with a `pic` and optional `paralax` makes the entity tile its image to fill the viewport's visible AABB exactly. Use this for skies/starfields/grids.

`devgrid` + `devbg` are debug aids using the same viewport-AABB-intersection trick. Use them when debugging coordinate spaces.

DO NOT USE `castle.drawing.scenegraph_system` (the old one) or `castle.ecs.viewport_helpers.findOwningViewport*` (decommissioned, throws). All new draw code threads `viewportEnt` through explicitly.

`computeEntityTransform` (in `ecshelpers`) is the OLDER non-paralax-aware version. Use `computeEntityTransform2` from inside scenegraph_system2 contexts; otherwise the old one is fine for non-rendering math like firing-direction calculation (see `modules/asteroids/entities/ship.lua:120`).

## Built-in systems (what you can rely on)

- `castle.systems.timer`: ticks every `timer` comp. `countDown=true` (default) decrements `t` from initial value; `countDown=false` increments. On reaching threshold sets `timer.alarm=true` and emits `timer.event` (if non-empty) into `input.events`. Honors `factor` (dt scale) and `loop` (resets to `reset` value).
- `castle.systems.selfdestruct`: destroys entities tagged `self_destruct` whose `timer.self_destruct.alarm` is true. Use the helper `selfDestructEnt(e, seconds)` from `ecshelpers` instead of doing it manually.
- `castle.systems.anim`: pairs `anim` with `timer` named to match. Reads `res.anims:get(anim.id).duration` lazily. Honors `anim.onComplete = "repeat"|"expire"|"selfDestruct"`.
- `castle.systems.physics`: Box2D wrapper. Runs on `physicsWorld` entities. Syncs `tr/vel/force` to bodies, steps the world, syncs back. Force impulses (`force.impx/y`, `force.angimp`) are zeroed each tick after apply. Collision pairs become `contact` components on each entity; iterate with `for _, contact in pairs(e.contacts or {}) do ...`. `body.categories` / `body.mask` are bitmask filters (use `bit.lshift`/`bit.bor`).
- `castle.systems.follower`: copies `tr.x/y` from the entity whose `followable.targetname` matches. No smoothing.
- `castle.systems.sound`: accumulates playtime; removes `sound` comp when one-shot duration exhausted. Music persists.
- `castle.systems.touch`: consumes `touch` events; when a press hit-tests against a `touchable` (using `seekEntityBottomUp` for draw-order-correct hit testing), attaches a `touch` comp; `released` touches live one tick.
- `castle.systems.touchbutton`: when `touch` and `button` co-exist, `kind="hold"` arms a `holdbutton` timer and emits `{type=button.eventtype, state=button.eventstate, eid, cid}` on alarm.
- `castle.systems.tween`: applies `tween` interpolation each tick using the named timer. Build via `TweenHelpers.tweenit(e, name, {comp={prop=to}}, {duration, easing})` from `castle.tween.tween_helpers`. Available easings live in `castle.tween.easing` (linear, outQuint, inQuad, etc.).
- `castle.systems.keystate`: per-entity `keystate` comp captures keyboard. Only keys listed in `keystate.handle` are tracked. `consume=true` removes events from queue. Reads as `e.keystate.pressed.up`, `e.keystate.held.space`, `e.keystate.released.space`.
- `castle.systems.controller_state`: same idea for joystick. Comp has `match_id` (e.g. `"joystick1"`); axis values land in `value.leftx`/`value.lefty`, buttons in `held.face1`/`pressed.face1`/`released.face1`.

`castle.soundmanager` is a singleton called by `draw_sound_entities` each draw to ping/keep alive sounds; `castle.main.love.draw` invokes `soundmanager.cleanup()` to stop unping'd ones. Don't manage `love.audio.Source` lifecycles by hand.

## Common patterns

Spawn-and-forget effect: create entity with `anim` (`onComplete="selfDestruct"`) and optional `sound`; the systems will tear it down. See `modules/asteroids/entities/explosion.lua`.

Cooldown gate: `cooldown` comp + `cooldown` system. `Cooldown.isReady(e, name)` / `Cooldown.trigger(e, name)` (modules/asteroids/systems/cooldown.lua). The system flips state back to "ready" when the named timer alarms.

Camera follow: target gets `{followable={targetname="x"}}`, follower gets `{follower={targetname="x"}}`. The asteroids project does this on the camera entity.

Ship-firing pattern: child entities tagged `gun_muzzle_left`/`gun_muzzle_right` with their own `tr`; firing logic uses `seekEntity(hasTag("gun_muzzle_..."))`, `computeEntityTransform(muzzle, parent)` to translate firing direction into the parent's space, then spawns a bullet at that location/velocity. See `modules/asteroids/entities/ship.lua:115`.

Switching gameplay modes: the "jig" pattern. A workbench entity carries `{state name="jig"}` plus a `keystate` listening for digit keys. A dispatcher system tears down current jig and constructs a new one. Each jig is a table with `{init(parent, estore, res), update(estore, input, res), finalize(jigE, estore)}`. See `modules/asteroids/systems/ship_workbench_system.lua` (currently disabled in resources.lua, but pattern is intact).

Debug logging: `local Debug = require("mydebug").sub("Tag", true, true); Debug.println("...")`. Toggle per-tag via the `mydebug` settings entry in resources.lua.

## Things to NOT do

- Don't add a new state-management approach. Use components + systems.
- Don't write your own require/reload mechanism; emit `castle.reloadRootModule` sidefx.
- Don't iterate `estore.ents` or `estore.comps` directly to find things; use queries/indexes.
- Don't manage `love.audio.Source` lifecycles; use `sound` components + `soundmanager`.
- Don't write your own scenegraph or push/pop transforms in a custom draw loop unless extending `scenegraph_system2`. Add a DrawFunc instead.
- Don't use `viewport_helpers.findOwningViewportCamera` — decommissioned.
- Don't use `scenegraph_system` (the v1) — use `scenegraph_system2`.
- Don't define helper components with names that collide with built-ins in `vendor/castle/components.lua`.
- Don't keep cross-tick state in module-local Lua variables; put it on an entity (use `state` comps or a singleton-named entity).
- Don't bypass `Estore:newEntity` / `Estore:newComp` to fabricate components — the object pool, indexes, and parent-linkage all live behind those methods.
- Don't capture `dt` from anywhere but `input.dt` inside a system.
- Don't write blocking loops in `update`; emit timers/tweens.
- Don't write `print` for transient diagnostics; use a `mydebug` sub-logger that can be toggled.

## Files an agent should read on first contact

`vendor/castle/main.lua` (love wiring), `vendor/castle/ecs/ecsadapter.lua` (tick/draw lifecycle), `vendor/castle/ecs/estore.lua` (data model + tree + queries), `vendor/castle/components.lua` (built-in comp catalog), `vendor/castle/ecs/ecshelpers.lua` (globals), `vendor/castle/resourceloader.lua` (manifest pipeline), `vendor/castle/drawing/scenegraph_system2.lua` (active draw pipeline), `modules/asteroids/resources.lua` (real-world manifest), `modules/asteroids/entities/scene_based.lua` (real-world scene tree), `modules/asteroids/systems/ship_controller.lua` (real-world system).

If you can't find a function with `require`, it's a global from helpers. If a system file looks weird, it's probably an `EventHelpers`-driven event consumer. If draw code looks off, you're in the v1 scenegraph — switch to v2.
