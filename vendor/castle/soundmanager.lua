-- soundmanager
--
-- Singleton wrapper around audio state.
--
-- manage(key, source): call for each alive sound each update tick
-- cleanup(): call once during each draw phase; removes un-pinged sounds
-- get(key) -> Source: return a managed Source by its key
-- remove(key): stop and remove a sound by its key
--
local Debug = require('mydebug').sub("soundmanager", false, false, false)
local GC = require('garbagecollect')

Debug.println("initialize")
love.audio.stop()

-- global state:
local _sources = {}       -- map[key -> Source]
local _pinged = {}        -- map[key -> bool]
local _paused = false     -- track if the global audio has been paused
local _pausedSources = {} -- track if the global audio has been paused

-- public singleton (facade for global state):
if not soundmanager then
  soundmanager = {}
end

-- Register an in-use audio Source by unique key.
-- (Ok to call and re-call with same key-source each update.)
-- Marks the sound as "pinged" (ie, "in use") for the current update, preventing
-- cleanup() from stopping removing the sound.
function soundmanager.manage(key, audioSrc)
  if not _sources[key] then
    Debug.println("managing sound " .. key)
  end
  _sources[key] = audioSrc
  _pinged[key] = true
  Debug.note(key, "on")
end

-- Remove sounds that haven't been "drawn"
-- Invoke after each update tick.
function soundmanager.cleanup()
  -- Remove any sounds that weren't pinged during the last update.
  for key, wasPinged in pairs(_pinged) do
    if not wasPinged then
      soundmanager.remove(key)
    end
  end
  -- Clear "pinged" state
  _pinged = {}
end

-- Retrieve a registered audio Source by its key.
-- Returns nil if not found.
function soundmanager.get(key)
  return _sources[key]
end

-- Stop and remove an audio Source by its key
function soundmanager.remove(key)
  local audioSrc = soundmanager.get(key)
  if audioSrc then
    love.audio.stop(audioSrc)
    _sources[key] = nil
    _pinged[key] = nil
    GC.request()
    Debug.note(key, nil) -- remove from notes
    Debug.println("removed sound " .. key)
  else
    Debug.println("remove " .. key .. ": sound not found.")
  end
end

function soundmanager.pause()
  if _paused then return end
  _paused = true
  _pausedSources = love.audio.pause()
  Debug.println("Paused")
end

function soundmanager.unpause()
  if not _paused then return end
  _paused = false
  for _, src in ipairs(_pausedSources) do
    love.audio.play(src)
  end
  _pausedSources = {}
  Debug.println("Unpaused")
end

function soundmanager.isPaused()
  return _paused
end

function soundmanager.printstate()
  print("*** soundmanager state ***")
  print("_paused: " .. tostring(_paused))
  print("#_pausedSources: " .. #_pausedSources)
  print("_sources (" .. tcount(_sources) .. "):\n" .. tdebug(tkeys(_sources)))
  print("_pinged (" .. tcount(_pinged) .. "):\n" .. tdebug(_pinged))
  print("**************************")
end

return soundmanager
