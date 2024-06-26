local Comps = require "castle.components"
local GC = require "garbagecollect"
local Debug = (require("mydebug")).sub("Physics", false, false)
local inspect = require('inspect')
local Query = require "castle.ecs.query"

-- local logDebug = print
local logDebug = function()
end
local logError = print

local BodyQuery = Query.create("body")
local JointQuery = Query.create("joint")

local CacheHelper = {
  get = function(estore, cacheName, keyOrComp, fillFunc)
    local cache = estore:getCache(cacheName)
    if not cache then
      error("CacheHelper.get: estore has no cache named " .. tostring(cacheName))
    end
    local key = keyOrComp
    if type(key) == "table" then
      key = keyOrComp.cid
    end
    if key == nil then
      error(
        "CacheHelper.get('" ..
        cacheName .. "'): key must either be a string/int key OR a Component, ie, a table with 'cid' usable as a key")
    end
    local obj = cache[key]
    if not obj and fillFunc then
      obj = fillFunc()
      if not obj then
        error("CacheHelper.get('" .. tostring(cacheName) .. "', '" .. tostring(key) .. "'): fillFunc must return non-nil")
      end
      cache[key] = obj
    end
    return obj
  end
}



-- (pre-declare some helpers, see below)
local generateCollisionEvents, newBody, newJoint, beginContact_handler, endContact_handler

local physics = love.physics

local _CollisionBuffer
-- Creates and maintains a physics simulation for entities that have body components.
local physicsSystem = defineQuerySystem(
  "physicsWorld",
  function(physEnt, estore, input, res)
    local physWorld = CacheHelper.get(estore, "physicsWorld", physEnt.physicsWorld, function()
      local worldComp = physEnt.physicsWorld
      Debug.println("Creating new physics world")
      local w = physics.newWorld(worldComp.gx, worldComp.gy, worldComp.allowSleep)
      w:setCallbacks(beginContact_handler, endContact_handler, nil, nil)
      return w
    end)

    --
    -- SYNC: Components->to->Physics Objects
    --
    -- Sync body comps to phys bodies:
    local sawIds = {}
    for _, e in ipairs(BodyQuery(estore)) do
      local id = e.body.cid
      table.insert(sawIds, id)

      -- See if there's a cached phys obj for this component
      local obj = CacheHelper.get(estore, "physics", e.body, function()
        -- First time seeing this 'body' component: create new physics obj
        local obj = newBody(physWorld, e)
        if obj == nil then
          error("Can't build new physics object for " .. inspect(e.body))
        end
        Debug.println("New physics body for cid=" .. e.body.cid .. " kind=" ..
          e.body.kind)
        return obj
      end)

      -- Apply values from Entity to the physics object
      local body = obj.body
      body:setPosition(e.tr.x, e.tr.y)
      body:setAngle(e.tr.r)
      if e.vel then
        body:setLinearVelocity(e.vel.dx, e.vel.dy)
        body:setLinearDamping(e.vel.lineardamping)
        body:setAngularVelocity(e.vel.angularvelocity)
        body:setAngularDamping(e.vel.angulardamping)
      end
      if e.force then
        local f = e.force
        body:applyForce(f.fx, f.fy)
        body:applyTorque(f.torque)
        body:applyLinearImpulse(f.impx, f.impy)
        body:applyAngularImpulse(f.angimp)
        -- Impulses need to be reset to 0 here
        f.impx = 0
        f.impy = 0
        f.angimp = 0
      end
    end

    -- (this cache is used throughout the rest of this monolithic func)
    local physObjCache = estore:getCache("physics")

    -- Sync joint comps to phys bodies:
    for _, e in ipairs(JointQuery(estore)) do
      local id = e.joint.cid
      table.insert(sawIds, id)
      -- See if there's a cached phys obj for this component
      local joint = CacheHelper.get(estore, "physics", id, function()
        -- newly-added Joint component -> create new phys joint in cache
        Debug.println("New physics joint for cid=" .. id .. " kind=" .. e.joint.kind)
        return newJoint(physWorld, e.joint, e, estore, physObjCache)
      end)
      -- Apply values from Joint comp to the physics Joint object
      -- TODO ... when we have more interesting Joints
    end

    -- Remove cached objects (bodies and joints) whose ids weren't seen in the last pass through the physics components
    local remIds = ldiff(tkeys(physObjCache), sawIds)
    for _, id in ipairs(remIds) do
      Debug.println("Removing phys obj cid=" .. id)
      local obj = physObjCache[id]
      if obj then
        if obj.body then
          obj.body:destroy()
          GC.request()
        end
        if obj.joint then
          obj.joint:destroy()
          GC.request()
        end
        physObjCache[id] = nil
      end
    end

    _CollisionBuffer = {}

    --
    -- Iterate the physics world
    --
    physWorld:update(input.dt)

    --
    -- Process Collisions
    --
    generateCollisionEvents(_CollisionBuffer, estore, input.events)
    _CollisionBuffer = {}

    --
    -- SYNC: Physics Objects->to->Components
    --
    estore:walkEntities(hasComps("body"), function(e)
      local id = e.body.cid
      local obj = physObjCache[id]
      if obj then
        -- Copy values from physics object to entity's pos and vel components
        local b = obj.body
        local x, y = b:getPosition()
        if e.tr then
          e.tr.x = x
          e.tr.y = y
          e.tr.r = b:getAngle()
        else
          error("physicsSystem: Need a tr")
        end
        if e.vel then
          local dx, dy = b:getLinearVelocity()
          e.vel.dx = dx
          e.vel.dy = dy
          e.vel.lineardamping = b:getLinearDamping()
          e.vel.angularvelocity = b:getAngularVelocity()
          e.vel.angulardamping = b:getAngularDamping()
        end
      else
        -- ? wtf ? obj is missing from the cache
      end
    end)
    -- TODO walkEntities(hasComps('joint'), ....)
    -- ...when we actually need to
  end)

