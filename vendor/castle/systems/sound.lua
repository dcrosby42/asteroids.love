local Debug = require("mydebug").sub("Sound", false, false)

-- Accumulate's playtime for "playing" sounds.
-- For non-looping sounds, once playtime exceeds the duration property, the sound component is deleted.
return defineUpdateSystem({ "sound" },
  function(e, estore, input, res)
    for _, sound in pairs(e.sounds) do
      if sound.state == "playing" then
        -- accumulate time for playing sounds
        sound.playtime = sound.playtime + input.dt

        local soundRes = res.sounds[sound.sound]
        if sound.music or soundRes.music then
          -- NB: sound comps with music=true do not auto-vanish on completion.
        else
          -- static sounds:
          if sound.duration <= 0 then
            sound.duration = res.sounds[sound.sound].duration
            Debug.println("Backfilled sound " .. sound.sound .. " duration=" .. tostring(sound.duration))
          end
          if (not sound.loop) and (sound.playtime > sound.duration) then
            Debug.println("Sound over, removing " .. tflatten(sound))
            e:removeComp(sound)
          end
        end
      end
    end
  end)
