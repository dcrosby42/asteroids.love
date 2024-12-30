-- camera_dev_system
--
-- Based on entities tagged "camera_dev_controller",
-- uses keystate to manipulate camera location/rotation/zoom

local TweenHelpers = require "castle.tween.tween_helpers"
local ZoomFactor = 0.2
local RotFactor = math.pi / 8
local PanFactor = 200
local TweenTime = 0.3
-- local TweenTime = 2
local Debug = (require "mydebug").sub("camera_dev_system", true, true)

local round = math.round

local function tweenit(e, compProps, timerName)
  TweenHelpers.addTweens(e, timerName, compProps, {
    duration = TweenTime,
    easing = "outQuint",
  })
end

local function zoomCameraTo(camera, zoom)
  tweenit(camera, { tr = { sx = zoom, sy = zoom } }, "zoom")
  Debug.println("zoomCameraTo " .. tostring(zoom))
end

local function zoomCameraIn(camera, factor)
  -- Zooming camera IN means SHRINKING sx,sy
  zoomCameraTo(camera, camera.tr.sx * (1 - factor))
end

local function zoomCameraOut(camera, factor)
  -- Zooming camera OUT means GROWING sx,sy
  zoomCameraTo(camera, camera.tr.sx * (1 + factor))
end

local function rotateCameraTo(camera, rot)
  tweenit(camera, { tr = { r = rot } }, "tr.r")
  Debug.println("rotateCameraTo " .. tostring(rot))
end

local function rotateCameraBy(camera, rot)
  local r = camera.tr.r + rot
  rotateCameraTo(camera, r)
end

local function panCameraTo(camera, x, y)
  tweenit(camera, { tr = { x = x, y = y } }, "pan")
end

local function panCameraBy(camera, x, y)
  x = x + camera.tr.x
  y = y + camera.tr.y
  panCameraTo(camera, x, y)
end

local function cameraHasDebugVis(camera)
  return camera.circles and camera.circles.debugdot
end

local function cameraDbgText(camera)
  local s = tostring(round(camera.tr.x)) .. ", " .. tostring(round(camera.tr.y))
  s = s .. "\nr: " .. tostring(round(camera.tr.r, 2))
  s = s .. "\nz: " .. tostring(round(camera.tr.sx, 2))
  return s
end

local function addCameraDebugVis(camera, name)
  -- add an orange circle
  local color = { 1, 0.5, 0 }
  camera:newComp("circle", { name = "debugdot", r = 10, color = color })
  -- add some info
  camera:newComp("label", { name = "debuglabel", x = 10, y = -15, text = cameraDbgText(camera), color = color })
end

local function removeCameraDebugVis(camera, name)
  if camera.circle then
    camera:removeComp(camera.circle)
  end
  if camera.label then
    camera:removeComp(camera.label)
  end
end

local function updateCameraDebugVis(camera)
  camera.label.text = cameraDbgText(camera)
end


return defineQuerySystem(
  { tag = 'camera_dev_controller' },
  function(e, estore, input, res)
    local camera = estore:getEntityByName(e.states.camera.value)
    if not camera then return end

    if e.keystate.pressed["="] then
      zoomCameraIn(camera, ZoomFactor)
    end
    if e.keystate.pressed["-"] then
      zoomCameraOut(camera, ZoomFactor)
    end
    if e.keystate.pressed["0"] then
      zoomCameraTo(camera, 1)
      rotateCameraTo(camera, 0)
      panCameraTo(camera, 0, 0)
    end
    if e.keystate.pressed["]"] then
      rotateCameraBy(camera, -RotFactor)
    end
    if e.keystate.pressed["["] then
      rotateCameraBy(camera, RotFactor)
    end
    if e.keystate.pressed["w"] then
      panCameraBy(camera, 0, -PanFactor)
    end
    if e.keystate.pressed["a"] then
      panCameraBy(camera, -PanFactor, 0)
    end
    if e.keystate.pressed["s"] then
      panCameraBy(camera, 0, PanFactor)
    end
    if e.keystate.pressed["d"] then
      panCameraBy(camera, PanFactor, 0)
    end

    if e.states.debug.value == true then
      if cameraHasDebugVis(camera) then
        updateCameraDebugVis(camera)
      else
        addCameraDebugVis(camera)
      end
    else
      if cameraHasDebugVis(camera) then
        removeCameraDebugVis(camera)
      end
    end
  end
)