local function tryGetUserData(obj)
  local userData
  ok, err = xpcall(function()
    userData = obj:getUserData()
  end, debug.traceback)
  if ok then return userData end
  -- ruh roh
  print("getUserData() FAILED on " .. tostring(obj) .. ": " .. tostring(err))
  print(debug.traceback())
  return nil
end

function beginContact_handler(a, b, contact)
  local a_cid = tryGetUserData(a)
  local b_cid = tryGetUserData(b)
  if not a_cid or not b_cid then return end -- sometimes we get stale fixtures, abort

  -- contact points
  local a_x, a_y, b_x, b_y = contact:getPositions()
  -- contact normal... vector from a->b
  local nx, ny = contact:getNormal()
  -- velocities
  local a_dx, a_dy, b_dx, b_dy
  if a_x and a_y then
    a_dx, a_dy = a:getBody():getLinearVelocityFromWorldPoint(a_x, a_y)
    if not (b_x and b_y) then
      b_x = a_x
      b_y = a_y
    end
    b_dx, b_dy = b:getBody():getLinearVelocityFromWorldPoint(b_x, b_y)
  end

  table.insert(_CollisionBuffer, {
    "begin",
    a,
    b,
    a_cid,
    b_cid,
    nx,
    ny,
    a_x,
    a_y,
    b_x,
    b_y,
    a_dx,
    a_dy,
    b_dx,
    b_dy,
  })
  -- delete the contact object. something about mem mgmt bugs in the physics engine regarding Contact objects
  contact = nil
  GC.request()
end

function endContact_handler(a, b, contact)
  local a_cid = tryGetUserData(a)
  local b_cid = tryGetUserData(b)
  if not a_cid or not b_cid then return end -- sometimes we get stale fixtures, abort

  table.insert(_CollisionBuffer, { "end", a, b, a_cid, b_cid })
end

