local Joystick = {}

local Defs = {
  {
    name = "PS4 Controller",
    axes = {
      { 1, "leftx" },
      { 2, "lefty" },
      { 3, "rightx" },
      { 4, "righty" },
      { 5, "l2" },
      { 6, "r2" },
    },
    buttons = {
      { 1,  "face1",   "cross" },
      { 2,  "face2",   "circle" },
      { 3,  "face3",   "square" },
      { 4,  "face4",   "triangle" },
      { 5,  "select",  "share" },
      { 6,  "power",   "ps" },
      { 7,  "start",   "pause" },
      { 8,  "l3" },
      { 9,  "r3" },
      { 10, "l1" },
      { 11, "r1" },
      { 12, "up" },
      { 13, "down",    "dpad_down" },
      { 14, "left",    "dpad_left" },
      { 15, "right",   "dpad_right" },
      { 16, "touchpad" },
    },
  }
}

Joystick.ControlMaps = {
  -- ["PS4 Controller"] = {
  --   name = "PS4 Controller",
  --   numAxes = 5,
  --   numButtons = 12,
  --   axisControls = { leftx = 1, lefty = 2, rightx = 3, righty = 4, l2 = 5, r2 = 6 },
  --   axisNames = {
  --     [1] = "leftx",
  --     [2] = "lefty",
  --     [3] = "rightx",
  --     [4] = "righty",
  --     [5] = "l2",
  --     [6] = "r2",
  --   },
  --   buttonControls = {
  --     face1 = 1, -- cross
  --     face2 = 2, -- circle
  --     face3 = 3, -- square
  --     face4 = 4, -- triangle
  --     select = 5,
  --     ps = 6,
  --     start = 7,
  --     l3 = 8,
  --     r3 = 9,
  --     l1 = 10,
  --     r1 = 11,
  --     up = 12,
  --     down = 13,
  --     left = 14,
  --     right = 15,
  --     touchpad = 16,
  --   },
  --   buttonNames = {
  --     [1] = "face1",
  --     [2] = "face2",
  --     [3] = "face3",
  --     [4] = "face4",
  --     [5] = "l2",
  --     [6] = "r2",
  --     [7] = "l1",
  --     [8] = "r1",
  --     [9] = "select",
  --     [10] = "start",
  --     [11] = "l3",
  --     [12] = "r3",
  --   },
  -- },
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
  for _, bdef in ipairs(def.buttons) do
    mapping.buttonNames[bdef[1]] = bdef[2]
    for i = 2, #bdef do
      mapping.buttonControls[bdef[i]] = bdef[1]
    end
  end

  mapping.numAxes = #def.axes
  mapping.axisControls = {}
  mapping.axisNames = {}
  for _, adef in ipairs(def.axes) do
    mapping.axisNames[adef[1]] = adef[2]
    for i = 2, #adef do
      mapping.axisControls[adef[i]] = adef[1]
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

return Joystick
