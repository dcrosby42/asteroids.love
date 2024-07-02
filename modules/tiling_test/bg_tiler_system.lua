local ViewportHelpers = require "castle.ecs.viewport_helpers"

local Comps = require "castle.ecs.component"
local ViewportHelpers = require "castle.ecs.viewport_helpers"

local Debug = require("mydebug").sub("BgTilerSystem", true, true)

local function strnd(n)
  return tostring(math.round(n))
end

local function getProjectedViewportCorners(viewport, camera)
  local offx, offy = computeViewportCameraOffset(viewport, camera)
  return camera.tr.x - offx, camera.tr.y - offy,
      camera.tr.x + offx, camera.tr.y + offy
end

local function getProjectedViewportCorners2(viewport, camera)
  local offx, offy = computeViewportCameraOffset(viewport, camera)
  local off = math.max(offx, offy)
  return camera.tr.x - off, camera.tr.y - off,
      camera.tr.x + off, camera.tr.y + off
end

local function getProjectedViewportCorners3(viewport, camera, bgtiler)
  local offx, offy = computeViewportCameraOffset(viewport, camera)
  return camera.tr.x - offx, camera.tr.y - offy,
      camera.tr.x + offx, camera.tr.y + offy
end

local function updateCornerDebugs(bgtiler, cameraE, ulx, uly, lrx, lry)
  local dotULName = "bgtiler_dbg_ul"
  local dotUL = bgtiler:getEstore():getEntityByName(dotULName)
  if not dotUL then
    dotUL = bgtiler:getParent():newEntity({
      { "tr",     {} },
      { "circle", { r = 5, style = "fill", color = { 1, 0, 0 } } },
      { "label",  { color = { 1, 0, 0 } } },
    })
    nameEnt(dotUL, dotULName)
  end
  local dotLRName = "bgtiler_dbg_lr"
  local dotLR = bgtiler:getEstore():getEntityByName(dotLRName)
  if not dotLR then
    dotLR = bgtiler:getParent():newEntity({
      { "tr",     {} },
      { "circle", { r = 5, style = "fill", color = { 1, 0, 0 } } },
      { "label",  { color = { 1, 0, 0 } } },
    })
    nameEnt(dotLR, dotLRName)
  end
  dotUL.tr.x = ulx
  dotUL.tr.y = uly
  dotUL.tr.sx = cameraE.tr.sx
  dotUL.tr.sy = cameraE.tr.sy
  dotUL.label.text = strnd(dotUL.tr.x) .. ", " .. strnd(dotUL.tr.y)

  dotLR.tr.x = lrx
  dotLR.tr.y = lry
  dotLR.tr.sx = cameraE.tr.sx
  dotLR.tr.sy = cameraE.tr.sy
  dotLR.label.text = strnd(dotLR.tr.x) .. ", " .. strnd(dotLR.tr.y)
end

local function findTileEnt(tileEnts, r, c)
  for _, tileEnt in ipairs(tileEnts) do
    if tileEnt.tile.row == r and tileEnt.tile.col == c then
      return tileEnt
    end
  end
  return nil
end

local function genTileCoverageCoords_rect(tiler, ulx, uly, lrx, lry)
  local c0 = math.floor(ulx / tiler.bgtiler.tilew)
  local r0 = math.floor(uly / tiler.bgtiler.tileh)
  local c1 = math.floor(lrx / tiler.bgtiler.tilew)
  local r1 = math.floor(lry / tiler.bgtiler.tileh)
  local cov = {}
  for r = r0, r1, 1 do
    for c = c0, c1, 1 do
      cov[#cov + 1] = r
      cov[#cov + 1] = c
    end
  end
  return cov
end

local function genTileCoverageCoords_square(tiler, camera, offx, offy)
  local x, y = camera.tr.x, camera.tr.y
  local halfSide = math.max(offx, offy)
  Debug.println(strnd(x) .. "," .. strnd(y) .. "  " .. strnd(offx) .. "," .. strnd(offy))

  local lrx, ulx, lry, uly = x - halfSide, y - halfSide, x + halfSide, y + halfSide
  local c0 = math.floor(ulx / tiler.bgtiler.tilew)
  local r0 = math.floor(uly / tiler.bgtiler.tileh)
  local c1 = math.floor(lrx / tiler.bgtiler.tilew)
  local r1 = math.floor(lry / tiler.bgtiler.tileh)
  local cov = {}
  for r = r0, r1, 1 do
    for c = c0, c1, 1 do
      cov[#cov + 1] = r
      cov[#cov + 1] = c
    end
  end
  return cov
end

local function newTileEnt(e, r, c)
  local tw, th = e.bgtiler.tilew, e.bgtiler.tileh
  local parax, paray = 1, 1
  local picId = e.bgtiler.picId
  local x, y = tw * c, th * r
  local label = tostring(x) .. ", " .. tostring(y)
  local name = e.bgtiler.name .. "_" .. label
  local color = { 1, 1, 0 } -- for debugging only
  local tile = e:newEntity({
    { "tile", { tilespace = e.bgtiler.name, row = r, col = c } },
    { "name", { name = name } },
    { "tr",   { x = x, y = y, parax = parax, paray = paray } },
    { "pic",  { id = picId } },
    { "box", {
      w = tw,
      h = th,
      debug = e.bgtiler.debug,
      color = color
    } },
  })
  if e.bgtiler.debug then
    tile:newComp("label", { text = label, color = color })
  end
  Debug.println("newTileEnt r=" .. r .. " c=" .. c .. " x=" .. x .. " y=" .. y)
  return tile
end

return defineQuerySystem(
  "bgtiler",
  function(e, estore, input, res)
    -- Compute in-world bounds based on viewport+camera
    local viewportE, cameraE = ViewportHelpers.findOwningViewportAndCamera(e)

    -- local ulx, uly, lrx, lry = getProjectedViewportCorners(viewportE, cameraE)
    local ulx, uly, lrx, lry = getProjectedViewportCorners2(viewportE, cameraE)
    -- local ulx, uly, lrx, lry = getProjectedViewportCorners3(viewportE, cameraE, e)
    if e.bgtiler.debug then
      updateCornerDebugs(e, cameraE, ulx, uly, lrx, lry)
    end

    -- Existing tile entities as children of e:
    local tileEnts = lfilter(e:getChildren(), function(ch) return ch.tile end)

    -- Iterate tilespace coverage, adding and removing tile entities
    local tileCoords = genTileCoverageCoords_rect(e, ulx, uly, lrx, lry)
    -- local offx, offy = computeViewportCameraOffset(viewportE, cameraE)
    -- local tileCoords = genTileCoverageCoords_square(e, cameraE, offx, offy)
    local keepEids = {}
    for i = 1, #tileCoords, 2 do
      local r, c = tileCoords[i], tileCoords[i + 1]
      -- Find existing tile entity at r,c OR create a new one
      local tileEnt = lfind(tileEnts, function(te)
        return te.tile.row == r and te.tile.col == c
      end) or newTileEnt(e, r, c)

      table.insert(keepEids, tileEnt.eid)
    end
    -- Delete any tile entities not included in the tileCoords coverage
    for _, tileEnt in ipairs(tileEnts) do
      if not lcontains(keepEids, tileEnt.eid) then
        Debug.println("destroy tileEnt r=" .. tileEnt.tile.row .. " c=" .. tileEnt.tile.col)
        tileEnt:destroy()
      end
    end
  end
)
