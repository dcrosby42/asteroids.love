# asteroids.love — dev docs

A Love2D asteroids-style game built on the in-repo [castle framework](../castle/README.md). Active code lives under [`modules/asteroids/`](../../modules/asteroids); the engine lives under [`vendor/castle/`](../../vendor/castle).

## Table of contents

| Doc | What's inside |
|-----|---------------|
| [architecture.md](architecture.md) | High-level architecture: top-down summary of how the boot, module switcher, ECS adapter, and asteroids module compose. Pointers into the deep guides. |
| [design.md](design.md) | Detailed design / arch guide: game flow each tick, how the project leverages castle, the rendering pipeline, the input pipeline, and the lifecycle of major game entities (ship, asteroids, scenery, explosions). |
| [modules.md](modules.md) | Index of every code module under `modules/asteroids/`, with file-and-line links. |
| [components.md](components.md) | Every component type the project uses (built-in + project-defined). |
| [systems.md](systems.md) | Every update/draw system in the loop, in order, with what they read and write. |
| [entities.md](entities.md) | Every entity factory and the components it produces. |
| [resources.md](resources.md) | All asset resources (pics, picStrips, anims, sounds, fonts) and how they're declared. |

## Quick run

```sh
love .
```

`main.lua` boots castle; `modules/root.lua` switches between `asteroids` (default) and `joystick_debug`. F1/F2 swap modules. Cmd+R hot-reloads the root.

## Companion docs

- [docs/castle/](../castle/README.md) — castle framework documentation
- [docs/context/asteroids.md](../context/asteroids.md) — agent crash course
- [docs/context/castle.md](../context/castle.md) — castle agent crash course

## Project state at a glance

- Active branch: `paralax2-fix-recursion`. Iterating on [`vendor/castle/drawing/scenegraph_system2.lua`](../../vendor/castle/drawing/scenegraph_system2.lua).
- The "main" gameplay path is the **scene-based** entry: [`modules/asteroids/entities/scene_based.lua`](../../modules/asteroids/entities/scene_based.lua).
- The older "**workbench/jig**" path is currently disabled in [`resources.lua`](../../modules/asteroids/resources.lua) (see commented-out lines for `ship_workbench_system` and `devsystem`). Jigs remain intact under [`modules/asteroids/jigs/`](../../modules/asteroids/jigs) for re-enabling.
