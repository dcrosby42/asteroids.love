require 'castle.helpers'
local D = {}

D.d = {
  varNames = {},
  varMap = {},
  lineHeight = 12,
  maxStringLines = 10,
  stringLines = {},
  notes = {},
  bounds = {},
  bgColor = { 0, 0, 0, 0.5 },
  fgColor = { 1, 1, 1, 1 },
  onces = {},
}

local function appendScrolled(lines, s, max)
  local e = #lines
  if e >= max then
    for i = 1, (e - 1) do lines[i] = lines[i + 1] end
    e = e - 1
  end
  n = e + 1
  lines[n] = s
end

local function println(str)
  appendScrolled(D.d.stringLines, str, D.d.maxStringLines)
end

local function toLines()
  local lines = {}
  local i = 1
  for sli, line in ipairs(D.d.stringLines) do
    lines[i] = line
    i = i + 1
  end
  return lines
end

local function setup()
  local bounds = D.d.bounds
  bounds.height = D.d.maxStringLines * D.d.lineHeight
  bounds.width = love.graphics.getWidth() -- / 2
  bounds.y = love.graphics.getHeight() - bounds.height
  bounds.x = 0
end

local function draw()
  local dlines = toLines()
  local y = D.d.bounds.y

  love.graphics.setColor(unpack(D.d.bgColor))
  love.graphics.rectangle("fill", 0, y, D.d.bounds.width, D.d.bounds.height)

  love.graphics.setColor(unpack(D.d.fgColor))
  for i, line in ipairs(dlines) do
    love.graphics.print(line, 0, y)
    y = y + D.d.lineHeight
  end
  love.graphics.setColor(1, 1, 1, 1)
end

local function drawNotes(ox, oy)
  local x, y = ox, oy
  love.graphics.print("Notes:", x, y)
  y = y + D.d.lineHeight
  for name, notes in pairsByKeys(D.d.notes) do
    love.graphics.print(name, x, y)
    y = y + D.d.lineHeight
    x = ox + 10
    for key, val in pairs(notes) do
      love.graphics.print(key .. ": " .. val, x, y)
      y = y + D.d.lineHeight
    end
    x = ox
  end
end

local function resolveMessage(m)
  if type(m) == "string" then
    return m
  elseif type(m) == "function" then
    return m()
  else
    return tostring()
  end
end

local function makeSub(name, printToScreen, printToConsole, doNotes)
  D.onScreen[name] = printToScreen or D.onScreen[name]
  D.onConsole[name] = printToConsole or D.onConsole[name]
  D.doNotes[name] = doNotes or D.doNotes[name]
  local sub = {
    println = function(str)
      if D.onScreen[name] then
        D.println("[" .. name .. "] " .. resolveMessage(str))
      end
      if D.onConsole[name] then
        print("[" .. name .. "] " .. resolveMessage(str))
      end
    end,
    note = function(key, val)
      if D.doNotes[name] then
        local n = D.d.notes[name]
        if not n then
          n = {}
          D.d.notes[name] = n
        end
        if val == nil then
          n[key] = nil
        else
          if type(val) == "number" then
            n[key] = tostring(math.round(val, 3))
          else
            n[key] = tostring(val)
          end
        end
      end
    end,
    once = function(key, fn)
      if not D.d.onces[key] then
        local out = fn()
        if out then print("[" .. key .. "] " .. tostring(out)) end
        D.d.onces[key] = true
      end
    end,
  }
  sub.noteObj = function(leadup, map)
    local pref = ""
    for i = 1, #leadup do pref = pref .. tostring(leadup[i]) .. "." end
    for k, v in pairs(map) do sub.note(pref .. k, v) end
  end
  return sub
end

D.toLines = toLines
D.println = println
D.setup = setup
D.draw = draw
D.drawNotes = drawNotes
D.sub = makeSub
D.onConsole = {}
D.onScreen = {}
D.doNotes = {}

return D
