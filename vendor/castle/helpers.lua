-- helpers.lua

-- Messy grab-bag of any useful helper funcs and extensions I want globally
-- available.

-- numberlua = require 'vendor/numberlua' -- intentionally global
-- bit32 = numberlua.bit32 -- intentionally global

if unpack == nil then
  unpack = table.unpack -- unpack moves out of global space starting in lua 5.2, I heard
end

function flattenTable(t)
  local s = ""
  for k, v in pairs(t) do
    if #s > 0 then
      s = s .. " "
    end
    s = s .. tostring(k) .. "=" .. tostring(v)
  end
  return s
end

tflatten = flattenTable

function tcount(t)
  local ct = 0
  for _, _ in pairs(t) do
    ct = ct + 1
  end
  return ct
end

function tcountby(t, key)
  local total = 0
  local counts = {}
  for _, item in pairs(t) do
    total = total + 1
    local k = item[key]
    if not counts[k] then
      counts[k] = 0
    end
    counts[k] = counts[k] + 1
  end
  return counts, total
end

function tcopy(orig, defaults)
  if orig == nil then
    orig = {}
  end
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
    if defaults then
      for def_key, def_value in pairs(defaults) do
        if copy[def_key] == nil then
          copy[def_key] = def_value
        end
      end
    end
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function shallowclone(src)
  if src == nil then
    return {}
  end
  local dest = {}
  for k, v in pairs(src) do
    dest[k] = v
  end
  return dest
end

