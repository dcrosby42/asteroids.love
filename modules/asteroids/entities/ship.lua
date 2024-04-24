local Ship = {}


function Ship.jig(parent, res, E)
  local world = Ship.basicWorld(parent, res, E)
  world:newEntity({
    { "tag",   { name = "jig_ship" } },
    { "state", { name = "debug_draw", value = false } },
  })

  Ship.ship(world, res, E)

  -- Ship.flameMenu(parent, res, E)
end

function Ship.basicWorld(parent, res, E)
  -- Default viewport (assumes default camera name "camera")
  local viewport = E.viewport(parent, res)
  -- world meant to be the direct child of viewport
  local world = viewport:newEntity({
    { "name", { name = "world" } },
  })
  -- camera is parented to world. (default name kept: "camera")
  E.camera(world, res)

  return world
end

function Ship.ship(parent, res, E)
  local ship = parent:newEntity({
    { "tr",   {} },
    { "name", { name = "ship" } },
  })
  ship:newEntity({
    { "tag", { name = "ship_flame" } },
    { "tr",  { y = 30 } },
    { 'pic', {
      id = "ship_flame_06",
      sx = 0.75,
      sy = 0.75,
      cx = 0.5,
      cy = 0,
      -- x = 0,
      -- y = 74,
      debug = false,
    } },
  })
  ship:newEntity({
    { "tag", { name = "ship_body" } },
    { 'pic', {
      id = "ship_example_05",
      sx = 0.75,
      sy = 0.75,
      cx = 0.5,
      cy = 0.5,
      debug = false,
    } },
  })
end

Ship.Flames = { "ship_flame_01", "ship_flame_02", "ship_flame_03", "ship_flame_04", "ship_flame_05", "ship_flame_06",
  "ship_flame_07", "ship_flame_08", "ship_flame_09", "ship_flame_10", "ship_flame_11", }

function Ship.flameMenu(parent, res, E)
  local w, h = res.data.screen_size.width, res.data.screen_size.height

  local initialSelected = 6
  local menu = parent:newEntity({
    { "tr",    { x = 20, y = h - 80 } },
    { "name",  { name = "flame_menu" } },
    { "state", { name = "selected", value = initialSelected } },
    -- { "rect",  { w = 50 * 11, h = 70, color = { 0.5, 0.5, 1, 1 } } },

  })
  local size = 0.5
  local x, y = 0, 0
  for i, picId in ipairs(Ship.Flames) do
    x = (i - 1) * 50
    menu:newEntity({
      { "name", { name = "menu-" .. picId } },
      { "tr",   { x = x, y = y } },
      { 'pic', {
        id = picId,
        sx = size,
        sy = size,
        y = 20,
        x = 50 / 2,
        cx = 0.5,
      } },
      { "label", {
        text = tostring(i),
        color = { 1, 1, 1 },
        align = "middle",
        -- cx = 0.5,
        -- y = -40,
        w = 50,
        h = 20,
      } },
    })
  end

  menu:newEntity({
    { "name", { name = "menu_cursor" } },
    { "tr",   { x = (initialSelected - 1) * 50, } },
    { "rect", { w = 50, h = 70, color = { 1, 1, 1, 1 } } }
  })
end

return Ship
