# Parallax Rendering Problems

Analysis of the observed bugs in `scenegraph_system2` and `applyParalax`, with root cause identification, design critique, and suggested remedies.

---

## Symptoms to Explain

1. Engine flame is offset and rotated away from the ship, worsening as the ship rotates.
2. Zooming/rotating the camera produces wild parallax artifacts.
3. The "farthest" background layer scrolls in the wrong direction when zoomed out far enough.

All three trace back to **two independent bugs** that happen to partially cancel each other in the simplest cases (no rotation, no scale, entity at origin), producing plausible-looking parallax while hiding the underlying breakage.

---

## Bug 1 — `drawEntity` Applies Global Transforms Into an Accumulating Stack

### Where

[`scenegraph_system2.lua:262`](../../vendor/castle/drawing/scenegraph_system2.lua#L262)

```lua
local function drawEntity(e, res, viewportEnt, viewProjection)
  local transform = computeEntityTransform2(e, nil, viewportEnt)  -- GLOBAL transform, root→e
  G.push()
  G.applyTransform(transform)   -- <-- compounded onto parent's already-pushed state
  ...
  for i = 1, #childs do
    drawEntity(childs[i], res, viewportEnt)  -- recurse; each child repeats the same mistake
  end
  G.pop()
end
```

`computeEntityTransform2` walks all the way from the scene root up to `e` and returns the entity's **full world-space transform**. `G.applyTransform` (unlike `G.replaceTransform`) **multiplies** that onto whatever is currently on Love2D's transform stack. Because parent entities have already pushed their portion of the world transform, each ancestor transform is applied **one extra time** per level of nesting.

### Concrete trace for the ship flame

```
drawViewport2 pushes: inv_camera
  drawEntity(scene1):   push identity   → stack = inv_camera
    drawEntity(world1): push identity   → stack = inv_camera
      drawEntity(ship):
        computeEntityTransform2(ship) = ship.tr
        G.applyTransform(ship.tr)      → stack = inv_camera · ship.tr   ← correct ✓
        DrawFuncs draw ship pic here   → appears at right world position

        drawEntity(ship_flame):
          computeEntityTransform2(ship_flame) = ship.tr · flame.local_tr
          G.applyTransform(ship.tr · flame.local_tr)
          → stack = inv_camera · ship.tr · ship.tr · flame.local_tr
                                 ^^^^^^^^^^^^^^^^ DOUBLED
```

Ship's rotation and position are baked in twice. The flame appears at `ship_pos + rotate(ship_r, rotate(ship_r, {0, 30}))` — a double-rotation orbit that spirals away as the ship turns.

The same is true for gun muzzles: bullet spawn position (`computeEntityTransform(muzzle, parent)` in `ship.lua:120`) uses the **old** `computeEntityTransform` from ecshelpers (which does not have this draw-stack problem), so bullets fire correctly — but if muzzle position were derived from the graphics stack, they would be wrong too.

### Why the top-level scene looks fine

`scene1`, `space_bg`, and `world1` all have identity transforms. Direct children of these nodes (camera1, ship, nebula, stars) are the **first** non-identity layer, so their draws get: `inv_camera · identity^N · their_own_tr` — only one application, which is correct. The bug only bites at depth ≥ 2 under a non-identity node.

---

## Bug 2 — `applyParalax` Computes World Positions with a Double-Application

### Where

[`scenegraph_system2.lua:232`](../../vendor/castle/drawing/scenegraph_system2.lua#L232)

```lua
function applyParalax(e, transform, viewportEnt)
  local cameraTransform = computeEntityTransform2(cameraEnt)
  local cx, cy = cameraTransform:transformPoint(cameraEnt.tr.x, cameraEnt.tr.y)  -- BUG A
  local ex, ey
  if e.tr then
    ex, ey = transform:transformPoint(e.tr.x, e.tr.y)  -- BUG B
  else
    ex, ey = 0, 0
  end
  local dx = (cx - ex)
  local dy = (cy - ey)
  local mysterious_correction = 0.5
  transform:translate(dx * e.paralax.px * mysterious_correction, ...)
end
```

**Bug A**: `cameraTransform` already encodes the camera's position (it was built by walking the parent chain, accumulating `tr` values). Calling `cameraTransform:transformPoint(0, 0)` yields the camera's world-space position. But the code passes `(cameraEnt.tr.x, cameraEnt.tr.y)` — which re-applies the camera's local offset through a transform that already includes it. For a camera at `(cx, cy)` with no rotation/scale, this gives `(2·cx, 2·cy)` instead of `(cx, cy)`.

**Bug B**: The same error for the entity. `transform:transformPoint(0, 0)` is the entity's world position. Passing `(e.tr.x, e.tr.y)` applies the local offset a second time through the world transform.

### The `mysterious_correction = 0.5`

The `0.5` factor precisely compensates Bug A **only when**:
- Camera has no rotation (scale compounds differently)
- Camera has scale = 1 (any scale changes the ratio)
- The entity's own `tr.x / tr.y` are both zero (Bug B would otherwise also need compensation)

For background entities at the scene origin with `tr = {0,0}`, Bug B contributes nothing (`(0,0)` is unaffected by the double-apply), and the 0.5 neatly halves the camera's doubled contribution. This is why the basic scrolling looks right.

### Effect of camera rotation

With a rotated camera transform `T(cx,cy)·R(r)·S(s,s)`:

```
cameraTransform:transformPoint(cx, cy)
  ≠ 2·(cx, cy)   -- rotation deflects the point off-axis
```

The 0.5 no longer corrects the error. `dx` and `dy` gain a spurious rotational component, so the parallax offset pushes backgrounds diagonally as the camera rotates — even for entities that should only scroll along the camera's path of travel.

### Effect of zoom (the "wrong direction" bug)

With the camera scaled to `s < 1` (zoomed out), `cameraTransform:transformPoint(cx, cy)` returns approximately `(cx·(1+s), cy·(1+s))`. For `s = 0.01`, that is `≈ 1.01·(cx,cy)`, so Bug A barely contributes. But Bug A's correction (0.5) is still applied, halving the delta. Meanwhile the camera's **inverse** transform magnifies world offsets by `1/s`. The parallax world-space offset (`≈ 0.5 · 1.01 · cam_pos · px`) gets amplified by `100×` on screen, dominating over the entity's intended position. At enough zoom-out the net screen displacement overflows the intended range, and the background appears to scroll backward relative to other world objects.

---

## Combined Effect on Observed Bugs

| Observed symptom | Root cause |
|---|---|
| Flame/muzzle offset from ship | Bug 1: ship.tr applied twice in nested drawEntity |
| Flame rotates away as ship turns | Bug 1: ship rotation compounded; flame orbits double-rotated |
| Parallax breaks under camera rotation | Bug 2: rotation makes the 0.5 correction wrong |
| Farthest layer scrolls wrong at max zoom-out | Bug 2: 0.5 overcorrects or undercorrects depending on scale; camera inverse magnifies the error |

---

## Design Critique

### The core mismatch

The code conflates two different coordinate regimes:

1. **Love2D's incremental transform stack** (`G.push / applyTransform / pop`) — designed for *local* transforms only. Each push multiplies the current state by the new transform. Children naturally accumulate parent context.

2. **`computeEntityTransform2`** — returns a *global* (root-to-entity) transform, bypassing the stack's incremental nature.

Using a global transform with `applyTransform` in an already-accumulated stack is always wrong for nested entities. Standard 2D engine draw traversals commit to one or the other:

**Standard local-transform pattern** (Unity SpriteRenderer, Godot `_draw`, LÖVE tutorials):
```
drawEntity(e):
  G.push()
  G.applyTransform(e.tr_local)   -- only this entity's OWN local tr
  draw self
  for each child: drawEntity(child)  -- child inherits accumulated parent context
  G.pop()
```

**Global-transform-with-replace pattern** (used when you need pre-computed world poses):
```
drawEntity(e, viewProjection):
  worldTransform = computeGlobal(e)
  screenTransform = viewProjection · worldTransform
  G.push()
  G.replaceTransform(screenTransform)  -- replaces; does NOT compound
  draw self
  for each child: drawEntity(child, viewProjection)  -- same projection, different global
  G.pop()
```

The commented-out block in `drawEntity` (`G.replaceTransform`, `viewProjection:clone():apply(transform)`) suggests the second pattern was attempted but abandoned mid-refactor. The current code is a hybrid of both — taking the global transform from pattern 2 but applying it via `applyTransform` from pattern 1.

### `viewProjection` is computed but orphaned

In `drawViewport2`:
```lua
local viewProjection = computeEntityTransform2(camera):inverse()
G.push()
G.applyTransform(viewProjection)
drawEntity(scene, res, viewportEnt, viewProjection)  -- passed in
```

In `drawEntity`, `viewProjection` is received but never used. The recursive children calls also drop it:
```lua
drawEntity(childs[i], res, viewportEnt)  -- viewProjection missing
```

This is the skeleton of the global+replace approach being left half-implemented.

### `viewportEnt` not forwarded in parent recursion

```lua
local function computeEntityTransform2(ent, relativeToEnt, viewportEnt)
  local transform = computeEntityTransform2(ent:getParent(), relativeToEnt)  -- no viewportEnt
```

If a parent entity ever has a `paralax` component, it will be silently ignored. Currently harmless since only leaf-level background entities carry `paralax`, but brittle.

---

## Suggested Fixes

### Fix 1: Choose one pattern and commit

**Recommended: Global transform + `replaceTransform`**

This requires minimal restructuring of the existing `computeEntityTransform2` infrastructure:

```lua
-- In drawViewport2, build a proper screen-from-world projection:
local viewportScreenTransform = computeEntityTransform2(viewportEnt)
local cameraInverse = computeEntityTransform2(cameraEnt):inverse()
local viewProjection = viewportScreenTransform:clone():apply(cameraInverse)
-- Pass viewProjection into drawEntity; drop the G.applyTransform(cameraInverse) call

-- In drawEntity:
local function drawEntity(e, res, viewportEnt, viewProjection)
  local worldTransform = computeEntityTransform2(e, nil, viewportEnt)
  G.push()
  if viewProjection then
    G.replaceTransform(viewProjection:clone():apply(worldTransform))
  else
    G.replaceTransform(worldTransform)
  end
  -- DrawFuncs...
  for i = 1, #childs do
    drawEntity(childs[i], res, viewportEnt, viewProjection)  -- pass down!
  end
  G.pop()
end
```

`G.push/pop` is still needed — it saves the current state so siblings draw correctly after a child's recursion returns.

### Fix 2: Correct the world-position computation in `applyParalax`

Replace both transform-point calls to use the `(0, 0)` origin, which is how a transform correctly yields its output-space position:

```lua
function applyParalax(e, transform, viewportEnt)
  local cameraEnt = getViewportCamera(viewportEnt)
  if not cameraEnt then return transform end

  local cameraTransform = computeEntityTransform2(cameraEnt)
  local cx, cy = cameraTransform:transformPoint(0, 0)   -- camera's world pos

  local ex, ey
  if e.tr then
    ex, ey = transform:transformPoint(0, 0)              -- entity's world pos
  else
    ex, ey = 0, 0
  end

  local dx = cx - ex
  local dy = cy - ey
  -- No mysterious_correction needed once positions are computed correctly:
  transform:translate(dx * e.paralax.px, dy * e.paralax.py)
  return transform
end
```

This gives the correct parallax offset `(cam_pos - entity_pos) * px` under all combinations of camera translation, rotation, and scale, with no fudge factor.

### Fix 3: Forward `viewportEnt` in the parent recursion

```lua
local function computeEntityTransform2(ent, relativeToEnt, viewportEnt)
  ...
  local transform = computeEntityTransform2(ent:getParent(), relativeToEnt, viewportEnt)
  ...
end
```

This ensures parent-level `paralax` components are included. Low immediate impact but removes a silent footgun.

---

## Are There Simpler / More Common Patterns?

### What you are building toward

Your design — viewport entity containing a camera name, camera entity with a `tr` in world space, inverse-camera projection applied at the viewport boundary, parallax as an additive world-space offset — is a completely sound, industry-standard approach. It mirrors how Unity 2D cameras, Godot `Camera2D`, and most hand-rolled LÖVE engines work.

The three pieces that are "almost there":

1. **Scene graph traversal with viewport cameras**: you have this. The draw pipeline correctly locates the viewport, looks up the camera, applies the inverse projection. The only error is `applyTransform` vs `replaceTransform`.

2. **Parallax as fractional camera offset**: you have the right formula — `delta = (cam_pos - entity_pos) * px`. It's just implemented with an off-by-one in the position extraction.

3. **Tiling backgrounds using viewport AABB**: `drawTilingBackground` and `getViewportAABB` are conceptually correct. They recompute the entity's parallax-adjusted transform independently of the draw stack, which avoids Bug 1 for the AABB math specifically. Once Bug 2 is fixed, the AABB center (currently `cam_pos * (1 + scale)` instead of `cam_pos`) will also be correct, and tile coverage will be tight.

### What common implementations do differently

Most engines decouple the parallax offset from the scene graph transform entirely. Rather than modifying the entity's world transform at draw time, they treat parallax as a **view-space property**: when building the per-layer view matrix, they scale the camera translation by `(1 - px)`. That is:

```
layer_view_matrix = inverse(camera_rotation_scale) · translate(-cam_pos * (1 - px))
```

This makes it obvious that `px=0` → full camera translation applied (entity appears fixed in world), `px=1` → no translation applied (entity fixed to screen). It also naturally handles zoom and rotation because the camera's rotation/scale are applied once to the baseline, not entangled with position extraction.

The equivalent in your system: instead of modifying the entity's `transform` inside `applyParalax`, modify the `viewProjection` passed to the entity before drawing:

```lua
-- layered parallax view projection:
local paralaxedViewProj = computeLayerViewProjection(viewProjection, e.paralax)
G.replaceTransform(paralaxedViewProj:clone():apply(worldTransform_without_paralax))
```

This separates "what transform does this entity have in the world" from "what fraction of the camera movement does this layer follow," which is both cleaner to reason about and sidesteps the need to re-compute world positions inside parallax logic.

---

## Summary

| | Root cause | Quick fix |
|---|---|---|
| Flame/child entities misplaced | `applyTransform` with global transforms in nested push/pop | Switch child `drawEntity` calls to use `replaceTransform` with pre-composed `viewProjection * globalTransform` |
| Parallax breaks with camera rotation/zoom | `transformPoint(tr.x, tr.y)` instead of `transformPoint(0, 0)` for world-position extraction | Use `transformPoint(0, 0)` for both camera and entity; remove `mysterious_correction` |
| Wrong-direction scroll at max zoom-out | Same Bug 2 amplified by camera inverse scale | Same fix as above |

Both fixes are surgical and local. Fixing Bug 2 alone will eliminate the zoom/rotation artifacts and make the 0.5 factor unnecessary. Fixing Bug 1 alone will correct the flame and muzzle positions. Together they clear all three observed symptoms.