-- Removes all the contact components from 'from'
-- whose otherEid field equals matching.eid
local function removeContactComps(from, matching)
  local rem = {}
  if not from.contacts then
    print("no contacts? " .. inspect(from))
    return
  end
  for _, contact in pairs(from.contacts) do
    if contact.otherEid == matching.eid then rem[#rem + 1] = contact end
  end
  for i = 1, #rem do from:removeComp(rem[i]) end
end

-- For each collision notes in physWorld._CollisionBuffer,
-- Create a "collision event" object and append to the given events list.
function generateCollisionEvents(collbuf, estore, events)
  if #collbuf > 0 then
    Debug.println("generateCollisionEvents: num items:" .. #collbuf)
    for _, c in ipairs(collbuf) do
      local state, a, b, a_cid, b_cid, nx, ny, a_x, a_y, b_x, b_y, a_dx, a_dy,
      b_dx, b_dy = unpack(c)
      local a_comp, a_ent = estore:getCompAndEntityForCid(a_cid)
      local b_comp, b_ent = estore:getCompAndEntityForCid(b_cid)
      if a_ent and b_ent then
        if state == "begin" then
          -- Emit a "begin collision" event
          table.insert(events, {
            type = "collision",
            state = "begin",
            normX = nx,
            normY = ny,
            entA = a_ent,
            compA = a_comp,
            entB = b_ent,
            compB = b_comp,
            xA = a_x,
            yA = a_y,
            xB = b_x,
            yB = b_y,
            dxA = a_dx,
            dyA = a_dy,
            dxB = b_dx,
            dyB = b_dy,
          })
          -- Add a contact for entity A
          a_ent:newComp("contact", {
            name = b_ent.eid,
            otherEid = b_ent.eid,
            otherCid = b_comp.cid,
            myCid = a_comp.cid,
            nx = nx,
            ny = ny,
            x = a_x,
            y = a_y,
            dx = a_dx,
            dy = a_dy,
          })
          -- Add a contact for entity B
          b_ent:newComp("contact", {
            name = a_ent.eid,
            otherEid = a_ent.eid,
            otherCid = a_comp.cid,
            myCid = b_comp.cid,
            nx = nx,
            ny = ny,
            x = a_x,
            y = a_y,
            dx = b_dx,
            dy = b_dy,
          })
        else
          -- Emit a "begin collision" event
          table.insert(events, {
            type = "collision",
            state = "end",
            normX = nx,
            normY = ny,
            entA = a_ent,
            compA = a_comp,
            entB = b_ent,
            compB = b_comp,
          })
          -- remove old contact components
          removeContactComps(a_ent, b_ent)
          removeContactComps(b_ent, a_ent)
        end
      else
        logError("!! Unable to register collision between '" .. a_cid ..
          "' and '" .. b_cid .. "'")
      end
    end
  end
end

function newJoint(pw, jointComp, e, estore, objCache)
  if e == nil or jointComp == nil then
    error("newJoint requires an entity with a joint component")
  end
  Debug.println("jointComp: " .. inspect(jointComp))

  local fromComp = e.body
  Debug.println("fromComp: " .. inspect(fromComp))

  local toEnt = estore:getEntity(jointComp.toEntity)
  if not toEnt then
    error("No entity '" .. jointComp.toEntity .. "'; cannot make joint " ..
      inspect(jointComp))
  end
  local toComp = toEnt.body
  Debug.println("toComp: " .. inspect(toComp))

  local from = objCache[fromComp.cid]
  local to = objCache[toComp.cid]

  local joint
  if jointComp.kind == "prismatic" then
    local fromCenterX = from.body:getX()
    local fromCenterY = from.body:getY()
    local toCenterX = to.body:getX()
    local toCenterY = to.body:getY()
    Debug.println("fromCenterX=" .. fromCenterX .. " fromCenterY=" ..
      fromCenterY)
    Debug.println("toCenterX=" .. toCenterX .. " toCenterY=" .. toCenterY)
    local vx = toCenterX - fromCenterX
    local vy = toCenterY - fromCenterY

    joint = physics.newPrismaticJoint(from.body, to.body, fromCenterX, fromCenterY,
      toCenterX, toCenterY, vx, vy, fromComp.docollide)
    if jointComp.upperlimit ~= "" and jointComp.lowerlimit ~= "" then
      joint:setLimits(jointComp.lowerlimit, jointComp.upperlimit)
    end
    if jointComp.motorspeed ~= "" and jointComp.maxmotorforce ~= "" then
      joint:setMotorEnabled(true)
      joint:setMotorSpeed(jointComp.motorspeed)
      joint:setMaxMotorForce(jointComp.maxmotorforce)
    end
  elseif jointComp.kind == "wheel" then
    local fromCenterX = from.body:getX()
    local fromCenterY = from.body:getY()
    local toCenterX = to.body:getX()
    local toCenterY = to.body:getY()
    Debug.println("fromCenterX=" .. fromCenterX .. " fromCenterY=" ..
      fromCenterY)
    Debug.println("toCenterX=" .. toCenterX .. " toCenterY=" .. toCenterY)
    local vx = toCenterX - fromCenterX
    local vy = toCenterY - fromCenterY

    joint = physics.newWheelJoint(from.body, to.body, fromCenterX, fromCenterY,
      toCenterX, toCenterY, vx, vy, jointComp.docollide)
    if jointComp.motorspeed ~= "" and jointComp.maxmotorforce ~= "" then
      joint:setMotorEnabled(true)
      joint:setMotorSpeed(jointComp.motorspeed)
      joint:setMaxMotorForce(jointComp.maxmotorforce)
    end
  elseif jointComp.kind == "weld" then
    local x = from.body:getX()
    local y = from.body:getY()
    joint = physics.newWeldJoint(from.body, to.body, x, y, false)
  else
    error("Cannot make a physics joint for: " .. inspect(jointComp))
  end
  return { joint = joint }
end

function newBody(pw, e)
  if not (e.rectangleShape or e.polygonShape or e.circleShape or e.chainShape) then
    Debug.println(
      "newGeneric() requires the Entity have rectangleShape, polygonShape, chainShape or circleShape component(s)")
    return nil
    -- error("newGeneric() requires the Entity have rectangleShape, polygonShape or circleShape component(s)")
  end
  local dyn = "dynamic"
  if not e.body.dynamic then dyn = "static" end
  local b = physics.newBody(pw, e.tr.x, e.tr.y, dyn)
  b:setBullet(e.body.bullet)
  b:setFixedRotation(e.body.fixedrotation)

  local shapes = {}
  local fixtures = {}

  local function addShape(s)
    local f = physics.newFixture(b, s)
    f:setUserData(e.body.cid)
    f:setFriction(e.body.friction)                                -- TODO someday allow this to be set per-shape instead of whole body instead of whole body.  If needed
    f:setRestitution(e.body.restitution)                          -- TODO someday allow this to be set per-shape instead of whole body instead of whole body.  If needed
    f:setSensor(e.body.sensor)
    f:setFilterData(e.body.categories, e.body.mask, e.body.group) -- https://love2d.org/wiki/Fixture:setFilterData
    table.insert(shapes, s)
    table.insert(fixtures, f)
  end

  for _, r in pairs(e.rectangleShapes or {}) do
    local s = physics.newRectangleShape(r.x, r.y, r.w, r.h, r.angle)
    addShape(s)
  end
  for _, poly in pairs(e.polygonShapes or {}) do
    local s = physics.newPolygonShape(poly.vertices)
    addShape(s)
  end
  for _, c in pairs(e.circleShapes or {}) do
    local s = physics.newCircleShape(c.x, c.y, c.radius)
    addShape(s)
  end
  for _, ch in pairs(e.chainShapes or {}) do
    local s = physics.newChainShape(ch.loop, ch.vertices)
    addShape(s)
  end

  if type(e.body.mass) == "number" then b:setMass(e.body.mass) end

  return { body = b, shapes = shapes, fixtures = fixtures }
end

return { system = physicsSystem }
