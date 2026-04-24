# Resources

Full inventory of assets declared by the asteroids module, organized by `*.res.lua` manifest file.

## Manifest entry-points

The top-level manifest [`modules/asteroids/resources.lua`](../../modules/asteroids/resources.lua) defines:

- One `ecs` config (`name="main"`).
- Two `settings` configs: `dev` (`bgmusic=false`) and `resource_loader` (lazy_load on pics/picStrips/anims/sounds + `realize_on_module_load=true`).
- Five `resource_file` references that recursively load other manifests.
- Two `sound` configs.
- One `font` config.

Resource categories at runtime (`res.<category>`):

| Category | Set type | Built from |
|---|---|---|
| `ecs` | LazyResourceSet | The `ecs` config block |
| `settings` | LazyResourceSet | `dev`, `resource_loader` (both eagerly built since they're not in `lazy_load`) |
| `data` | LazyResourceSet | Set up in `entities.lua`: `screen_size = {width,height}` |
| `pics` | LazyResourceSet | Pic configs across all manifests + alias mappings |
| `picStrips` | LazyResourceSet | `picStrip`-typed configs (only the explosions file uses these currently) |
| `anims` | LazyResourceSet | Anim definitions inside picStrip configs |
| `sounds` | LazyResourceSet | `sound`-typed configs |
| `fonts` | LazyResourceSet | `font`-typed configs (with auto `<name>_default` choice) |

## Pic resources

### Roids — [`images/roidpics.res.lua`](../../modules/asteroids/images/roidpics.res.lua)

23 entries. Sprites are organized in directories `images/{small,medium,large}/{grey,red,brown}/<variant>/`.

| Pic name (raw) | File path |
|---|---|
| `roid_small_grey_a1` | `small/grey/a1/a10000.png` |
| `roid_small_grey_b1` | `small/grey/b1/b10000.png` |
| `roid_small_red_a3` | `small/red/a3/a30000.png` |
| `roid_small_red_b3` | `small/red/b3/b30000.png` |
| `roid_small_brown_a4` | `small/brown/a4/a40000.png` |
| `roid_small_brown_b4` | `small/brown/b4/b40000.png` |
| `roid_medium_grey_a1` | `medium/grey/a1/a10000.png` |
| `roid_medium_grey_c1` | `medium/grey/c1/c10000.png` |
| `roid_medium_grey_d1` | `medium/grey/d1/d10000.png` |
| `roid_medium_red_a3` | `medium/red/a3/a30000.png` |
| `roid_medium_red_c3` | `medium/red/c3/c30000.png` |
| `roid_medium_red_d3` | `medium/red/d3/d30000.png` |
| `roid_medium_brown_a4`, `_b4`, `_c4`, `_d4` | `medium/brown/<x>/<x>0000.png` |
| `roid_large_grey_a1`, `_b1`, `_c1` | `large/grey/<x>/<x>0000.png` |
| `roid_large_red_a3`, `_b3`, `_c3` | `large/red/<x>/<x>0000.png` |
| `roid_large_brown_c4` | `large/brown/c4/c40000.png` |

### Roid aliases — [`images/roidaliases.res.lua`](../../modules/asteroids/images/roidaliases.res.lua)

A single `picaliases` config that maps numeric-suffix names → raw sprite names. The `Roids` module uses these aliases:

```
roid_small_grey_01  →  roid_small_grey_a1
roid_small_red_01   →  roid_small_red_a3
roid_small_grey_02  →  roid_small_grey_b1
roid_small_red_02   →  roid_small_red_b3

roid_medium_grey_01 →  roid_medium_grey_a1
roid_medium_red_01  →  roid_medium_red_a3
roid_medium_grey_02 →  roid_medium_grey_c1
roid_medium_red_02  →  roid_medium_red_c3
roid_medium_grey_03 →  roid_medium_grey_d1
roid_medium_red_03  →  roid_medium_red_d3

roid_large_grey_01  →  roid_large_grey_a1
roid_large_red_01   →  roid_large_red_a3
roid_large_grey_02  →  roid_large_grey_b1
roid_large_red_02   →  roid_large_red_b3
roid_large_grey_03  →  roid_large_grey_c1
roid_large_red_03   →  roid_large_red_c3
```

### Backgrounds — [`images/bg/backgrounds.res.lua`](../../modules/asteroids/images/bg/backgrounds.res.lua)

| Pic name | File | Notes |
|---|---|---|
| `example_background` | `images/example_background.png` | 1000×1000 dev tile |
| `starfield_1` | `bg/Stars Small_1.png` | active scene uses this |
| `starfield_2` | `bg/Stars Small_2.png` | |
| `starfield_3` | `bg/Stars-Big_1_1_PC.png` | |
| `starfield_4` | `bg/Stars-Big_1_2_PC.png` | |
| `nebula_blue` | `bg/NebulaBlue.png` | active scene uses this; `data` carries `sx=2, sy=2` so the resource loader scales the underlying pic 2×|
| `nebula_red` | `bg/NebulaRed.png` | |
| `nebula_aqua_pink` | `bg/NebulaAquaPink.png` | |

### Ship parts — [`images/ships/ship_pics.res.lua`](../../modules/asteroids/images/ships/ship_pics.res.lua)

Large file (988 lines, ~117 entries). Organized by category:

| Category | Pic names | Count |
|---|---|---|
| Bodyes A | `ship_bodyes_a_01` .. `_10` | 10 |
| Bodyes B | `ship_bodyes_b_01` .. `_10` | 10 |
| Bodyes C | `ship_bodyes_c_01` .. `_05` | 5 |
| Bullets | `ship_bullets_01` .. `_12` | 12 |
| Cabins | `ship_cabins_01` .. `_11` | 11 |
| Engines | `ship_engines_01` .. `_10` | 10 |
| Example | `ship_example_01` .. `_16` plus `ship_example_bg` | 17 |
| Flame | `ship_flame_01` .. `_11` | 11 |
| Guns A | `ship_guns_a_01` .. `_10` | 10 |
| Guns B | `ship_guns_b_01` .. `_10` | 10 |
| Mines | `ship_mines_01` .. `_05` | 5 |
| Missiles | `ship_missiles_01` .. `_05` | 5 |
| Missiles/Flame | `missiles_flame_01` .. `_05` | 5 |
| Wings A | `ship_wings_a_01` .. `_10` | 10 |
| Wings B | `ship_wings_b_01` .. `_10` | 10 |

Active scene uses: `ship_example_05` (ship body), `ship_flame_06` (flame), `ship_bullets_04` (bullets).

The `Workbench.Flames` and `Workbench.Bullets` lists in [`workbench.lua`](../../modules/asteroids/entities/workbench.lua) reference the flame and bullet families respectively for the editor jigs.

## PicStrip + Anim resources

### Explosions — [`images/explosions/sheets_halved/explosions.res.lua`](../../modules/asteroids/images/explosions/sheets_halved/explosions.res.lua)

A helper function `debris_explosion(n)` emits a `picStrip` config:

```lua
{
  type = "picStrip",
  name = "debris_explosion_<n>",
  data = {
    path = "modules/asteroids/images/explosions/sheets_halved/debris_explosion_<n>.sheet.png",
    picWidth = 192, picHeight = 192,
    picOptions = { sx=1, sy=1, duration=2/60 },
    anims = {
      ["debris_explosion_<n>"] = { },   -- inherits picOptions
    },
  },
}
```

The file returns `map({1,2,3,4,5,6}, debris_explosion)` → 6 picStrip configs.

Each picStrip slices a `.sheet.png` (192×192 cells) into individual pics. The accompanying `anims` block creates a `res.anims["debris_explosion_<n>"]` animation. Frame duration: `2/60 ≈ 0.033s` per frame. Source credits in the file comments: castorstudios.itch.io and codeandweb.com sprite-sheet packer.

The companion directory [`images/explosions/sheets_halved/`](../../modules/asteroids/images/explosions/sheets_halved) contains the six sheet PNGs. There's a sibling [`images/explosions/`](../../modules/asteroids/images/explosions/) directory with a (commented-out) `explosions.res.lua` for a non-halved variant.

The asteroids manifest currently uses `sheets_halved/explosions.res.lua` (the live reference is in [`resources.lua:81`](../../modules/asteroids/resources.lua#L81)).

## Sound resources

Both declared inline in the top-level manifest [`resources.lua:85-101`](../../modules/asteroids/resources.lua#L85):

| Sound name | File | Volume | Used by |
|---|---|---|---|
| `medium_explosion_1` | `sounds/medium-explosion-40472.mp3` | 0.4 | `Battle.destroyRoid` (attached to roid-kill explosion) |
| `laser_small` | `sounds/laser_small.wav` | 0.5 | `ship_controller` fire path (attached to right bullet) |

There's a commented-out `music` config (`city`, `welcome-to-city.mp3`) — not used.

The `sound` system auto-removes `sound` comps once playtime exceeds duration.

## Font resources

| Font name | File | Sizes |
|---|---|---|
| `narpassword` | `modules/common/fonts/narpassword.ttf` | `64` |

The font loader auto-creates `narpassword_default` and `narpassword_64`. Lookup via `res.fonts:get("narpassword_64")`.

The active scene doesn't currently render any text (no `label` entities in scene_based.populate). The font is loaded for jig usage.

## Shared resources

[`modules/common/fonts/narpassword.ttf`](../../modules/common/fonts/narpassword.ttf) — the only font asset; could in principle be shared across modules.

[`modules/common/images/`](../../modules/common/images) — a place for shared images, currently a sibling directory.

## Lazy / eager loading

The manifest sets:

```lua
{ type = "settings", name = "resource_loader",
  data = {
    lazy_load = { pics=true, picStrips=true, anims=true, sounds=true },
    realize_on_module_load = true,
  },
}
```

This means: every pic/picStrip/anim/sound gets a deferred build closure (no I/O during boot of castle), but **all** of those closures are realized when the asteroids module's world is first instantiated (since `realize_on_module_load=true`). Net effect: heavy work happens when you switch to asteroids, not when castle starts up — but once switched, all assets are warm.

Settings + fonts + data + ecs are NOT in `lazy_load` so they're built immediately at manifest load time.

CLI override: passing `--lazy-resources` forces deferred resource loads even if `realize_on_module_load=true`. Useful for fast iteration ([`vendor/castle/resourceloader.lua:317`](../../vendor/castle/resourceloader.lua#L317)).

## How to add an asset

### A new pic

Either inline in `resources.lua`:

```lua
{ type = "pic", name = "my_pic",
  data = { path = "modules/asteroids/images/my/my.png" } },
```

Or in a dedicated `*.res.lua` file referenced by `resource_file`. Use `data.rect = {x,y,w,h}` to clip a sub-rectangle of an image, `data.sx`/`data.sy` to scale.

### A new sound

```lua
{ type = "sound", name = "my_sfx",
  data = { file = "modules/asteroids/sounds/my.wav", volume = 0.7 } },
```

For streaming music, set `music = true` (or use `type = "music"`).

### A new spritesheet animation

```lua
{ type = "picStrip", name = "my_anim",
  data = {
    path = "modules/asteroids/images/my/sheet.png",
    picWidth = 64, picHeight = 64,
    picOptions = { duration = 1/30 },
    anims = { my_anim = {} },
  } },
```

Then attach `{ "anim", { id = "my_anim", … } }` plus a paired `timer` to an entity.

### A new font choice

```lua
{ type = "font", name = "narpassword",
  data = { file = "modules/common/fonts/narpassword.ttf",
           choices = { 24, 48, 64 } } },
```

`res.fonts:get("narpassword_24")`, `_48`, `_64` will be available.
