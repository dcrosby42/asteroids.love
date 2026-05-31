-- camera_dev_system
--
-- Based on entities tagged "camera_dev_controller",
-- uses keystate to manipulate camera location/rotation/zoom

local TweenHelpers = require "castle.tween.tween_helpers"
local ZoomFactor = 0.2
local RotFactor = math.pi / 8
local PanFactor = 200
local TweenTime = 0.5
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

local Query = require "castle.ecs.query"
local planetQuery = Query.create({
  indexLookup = { name = "byTag", key = "planet" }
})

local function focusNextPlanet(estore, devController, camera)
  -- Figure out which (if any) planet is focused
  local focusedPlanet = ""
  if devController.states.focused_planet then
    focusedPlanet = devController.states.focused_planet.value
  else
    -- first time, let's add a place to store the focus state
    devController:newComp("state", { name = "focused_planet", value = "" })
  end

  -- Find all planets
  local planetEnts = planetQuery(estore)
  if #planetEnts == 0 then
    -- Nothing to do
    Debug.println("Couldn't find any planets to focus")
    return
  end

  -- Find the currently focused planet (if we think we have one)
  local currentPlanetIdx = 1
  if focusedPlanet and focusedPlanet ~= "" then
    for i = 1, #planetEnts do
      if planetEnts[i].name.name == focusedPlanet then
        currentPlanetIdx = i
      end
    end
  end

  -- Find the new planet to focus
  local nextPlanetIdx = currentPlanetIdx + 1
  if nextPlanetIdx > #planetEnts then
    -- wrap back to the front of the list
    nextPlanetIdx = 1
  end

  -- Begin focusing animation by tweening the camera to the new location
  if nextPlanetIdx <= #planetEnts then
    local planetE = planetEnts[nextPlanetIdx]
    Debug.println("Switching focus to " .. planetE.name.name)
    panCameraTo(camera, planetE.tr.x, planetE.tr.y)

    local info = planetE.states.object_info.value
    zoomCameraTo(camera, info.camera_zoom)
    rotateCameraTo(camera, 0)

    -- Save focus state
    local nextName = planetE.name.name
    devController.states.focused_planet.value = nextName
  end
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

    if e.keystate.pressed["tab"] then
      focusNextPlanet(estore, e, camera)
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
