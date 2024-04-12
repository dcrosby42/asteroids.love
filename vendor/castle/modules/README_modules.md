# Castle Modules

A **Module** is an object conforming to this interface:

1. myModule.newWorld(opts) -> world
2. myModule.updateWorld(world, action) -> (world, sideEffects)
3. myModule.drawWorld(world)

A module may be a simple table or an "object" instance.

**A Module does not maintain internal state.** Instead, state is managed as a `world` value, which is initialized via `newWorld()`, updated only via `updateWorld()`, and rendered via `drawWorld()`.

Though the calling context is responsible for wrangling the `world` lifecycle from the outside, **ONLY updateWorld() is allowed to change it**.

The interface is designed such that (in theory) `world` may be represented by an immutable/persistent data structure: the current `world` is passed to `updateWorld` with some `action`, the next state of `world` is computed and returned.

The type and structure and rules governing `world`'s content are owned wholly by the Module's implementation.  

ANY valid value of `world` may be submitted to `updateWorld` or `drawWorld` at ANY TIME.

# ECS Modules

ECS Modules are not Castle Modules; however, the EcsAdapter wraps an ECS Module to fit the interface


# WHY ARE THERE TWO KINDS OF MODULE?

"Castle Modules" are a the foundation of a very useful base pattern for wrangling game state.  Though it's not "capital F functional", I was inspired by ELM's functional design for web UI implementation, particularly in how it decouples state, update logic and rendering and creates a simple-but-powerful pattern for composability.  Castle Modules impost a pattern of state management, but how each module represents, manipulates and renders its state is entirely self determined.

"ECS Modules" provide a framework for writing Entity-Component-System-style code.  The technique itself turns state management on its ear (in a good way, imho) and provides a wonderful foundation for starting and scaling complex game systems and keeping the genie in the bottle, so to speak.

But while ECS is totally worthwhile to learn once you decide to embark on building a game, it can get in your way if all you want to do is slap some stuff onto the screen and test something out.  Or, for a highly-specialized but otherwise-isolated aspect of your game, such as a title screen or end credits sequence, it might be clearer and easier to code it (mostly) plain-ol-Love2d-style.

Castle Modules are nestable and interchangeable.  So you can write a basic Castle Module and have that owning updates and drawing, then swap over to an ECS Module for involved gameplay.  For this reason, I usually install a castle.modules.switcher module as the RootModule in my game, and use sidefx signalling to switch between "modes".