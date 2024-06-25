local M = {}

-- Use keystate to set ship_controller values
function M.updateShipController_keyboard(ship_controller, keystate)
  local turn = 0
  if keystate.held.left then
    turn = turn - 1
  end
  if keystate.held.right then
    turn = turn + 1
  end
  ship_controller.turn = turn

  local accel = 0
  if keystate.held.up then
    accel = accel + 1
  end
  ship_controller.accel = accel

  if keystate.held.space then
    ship_controller.fire_gun = 1
  else
    ship_controller.fire_gun = 0
  end
end

-- Use controller_state (joystick) to update ship_controller values
function M.updateShipController_gamepad(ship_controller, controller_state)
  ship_controller.turn = controller_state.value.leftx or 0
  ship_controller.accel = -(controller_state.value.lefty or 0)
  if controller_state.held.face1 then
    ship_controller.fire_gun = 1
  else
    ship_controller.fire_gun = 0
  end
end

return M
