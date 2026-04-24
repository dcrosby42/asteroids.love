# Proper scene graph transforms

# Context

There's two "modes" where transforms are needed and computed: during updates and during rendering.
- tr components store parent-relative entity transforms.
- Update-time systems compute world transforms recursively using tr components up the parent chain.
- During rendering, entities are drawn recursively, and transform state accumulates via love2d's transform stack... but also there is an artificial paralax computation involving the current camera+viewport info.  (This is because paralax is immitating pov to give the impression of distance between layers... and the offsets would depend entirely on the camera's viewport... imagine if we had a screen with two viewports, two cameras, same scene... the offsets for rendered layers within each viewport would depend on the location of the particular camera in the viewport.)


I've tried to factor this stuff out into meaningful components, entities and properties for viewports, cameras, tr components, paralax properties, etc.  I've tried to break the logic down into purposeful functions that can be properly reused to gain consistent computation but also yield the desired effect visually, render items properly, and let me compute proper world coords of entities.

Things are close, but not quite right.

# Problems:

- Zooming and rotating the camera has interesting side effects to paralax computation.
- The Ship entity's engine thrust graphic is offset and rotated quite incorrectly, since my attempts to introduce paralax into the transform helper funcs... it moves away from the ship. rotates mysteriously etc.
- If I zoom out far enough, the "furthest" background layer scrolls in the wrong direction.

# Instructions:

- Read: docs/castle/systems.md, it has a "Draw pipeline" section that covers some of this.
- Scrutinize my scenegraph draw pipeline and associated helper funcs
- Scrutinize the ship's componentry and related systems
- Answer:
  - Can you identify any obvious errors that might result in the observed above problems?
  - Speculate further
  - Offer opinions on the code design, logic.
  - Are there more complete/common patterns out in the world that I'm coming close to but missing something important? Render an opinion on my design, its deviations, and offer suggestions.  There might just be a couple fixes we could apply to fix the problems... but if not, this setup has been tricky to debug.  Perhaps there's a simpler, more-consistent design that would make this a less-compounded problem space.
- Write docs/castle/paralax_rendering_problems.md

 