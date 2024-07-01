local Workbench = require "modules.asteroids.entities.workbench"
local Roids = require "modules.asteroids.entities.roids"
local Menu = require "modules.asteroids.jigs.menu"
local State = require "castle.state"
local TweenHelpers = require "castle.tween.tween_helpers"

local RoidPics = Roids.PicIds
-- local RoidPics = {
--   "roid_small_grey_01",
--   "roid_small_red_01",

--   "roid_small_grey_02",
--   "roid_small_red_02",

--   "roid_medium_grey_01",
--   "roid_medium_red_01",

--   "roid_medium_grey_02",
--   "roid_medium_red_02",

--   "roid_medium_grey_03",
--   "roid_medium_red_03",

--   "roid_large_grey_01",
--   "roid_large_red_01",

--   "roid_large_grey_02",
--   "roid_large_red_02",

--   "roid_large_grey_03",
--   "roid_large_red_03",
-- }

-- Reasonable scaling ranges:
--   small: 0.5 thru 1.5
--   medium: 0.3 thru 1.75
--   large: 0.15 thru 2.75

-- Normalizing scale factors that make medium and large roids similar-sized to smalls:
local Med2Small = 0.5
local Large2Small = 0.2
-- Normalize mediums up to large:
local Med2Lg = 2.4 -- note this is a stretch, 1.75 is kinda the max, but hey, more roids!


local AllSmalls = {
  { pic = "roid_small_grey_01",  size = 1 },
  { pic = "roid_small_grey_02",  size = 1 },
  { pic = "roid_medium_grey_01", size = Med2Small },
  { pic = "roid_medium_grey_02", size = Med2Small },
  { pic = "roid_medium_grey_03", size = Med2Small },
  { pic = "roid_large_grey_01",  size = Large2Small },
  { pic = "roid_large_grey_02",  size = Large2Small },
  { pic = "roid_large_grey_03",  size = Large2Small },
}

local AllMeds = lmap(deepclone(AllSmalls), function(cfg)
  cfg.size = 2 * cfg.size
  return cfg
end)

