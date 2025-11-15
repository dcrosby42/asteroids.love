-- TODO FIXME: This system uses extinct 'pos' component
-- Entities with 'follower' components will have their pos comps updated
-- to match the pos of the targeted entity.
-- Target entity has a 'followable' comp with matching 'targetname' prop.
return defineQuerySystem(
  { "follower", "tr" },
  function(e, estore, input, res)
    estore:seekEntity(hasComps("followable", "tr"), function(targetE)
      if e.follower.targetname == targetE.followable.targetname then
        -- targetE is the thing we want to track
        e.tr.x = targetE.tr.x
        e.tr.y = targetE.tr.y

        return true -- exit seekEntity
      end
      return false  -- keep seeking
    end)
  end)
