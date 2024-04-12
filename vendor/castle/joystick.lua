local Joystick = {}

Joystick.ControlMaps = {
  Dualshock = {
    name = "Dualshock",
    numAxes = 5,
    numButtons = 12,
    axisControls = {leftx = 1, lefty = 2, unknown = 3, rightx = 4, righty = 5},
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
    axisControls = {leftx = 1, lefty = 2},
    axisNames = {[1] = "leftx", [2] = "lefty"},
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