local AllMedLg = lmap(deepclone(AllSmalls), function(cfg)
  cfg.size = 3 * cfg.size
  return cfg
end)
-- (drop the first two, smalls don't scale up to 3x nicely)
table.remove(AllMedLg, 1)
table.remove(AllMedLg, 1)

local AllLarges = {
  { pic = "roid_medium_grey_01", size = Med2Lg },
  { pic = "roid_medium_grey_02", size = Med2Lg },
  { pic = "roid_medium_grey_03", size = Med2Lg },
  { pic = "roid_large_grey_01",  size = 1 },
  { pic = "roid_large_grey_02",  size = 1 },
  { pic = "roid_large_grey_03",  size = 1 },
}

local AllHuges = {
  { pic = "roid_large_grey_01", size = 2.75 },
  { pic = "roid_large_grey_02", size = 2.75 },
  { pic = "roid_large_grey_03", size = 2.75 },
}




local Jig = {}

function Jig.newRoidMenu(name, choices, parent, res)
  local w, h = res.data.screen_size.width, res.data.screen_size.height

  local initialSelected = 1
  local menu = parent:newEntity({
    { "tr",       { x = 20, y = h - 150 } },
    { "name",     { name = name } },
    { "state",    { name = "selected", value = initialSelected } },
    { "keystate", { handle = { "j", "k" } } },
    { "label", {
      text = "Select: j, k | Zoom: up, down | Toggle chart: c",
      color = { 1, 1, 1 },
      y = -20,
    } }
  })
  local picSize = 0.5
  local x, y = 0, 0
  for i, picId in ipairs(choices) do
    x = (i - 1) * 50
    menu:newEntity({
      { "name", { name = "menu-" .. picId } },
      { "tr",   { x = x, y = y } },
      { 'pic', {
        id = picId,
        sx = picSize,
        sy = picSize,
        y = 20,
        x = 50 / 2,
        cx = 0.5,
      } },
      { "label", {
        text = tostring(i),
        color = { 1, 1, 1 },
        align = "middle",
        -- cx = 0.5,
        -- y = -40,
        w = 50,
        h = 20,
      } },
    })
  end

  menu:newEntity({
    { "name", { name = "menu_cursor" } },
    { "tr",   { x = (initialSelected - 1) * 50, } },
    { "rect", { w = 50, h = 70, color = { 1, 1, 1, 1 } } }
  })
  return menu
end

function Jig.newRoid(parent, opts)
  opts = opts or {}
  -- if not opts.pic then return end
  opts.size = opts.size or 1
  opts.color = opts.color or { 1, 1, 1 }
  opts.name = opts.name or "a_roid"
  return parent:newEntity({
    { "name", { name = opts.name } },
    { "tag",  { name = "roid" } },
    { 'tr',   { x = 0, y = 0, } },
    { 'pic', {
      -- id = "roid_large_grey_a1",
      id = opts.pic,
      cx = 0.5,
      cy = 0.5,
      sx = opts.size,
      sy = opts.size,
      color = opts.color,
      debug = false,
    } },
  })
end

local function addRoidSheet(jig, cfgs, x, y, w)
  for i, cfg in ipairs(cfgs) do
    local tile = jig:newEntity({
      { "tr", {
        x = x + ((i - 1) * w),
        y = y
      } },
    })
    local roid = Jig.newRoid(tile, { pic = cfg.pic, size = cfg.size })

    local labelText = string.sub(cfg.pic, 6, -1)
    tile:newEntity({
      { "label", {
        text = labelText,
        color = { 1, 1, 1 },
        align = "middle",
        valign = "bottom",
        -- debug = true,
        w = 200,
        h = w,
        cx = 0.5,
        cy = 0.5,
      } },
    })
  end
end

local function makeRoidChart(parent)
  local chart = parent:newEntity({
    { "name", { name = "the_chart" } },
  })

  local sheetY = 160
  addRoidSheet(chart, AllHuges, -450, sheetY, 400)
  sheetY = sheetY - 170
  addRoidSheet(chart, AllLarges, -450, sheetY, 150)
  sheetY = sheetY - 130
  addRoidSheet(chart, AllMedLg, -450, sheetY, 120)
  sheetY = sheetY - 110
  addRoidSheet(chart, AllMeds, -450, sheetY, 120)
  sheetY = sheetY - 100
  addRoidSheet(chart, AllSmalls, -450, sheetY, 120)
end

function Jig.init(parent, estore, res)
  local jig = parent:newEntity({
    { "name",     { name = "roid_browser" } },
    { "keystate", { handle = { "up", "down", "left", "right", ",", ".", "c" } } },
  })
  Workbench.dev_background(jig, res)

  local menu = Jig.newRoidMenu("roid_menu", RoidPics, estore, res)
  jig:newComp("state", { name = "menu_eid", value = menu.eid })

  local selectedPic = Menu.getMenuChoice(menu, RoidPics)
  if selectedPic then
    Jig.newRoid(jig, { pic = selectedPic, name = "the_roid" })
  end

  -- makeRoidChart(jig)
end

function Jig.finalize(jigE, estore)
  -- since the menu is parented higher up in the estore, we have to find and kill it
  local menuEid = State.get(jigE, "menu_eid")
  if menuEid then
    local menu = estore:getEntity(menuEid)
    if menu then
      menu:destroy()
    end
  end
end

local matchRoids = hasTag("roid")

local function moveRoids(jig, input)
  jig:walkEntities(matchRoids, function(e)
    if e then
      e.tr.r = e.tr.r + (0.3 * input.dt)
      -- e.tr.x = e.tr.x + (18 * input.dt)
      -- e.tr.y = e.tr.y + (36 * input.dt)
    end
  end)
end

local function controlRoid(jig)
  local action
  if jig.keystate.pressed.up then
    action = "zoom_in"
  elseif jig.keystate.pressed.down then
    action = "zoom_out"
  end
  if action then
    jig:seekEntity(hasName("the_roid"), function(e)
      local factor = 0.25
      local mul
      if action == "zoom_in" then
        mul = 1 + factor
      elseif action == "zoom_out" then
        mul = 1 - factor
      end
      local s = e.tr.sx * mul
      print("Roid scale: " .. tostring(s))
      TweenHelpers.tweenit(e, "scale", { tr = { sx = s, sy = s } }, { duration = 0.3 })
      return true
    end)
  end
end

function Jig.update(estore, input, res)
  local jig = estore:getEntityByName("roid_browser")

  moveRoids(jig, input)
  controlRoid(jig)

  local menu = estore:getEntityByName("roid_menu")
  Menu.updateMenu(menu, RoidPics, estore, function(picId)
    local roidE = estore:getEntityByName("the_roid")
    if roidE then
      roidE.pic.id = picId
      -- roidE:destroy()
    end
    -- New roid
    -- Jig.newRoid(jig, { pic = picId })
  end)

  if jig.keystate.pressed.c then
    local chart = estore:getEntityByName("the_chart")
    if chart then
      chart:destroy()
    else
      makeRoidChart(jig)
    end
  end
end

return Jig
