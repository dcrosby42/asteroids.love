local M = {}

-- Iterate event objects, match event.type to eventType.
-- Handlers is a table whose string keys point to functions.
-- When an event matches, event.state is used to select the proper func from handlers.
function M.handle(events, eventType, handlers)
  local consumed = {} -- indexes of events to remove
  for i = 1, #events do
    if events[i].type == eventType then
      local fn = handlers[events[i].state]
      if fn then
        local consumeMe = fn(events[i])
        if consumeMe ~= false then
          -- unless the handler func explicitly returns false, consume the event
          consumed[#consumed + 1] = i
        end
      end
    end
  end
  -- Consume marked events
  for i = 1, #consumed do
    table.remove(events, consumed[i])
  end
end

-- M.on(input.events, "keyboard", "g", function(evt)...end)
-- M.on(input.events, "keyboard", function(evt)...end)
function M.on(events, eventType, eventState, fn)
  if type(eventState) == "function" then
    fn = eventState
    eventState = nil
  end

  local consumed = {} -- indexes of events to consume
  for i = 1, #events do
    if events[i].type == eventType then
      if (not eventState) or events[i].state == eventState then
        local consumeMe = fn(events[i])
        if consumeMe == true then
          -- unless the handler func explicitly returns false, consume the event
          consumed[#consumed + 1] = i
        end
      end
    end
  end

  -- Consume marked events
  for i = 1, #consumed do
    table.remove(events, consumed[i])
  end
end

function M.onKeyPressed(events, key, fn)
  M.on(events, "keyboard", "pressed", function(evt)
    if evt.key == key then
      return fn(evt)
    end
  end)
end

return M
