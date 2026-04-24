# Entities

Every entity factory in the asteroids module, organized by file. Each lists what entity is produced, its component composition, and any child entities.

## Active scene tree (built by `scene_based.populate`)

[`modules/asteroids/entities/scene_based.lua`](../../modules/asteroids/entities/scene_based.lua)

`SceneBased.populate(estore, res)` builds the active scene during `initialEntities`. The resulting tree:

```
estore (root)
├── main_scene                      (name="main_scene")
│   └── viewport                    (name="viewport")
│       comps: viewport{scene="scene1",camera="camera1",blockout=true,
│                       bgcolor={0,0.4,0},use_bgcolor=false},
│              tr{x=screenW/2,y=screenH/2,cx=0,cy=0},
│              box{w=screenW,h=screenH,cx=0.5,cy=0.5,debug=false}
├── scene1                          (name="scene1")
│   ├── space_bg                    (name="space_bg")
│   │   ├── (nebula entity)
│   │   │   comps: tilingBackground, pic{id="nebula_blue"},
│   │   │          paralax{px=0.25,py=0.25}
│   │   └── (stars entity)
│   │       comps: tilingBackground, pic{id="starfield_1"},
│   │              paralax{px=0.75,py=0.75}
│   └── world1                      (name="world1")
│       ├── camera1                 (name="camera1")
│       │   comps: tr{x=0,y=0}, follower{targetname="playership"}
│       ├── physics_world           (name="physics_world")
│       │   comps: physicsWorld{allowSleep=false}
│       └── ship                    (built by Ship.ship — see below)
└── camera_dev_controller           (name="camera1_dev_controller")
    comps: tag{name="camera_dev_controller"},
            state{name="camera",value="camera1"},
            state{name="debug",value=false},
            keystate{handle={"[","]","-","=","0","w","a","s","d"}}
```

Note: `main_scene`, `scene1`, and `camera_dev_controller` are siblings at root level. The viewport's `viewport.scene = "scene1"` reference is what wires the rendering hierarchy together at draw-time, not the parent/child tree.

## Ship

