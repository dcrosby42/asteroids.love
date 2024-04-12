-- Per https://en.wikipedia.org/wiki/Lehmer_random_number_generator
local A = 48271
local B = 2147483647 -- 2^31 - 1

local function nextState(s)
  return (s * A) % B
end

local function churnState(s, n)
  for i = 1, n do
    s = nextState(s)
  end
  return s
end

local function randomFloat(s, lo, hi)
  lo = lo or 0.0
  hi = hi or 1.0
  local s1 = nextState(s)
  return (s1 / B) * (hi - lo) + lo, s1
end

-- lo and hi are INclusive
local function randomInt(s, lo, hi)
  local f, s1 = randomFloat(s)
  return math.floor(f * (hi - lo + 1)) + lo, s1
end

local function randomChance(s, w)
  w = w or 0.5
  local f, s1 = randomFloat(s)
  return (f <= w), s1
end

local function pickRandom(s, list)
  local i, s1 = randomInt(s, 1, #list)
  return list[i], s1
end

local function localRandom(seed, x, y)
  local num = (seed % B) * math.floor(math.pow(love.math.noise(x / 10, y / 10) * 10000, 2))
  num = churnState(num, 5)
  return num
end

return {
  A = A,
  B = B,
  nextState = nextState,
  churnState = churnState,
  randomFloat = randomFloat,
  randomInt = randomInt,
  randomChance = randomChance,
  pickRandom = pickRandom,
  localRandom = localRandom,
  -- new = function(s) return Rng:new(s) end,
}
