local Predicates = require "castle.ecs.predicates"
local Query = {}
local inspect = require "inspect"

function Query:new(o)
  o = o or {}
  -- o.indexLookup = o.indexLookup or nil
  -- o.filter = o.filter or nil

  if o._debug then
    print("Query:new(): " .. inspect(o))
  end

  setmetatable(o, self)
  self.__index = self

  return o
end

function Query:__call(estore)
  local ents = {}
  if self.indexLookup then
    ents = estore:indexLookup(self.indexLookup.name, self.indexLookup.key)
  end
  if self.filter then
    ents = lfilter(ents, self.filter)
  end
  return ents
end

local function addCompTypes(queryArgs, compTypes)
  if #compTypes == 0 then return queryArgs end
  if not queryArgs.indexLookup then
    local firstType = compTypes[1]
    queryArgs.indexLookup = { name = "byCompType", key = firstType }
    compTypes = tail(compTypes)
  end
  if #compTypes > 0 then
    local matcherFn = Predicates.hasComps(unpack(compTypes))
    if queryArgs.filter then
      queryArgs.filter = Predicates.allOf(queryArgs.filter, matcherFn)
    else
      queryArgs.filter = matcherFn
    end
  end
  return queryArgs
end

-- Given a variety of "query args", return proper Query ctor params
-- Sugar:
--   * string: component-type query
--   * function: filter-type query using the given predicate
--   * array: multi-comp=type; first type becomes an indexLookup, subsquent types are converted to a hasComps filter
--   * obj.tag: use byTag index lookup
--   * obj.tags: add comp-type filters; use byTag index lookup if indexLookup not already specified
--   * obj.name: use byName index lookup
local function expand(args)
  local argsType = type(args)
  if argsType == "string" then
    -- a single string becomes a comp-type index lookup
    return { indexLookup = { name = "byCompType", key = args } }
  end
  if argsType == "function" then
    -- a func is presumeed to be a filter predicate / matcher:
    return { filter = args }
  end
  if isArray(args) then
    -- multiple comp-type query: first type is index-searched, remainder become a filter
    return addCompTypes({}, args)
  end
  if argsType == "table" then
    args = shallowclone(args)
    if args.tag then
      -- the singular "tag" key implies a single index lookup
      args.indexLookup = { name = "byTag", key = args.tag }
      args.tag = nil
    end
    -- TODO: tags...?
    if args.comp then
      addCompTypes(args, { args.comp })
      args.comp = nil
    end
    if args.comps then
      addCompTypes(args, args.comps)
      args.comps = nil
    end
    return args
  end
end

function Query.create(queryArgs)
  local query = Query:new(expand(queryArgs))
  return query
end

return Query