function tcopydeep(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[tcopydeep(orig_key)] = tcopydeep(orig_value)
    end
    setmetatable(copy, tcopydeep(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function tkeys(t)
  local keys = {}
  local n = 0
  for k, _ in pairs(t) do
    n = n + 1
    keys[n] = k
  end
  return keys
end

function numkeys(t)
  return #tkeys(t)
end

function tvalues(t)
  local vals = {}
  local n = 0
  for _, v in pairs(t) do
    n = n + 1
    vals[n] = v
  end
  return vals
end

function tsetdeep(t, path, value)
  local key = table.remove(path, 1)
  if #path == 0 then
    t[key] = value
  else
    local next = t[key]
    if not next then
      next = {}
      t[key] = next
    end
    tsetdeep(next, path, value)
  end
end

function tgetdeep(t, path)
  local key = table.remove(path, 1)
  local v = t[key]
  if v == nil then
    return nil
  end
  if #path == 0 then
    return v
  end
  if type(v) == "table" then
    return tgetdeep(v, path)
  else
    return nil
  end
end

function lcopy(src)
  local c = {}
  for i = 1, #src do
    c[i] = src[i]
  end
  return c
end

function removeObject(list, obj)
  local ridx = 0
  for i = 1, #list do
    if list[i] == obj then
      ridx = i
      break
    end
  end
  if ridx > 0 then
    table.remove(list, ridx)
    return ridx
  end
  return nil
end

function tmerge(left, right)
  for k, v in pairs(right) do
    left[k] = v
  end
end

function clonemergeshallow(left, right)
  return tmerge(shallowclone(left), right)
end

function lindexof(t, v)
  for i, x in ipairs(t) do
    if x == v then
      return i
    end
  end
  return nil
end

function lfindindexof(t, fn)
  for i, x in ipairs(t) do
    if fn(x) == true then
      return i
    end
  end
  return nil
end

function tconcat(t1, t2)
  if not t2 then
    return t1
  end
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

function appendlist(l1, l2)
  local r = {}
  if l1 then
    for i = 1, #l1 do
      r[#r + 1] = l1[i]
    end
  end
  if l2 then
    for i = 1, #l2 do
      r[#r + 1] = l2[i]
    end
  end
  return r
end

function tdebug(t, ind)
  if not ind then
    ind = ""
  end

  if type(t) == "table" then
    local lines = {}
    if ind ~= "" then
      lines[1] = ""
    end -- inner tables need to bump down a line
    local count = 0
    for k, v in pairs(t) do
      local s = ind .. k .. ": " .. tdebug(v, ind .. "  ")
      table.insert(lines, s)
      count = count + 1
    end
    if count > 0 then
      return table.concat(lines, "\n")
    else
      return "{}"
    end
  else
    return tostring(t)
  end
end

function tdebug1(t, ind)
  if type(t) == "table" then
    local s = ""
    if not ind then
      ind = "  "
    end
    for k, v in pairs(t) do
      s = s .. ind .. tostring(k) .. ": " .. tostring(v) .. "\n"
    end
    return s
  else
    return ind .. tostring(t)
  end
end

function debugStringBytes(str)
  local out = ""
  for i = 1, #str do out = out .. string.byte(str, i) .. " " end
  return out
end

function keyvalsearch(t, matchFn, callbackFn)
  for k, v in pairs(t) do
    if matchFn(k, v) then
      callbackFn(k, v)
    end
  end
end

function valsearch(t, matchFn, callbackFn)
  for _, v in pairs(t) do
    if matchFn(v) then
      callbackFn(v)
    end
  end
end

function valsearchfirst(t, matchFn, callbackFn)
  for _, v in pairs(t) do
    if matchFn(v) then
      return callbackFn(v)
    end
  end
end

function tfind(t, fn)
  if t == nil or type(t) ~= "table" then
    return nil
  end
  for k, v in pairs(t) do
    if fn(v, k) == true then
      return v
    end
  end
end

function tfindby(t, key, val)
  for _, v in pairs(t) do
    if v[key] == val then
      return v
    end
  end
end

function tfindall(t, fn)
  local res = {}
  if t == nil or type(t) ~= "table" then
    return res
  end
  for k, v in pairs(t) do
    if fn(v, k) == true then
      table.insert(res, v)
    end
  end
  return res
end

function tfindallby(t, key, val)
  local res = {}
  for _, v in pairs(t) do
    if v[key] == val then
      table.insert(res, v)
    end
  end
  return res
end

function lcontains(list, item)
  for i = 1, #list do
    if list[i] == item then
      return true
    end
  end
  return false
end

function lfind(list, fn)
  for i = 1, #list do
    if fn(list[i], i) == true then
      return list[i]
    end
  end
end

function lfindby(list, key, val)
  for i = 1, #list do
    if list[i][key] == val then
      return list[i]
    end
  end
end

function lfindall(list, fn)
  local res = {}
  for i = 1, #list do
    if fn(list[i], i) == true then
      table.insert(res, list[i])
    end
  end
  return res
end

function lfindallby(list, key, val)
  local res = {}
  for i = 1, #list do
    if list[i][key] == val then
      table.insert(res, list[i])
    end
  end
  return res
end

-- Map over a list and return a list of transformed items
function lmap(list, fn)
  local res = {}
  for i = 1, #list do
    res[i] = fn(list[i])
  end
  return res
end

-- Map over the k,v in a map and return a map with the same keyset
function tmap(t, fn)
  local res = {}
  for key, val in pairs(t) do
    res[key] = fn(key, val)
  end
  return res
end

-- Sorts list in-place and returns it
-- (added this as a convenience; table.sort returns nil so it's no good for inlining)
function lsort(list, fn)
  table.sort(list, fn)
  return list
end

-- Returns a sorted clone of the given list
function lsorted(list, fn)
  local list2 = shallowclone(list)
  table.sort(list2, fn)
  return list2
end

function lfilter(list, fn)
  if not fn then return list end
  local values = {}
  for _i, val in ipairs(list) do
    if fn(val) then
      table.insert(values, val)
    end
  end
  return values
end

function tfilter(t, fn)
  if not fn then return t end
  local values = {}
  for _key, val in pairs(t) do
    if fn(val) then
      table.insert(values, val)
    end
  end
  return values
end

function iterateFuncs(funcs)
  return function(a, b, c)
    for _, fn in ipairs(funcs) do
      fn(a, b, c)
    end
  end
end

function math.dist(x1, y1, x2, y2)
  -- return ((x2-x1)^2+(y2-y1)^2)^0.5
  return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

dist = math.dist

function math.pointinrect(ptx, pty, x1, y1, x2, y2)
  return ptx >= x1 and ptx <= x2 and pty >= y1 and pty <= y2
end

function math.pointinrectwh(ptx, pty, rx, ry, rw, rh)
  return ptx >= rx and ptx < rx + rw and pty >= ry and pty < ry + rh
end

function math.pointinbounds(x1, y1, b)
  return x1 >= b.x and x1 < b.x + b.w and y1 >= b.y and y1 < b.y + b.h
end

-- Returns true if two rectangles overlap, false if they don't.
function math.rectanglesintersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
  return ax1 < bx2 and
      bx1 < ax2 and
      ay1 < by2 and
      by1 < ay2
end

-- Returns true if two rectangles overlap, false if they don't.
function math.rectanglesintersectwh(x1, y1, w1, h1, x2, y2, w2, h2)
  return x1 < x2 + w2 and
      x2 < x1 + w1 and
      y1 < y2 + h2 and
      y2 < y1 + h1
end

function math.clamp(val, min, max)
  if val < min then
    return min, true
  elseif val > max then
    return max, true
  else
    return val, false
  end
end

function math.round0(num)
  return math.floor(num + 0.5)
end

function math.round1(num)
  return math.floor(num * 10 + 0.5) / 10
end

function math.round(num, numDecimalPlaces)
  local mult = 10 ^ (numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function forEach(list, fn)
  if list then
    for i, x in ipairs(list) do
      fn(i, x)
    end
  end
end

function forEachMatching(list, key, val, fn)
  if list then
    for _, element in ipairs(list) do
      if element[key] == val then
        fn(element)
      end
    end
  end
end

function offsetBounds(t, w, h, wr, hr)
  t.w = w
  t.h = h
  t.offx = wr * w
  t.offy = hr * h
  return t
end

function lazy(fn)
  local called = false
  local value
  return function()
    if not called then
      value = fn()
      called = true
    end
    return value
  end
end

function lazytable(list, mapper)
  local m = {}
  for _, item in ipairs(list) do
    local k = item
    m[k] =
        lazy(
          function()
            return mapper(k)
          end
        )
  end
  return m
end

function makeTimeLookupFunc(data, opts)
  opts = tcopy(opts, { loop = true })
  return function(t)
    local newVal = nil
    if opts.loop then
      t = t % data[#data - 1]
    end
    for i = 1, #data, 2 do
      if t >= data[i] then
        newVal = data[i + 1]
      else
        return newVal
      end
    end
    return newVal
  end
end

function dirname(fname)
  return string.gsub(fname:match("(.*/)[^%/]+$"), "/$", "")
end

function split(str, char)
  local res = {}
  for i in string.gmatch(str, "[^" .. char .. "]+") do
    table.insert(res, i)
  end
  return res
end

function floatstr(x, places)
  places = places or 3
  return "" .. math.round(x, places)
end

-- Given w between 0.0 and 1.0,
-- generate a random number and
-- return true if less-or-equal than w.
-- Eg, randomChance(0.25) should return true 25% of the time.
function randomChance(w)
  w = w or 0.5
  return love.math.random() <= w
end

flipCoin = randomChance
coinFlip = randomChance

function randomInt(lo, hi)
  return math.floor(love.math.random() * (hi - lo + 1)) + lo
end

function randomFloat(lo, hi)
  lo = lo or 0
  hi = hi or 1
  return love.math.random() * (hi - lo) + lo
end

function pickRandom(list)
  return list[randomInt(1, #list)]
end

function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do
    table.insert(a, n)
  end
  table.sort(a, f)
  local i = 0 -- iterator variable
  local iter = function()
    -- iterator function
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  return iter
end

function colorstring(c)
  return "Color(" .. c[1] .. "," .. c[2] .. "," .. c[3] .. "," .. tostring(c[4]) .. ")"
end

function map(array, func)
  local new_array = {}
  for i, v in ipairs(array) do
    new_array[i] = func(v)
  end
  return new_array
end

function memoize0(fn)
  local result
  return function()
    if result == nil then
      result = fn()
    end
    return result
  end
end

function memoize1(fn)
  local cache = {}
  return function(arg)
    if not cache[arg] then
      cache[arg] = fn(arg)
    end
    return cache[arg]
  end
end

function memoize2(fn)
  local cache = {}
  return function(arg1, arg2)
    assert(arg1, "func from memoize2 ")
    if not cache[arg1] then
      cache[arg1] = {}
    end
    if not cache[arg1][arg2] then
      cache[arg1][arg2] = fn(arg1, arg2)
    end
    return cache[arg1][arg2]
  end
end

function tail(list)
  return { select(2, unpack(list)) }
end

function noop()
end

function arity(fn)
  return debug.getinfo(fn).nparams
end

-- Given a list of funcs, return a function that executes them all in order.
-- The funcs in the given list are expected to accept 2 args.
-- Funcs are executed for their side effects; this is mostly for things like drawing funcs.
-- (This isn't quite "composition" because the results of each all are discarded.)
-- No meaningful return comes from the resulting function.
-- IF THE FIRST FUNCTION'S ARITY IS 3:
--    * The tail of the funcs list will be converted via recursive call to makeFuncChain2,
--    * The first func will be invoked with that resulting tail func passed as third param.
--    * Because...? This lets a func programmtically decide when/if to resume executing the func chain.
--      (This was developed to allow the ViewportDrawSystem to pre/post modify
--      global graphics transform state surrounding the remaining drawing
--      operations)
function makeFuncChain2(fns)
  local n = 2
  if #fns == 0 then return noop end
  local func = fns[1]
  local remain = makeFuncChain2(tail(fns))
  if arity(func) == n + 1 then
    return function(a, b)
      func(a, b, function()
        remain(a, b)
      end)
    end
  else
    return function(a, b)
      func(a, b)
      remain(a, b)
    end
  end
end

function keyBy(list, key)
  local m = {}
  if type(key) == 'function' then
    for _, val in ipairs(list) do m[key(val)] = val end
  else
    for _, val in ipairs(list) do m[val[key]] = val end
  end
  return m
end

function groupBy(list, key)
  local m = {}
  for _, val in ipairs(list) do
    local vals = m[val[key]] or {}
    table.insert(vals, val)
    m[val[key]] = vals
  end
  return m
end

function groupThenKeyBy(list, gkey, mkey)
  local m = {}
  for _, val in ipairs(list) do
    local vals = m[val[gkey]] or {}
    vals[val[mkey]] = val
    m[val[gkey]] = vals
  end
  return m
end

function invertMap(map)
  local m = {}
  for key, val in pairs(map) do
    m[val] = key
  end
  return m
end

function array2grid(list, width, height)
  local i = 1
  local grid = {}
  for row = 1, height do
    grid[row] = {}
    for col = 1, width do
      grid[row][col] = list[i]
      i = i + 1
    end
  end
  return grid
end

function attrstring(t, keys)
  if not keys then
    keys = tkeys(t)
  end
  return table.concat(lmap(keys, function(key)
    return key .. ": " .. tostring(t[key])
  end), ", ")
end

function firstNonNil(...)
  local items = { ... }
  for i = 1, #items do
    if items[i] ~= nil then
      return items[i]
    end
  end
  return nil
end
