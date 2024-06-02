local Jigs = {}

Jigs.test_flight = require "modules.asteroids.jigs.test_flight"
Jigs.flame_editor = require "modules.asteroids.jigs.flame_editor"
Jigs.bullet_editor = require "modules.asteroids.jigs.bullet_editor"
Jigs.roid_browser = require "modules.asteroids.jigs.roid_browser"
Jigs.explosion_browser = require "modules.asteroids.jigs.explosion_browser"

-- map of kbd presses to jigs:
local JigSelectorMap = {
  ["1"] = "test_flight",
  ["2"] = "bullet_editor",
  ["3"] = "flame_editor",
  ["4"] = "roid_browser",
  ["5"] = "explosion_browser",
}
-- local DefaultJigName = "roid_browser"
-- local DefaultJigName = "explosion_browser"
local DefaultJigName = "test_flight"
-- local DefaultJigName = "bullet_editor"

local function transitionToJig(jigName, workbench, estore, res)
  local currentJigName = workbench.states.jig.value
  local jig = Jigs[jigName]
  if jig and jig.init then
    if currentJigName and currentJigName ~= '' then
      -- destroy current jig
      local currentJig = Jigs[currentJigName]
      local currentJigE = estore:getEntityByName(currentJigName)
      if currentJig and currentJigE then
        if currentJig.finalize then
          -- optional finalize function
          currentJig.finalize(currentJigE, estore)
        end
        -- remove the existing jig entity
        currentJigE:destroy()
      end
    end
    -- create new jig entities(s)
    jig.init(workbench, estore, res)
    -- Update the workbench's jig name
    workbench.states.jig.value = jigName
  end
end

return function(estore, input, res)
  local workbench = estore:getEntityByName("ship_workbench")
  if not workbench then return end

  local currentJigName = workbench.states.jig.value
  if not currentJigName or currentJigName == "" then
    -- Create default jig
    transitionToJig(DefaultJigName, workbench, estore, res)
  else
    -- See if a jig selector was pushed
    local jigSelected
    for key, name in pairs(JigSelectorMap) do
      if workbench.keystate.pressed[key] then
        jigSelected = name
      end
    end
    -- (if so) Switch away from current jig to new jig
    if jigSelected then
      transitionToJig(jigSelected, workbench, estore, res)
    end
  end

  -- Update the current jig
  local jig = Jigs[workbench.states.jig.value]
  if jig and jig.update then
    jig.update(estore, input, res)
  end
end
