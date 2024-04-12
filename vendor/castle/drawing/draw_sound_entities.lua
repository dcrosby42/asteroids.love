local soundmanager = require "castle.soundmanager"
local mk_entity_draw_loop = require "castle.drawing.mk_entity_draw_loop"

local Debug = require('mydebug').sub("DrawSound", false, false)
local inspect = require("inspect")

local PLAYTIME_SYNC_TOLERANCE = 0.1 -- roughly 3 frames

local function getSoundKey(sndComp)
  return "sound." .. sndComp.eid .. "." .. sndComp.cid .. "." .. sndComp.sound
end

local function getSoundCompTime(sndCmp)
  if sndCmp.loop and sndCmp.duration > 0 then
    return sndCmp.playtime % sndCmp.duration
  end
  return sndCmp.playtime
end

-- "draw" sound components by using love's Source and Castle's soundmanager.
-- Creates or updates underlying sound Source objects based on component state.
-- Invoking soundmanager.manage() lets the soundmanager the sound still "exists" in the ECS world.
-- (After each global update, Source objects that didn't get marked via manage() will be stopped and removed.)
local function drawSound(e, soundComp, res)
  if soundmanager.isPaused() then return end
  local key = getSoundKey(soundComp)

  -- Is there already a Source for this sound component?
  local audioSrc = soundmanager.get(key)
  if audioSrc then
    -- Source already existing.
    if soundComp.state == "playing" and not audioSrc:isPlaying() then
      audioSrc:play()
    elseif soundComp.state ~= "playing" and audioSrc:isPlaying() then
      audioSrc:pause()
    end
    -- If the component's idea of playtime is different (by at least 0.05 seconds)
    -- then seek the underlying sound to the expected time.
    local t = getSoundCompTime(soundComp)
    local diff = math.abs(t - audioSrc:tell())
    if diff > PLAYTIME_SYNC_TOLERANCE then
      Debug.println(function()
        return "seeking to t=" .. tostring(t) .. " because audioSrc=" .. tostring(audioSrc:tell())
      end)
      audioSrc:seek(t)
    end
    -- Poke the soundmanager to let 'im know we still care about this sound:
    soundmanager.manage(key, audioSrc)
  else
    if soundComp.state == 'playing' then
      -- Sound component is new and playing.
      -- 1. Lookup our sound configuration in resources
      -- 2. Create and configure new love.audio Source object
      -- 3. Register the Source with soundmanager for ongoing maint
      Debug.println("Playing sound " .. soundComp.sound)
      local soundRes = res.sounds[soundComp.sound]
      if soundRes then
        -- New Source:
        Debug.println(function()
          return "soundComp=" .. inspect(soundComp)
              .. " soundRes=" .. inspect(soundRes)
        end)
        local audioSrc
        if soundComp.music or soundRes.music or soundRes.data == nil then
          audioSrc = love.audio.newSource(soundRes.file, "stream")
        else
          audioSrc = love.audio.newSource(soundRes.data, "static")
        end
        audioSrc:setLooping(soundComp.loop)
        audioSrc:seek(getSoundCompTime(soundComp))
        audioSrc:setVolume(soundComp.volume * soundRes.volume)

        -- Manage:
        soundmanager.manage(key, audioSrc)

        -- Start playing:
        audioSrc:play()
      else
        Debug.println("!! update() unknown sound in " .. tflatten(soundComp))
      end -- end if soundCfg
    else
      -- Debug.println("Not playing")
    end -- end if playing
  end   -- end if src
end

return mk_entity_draw_loop('sounds', drawSound)
