local State = require "castle.state"
local TweenHelpers = require "castle.tween.tween_helpers"

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
  local newX = (selected - 1) * 50
  TweenHelpers.tweenit(cursorE, "cursor_move", { tr = { x = newX } }, { duration = 0.3 })
end

function Menu.getMenuChoice(menu, choices)
  local selected = State.get(menu, "selected")
  return choices[selected]
end

-- TODO: currently hardcoded to use j,k keys... make configurable?
function Menu.updateMenu(menu, choices, estore, onChange)
  if menu then
    local changed = false
    if menu.keystate.pressed.j then
      Menu.incrementMenuSelection(menu, choices, -1, estore)
      changed = true
    end
    if menu.keystate.pressed.k then
      Menu.incrementMenuSelection(menu, choices, 1, estore)
      changed = true
    end
    if changed then
      local chosen = Menu.getMenuChoice(menu, choices)
      if onChange then
        onChange(chosen)
      end
    end
  end
end

return Menu
