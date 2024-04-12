require "castle.helpers"

local Debug = require("mydebug").sub("pool")

local Pool = {}

-- {init, reset, finalize, proto, initSize, incSize, mulSize}
function Pool:new(conf)
  conf = conf or {}
  conf.initSize = conf.initSize or 5
  conf.incSize = conf.incSize or 10
  conf.mulSize = conf.mulSize or 1
  if conf.proto then
    if not conf.init then
      conf.init = function()
        return tcopy(conf.proto)
      end
    end
    if not conf.reset then
      conf.reset = function(item)
        tmerge(item, conf.proto)
      end
    end
  end
  if not conf.init then error("Pool requires init func") end
  conf.reset = conf.reset or function(item)
  end
  conf.finalize = conf.finalize or function(item)
  end

  -- initial fill
  local items = {}
  for i = 1, conf.initSize do
    items[i] = conf.init()
    if items[i] == nil then
      error("Trying to initialize pool, init() func returned nil")
    end
  end

  local o = {
    newItem = conf.init,
    resetItem = conf.reset,
    finalizeItem = conf.finalize,
    initSize = conf.initSize,
    incSize = conf.incSize,
    mulSize = conf.mulSize,
    items = items,
    cap = #items,
  }
  Debug.println("constructor: cap " .. o.cap)
  setmetatable(o, self)
  self.__index = self
  return o
end

function Pool:get()
  local items = self.items
  local lasti = #items
  if lasti == 0 then
    self:expand()
    lasti = #items
  end
  local obj = items[lasti]
  items[lasti] = nil
  Debug.println("get()")
  return obj
end

function Pool:put(obj)
  self.resetItem(obj)
  self.items[#self.items + 1] = obj
  Debug.println("put()")
end

function Pool:expand()
  local newCap = (self.cap * self.mulSize) + self.incSize
  Debug.println(
    "newCap " .. newCap .. " / oldcap " .. self.cap .. " mulSize " ..
    self.mulSize .. " incSize " .. self.incSize)
  local start = #self.items + 1
  local num = newCap - self.cap
  for i = start, num do
    Debug.println(start .. "->" .. num .. "expand(" .. i .. ")")
    self.items[i] = self.newItem()
  end
  self.cap = newCap
  Debug.println("cap is now " .. self.cap)
end

function Pool:debugString()
  return "[Pool count=" .. #self.items .. " " .. tflatten(self) .. "]"
end

function Pool:debugStringFull()
  local str = "[Pool count=" .. #self.items .. " " .. tflatten(self) .. "\n"
  for i, item in ipairs(self.items) do
    str = str .. "  " .. i .. ": " .. tflatten(item) .. "\n"
  end
  return str
end

return Pool
