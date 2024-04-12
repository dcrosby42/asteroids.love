local Entity = {}

function Entity:new(o)
  local o = o or { eid = nil, _estore = nil }
  setmetatable(o, self)
  self.__index = self
  return o
end

function Entity:getEstore()
  return self._estore
end

function Entity:newComp(ctype, data)
  return self._estore:newComp(self, ctype, data)
end

function Entity:addComp(comp)
  return self._estore:addComp(self, comp)
end

function Entity:removeComp(comp)
  self._estore:removeComp(comp)
end

function Entity:getParent()
  return self._parent
end

function Entity:getChildren()
  return self._children
end

function Entity:newChild(compInfos, subs)
  parentInfo = { 'parent', { parentEid = self.eid } }
  if compInfos then
    local parentInfoFound = false
    for i, info in ipairs(compInfos) do
      if info[1] == 'parent' then
        if parentInfoFound then
          error("ERR newChild() cannot accept two 'parent' comp types")
        end
        parentInfoFound = true
        if info[2].order then parentInfo[2].order = info[2].order end
        compInfos[i] = parentInfo
      end
    end
    if not parentInfoFound then table.insert(compInfos, parentInfo) end
  else
    compInfos = { parentInfo }
  end

  return self._estore:newEntity(compInfos, subs)
end

-- alias of newChild, allows polymorphic newEntity behavior w an estore
function Entity:newEntity(compInfos, subs)
  return self:newChild(compInfos, subs)
end

function Entity:addChild(childEnt)
  self._estore:setupParent(self, childEnt)
end

function Entity:walkEntities(matchFn, handler)
  self._estore:walkEntity(self, matchFn, handler)
end

function Entity:walkChildren(matchFn, handler)
  self._estore:walkChildren(self, matchFn, handler)
end

function Entity:seekEntity(matchFn, doFn)
  self._estore:_seekEntity(self, matchFn, doFn)
end

function Entity:resortChildren(deep)
  if self._children then sortEntities(self._children, deep) end
end

function Entity:destroy()
  self._estore:destroyEntity(self)
end

return Entity
