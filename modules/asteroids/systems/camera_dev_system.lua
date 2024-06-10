local TweenHelpers = require "castle.tween.tween_helpers"
local ZoomFactor = 0.2
local RotFactor = math.pi / 8
local TweenTime = 0.3
local Debug = (require "mydebug").sub("camera_dev_system", true, true)

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

return defineUpdateSystem(hasTag('camera_dev_controller'),
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
    end
    if e.keystate.pressed["]"] then
      rotateCameraBy(camera, -RotFactor)
    end
    if e.keystate.pressed["["] then
      rotateCameraBy(camera, RotFactor)
    end
  end
)
