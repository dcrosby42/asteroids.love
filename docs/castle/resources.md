# The Resource Pipeline

Castle's resources system is the *bridge* between the Module Layer and the ECS Layer: a single declarative manifest is loaded into a `ResourceRoot`, which is then handed to systems as `res`.

The whole machinery lives in two files:

- [`vendor/castle/resourceloader.lua`](../../vendor/castle/resourceloader.lua) — the generic pipeline
- [`vendor/castle/ecs/loaders.lua`](../../vendor/castle/ecs/loaders.lua) — adds the `ecs` resource type for hooking into `EcsAdapter`

## A resources.lua manifest

A manifest is a Lua file returning a list of typed config objects. Each object has at minimum `type` and (almost always) `name` plus a `data` block. From [`modules/asteroids/resources.lua`](../../modules/asteroids/resources.lua):

```lua
return {
  { type = "ecs", name = "main",
    data = {
      entities    = { datafile = "modules/asteroids/entities.lua" },
      components  = { datafile = "modules/asteroids/components.lua" },
      systems     = { data = { "castle.systems.timer", … } },
      drawSystems = { data = { "castle.drawing.scenegraph_system2" } },
    },
  },

  { type = "settings", name = "dev", data = { bgmusic = false } },
  { type = "settings", name = "resource_loader",
    data = {
      lazy_load = { pics=true, picStrips=true, anims=true, sounds=true },
      realize_on_module_load = true,
    },
  },

  { type = "resource_file", file = "modules/asteroids/images/roidpics.res.lua" },
  { type = "resource_file", file = "modules/asteroids/images/ships/ship_pics.res.lua" },
  …

  { type = "sound", name = "laser_small",
    data = { file = "modules/asteroids/sounds/laser_small.wav", volume = 0.5 },
  },

  { type = "font", name = "narpassword",
    data = { file = "modules/common/fonts/narpassword.ttf", choices = { 64 } },
  },
}
```

`resource_file` is recursive: its target file returns another list of configs which are loaded inline.

## ResourceRoot ─ the runtime container

