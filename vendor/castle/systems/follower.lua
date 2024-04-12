local function constrainRectWithin(e, parentE)
  -- local ey = e.pos.y + e.rect.offy
  local ex = math.max(e.pos.x + e.rect.offx, parentE.pos.x)
  -- ey = math.max(e.pos.y + e.rect.offy, parentE.pos.y)
  print(e.name.name .. " " .. e.pos.x .. " " .. (e.pos.x + e.rect.offx) /
            e.viewport.sx)
  -- e.pos.x = ex + e.rect.offx
  -- e.pos.y = ey + e.rect.offy

end

-- Entities with 'follower' components will have their pos comps updated
-- to match the pos of the targeted entity.
-- Target entity has a 'followable' comp with matching 'targetname' prop.
return defineUpdateSystem(hasComps("follower", "pos"),
                          function(e, estore, input, res)
  estore:seekEntity(hasComps("followable", "pos"), function(targetE)
    if e.follower.targetname == targetE.followable.targetname then
      -- targetE is the thing we want to track
      e.pos.x = targetE.pos.x
      e.pos.y = targetE.pos.y

      -- local par = estore:getParent(e)
      -- if par and par.pos and par.rect and e.viewport then constrainRectWithin(e, par) end
      return true -- exit seekEntity
    end
    return false -- keep seeking
  end)
end)

