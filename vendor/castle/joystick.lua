local Joystick = {}

-- PS4 R2 and L2 triggers report as axis type controls.
-- They report from -1 to 1, with 0 somewhere around half-pulled.
-- This func adjusts the range from: rest position at 0, full-pull at 1.
local function normalizePs4TriggerAccess(value)
  return (value + 1) / 2
end

local Defs = {
  {
    name = "PS4 Controller",
    axes = {
      { 1, "leftx" },
      { 2, "lefty" },
      { 3, "rightx" },
      { 4, "righty" },
      { 5, "l2",    { transform = normalizePs4TriggerAccess } },
      { 6, "r2",    { transform = normalizePs4TriggerAccess } },
    },
    buttons = {
      { 1,  "face1", },
      { 2,  "face2", },
      { 3,  "face3", },
      { 4,  "face4", },
      { 5,  "select", },
      { 6,  "power", },
      { 7,  "start", },
      { 8,  "l3" },
      { 9,  "r3" },
      { 10, "l1" },
      { 11, "r1" },
      { 12, "up", },
      { 13, "down", },
      { 14, "left", },
      { 15, "right", },
      { 16, "touchpad" },
    },
  }
}

Joystick.ControlMaps = {
  Dualshock = {
    name = "Dualshock",
    numAxes = 5,
    numButtons = 12,
    axisControls = { leftx = 1, lefty = 2, unknown = 3, rightx = 4, righty = 5 },
    axisNames = {
      [1] = "leftx",
      [2] = "lefty",
      [3] = "unknown",
      [4] = "rightx",
      [5] = "righty",
    },
    buttonControls = {
      face1 = 1,
      face2 = 2,
      face3 = 3,
      face4 = 4,
      l2 = 5,
      r2 = 6,
      l1 = 7,
      r1 = 8,
      select = 9,
      start = 10,
      l3 = 11,
      r3 = 12,
    },
    buttonNames = {
      [1] = "face1",
      [2] = "face2",
      [3] = "face3",
      [4] = "face4",
      [5] = "l2",
      [6] = "r2",
      [7] = "l1",
      [8] = "r1",
      [9] = "select",
      [10] = "start",
      [11] = "l3",
      [12] = "r3",
    },
  },
  GamePadPro = {
    name = "GamePadPro",
    numAxes = 2,
    numButtons = 10,
    axisControls = { leftx = 1, lefty = 2 },
    axisNames = { [1] = "leftx", [2] = "lefty" },
    buttonControls = {
      face1 = 4,
      face2 = 3,
      face3 = 2,
      face4 = 1,
      l2 = 5,
      r2 = 6,
      l1 = 7,
      r1 = 8,
      select = 9,
      start = 10,
    },
    buttonNames = {
      [1] = "face4",
      [2] = "face3",
      [3] = "face2",
      [4] = "face1",
      [5] = "l2",
      [6] = "r2",
      [7] = "l1",
      [8] = "r1",
      [9] = "select",
      [10] = "start",
    },
  },
}

for _, def in ipairs(Defs) do
  local mapping = {}
  mapping.name = def.name

  mapping.numButtons = #def.buttons
  mapping.buttonControls = {}
  mapping.buttonNames = {}
  mapping.transforms = {} -- index of control ids to transform funcs (optional)
  for _, buttonDef in ipairs(def.buttons) do
    -- map button id to button name
    mapping.buttonNames[buttonDef[1]] = buttonDef[2]
    -- map button name to button id
    mapping.buttonControls[buttonDef[2]] = buttonDef[1]
  end

  mapping.numAxes = #def.axes
  mapping.axisControls = {}
  mapping.axisNames = {}
  mapping.axisTransforms = {}
  for _, axisDef in ipairs(def.axes) do
    -- map axis id to axis name
    mapping.axisNames[axisDef[1]] = axisDef[2]
    -- map axis name to axis id
    mapping.axisControls[axisDef[2]] = axisDef[1]
    if axisDef[3] then
      -- opts: transform
      if axisDef[3].transform then
        mapping.axisTransforms[axisDef[1]] = axisDef[3].transform
      end
    end
  end

  Joystick.ControlMaps[mapping.name] = mapping
end



-- Aliasing:
Joystick.ControlMaps["Generic   USB  Joystick  "] =
    Joystick.ControlMaps.Dualshock
Joystick.ControlMaps["GamePad Pro USB "] = Joystick.ControlMaps.GamePadPro

Joystick.ControlMaps.Default = Joystick.ControlMaps.Dualshock
Joystick.DefaultControlMap = Joystick.ControlMaps.Default

function Joystick.getControlMap(name)
  local map = Joystick.ControlMaps[name] or Joystick.ControlMaps.Default
  assert(map, "Joystick: Couldn't find ControlMap for '" .. name .. "'")
  return map
end

function Joystick.getControlMapForJoystick(joystick)
  return Joystick.getControlMap(joystick:getName())
end

local AxisDeadzone = 0.18

-- Small axis values are quashed to 0
local function applyAxisDeadzone(value)
  return math.abs(value) >= AxisDeadzone and value or 0
end

-- If the given joystick config contains a special transform func for the given axis,
-- apply the transform, otherwise just return value.
local function transformAxisValue(controlMap, axisId, value)
  local txfunc = controlMap.axisTransforms and controlMap.axisTransforms[axisId]
  if txfunc then
    value = txfunc(value)
  end
  return value
end

-- Apply special transforms and deadzone threshold to control value
function Joystick.groomAxisValue(controlMap, axis, value)
  return applyAxisDeadzone(transformAxisValue(controlMap, axis, value))
end

return Joystick
