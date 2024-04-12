local History = require("castle.ecs.rollinghistory")
local Debug = require("mydebug")
local suit = require "SUIT"
local inspect = require "inspect"

local G = love.graphics

local Editor = {}

function Editor.init()
  local editor = {
    on = false,
    recording = false,
    history = History:new(10 * 60),
    historyIndex = 0,
    ui = {
      bgOpacity = { value = 0.8, min = 0, max = 1 },
      timeSpeedSlider = { value = 1, min = 0, max = 2 },
      historyCheckbox = { text = "Record", checked = false },
      pausedCheckbox = { text = "Paused", checked = false },
      estoreCheckbox = { text = "Entities", checked = true },
      timeNavSlider = { value = 0, min = 0, max = 0, step = 1 },
      entityFilterInput = { text = "" },
      ents = {},
      pinnedEnts = {},
      notesBox = { w = 400, h = "full", pin = "right" },
    },
  }
  return editor
end

local function getEstore(editor)
  if editor.historyIndex > 0 then
    local es = editor.history:get(editor.historyIndex)
    if es == nil then
      print("!! DANG: editor.historyIndex=" .. editor.historyIndex ..
        " but len is " .. editor.history:length())
      return editor.estore
    end
    return es
  else
    return editor.estore
  end
end
Editor.getEstore = getEstore

local round, round0 = math.round, math.round0

local function roundSliderValue(sl)
  sl.value = round0(sl.value)
end

local function adjSliderValue(sl, x)
  sl.value = sl.value + x
  if sl.value < sl.min then
    sl.value = sl.min
  elseif sl.value > sl.max then
    sl.value = sl.max
  else
    roundSliderValue(sl)
  end
end

local function nameBlurb(c)
  if c.name ~= "" then
    return "[" .. c.name .. "] "
  else
    return ""
  end
end
local function coordStrParen(x, y)
  return "(" .. round(x, 3) .. ", " .. round(y, 3) .. ")"
end

local function updateCompGui(c)
  if c.type == "name" then return end

  local str = c.type
  str = string.sub(str, 1, 13)
  suit.Label("  ", suit.layout:row(10, h))
  suit.Button(str, { id = c.cid, align = "right" }, suit.layout:col(100, h))

  local h = 15
  local w = 1000
  if c.type == "pos" then
    local str = nameBlurb(c) .. "(" .. round(c.x, 3) .. ", " .. round(c.y, 3) ..
        ") r: " .. round(c.r, 3)
    suit.Label(str, { align = "left" }, suit.layout:col(w, h))
  elseif c.type == "contact" then
    local str = c.otherEid .. " N" .. coordStrParen(c.nx, c.ny) .. " loc" ..
        coordStrParen(c.x, c.y)
    suit.Label(str, { align = "left" }, suit.layout:col(w, h))
  elseif c.type == "tag" then
    suit.Label(c.name, { align = "left" }, suit.layout:col(w, h))
  else
    local str = nameBlurb(c)
    for key, val in pairs(c) do
      if key ~= "name" and key ~= "cid" and key ~= "eid" and key ~= "type" then
        if type(val) == "number" then val = round(val, 3) end
        -- str = str .. key .. ": " .. tostring(val) .. " "
        str = str .. key .. ": " .. inspect(val) .. " "
      end
    end
    suit.Label(str, { align = "left" }, suit.layout:col(w, h))
  end

  suit.layout:returnLeft()
end

local function makeFilter(filterTxt, pinnedEnts)
  return { text = filterText, pat = "^" .. filterTxt, pinned = pinnedEnts }
end

local function matchEntity(e, f)
  if (f.pinned and f.pinned[e.eid]) or e.eid:match(f.pat) or
      (e.name and e.name.name:match(f.pat)) then
    return true
  end
  return false
end

local function getFilteredEntities(ents, filter)
  local ret = {}
  for eid, e in pairsByKeys(ents, compareEids) do
    if matchEntity(e, filter) then table.insert(ret, e) end
  end
  return ret
end

-- for eid,e in pairsByKeys(estore.ents, compareEids) do

