require "castle.helpers"

local M = {}

function M.touchingUp(e)
  return not (not tfind(e.contacts, function(c)
    return c.ny < 0
  end))
end

function M.touchingDown(e)
  return not (not tfind(e.contacts, function(c)
    return c.ny > 0
  end))
end

function M.isUp(c)
  return c.ny < 0
end

function M.getUpContacts(e)
  return tfindall(e.contacts, function(contact)
    return contact.ny < 0
  end)
end

function M.getDownContacts(e)
  return tfindall(e.contacts, function(contact)
    return contact.ny > 0
  end)
end

return M
