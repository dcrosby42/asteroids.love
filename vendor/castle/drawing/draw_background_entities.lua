require "castle.drawing.drawhelpers" -- debugDraw
local mk_entity_draw_loop = require 'castle.drawing.mk_entity_draw_loop'
local drawPicLike = require 'castle.drawing.draw_piclike'

local ViewportHelpers = require "castle.ecs.viewport_helpers"

local round = math.round
local floor = math.floor
local max = math.max

-- Computes the apparent location of the viewport's upper-left and lower-right corners
-- in world space, based the viewport's camera location, rotation and scale.
-- Returns: upper_left_x, upper_left_y, lower_right_x, lower_right_y
local function getProjectedViewportCorners2(viewport, camera)
  local offx, offy = computeViewportCameraOffset(viewport, camera) -- ecshelpers.lua
  local off = max(offx, offy)
  return camera.tr.x - off, camera.tr.y - off,
      camera.tr.x + off, camera.tr.y + off
end

-- Returns: col0, row0, col1, row1
local function computeTilingExtents(tw, th, ulx, uly, lrx, lry, rounder)
  if not rounder then rounder = floor end
  return rounder(ulx / tw), rounder(uly / th),
      rounder(lrx / tw), rounder(lry / th)
end

-- Draw background components as tiles, covering only the area in and nearby the
-- viewport's current location and zoom/rot factors.
local function drawBackground(e, background, res)
  local picRes = res:get('pics'):get(background.id)
  if not picRes then
    error("No background pic resource '" .. background.id .. "'")
  end

  local w, h = picRes.rect.w, picRes.rect.h

  -- Compute in-world viewing bounds based on viewport+camera
  local viewportE, cameraE = ViewportHelpers.findOwningViewportAndCamera(e)
  if not viewportE or not cameraE then
    print("cannot draw background missing viewport or camera or both")
    return
  end

  local ulx, uly, lrx, lry = getProjectedViewportCorners2(viewportE, cameraE)

  -- paralax factor
  local parax = 0.5
  local paray = parax
  -- image offset due to paralax:
  -- local poffx = w * parax
  -- local poffy = h * paray

  -- adjust corner locs
  -- ulx = ulx + poffx
  -- lrx = lrx + poffx
  -- uly = uly + poffy
  -- lry = lry + poffy

  -- ulx = ulx * parax
  -- lrx = lrx * parax
  -- uly = uly * paray
  -- lry = lry * paray

  -- local dx = cameraE.tr.x - e.tr.x
  -- local dy = cameraE.tr.y - e.tr.y
  -- local ax = dx * e.tr.parax
  -- local ay = dy * e.tr.paray
  -- x = x + ax
  -- y = y + ay
  local c0, r0, c1, r1 = computeTilingExtents(w, h, ulx, uly, lrx, lry)

  -- For each tiling location, stamp a drawing of the bg image
  for row = r0, r1, 1 do
    for col = c0, c1, 1 do
      background.x = (col * w) --+ poffx
      background.y = (row * h) --+ poffy
      -- A background comp shares common ancestry w pic component
      drawPicLike(background, picRes, res)
    end
  end
  -- (reset the location for cleanliness)
  background.x = 0
  background.y = 0
end

return mk_entity_draw_loop('backgrounds', drawBackground)
