# Dev docs for asteroids.love codebase

In docs/asteroids/ generate all these new markdown docs:

- High-level Architecture, linking into the next doc...
- Detailed design/arch guide:
  - What's the main game flow
  - How the game code uses castle's module and ecr system in general
  - How rendering works
  - How input works
  - Identify major state elements that correspond to lifecycle of user-facing entities like the ship, asteroids, scenery
- Detailed index of modules with thorough linkage into files
- Full details on all components
- Full details on all systems
- Full details on all entities
- Full details on all asset resources
- Main README.md that serves as a table of contents linking to all these docs

# agent context docs for asteroids.love

Write docs/context/asteroids.md thusly:

- Generate a single-file, agent-friendly crash course document for agents to efficiently understand the arhcitecture and design of the asteroids.love love2d game, how entities components systems and assets come together to make the game, how castle is being leveraged.
- Strong admonition to live and die by the castle framework. Strong instruction for agents to read docs/context/castle.md to let agents become experts wrt the castle framework
- Write in a compact, detail-rich format that's easy for agents to digest.  No diagrams or formatted tables required.