`ResourceRoot` is a flat map from category name to a `LazyResourceSet` ([resourceloader.lua:278](../../vendor/castle/resourceloader.lua#L278)).

```
ResourceRoot
├── ecs        : { main = { entities, components, update, draw } }
├── settings   : { dev, resource_loader, mydebug, … }
├── data       : { screen_size, … }
├── pics       : LazyResourceSet { ship_example_05, roid_small_grey_01, … }
├── picStrips  : LazyResourceSet { debris_explosion_1, … }
├── anims      : LazyResourceSet { debris_explosion_1, … }
├── sounds     : LazyResourceSet { laser_small, medium_explosion_1, … }
└── fonts      : { narpassword_default, narpassword_64 }
```

A `LazyResourceSet` ([resourceloader.lua:212](../../vendor/castle/resourceloader.lua#L212)) holds either resolved resources or constructor functions. `:get(name)` realizes lazily on first access, then caches:

```lua
function LazyResourceSet:get(name)
  local res = self[name]
  if res then return res end
  local func = self._private.builders[name]
  if func then
    res = func()       -- realize
    self[name] = res   -- cache
    return res
  end
  error("No resource or constructor for key '" .. name .. "'")
end
```

Two extra methods worth knowing:

- `:put_lazy(name, fn)` — register a constructor instead of a value ([resourceloader.lua:232](../../vendor/castle/resourceloader.lua#L232))
- `:alias(from, to)` — make `from` resolve to whatever `to` resolves to (works on either pre-built items *or* unbuilt builders) ([resourceloader.lua:258](../../vendor/castle/resourceloader.lua#L258))

## Loaders

[`Loaders` table](../../vendor/castle/resourceloader.lua#L345) is a dispatch by config `type`. `Loaders.loadConfig(res, config)` ([resourceloader.lua:689](../../vendor/castle/resourceloader.lua#L689)):

```lua
if config.type == "resource_file" then
  -- recurse into the referenced file
  return Loaders.loadConfigs(res, R.loadLuaFile(config.file), loaders)
else
  loaders[config.type](res, config)
end
```

Built-in loader types:

| `type` | Loader | What it does |
|--------|--------|-------------|
| `pic` | [`Loaders.pic`](../../vendor/castle/resourceloader.lua#L447) | Adds a built `pic` (image + quad + dimensions) to `res.pics` |
| `picStrip` | [`Loaders.picStrip`](../../vendor/castle/resourceloader.lua#L388) | Slices a sprite sheet into a list of pics; can also publish individual pics and anims |
| `picaliases` | [`Loaders.picaliases`](../../vendor/castle/resourceloader.lua#L464) | Adds aliases pointing at existing pics (for renaming) |
| `anim` | [`Loaders.anim`](../../vendor/castle/resourceloader.lua#L480) | Builds a frame-driven animation from a list of pic configs |
| `sound` / `music` | [`Loaders.sound`](../../vendor/castle/resourceloader.lua#L515) | Loads SoundData (or sets up streaming for music) |
| `font` | [`Loaders.font`](../../vendor/castle/resourceloader.lua#L552) | Pre-loads font sizes; auto-creates a `<name>_default` choice |
| `settings` | [`Loaders.settings`](../../vendor/castle/resourceloader.lua#L675) | Plain key/value storage; the `mydebug` settings doc activates debug toggles |
| `data` | [`Loaders.data`](../../vendor/castle/resourceloader.lua#L684) | Raw lua table data, stuffed into `res.data` |
| `ecs` | [`Loaders.ecs`](../../vendor/castle/ecs/loaders.lua#L60) | Composes systems, draw systems, components, entities → an ECS module spec |

A Loader can also be added externally — `R.Loaders.copy()` returns a shallow copy you can extend, then pass to `GameModule.newFromConfigs(configs, loaders)`.

### Lazy vs eager

`addToResourceSet` ([resourceloader.lua:335](../../vendor/castle/resourceloader.lua#L335)) checks `settings.resource_loader.lazy_load[<setName>]`:

- If lazy, the build closure is registered with `put_lazy`.
- If not, the closure runs immediately and the result is `put` directly.

`realize_on_module_load` ([resourceloader.lua:317](../../vendor/castle/resourceloader.lua#L317)) controls whether `res:buildAll()` is called when the module first loads its world (vs. truly lazy at first access, e.g. on the first draw). The asteroids module uses **lazy + realize_on_module_load** so all resources get built when the module wakes up but not when castle boots:

```lua
{ type = "settings", name = "resource_loader",
  data = {
    lazy_load = { pics=true, picStrips=true, anims=true, sounds=true },
    realize_on_module_load = true,
  },
},
```

CLI arg `--lazy-resources` overrides `realize_on_module_load=false`. ([resourceloader.lua:317](../../vendor/castle/resourceloader.lua#L317))

## The `ecs` loader

[`vendor/castle/ecs/loaders.lua`](../../vendor/castle/ecs/loaders.lua) extends the base loaders by adding the `ecs` type. Its `data` block has four sub-blocks:

```lua
data = {
  entities    = { datafile = "…/entities.lua" },     -- chunk returning a table with .initialEntities
  components  = { datafile = "…/components.lua" },   -- map of typeName -> field-list (registered via Comp.define)
  systems     = { data = { "module.path", …  } },    -- list of system specs
  drawSystems = { data = { "castle.drawing.scenegraph_system2" } },
}
```

The loader transforms this into:

```lua
res:get('ecs'):put(name, {
  name       = name,
  entities   = data.entities,             -- caller will use .initialEntities
  components = Comp,                      -- side effect: ALL registered comp types
  update     = composeSystems(systems),
  draw       = mkDrawSystemChain(drawSystems, res),
})
```

`mkDrawSystemChain` ([loaders.lua:18](../../vendor/castle/ecs/loaders.lua#L18)) uses [`makeFuncChain2`](../../vendor/castle/helpers.lua#L729) — a lazily-recursive composition where a 3-arity function gets the *rest of the chain* as its third arg. This lets a draw system push transform state, run downstream draws, then pop. Currently asteroids uses just one draw system but the machinery exists.

## getData & datafiles

Most config objects have **either** `data = {…}` inline **or** `datafile = "path"` referencing another lua file. `Loaders.getData(cfg)` ([resourceloader.lua:651](../../vendor/castle/resourceloader.lua#L651)) handles both, plus two optional transforms:

| Option | Effect |
|--------|--------|
| `expandDatafiles = true` | Recursively replace any nested `{datafile=…}` placeholders with the loaded data ([resourceloader.lua:622](../../vendor/castle/resourceloader.lua#L622)) |
| `dataconverter = { require = "mod.path", func = "transform" }` | After loading, run the data through a function or module ([resourceloader.lua:600](../../vendor/castle/resourceloader.lua#L600)) |

These let you keep manifests slim and split per-content into many small files.

## Resource files in the wild

Asteroids splits assets into per-category files:

| File | Type | Contents |
|------|------|----------|
| [`images/roidpics.res.lua`](../../modules/asteroids/images/roidpics.res.lua) | `pic` list | All asteroid sprites |
| [`images/roidaliases.res.lua`](../../modules/asteroids/images/roidaliases.res.lua) | `picaliases` | Friendly names for the above |
| [`images/ships/ship_pics.res.lua`](../../modules/asteroids/images/ships/ship_pics.res.lua) | `pic` list | Ship body/wing/gun/bullet/flame images |
| [`images/bg/backgrounds.res.lua`](../../modules/asteroids/images/bg/backgrounds.res.lua) | `pic` list | Nebulae & starfields |
| [`images/explosions/sheets_halved/explosions.res.lua`](../../modules/asteroids/images/explosions/sheets_halved/explosions.res.lua) | `picStrip` list | 6 debris-explosion spritesheets, each producing a named `anim` |

Each is referenced from the master manifest with `{ type = "resource_file", file = "..." }`.

## How systems read the resources

Once an `EcsAdapter` is alive, every system gets `res` as its third argument. Common access patterns:

```lua
-- Look up a pic by id
local picRes = res.pics:get(pic.id)

-- Look up an animation
local animRes = res.anims:get(anim.id)
local frame = animRes.getFrame(timer.t)   -- returns a pic for time t

-- Stash module-global data
res.data:put("screen_size", { width = w, height = h })
local size = res.data:get("screen_size")

-- Read a settings block
local debug = res.settings:get("dev").debug
```

Asteroids uses `res.data` to publish initial screen dimensions in [`entities.lua:14`](../../modules/asteroids/entities.lua#L14), then jigs and entity factories read it as `res.data.screen_size`.

## Cheat-sheet

| Task | Snippet |
|------|---------|
| Wire a new gameplay-only resource file | `{ type = "resource_file", file = "modules/x/foo.res.lua" }` |
| Add an image | `{ type = "pic", name = "x", data = { path = "…/x.png" } }` |
| Add a sound | `{ type = "sound", name = "x", data = { file = "…/x.wav", volume = 0.5 } }` |
| Add a sprite-sheet anim | `{ type = "picStrip", name = "x", data = { path, picWidth, picHeight, anims = { x = {} } } }` |
| Eager-load all resources | `lazy_load = {}` |
| Force everything truly lazy | `realize_on_module_load = false` |
| Read a pic in a system | `res.pics:get(pic.id)` |
| Define a custom loader | extend `Loaders` then pass to `GameModule.newFromConfigs(configs, loaders)` |
