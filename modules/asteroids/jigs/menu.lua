local State = require "castle.state"

local Menu = {}

function Menu.incrementMenuSelection(menu, choices, inc, estore)
  local selected = State.get(menu, "selected")
  selected = selected + inc
  if selected < 1 then
    selected = #choices
  elseif selected > #choices then
    selected = 1
  end
  print("menu selected " .. tostring(selected))
  State.set(menu, "selected", selected)

  local cursorE = estore:getEntityByName("menu_cursor")
  cursorE.tr.x = (selected - 1) * 50
end

function Menu.getMenuChoice(menu, choices)
  local selected = State.get(menu, "selected")
  return choices[selected]
end

return Menu
