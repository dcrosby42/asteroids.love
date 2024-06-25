local Predicates = require "castle.ecs.predicates"
local Query = {}
local inspect = require "inspect"

-- indexLookup -> { name=, key= }
-- filter -> func<e -> bool>
function Query:new(o)
  o = o or {}
  if o._debug then
    print("Query:new(): " .. inspect(o))
  end

  setmetatable(o, self)
  self.__index = self

  return o
end

-- Accepts an entity store, returns a list of 0 or more matching Entities.
function Query:execute(estore)
  local ents = {}
  if self.indexLookup then
    ents = estore:indexLookup(self.indexLookup.name, self.indexLookup.key)
  end
  if self.filter then
    ents = lfilter(ents, self.filter)
  end
  return ents
end

-- Implement "callable" interface; a Query object may be invoked like a function.
function Query:__call(estore)
  return self:execute(estore)
end

-- Update a queryArgs structure to filter on one or more component types.
-- Unless an indexLookup already exists in the args, the first comp type becomes an indexLookup.
-- Remaining comp types are combined using the hasComps predicate composer.
-- Modifies queryArgs in-place and also returns it.
-- Does nothing if compTypes is empty.
local function addCompTypes(queryArgs, compTypes)
  if not compTypes or #compTypes == 0 then return queryArgs end
  if not queryArgs.indexLookup then
    -- This queryArgs hasn't got an indexLookup yet.
    -- Use the first component type as an indexLookup:
    local firstType = compTypes[1]
    queryArgs.indexLookup = { name = "byCompType", key = firstType }
    compTypes = tail(compTypes)
  end
  if #compTypes > 0 then
    -- Generate a hasComps predicate function based on 1 or more remaining component types
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
-- Sugar: (in order of selection/evaluation)
--   * string: component-type query
--   * function: filter-type query using the given predicate
--   * array: multi-comp-type; first type becomes an indexLookup, subsquent types are converted to a hasComps filter
--   * obj.tag: use byTag index lookup
--   * obj.comp: add comp-type filters use byCompType index lookup, if indexLookup not already specified
--   * obj.comps: add comp-type filters; use byCompType index lookup, if indexLookup not already specified
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
