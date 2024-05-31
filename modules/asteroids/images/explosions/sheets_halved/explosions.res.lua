-- https://castorstudios.itch.io/animated-explosions-pack-4
-- https://www.codeandweb.com/free-sprite-sheet-packer settings->padding=0 -> 3072 = 384 * 8

local function debris_explosion(n)
  local picw, pich = 192, 192
  local s = 1
  if type(n) == "table" then
    picw = n[2]
    pich = picw
    if #n == 3 then
      pich = n[3]
    end
    if #n == 4 then
      s = n[4]
    end
    n = n[1]
  end
  local name = "debris_explosion_" .. tostring(n)
  return {
    type = "picStrip",
    name = name,
    data = {
      path = "modules/asteroids/images/explosions/sheets_halved/" .. name .. ".sheet.png",
      picWidth = picw,
      picHeight = pich,
      picOptions = {
        sx = s,
        sy = s,
        duration = 2 / 60,
      },
      anims = {
        [name] = {
          -- frameDuration = 1 / 60,
          -- sx = 2,
          -- sy = 1,
        } -- ?? frameDuration and sx,sy aren't having the desired effect. BUG? in renderer or loader?
      }
    }
  }
end

-- return map({ 1, 2, 3, 4, { 5, 192, 192, 2 }, 6 }, debris_explosion) -- #5 is a half-size image
return map({ 1, 2, 3, 4, 5, 6 }, debris_explosion) -- #5 is a half-size image
