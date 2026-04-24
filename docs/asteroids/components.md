# Components

Every component type used by this project, with fields, defaults, and where they are produced/consumed.

> Built-in component types ship from castle ([`vendor/castle/components.lua`](../../vendor/castle/components.lua)). Project-specific types live in [`modules/asteroids/components.lua`](../../modules/asteroids/components.lua) and a couple of inline `Comps.define(...)` calls.

## Where defined

| Source | Components |
|--------|------------|
| [`vendor/castle/components.lua`](../../vendor/castle/components.lua) | All built-ins below |
| [`vendor/castle/ecs/component.lua:126`](../../vendor/castle/ecs/component.lua#L126) | `parent`, `name` (defined alongside the comp module itself) |
| [`vendor/castle/systems/controller_state.lua:5`](../../vendor/castle/systems/controller_state.lua#L5) | `controller_state` |
| [`vendor/castle/drawing/scenegraph_system2.lua:46`](../../vendor/castle/drawing/scenegraph_system2.lua#L46) | `devgrid`, `devbg`, `tilingBackground` |
| [`modules/asteroids/components.lua`](../../modules/asteroids/components.lua) | `health`, `cooldown`, `ship_controller` |
| [`modules/asteroids/systems/boxthinger.lua:3`](../../modules/asteroids/systems/boxthinger.lua#L3) | `boxthing` |

## Project-defined components

### `health`
Defaults: `{ hp = 10 }`.
- **Produced by**: [`Roids.roid`](../../modules/asteroids/entities/roids.lua#L131) (sets hp from the size category map).
- **Consumed by**: [`Battle.damageEntity`](../../modules/asteroids/battle_helpers.lua#L7) (decrements `hp`); [`Battle.destroyRoid`](../../modules/asteroids/battle_helpers.lua#L36) (removes the comp to prevent double-destruction).
- **Notes**: An entity without a `health` comp returns `false` from `damageEntity` — i.e., is invulnerable. Removing the comp mid-frame is a defensible "I am dying, do not double-kill me" sentinel pattern.

### `cooldown`
Defaults: `{ t = 1, state = "ready" }`.
- **Produced by**: [`Ship.ship`](../../modules/asteroids/entities/ship.lua#L31) (`name="lasers", t=0.1`).
- **Consumed by**: [`modules.asteroids.systems.cooldown`](../../modules/asteroids/systems/cooldown.lua); helpers `Cooldown.isReady`, `Cooldown.trigger`.
- **Notes**: Pairs with a `timer` comp of the same name. The cooldown system flips state from `"cooldown"` back to `"ready"` when that timer alarms, and removes the timer.

### `ship_controller`
Defaults: `{ dx = 0, dy = 0, turn = 0, accel = 0, fire_gun = 0 }`.
- **Produced by**: [`Ship.ship`](../../modules/asteroids/entities/ship.lua#L17).
- **Consumed by**: [`modules.asteroids.systems.ship_controller`](../../modules/asteroids/systems/ship_controller.lua); also written to by [`update_ship_controller.lua`](../../modules/asteroids/jigs/update_ship_controller.lua) (used by test_flight).
- **Notes**: This is the abstraction layer between input source (keyboard or controller) and the ship's physical actuation. Setting `accel=1` engages thrust; `turn=±1` engages spin; `fire_gun=1` engages weapon (cooldown-gated).

### `boxthing`
Defaults: `{}` (just a marker).
- **Produced by**: nothing in the active game (the `boxthinger` system is included in the systems list but no entity has the comp).
- **Consumed by**: [`boxthinger.lua`](../../modules/asteroids/systems/boxthinger.lua) — rotates `tr.r` and translates `tr.y` from arrow-key keystate.
- **Notes**: Vestigial. Add it to an entity to make that entity arrow-controlled for debugging.

## Built-in components used by this project

### `name` and `tag`
- `name` — `{ name = "" }`. Indexed by `byName`; supports `getEntityByName`.
- `tag` — `{ name = "" }`. Indexed by `byTag`; supports tag-based queries (`Query.create({tag="foo"})`).
- An entity may carry multiple `tag` comps (different `name` per comp). The ship has muzzle children with two tags each: `gun_muzzle` + `gun_muzzle_left`.

### `tr`
`{ x=0, y=0, r=0, sx=1, sy=1, cx=0, cy=0 }`. Position, rotation, scale, center-of-rotation.
- Used everywhere a thing has a location.
- The scenegraph composes `tr` values down the parent chain; world-space transform is the product.

### `paralax`
`{ px=1, py=1 }`. Per-axis parallax factor. Applied during draw if a `viewportEnt` is in scope.
- Used on space_bg's nebula (`0.25, 0.25`) and stars (`0.75, 0.75`).
- 0 = locked to world, 1 = locked to camera.

### `state`
`{ value = "" }`. Generic key-value carrier; access via `castle.state` helpers (`State.get/set/toggle`). Multiple states per entity are keyed by `name`.
- Used heavily in jigs (`control_mode`, `selected`, `tab`, `jig`, `menu_eid`).

### `box`, `radius`
- `box`: rect + debug flag. The viewport's `box` defines its rect; the ship has a `box` for debug visualization.
- `radius`: circular hit-testing radius. Roids and bullets use it.

### `timer`
`{ t=0, factor=1, reset=0, countDown=true, loop=false, alarm=false, event='' }`.
- Used by anim, cooldown, selfdestruct, ship_flame animation, etc.
- See [docs/castle/systems.md](../castle/systems.md) for full semantics.

### `followable`, `follower`
- Camera entity has `follower {targetname="playership"}`.
- The ship would have `followable {targetname="playership"}` — but in the active scene_based path that line is **commented out** (`scene_based.lua:92`). So follow-mode isn't operative in the active scene. `test_flight` jig instead manually copies `ship.tr.x/y` onto camera each tick.

### `viewport`
`{ scene='', camera='', blockout=true, bgcolor={0,0,0}, use_bgcolor=false }`.
- Single instance: the `viewport` entity under `main_scene`. References `scene="scene1"`, `camera="camera1"`. `blockout=true` enables stencil clipping. `use_bgcolor=false` (so castle's BGColorSystem clears with the global default).

### `bgcolor`
Not currently used by this project. (BGColor is set globally by Love2D via `setBackgroundColor` from the BGColorSystem.)

### `pic`
PicAttrs (extends `tr`): `{ id='UNSET', cx=0, cy=0, color={1,1,1,1}, debug=false, x, y, r, sx, sy }`.
- Hugely common: ships, roids, bullets, flame, backgrounds, menu items.
- `id` references `res.pics:get(id)`.
- `cx/cy` are the *center-of-pic* ratios (0..1). 0.5 centers.

### `anim`
PicAttrs + `{ duration=-1, timer='', timescale=1, onComplete='repeat' }`.
- Explosions use it (`onComplete='selfDestruct'`).
- Pairs with a `timer` comp; the `timer` field defaults to the anim's own name. `t` value is used to look up the current frame.

### `rect`, `circle`, `label`
- `rect`: filled or outlined rectangle. Used for menu cursor (`50×70` white outline).
- `circle`: outline circle. Used in dev visualizations.
- `label`: text. Used in menus, roid_browser charts, explosion_browser tab labels.

### `sound`
`{ sound='', music=false, loop=false, state='playing', volume=1, playtime=0, duration=0 }`.
- Attached temporarily to entities to play sounds.
- The right-side bullet gets `sound="laser_small"`; explosions get `sound="medium_explosion_1"`.
- Auto-removed when playtime exceeds duration (for non-music, non-loop).

### `tween`
- Indirectly created by `TweenHelpers.tweenit/addTweens`. The asteroids module uses tweens via the camera dev system and by `roid_browser.lua` and `menu.lua`.

### `physicsWorld`, `body`, `vel`, `force`, `circleShape`
- Single `physicsWorld` per active scene (in `world1`).
- `body` carries mass/friction/restitution/categories/mask plus debug flag.
- `vel` carries velocity (linear + angular + damping).
- `force` carries pending forces/impulses; system clears them post-apply.
- `circleShape` carries a radius (rectangleShape, polygonShape, chainShape are also available built-ins, just not used here).
- See [docs/castle/systems.md#physics](../castle/systems.md) for system behavior.

### `keystate`
`{ handle={}, consume=false, pressed={}, held={}, released={} }`.
- Lists the keys an entity tracks. Every entity that wants keyboard input has one.
- In this project: ship (`left/right/up/down/space`), camera_dev_controller (`[ ] - = 0 w a s d`), test_flight jig (`return`), various editors and browsers.

### `controller_state`
`{ match_id='', value={}, pressed={}, held={}, released={} }`.
- Ship has one (`match_id="joystick1"`).
- Updated by `castle.systems.controller_state`; values appear in `value.leftx`, `value.lefty`, `held.face1`, etc.

### `parent`
Built-in. Not constructed by user code; auto-injected by `Entity:newChild`.

### `contact`
Built-in. Auto-attached to entities by the physics system on Box2D collision begin. Carries `otherEid, nx, ny, x, y, dx, dy, myCid, otherCid`.
- Read by jigs: `for _, c in pairs(e.contacts or {}) do … end`.

### `screen_grid`, `touchable`, `touch`, `button`
- Not currently used by the active scene.
- `screen_grid` is for debug grid overlays (handled by `draw_screengrid_entity.lua`).
- `touchable`/`touch`/`button` would drive on-screen touchable controls — currently no UI uses them.

## Inline-defined drawing components (from scenegraph_system2.lua)

### `devgrid`
`{ left=0, right=1000, top=0, bottom=1000, tilew=100, tileh=100, color={1,1,1}, dot_size=3, draw_coords=true, draw_coords_y=0 }`.
- Draws a grid of small dots with optional coordinate labels.
- Not currently used by the active scene.

### `devbg`
`{}` (marker).
- Draws a green-tinted tile pattern bound to the viewport AABB.
- Not currently used.

### `tilingBackground`
`{}` (marker).
- Used in tandem with a `pic`. Tiles the pic to cover the visible viewport AABB in the entity's local coord space.
- Active in the scene_based path: nebula and stars in `space_bg`.

## Composition rules

- An entity can have ANY combination of these components.
- The first comp of a type added to an entity becomes the singular shortcut: `e.tr`. The plural form `e.trs[name or cid]` lists all of that type.
- Component construction goes through `Estore:newComp` (or the `{type, data}` pair list to `newEntity`/`newChild`); this lets the indexer maintain `byCompType` so queries work.
- Removing a comp (`e:removeComp(comp)`) deindexes and may delete the entity if it was the last comp.

## Authoring guidance

- Prefer reusing existing component types rather than introducing new ones. The asteroids module's three project-specific comps (`health`, `cooldown`, `ship_controller`) are exemplary minimal additions.
- Don't redefine a built-in (no name shadowing).
- Components are **dumb data**. All behavior belongs in systems.
- Multi-instance components (e.g., multiple `tag` per entity, multiple `pic` per entity) are fine and used by the codebase. Reach for them when a single conceptual entity has several discrete pieces of the same kind.
