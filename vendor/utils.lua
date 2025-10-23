-- At some point, unpack moved into table.
-- THIS WILL ENSURE BOTH EXIST
if not unpack then unpack = table.unpack end
if not table.unpack then table.unpack = unpack end

---Collection helper utils
local Utils = {}

--
-- MAP STUFF
--

---@param t table
---@return boolean is_empty True if t is nil, or blank string, or empty table
function Utils.is_empty(t)
  if t == nil then return true end
  if type(t) == "string" then return true end
  for _ in pairs(t) do
    return false
  end
  return true
end

---Returns the key set for the given map-like table
---@param t table
---@return table keys
function Utils.keys(t)
  local keys = {}
  for k, _ in pairs(t) do
    keys[#keys + 1] = k
  end
  return keys
end

---Returns the values from the given map-like table,
---in no particular order.
---@param t table
---@return table values Array-like
function Utils.values(t)
  local vals = {}
  for _, v in pairs(t) do
    vals[#vals + 1] = v
  end
  return vals
end

---Create a (shallow) copy of a table.
---If `orig` is nil, an new empty table is returned.
---@param orig table
---@return table dude
function Utils.clone(orig)
  if orig == nil then
    return {}
  end
  local copy = {}
  for k, v in pairs(orig) do
    copy[k] = v
  end
  return copy
end

---Create a (recursive, if a list or map) copy of `orig`
---@param val table
---@return table copy
function Utils.clone_deep(val)
  local val_type = type(val)
  if val_type == "table" then
    local copy = {}
    for key, orig_value in next, val, nil do
      copy[key] = Utils.clone_deep(orig_value)
    end
    setmetatable(copy, Utils.clone_deep(getmetatable(val)))
    return copy
  end
  return val -- scalar types like string,number,bool etc
end

---Overwrites fields in `dest` with values in `src`.
---Intended for use on map-like tables.
---@param dest table will by updated with values from `src`
---@param src table source of values
---@return table dest mutated
function Utils.merge(dest, src)
  for k, v in pairs(src) do
    dest[k] = v
  end
  return dest
end

---Overwrites fields in `dest` with values in `src`.
---If a value exists in both `dest` and `source`, and both are tables,
---they are recursively merged.
---`dest` is mutated
---Non-merged (copied) table values from `src` are assigned, NOT cloned.
---This means _some_ tables in src may be referenced, and subsequently mutated, by holders of references to `dest`.
---Intended for use on map-like tables.
---@param dest table will by updated with values from `src`
---@param src table source of values
---@param do_copy boolean? (Optional) When true, deep cloning is used
---@return table dest The updated `dest`, or an updated deep clone
function Utils.merge_deep(dest, src, do_copy)
  local dest_type = type(dest)
  if do_copy == nil then do_copy = false end
  if dest_type == "table" then
    local orig_dest = dest
    if do_copy then
      dest = {}
    end
    for key, orig_value in pairs(orig_dest) do
      local src_value = src[key]
      if src_value ~= nil then
        if type(orig_value) == 'table' and type(src_value) == 'table' then
          dest[key] = Utils.merge_deep(orig_value, src_value, do_copy)
        else
          if do_copy then
            dest[key] = Utils.clone_deep(src_value)
          else
            dest[key] = src_value
          end
        end
      else
        if do_copy then
          dest[key] = Utils.clone_deep(orig_value)
        else
          dest[key] = orig_dest[key] -- just to be clear.  This is likely redundant.
        end
      end
    end
    -- For any keys in src not in dest, assign
    local new_keys = Utils.list_diff(Utils.keys(src), Utils.keys(orig_dest))
    for i = 1, #new_keys do
      local key = new_keys[i]
      if do_copy then
        dest[key] = Utils.clone_deep(src[key])
      else
        dest[key] = src[key]
      end
    end
    return dest -- either a clone or orig
  end
  return dest   -- scalar types like string,number,bool etc
end

---Shallow-clone `defaults` and merge with `from`.
---@param defaults table
---@param from table
---@return table default_clone
function Utils.populate(defaults, from)
  return Utils.merge(Utils.clone(defaults), from)
end

--- Returns a table constructor which returns a shallow copy
--- of the original defaults merged with a sparse table of inputs.
--- @param defaults table stuff and stuff
--- @return fun(opts: table): table builder constructor function
function Utils.make_constructor(defaults)
  -- defaults = Utils.clone_deep(defaults)
  return function(opts)
    return Utils.merge(Utils.clone_deep(defaults), opts or {})
  end
end

---Iterate each index,val or key,val in t invoking fn
function Utils.for_each(t, fn)
  if Utils.is_array(t) then
    for i = 1, #t do
      fn(i, t[i])
    end
  else
    for k, v in ipairs(t) do
      fn(k, v)
    end
  end
end

--
-- LIST STUFF
--

---Detect if a table is array-like. Peeks at size and first element.
---@param t table The table to check
---@return boolean is_array True if the table looks to be an array; false if size is 0.
function Utils.is_array(t)
  return #t > 0 and t[1] ~= nil
end

--- Returns the index of the first occurrence of value `v` in array `t`, or nil if not found.
---@param t table The array-style table.
---@param v any The value to search for.
---@return integer|nil
function Utils.index_of(t, v)
  for i, val in ipairs(t) do
    if val == v then
      return i
    end
  end
  return nil
end

---@param t table
---@return table result A reversed copy of `t`
function Utils.reverse(t)
  local result = {}
  for i = #t, 1, -1 do
    result[#result + 1] = t[i]
  end
  return result
end

--- Returns a shallow slice of an array-style table.
---@param t table The input array
---@param first integer Start index (inclusive)
---@param last integer? (Optional) End index (inclusive). Defaults to end
---@return table Slice of the array
function Utils.slice(t, first, last)
  last = last or #t
  local result = {}
  for i = first, last do
    result[#result + 1] = t[i]
  end
  return result
end

--- Applies a function to each element of an list-like table and returns a new table.
---@generic T, R
---@param fn fun(value: T, index: integer): R Function to apply to each element.
---@param t T[] The input table
---@return R[] t2 A new table containing the results.
function Utils.map(fn, t)
  local result = {}
  for i, v in ipairs(t) do
    result[i] = fn(v, i)
  end
  return result
end

---Returns the first element in `t` for which `fn` returns true, nil otherwise
---@generic T
---@param t T[] The list to search
---@param fn fun(T): boolean
---@return T|nil value The matched value or nil
function Utils.find_by(t, fn)
  for i = 1, #t do
    if fn(t[i]) then
      return t[i]
    end
  end
  return nil
end

---Search a list of pairs, returning `pair[2]` for the first true `fn(pair[1])`.
---@param t table The list of pairs to search
---@param fn fun(p1:any): boolean The fn to evaluate for each `pair[1]`
---@return any value The `pair[2]` value if matched, else nil.
function Utils.find_assoc(t, fn)
  for i = 1, #t do
    if fn(t[i][1]) then
      return t[i][2]
    end
  end
  return nil
end

---Search a list of pairs, returning all `pair[2]` for the which `fn(pair[1])` is true.
---@param t table The list of pairs to search
---@param fn fun(p1:any): boolean The fn to evaluate for each `pair[1]`
---@return any[] value The list of `pair[2]` values. May be empty.
function Utils.find_assoc_all(t, fn)
  local result = {}
  for i = 1, #t do
    if fn(t[i][1]) then
      table.insert(result, t[i][2])
    end
  end
  return result
end

---Sort a list of values using the given comp func.
---@generic T
---@param t T[] An array-style table. WILL BE MUTATED by sorting in-place
---@param comp fun(a:any, b:any): boolean Comp fn returns true when `a` comes before `b`
---@return T[] t The list of `pair[2]` values. May be empty.
function Utils.sort(t, comp)
  table.sort(t, comp)
  return t
end

-- Just like `Utils.sort()`, but returns a sorted clone of `t`, leaving the original unmodified.
function Utils.sorted(t, comp)
  return Utils.sort(Utils.clone(t), comp)
end

--
-- SET STUFF
--

---@param t table An array-style table
---@return table set A array-style table containing just one of each value in `t`
function Utils.to_set(t)
  local s = {}
  for _, v in ipairs(t) do
    s[v] = true
  end
  return s
end

---Compute the set difference A - B
---@param a table A set-like table.
---@param b table Another set-like table.
---@return table diff_set The set of values in `a` not found in `b`
function Utils.set_diff(a, b)
  local diff_set = {}
  for k in pairs(a) do
    if not b[k] then
      diff_set[k] = true
    end
  end
  return diff_set
end

---Compute the set diff for two lists A - B
---@param a table A set-like table.
---@param b table Another set-like table.
---@return table list The set of values in `a` not found in `b`
function Utils.list_diff(a, b)
  return Utils.keys(Utils.set_diff(Utils.to_set(a), Utils.to_set(b)))
end

--
-- FP STUFF
--

---@generic R
---@vararg fun(...: any): any
---@return fun(...: any): R
--- Returns the composition of the given functions, applied right-to-left.
--- Example: compose(f, g, h)(x) == f(g(h(x)))
function Utils.compose(...)
  local funcs = { ... }
  return function(...)
    local result = { ... }
    for i = #funcs, 1, -1 do
      result = { funcs[i](unpack(result)) }
    end
    return unpack(result)
  end
end

--- Partially applies arguments to a function (currying).
---@param fn function The original function.
---@vararg any Pre-applied arguments.
---@return function A new function awaiting the remaining arguments.
function Utils.partial(fn, ...)
  local args = { ... }
  return function(...)
    local all_args = { unpack(args) }
    for i = 1, select("#", ...) do
      all_args[#all_args + 1] = select(i, ...)
    end
    return fn(unpack(all_args))
  end
end

---Wraps a bound object method into a regular function.
---(Basically just currying an object to its method's self arg)
---@param method function The object's method
---@param self table The object
---@return function bound A function with `method` bound to `self`
function Utils.bind(method, self)
  return function(...) return method(self, ...) end
end

--
-- STRING STUFF
--

-- Strip leading/trailing whitespace from a string
---@param s string
---@return string stripped
function Utils.trim(s)
  return s:match("^%s*(.-)%s*$")
end

---Split a string on a character into a list of strings
---@param s string
---@param char string Character to split on
---@return table result
function Utils.split(s, char)
  local res = {}
  for i in string.gmatch(s, "[^" .. char .. "]+") do
    table.insert(res, i)
  end
  return res
end

--- Splits a string on any whitespace and returns a list of trimmed words.
---@param s string
---@return string[]
function Utils.split_words(s)
  local words = {}
  for word in s:gmatch("%S+") do
    words[#words + 1] = word
  end
  return words
end

--
-- PRINTING STUFF
--

---Generate a pretty-formatted string, especially useful for tables.
---Recurses and indents as needed.
---@param val any thing to print
---@param ind string|nil indent shim. Defaults to ""
---@return string prettied
function Utils.pretty(val, ind)
  if not ind then
    ind = ""
  end

  if type(val) == "table" then
    local lines = {}
    if ind ~= "" then
      lines[1] = ""
    end -- inner tables need to bump down a line
    local count = 0
    for k, v in pairs(val) do
      local s = ind .. k .. ": " .. Utils.pretty(v, ind .. "  ")
      table.insert(lines, s)
      count = count + 1
    end
    if count > 0 then
      return table.concat(lines, "\n")
    else
      return "{}"
    end
  else
    return tostring(val)
  end
end

--- Converts a Lua value to a debug string resembling Lua source.
---@param value any The value to convert.
---@param seen? table Internal table for cycle detection.
---@return string
function Utils.as_lua(value, seen)
  seen = seen or {}

  local t = type(value)

  if t == "string" then
    return string.format("%q", value) -- Lua-safe quoted string
  elseif t == "number" or t == "boolean" or t == "nil" then
    return tostring(value)
  elseif t == "table" then
    if seen[value] then
      return '"<cycle>"'
    end
    seen[value] = true

    local parts = {}
    local is_array = true
    local i = 1
    for k, v in pairs(value) do
      if k ~= i then
        is_array = false
        break
      end
      i = i + 1
    end

    if is_array then
      for i = 1, #value do
        parts[#parts + 1] = Utils.as_lua(value[i], seen)
      end
      return "{" .. table.concat(parts, ", ") .. "}"
    else
      for k, v in pairs(value) do
        local key
        if type(k) == "string" and k:match("^%a[%w_]*$") then
          key = k
        else
          key = "[" .. Utils.as_lua(k, seen) .. "]"
        end
        parts[#parts + 1] = key .. " = " .. Utils.as_lua(v, seen)
      end
      return "{" .. table.concat(parts, ", ") .. "}"
    end
  else
    return '"<' .. t .. '>"'
  end
end

Utils.to_lua = Utils.as_lua

---Pretty-format and print the argument.
---@param val any
function Utils.pretty_print(val)
  print(Utils.pretty(val))
end

Utils.pprint = Utils.pretty_print

---Print Lua-source formatted value
---@param val any
function Utils.print_lua(val)
  print(Utils.as_lua(val))
end

Utils.lprint = Utils.print_lua

--
-- MATH STUFF
--

function Utils.round(x)
  if x >= 0 then
    return math.floor(x + 0.5)
  else
    return math.ceil(x - 0.5)
  end
end

-- Round num to the nearest tenth
function Utils.round1(num)
  return math.floor(num * 10 + 0.5) / 10
end

-- Round num to the nearest Dth decimal place
function Utils.roundD(num, numDecimalPlaces)
  local mult = 10 ^ (numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

return Utils
