-- RollingHistory (see below)
--
-- ...is just a small wrapper around this other implementation:
--
-- circular buffer factory for lua
-- (dcrosby downloaded this gist from Github: https://gist.githubusercontent.com/johndgiese/3e1c6d6e0535d4536692/raw/5be9899066fd0f3b45f44fa0b6979038548bd931/circular_buffer.lua

local function rotate_indice(i, n)
    return ((i - 1) % n) + 1
end

local circular_buffer = {}

function circular_buffer:filled()
    return #(self.history) == self.max_length
end

function circular_buffer:push(value)
    if self:filled() then
        local value_to_be_removed = self.history[self.oldest]
        self.history[self.oldest] = value
        self.oldest = self.oldest == self.max_length and 1 or self.oldest + 1
    else
        self.history[#(self.history) + 1] = value
    end
end

circular_buffer.metatable = {}

-- positive values index from newest to oldest (starting with 1)
-- negative values index from oldest to newest (starting with -1)
function circular_buffer.metatable:__index(i)
    local history_length = #(self.history)
    if i == 0 or math.abs(i) > history_length then
        return nil
    elseif i >= 1 then
        local i_rotated = rotate_indice(self.oldest - i, history_length)
        return self.history[i_rotated]
    elseif i <= -1 then
        local i_rotated = rotate_indice(i + 1 + self.oldest, history_length)
        return self.history[i_rotated]
    end
end

function circular_buffer.metatable:__len()
    return #(self.history)
end

function circular_buffer.new(max_length)
    if type(max_length) ~= 'number' or max_length <= 1 then
        error("Buffer length must be a positive integer")
    end

    local instance = {
        history = {},
        oldest = 1,
        max_length = max_length,
        push = circular_buffer.push,
        filled = circular_buffer.filled,
    }
    setmetatable(instance, circular_buffer.metatable)
    return instance
end

-- XXX return circular_buffer
-- (we're hiding this impl in favor of RollingHistory below -- dcrosby

--
-- RollingHistory
--
-- dcrosby wrote the RolingHistory wrapper around circular_buffer Sun Jan  6 18:42:08 EST 2019
-- because I wanted any easy append-only, [1]-is-the-oldest, [length]-is-the-newest index scheme.
--

local RollingHistory = {}

function RollingHistory:new(maxlen)
  local o = {
    _buffer = circular_buffer.new(maxlen),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function RollingHistory:length()
  return #(self._buffer.history)
end

function RollingHistory:push(data)
  self._buffer:push(data)
end

function RollingHistory:get(i)
  local len = self:length()
  if len == 0 then return nil end
  -- CircularBuffer is ordered FILO so if we want i=1 to mean 
  -- the "beginning" of the list, or the "oldest" entry, we use reverse indexing.
  return self._buffer[len + 1 - i]
end

function RollingHistory:getFilo(i)
  return self._buffer[i]
end

return RollingHistory
