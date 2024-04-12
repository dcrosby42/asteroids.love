local function mk_entity_draw_loop(complistname, func)
  return function(e, res)
    local complist = e[complistname]
    if complist then
      for _, comp in pairs(complist) do
        func(e, comp, res)
      end
    end
  end
end

return mk_entity_draw_loop