local function updateEstoreGui(ui, estore)
  local h = 15

  suit.Label("Filter", suit.layout:row(35, h))
  suit.Input(ui.entityFilterInput, suit.layout:col(90, h))
  suit.layout:returnLeft()
  local filterTxt = ui.entityFilterInput.text
  local ents = getFilteredEntities(estore.ents,
    makeFilter(filterTxt, ui.pinnedEnts))
  -- For each Entity (sorted ascend by numeric eid)
  -- for eid,e in pairsByKeys(estore.ents, compareEids) do
  for _, e in ipairs(ents) do
    local eid = e.eid
    -- Entity name button
    local name = eid
    if e.name then
      name = name .. "." .. e.name.name
    elseif e.tag then
      name = name .. "." .. e.tag.name
    end
    if #name > 17 then name = name:sub(1, 17) .. ">" end
    if suit.Button(name, { id = eid, align = "left" }, suit.layout:row(130, h)).hit then
      if ui.ents[eid] then
        ui.ents[eid] = nil
      else
        ui.pinnedEnts[eid] = true
        ui.ents[eid] = true
      end
    end

    -- Entity "pinned" checkbox
    local pinned = ui.pinnedEnts[eid] == true
    if suit.Checkbox({ checked = pinned }, { id = eid .. "_keep", align = "right" },
          suit.layout:col(100, 15)).hit then
      if not pinned then
        ui.pinnedEnts[eid] = true
      else
        ui.pinnedEnts[eid] = false
      end
    end
    suit.layout:returnLeft()

    -- If Entity is "opened", show the components
    if ui.ents[eid] then
      local comps = {}
      for _, comp in pairs(estore.comps) do
        if eid == comp.eid then table.insert(comps, comp) end
      end

      table.sort(comps, function(a, b)
        -- return a.type < b.type
        return tonumber(a.cid:sub(2)) < tonumber(b.cid:sub(2))
      end)

      for _, comp in ipairs(comps) do updateCompGui(comp) end
    end
  end
end

function Editor.update(editor)
  local ret = {}
  local ui = editor.ui

  local x = 0
  local y = 0
  local h = 25
  suit.layout:reset(x, y, 5, 2)

  suit.Label("Opacity", { align = "left" }, suit.layout:row(100, h))
  suit.Slider(ui.bgOpacity, suit.layout:col(100, h))
  suit.Label(tostring(ui.bgOpacity.value), suit.layout:col(50, h))
  if suit.Button("Reset", { id = "reset2" }, suit.layout:col(50, h)).hit then
    ui.bgOpacity.value = 0.8
  end

  suit.layout:returnLeft()
  suit.Label("Time Dilation", { align = "left" }, suit.layout:row(100, h))
  suit.Slider(ui.timeSpeedSlider, suit.layout:col(100, h))
  suit.Label(tostring(ui.timeSpeedSlider.value), suit.layout:col(50, h))
  if suit.Button("Reset", suit.layout:col(50, h)).hit then
    ui.timeSpeedSlider.value = 1
  end

  suit.layout:returnLeft()
  suit.Checkbox(ui.historyCheckbox, suit.layout:row(100, h))
  editor.recording = ui.historyCheckbox.checked

  suit.layout:returnLeft()
  suit.Checkbox(ui.pausedCheckbox, suit.layout:row(100, h))

  ui.timeNavSlider.min = 1
  ui.timeNavSlider.max = editor.history:length()
  ui.timeNavSlider.value = editor.historyIndex

  suit.Label("History:", { align = "left" }, suit.layout:col(50, h))
  if editor.history:length() > 0 then
    suit.Slider(ui.timeNavSlider, suit.layout:col(300, h))
    roundSliderValue(ui.timeNavSlider)
    suit.Label(tostring(ui.timeNavSlider.value), suit.layout:col(50, h))
    if suit.Button("<", suit.layout:col(20, h)).hit then
      adjSliderValue(ui.timeNavSlider, -1)
    end
    if suit.Button(">", suit.layout:col(20, h)).hit then
      adjSliderValue(ui.timeNavSlider, 1)
    end
    if ui.timeNavSlider.value == ui.timeNavSlider.max then
      if suit.Button("Step 1", suit.layout:col(50, h)).hit then
        ret.step = true
      end
    end
    editor.historyIndex = ui.timeNavSlider.value
  end

  suit.layout:returnLeft()
  suit.Checkbox(ui.estoreCheckbox, suit.layout:row(100, 25))
  if ui.estoreCheckbox.checked then updateEstoreGui(ui, getEstore(editor)) end

  return ret
end

function Editor.draw(editor, opts)
  G.setColor(0, 0, 0, editor.ui.bgOpacity.value)
  G.rectangle("fill", unpack(opts.rect))
  G.setColor(1, 1, 1)
  suit.draw()

  local n = editor.ui.notesBox
  local nx = opts.rect[3] - n.w
  local ny = 0
  Debug.drawNotes(nx, ny)
end

function Editor.keypressed(key)
  suit.keypressed(key)
end

function Editor.textinput(text)
  suit.textinput(text)
end

return Editor