[`Ship.ship(parent, res)`](../../modules/asteroids/entities/ship.lua#L9) returns a ship entity composed thus:

```
ship                                 (name="ship")
  comps:
    tr {}                            -- defaulted, position=0,0
    vel {}
    controller_state{match_id="joystick1"}
    keystate{handle={"left","right","up","down","space"}}
    ship_controller{}
    body{mass=5, friction=0, restitution=0.3,
         categories=Coll.Ships, mask=Coll.Roids, debug=true}
    force{}
    circleShape{radius=40}
    cooldown{name="lasers", t=0.1, state="ready"}
    box{w=100,h=100,cx=0.5,cy=0.5,debug=true}
    pic{id="ship_example_05",sx=0.75,sy=0.75,cx=0.5,cy=0.5,debug=true}

  children:
  ├── (untagged box debug entity)
  │   comps: box{w=200,h=200,cx=0.5,cy=0.5,debug=true}
  ├── (left muzzle)
  │   comps: tag{name="gun_muzzle"},
  │          tag{name="gun_muzzle_left"},
  │          tr{x=-22,y=-9}
  ├── (right muzzle)
  │   comps: tag{name="gun_muzzle"},
  │          tag{name="gun_muzzle_right"},
  │          tr{x=22,y=-9}
  └── (flame)
      comps: tag{name="ship_flame"},
             tr{y=30},
             pic{name="flame",id="ship_flame_06",
                 sx=0.75,sy=0.75,cx=0.5,cy=0,color={1,1,1,0}},
             timer{name="flame",reset=1,countDown=false,loop=true}
```

The muzzles are pure transform sentinels — no visual. They're located by `seekEntity(hasTag("gun_muzzle_<side>"))` from `Ship.fireBullet`.

The flame's color alpha is initially 0 (invisible); ship_controller toggles it.

The flame's `timer` ticks up forever (countDown=false, loop) and resets at 1 second. test_flight modulates `flame.pic.sy` based on `sin(timer.t * 8π) * 0.1` for a flicker effect.

`Ship.fireBullet(ship, side, bulletPicId, bulletSpeed)` ([`ship.lua:115`](../../modules/asteroids/entities/ship.lua#L115)) creates a bullet entity as a sibling of the ship (parented to `ship:getParent()`):

```
ship_bullet_<side>                  (name="ship_bullet_<side>")
  comps:
    tag{name="ship_bullet"}
    tr{x,y from muzzle, r from muzzle facing direction}
    vel{dx,dy = direction * bulletSpeed}
    pic{name="bullet",id=bulletPicId,sx=1,sy=1,cx=0.5,cy=0.5}
    radius{radius=10,debug=false}
  + selfDestructEnt(2.0)            -- adds tag & timer for 2s lifespan
```

After the call, ship_controller adds `body{mass=0.5,...,Coll.Lasers,Coll.Roids}`, `force{}`, `circleShape{radius=7}` to enable physics, and the right bullet additionally gets `sound{sound="laser_small"}`.

## Asteroids

[`Roids.roid(parent, opts)`](../../modules/asteroids/entities/roids.lua#L105):

```
(unnamed roid, optional name=opts.name)
  comps:
    tag{name="roid"}
    tr{x=opts.x, y=opts.y}
    vel{}
    pic{id=opts.picId, cx=0.5, cy=0.5,
        sx=opts.size, sy=opts.size, color=opts.color, debug=false}
    radius{radius=opts.radius, debug=opts.debugHit}
    health{hp=opts.hp}
    body{mass=opts.mass (default π·r²), friction=0.8, restitution=0.9,
         categories=Coll.Roids,
         mask=bit.bor(Coll.Roids, Coll.Lasers, Coll.Ships),
         debug=opts.debugBody}
    force{}
    circleShape{radius=opts.radius}
```

`Roids.random(parent, opts)` is the higher-level factory: takes `opts.sizeCat` ∈ `small | medium | medium_large | large | huge`, picks a random sprite from that category's `SpriteConfigs`, looks up `radius` and `hp` from the maps, and calls `Roids.roid`.

Size category attributes:

| sizeCat | radius (px) | hp |
|---|---|---|
| small | LargeRadius·0.2 = 13 | 1 |
| medium | LargeRadius/2.4 ≈ 27 | 2 |
| medium_large | 3·LargeRadius·0.2 = 39 | 3 |
| large | LargeRadius = 65 | 6 |
| huge | 2.75·LargeRadius ≈ 179 | 12 |

Sprite catalog per size cat (`SpriteConfigs.<cat>`) consists of `{picId, size}` entries. The `size` is the per-pic scale-factor needed to make any pic look like a given size category. E.g., a `roid_large_grey_01` rendered at `size=0.2` looks like a small roid.

Roids are not spawned in the active scene_based path. The test_flight jig spawns 100 of them via `generateRoidField(jig, 100, -4000, 4000)`.

## Explosions

[`Explosion.explosion(parent, opts)`](../../modules/asteroids/entities/explosion.lua#L5):

```
(unnamed by default; opts.name can name)
  comps:
    tag{name="explosion"}
    tr{x=opts.x, y=opts.y, r=randomFloat(0,2π)}
    anim{name="splode",
         id=animId,                  -- "debris_explosion_<n>" or opts.animId
         sx=opts.size, sy=opts.size,
         cx=0.5, cy=0.5,
         onComplete="selfDestruct"}
    timer{name="splode", countDown=false, factor=opts.animSpeed}
```

`animId` selection:
1. `opts.animId` — explicit override.
2. `opts.num` (1-6) — selects `"debris_explosion_<num>"`.
3. otherwise — random num in `[1, 6]`.

Lifecycle: the `anim` system observes `timer.t > duration` and (because `onComplete="selfDestruct"`) invokes `estore:destroyEntity(e)` automatically.

For belt-and-suspenders, `Battle.destroyRoid` adds a `selfDestructEnt(expl, 3.0)` second timer, and `Battle.bulletHitsRoid` adds `selfDestructEnt(expl, 1.0)` for strike effects.

## Workbench / dev backgrounds

[`Workbench.workbench(parent, res)`](../../modules/asteroids/entities/workbench.lua#L5) — alternate top-level entry. Calls `W.basicWorldAndViewport`, `W.camera_dev_controller`, then creates a `ship_workbench` entity:

```
ship_workbench
  comps:
    name="ship_workbench"
    state{name="jig", value=""}        -- starts empty, dispatcher fills with default
    state{name="debug_draw", value=false}
    keystate{handle={"1","2","3","4","5","6"}}
```

The `ship_workbench_system`, when enabled, watches this entity.

[`Workbench.dev_background(parent, res)`](../../modules/asteroids/entities/workbench.lua#L16) — Creates a `devbackground` entity with 9 tiled `pic{id="example_background"}` comps in a 3×3 layout (1000×1000 each, offset by `-1500`). Used by jigs for the example_background image.

[`Workbench.dev_background_nebula_blue`](../../modules/asteroids/entities/workbench.lua#L59), [`dev_background_starfield1`](../../modules/asteroids/entities/workbench.lua#L83), and [`dev_background_starfield2`](../../modules/asteroids/entities/workbench.lua#L104) — same pattern but for 4096×4096 tiles, with `paralax{px=0.5/0.8/0.5}`. (Note: `dev_background_starfield2` has a bug — the inner loop assignment to `comps` is missing; only the entity from outside the loops gets created.) Used by the older bg approach. The active scene_based path uses `tilingBackground` instead.

[`Workbench.flameMenu(parent, res)`](../../modules/asteroids/entities/workbench.lua#L127):

```
flame_menu                          (name="flame_menu")
  comps:
    tr{x=20, y=screenH-80}
    state{name="selected", value=6}
    keystate{handle={"j","k"}}
    label{text="j,k: select flame | up,down: adjust flame", y=-20}
  children:
    11 menu tiles, one per ship_flame_<n> for n in 01..11:
      tr{x=(i-1)*50}, pic{id="ship_flame_<n>", sx=0.5,sy=0.5,y=20,x=25,cx=0.5},
      label{text=tostring(i), align="middle", w=50, h=20}
    menu_cursor                     (name="menu_cursor")
      comps: tr{x=(initial-1)*50}, rect{w=50,h=70,color={1,1,1,1}}
```

[`Workbench.bulletMenu(parent, res)`](../../modules/asteroids/entities/workbench.lua#L180) — same shape with 12 ship_bullets sprites and slightly different label text. Used by `bullet_editor`.

## World factories

[`W.basicWorldAndViewport(estore, res, opts)`](../../modules/asteroids/entities/world.lua#L3) — Creates a viewport, a world entity (default name `world1`), and a camera (default name `camera1`). Returns `world, viewport, camera`. Used by Workbench.workbench.

[`W.viewport(parent, res, cameraName)`](../../modules/asteroids/entities/world.lua#L16):

```
viewport
  comps: name="viewport", viewport{camera=cameraName},
         tr{}, box{w=screenW,h=screenH,debug=false}
```

(Note: this older factory does NOT set `viewport.scene`, so it relies on the default which is `''` — incompatible with `scenegraph_system2`. The scene_based factory builds its viewport directly.)

[`W.camera(parent, res, name)`](../../modules/asteroids/entities/world.lua#L26):

```
(parent's child)
  comps: tag{name="camera"}, name=cameraName, tr{x=0,y=0}
```

[`W.camera_dev_controller(parent, name)`](../../modules/asteroids/entities/world.lua#L37):

```
(camera_dev_controller entity)
  comps: name=<name>+"_dev_controller",
         tag{name="camera_dev_controller"},
         state{name="camera", value=name},
         state{name="debug", value=false},
         keystate{handle={"[", "]", "-", "=", "0", "w", "a", "s", "d"}}
```

## Jig entities (when workbench is enabled)

Each jig creates a top-level entity named after itself (e.g., `"test_flight"`). Most also create a `physics_world` entity, dev backgrounds, a ship, and category-specific gameplay entities. See [`modules/asteroids/jigs/`](../../modules/asteroids/jigs) for full bodies; key compositions:

### test_flight

Tagged `"jig"`, named `"test_flight"`, has `keystate{handle={"return"}}` for the keyboard/joystick toggle, and `state{name="control_mode", value="keyboard"}`. Children include:
- A `physics_world` entity.
- Two background entities (nebula + starfield_1, via Workbench.dev_background_*).
- 100 random roids over a 8000×8000 area.
- A ship (via `Ship.ship`).

### bullet_editor

Named `"bullet_editor"`, `keystate{handle={"up","down","left","right",",","."}}`. Children: dev_background, ship, two pre-fired bullets, plus a `bullet_menu` (via Workbench.bulletMenu).

### flame_editor

Named `"flame_editor"`. Children: dev_background, a ship with the flame already revealed (`pic.color[4] = 1`), plus a `flame_menu`.

### roid_browser

Named `"roid_browser"`, `keystate{handle={"up","down","left","right",",",".","c"}}`. Children: dev_background, a `roid_menu` (via local Jig.newRoidMenu over `Roids.PicIds`), the currently selected `the_roid` entity. `c` toggles a multi-row `the_chart` of all roid sprites.

### explosion_browser

Named `"explosion_browser"`, `keystate{handle={"left","right","space"}}`, `state{name="tab", value=1}`. Tabs implemented as a list of `{enter(jig,estore), leave(jig,estore)}` callbacks. Each tab creates and tears down a child entity (`splode_overview`, `splode_single`, `nukeit`). The `nukeit` tab includes a moving roid that space-bar destroys via `Battle.destroyRoid`.

## Battle helpers

[`battle_helpers.lua`](../../modules/asteroids/battle_helpers.lua) is not strictly an entity factory, but it produces transient entities:

- `M.generateBulletStrike(bullet, contact, roid)` — creates a small `Explosion.explosion` at `contact.x,y` with `size=0.5, animSpeed=2`, then `selfDestructEnt(expl, 1.0)`.
- `M.bulletHitsRoid(bullet, contact, roid)` — generates a strike, calls `damageEntity(roid, 1)`, and if hp depleted calls `M.destroyRoid(roid)`. Then `bullet:destroy()`.
- `M.destroyRoid(roid)` — removes the roid's `health` comp, `selfDestructEnt(roid, 0.2)`, creates a large `Explosion.explosion` (size=2.5, animSpeed=0.8) named `roidsplode`, attaches `sound{sound="medium_explosion_1"}`, and `selfDestructEnt(expl, 3.0)`.
- `M.generateShipStrike(ship, contact, roid)` and `M.shipHitsRoid(ship, contact, roid)` — analogous to the bullet ones but the roid damage path is currently commented out (only a strike effect is generated).

## Conventions when adding entities

- **Always parent under the right scene branch.** Things in the world go under `world1`. Things in the background go under `space_bg`. Things in the HUD go directly under `main_scene` (not in a viewport).
- **Name entities you'll need to find.** `getEntityByName` is the lookup; without a `name` comp you'll need a query.
- **Tag entities you'll need to find collectively.** Use queries on tags.
- **For temporary entities, attach a self-destruct.** `selfDestructEnt(e, seconds)` is the standard way to schedule cleanup.
- **For physical entities, build the trio.** `body + force + circleShape` (or `rectangleShape`/etc.) plus a `tr` and usually `vel`.
- **For visual entities, choose `pic` for static, `anim` for sequential.** Both honor `cx,cy,sx,sy,color`.
