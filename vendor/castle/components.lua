local Comp = require 'castle.ecs.component'

local ext = appendlist

local TrAttrs = { 'x', 0, 'y', 0, 'r', 0, 'sx', 1, 'sy', 1 }
local RectAttrs = { 'x', 0, 'y', 0, 'w', 0, 'h', 0, 'cx', 0, 'cy', 0 } -- sx,sy?
-- local SizeAttrs = { 'w', 0, 'h', 0, 'cx', 0, 'cy', 0 }
local PicAttrs = ext(TrAttrs, { 'id', 'UNSET', 'cx', 0, 'cy', 0, 'color', { 1, 1, 1, 1 },
  'debug', false })

--
-- COMMON
--

Comp.define("tag", {})

Comp.define("tr", TrAttrs)

Comp.define("state", { 'value', '' })

Comp.define("box", ext(RectAttrs, { 'debug', false, 'color', { 1, 1, 0, 1 } })) -- sx,sy?

Comp.define("timer", { 't', 0, 'factor', 1, 'reset', 0, 'countDown', true, 'loop', false, 'alarm', false, 'event', '' })

Comp.define("followable", { 'targetname', '' })

Comp.define("follower", { 'targetname', '' })

--
-- VISUALS
--
Comp.define('viewport', { 'camera', '', 'blockout', true, 'bgcolor', { 0, 0, 0 } })

Comp.define("bgcolor", { 'color', { 0, 0, 0 } })

Comp.define("pic", PicAttrs)

Comp.define("anim", ext(PicAttrs, { 'timer', '', 'timescale', 1 }))

Comp.define("rect", ext(RectAttrs, { 'style', 'line', 'color', { 1, 1, 1 } })) -- sx,sy?

Comp.define("circle", { 'style', 'line', 'x', 0, 'y', 0, 'r', 0, 'color', { 1, 1, 1 } })

Comp.define("label", ext(RectAttrs,
  { 'text', 'Label',
    'color', { 0, 0, 0 },
    'font', '',
    'align', 'left',
    'valign', 'middle',
    'r', 0, 'sx', 1, 'sy', 1,
    'shadowcolor', false,
    'shadowx', 0, 'shadowy', 0,
    'debug', false,
  }))



Comp.define("sound", {
  'sound', '',
  'music', false,
  'loop', false,
  'state', 'playing',
  'volume', 1,
  'playtime', 0,
  'duration', 0,
})

Comp.define('tween', {
  'comp', '',
  'prop', '',
  'from', 0,
  'to', 0,
  'duration', 1,
  'timer', '',
  'easing', 'linear',
  'finished', false,
  'killtimer', false,
})

--
-- PHYSICS
--
Comp.define('physicsWorld', { 'gx', 0, 'gy', 0, 'allowSleep', true })
Comp.define("vel", { 'dx', 0, 'dy', 0, 'angularvelocity', 0, 'lineardamping', 0, 'angulardamping', 0 })
Comp.define('body', {
  'kind', '',
  'group', 0,
  'dynamic', true,
  'mass', '', -- non-number tells physics system to compute its own mass
  'friction', 0.2,
  'restitution', 0.2,
  'fixedrotation', false,
  'bullet', false,
  'sensor', false,
  'debugDraw', false,
  'debugDrawColor', { 0.8, 0.8, 1 },
})
Comp.define("force", { 'fx', 0, 'fy', 0, 'torque', 0, 'impx', 0, 'impy', 0, 'angimp', 0 })
Comp.define('joint',
  { 'kind', '',
    'toEntity', '',
    'lowerlimit', '',
    'upperlimit', '',
    'motorspeed', '',
    'maxmotorforce', '',
    'docollide', false
  })
Comp.define("rectangleShape", { 'x', 0, 'y', 0, 'w', 0, 'h', 0, 'angle', 0 })
Comp.define("circleShape", { 'x', 0, 'y', 0, 'radius', 0 })
Comp.define("chainShape", { 'vertices', {}, 'loop', false })
Comp.define("polygonShape", { 'vertices', {} })

Comp.define("polygonLineStyle",
  { 'draw', true, 'color', { 1, 1, 1 }, 'linewidth', 1, 'linestyle', 'smooth', 'closepolygon', true })

Comp.define("contact",
  { 'otherEid', '', 'nx', 0, 'ny', 0, 'myCid', '', 'otherCid', '', 'x', 0, 'y', 0, 'dx', 0, 'dy', 0 })

--
-- INPUT / UI
--

Comp.define("keystate", {
  'handle', {},   -- list of key names to be tracked
  'pressed', {},  -- set of keys recently pressed
  'held', {},     -- set of keys recently pressed and/or held
  'released', {}, -- set of keys released
})

Comp.define("button", {
  'kind', 'tap', -- hold, tap
  'eventtype', '',
  'eventstate', '',
  'holdtime', 1,
  'shape', 'circle',
  'progresssize', 50,
  'progresscolor', { 1, 1, 1, 0.5 },
})


Comp.define('touchable', { 'r', 20, 'x', 0, 'y', 0, 'debug', false })

Comp.define("touch", {
  'id', '',
  'state', '',
  'init_x', 0,
  'init_y', 0,
  'init_ex', 0,
  'init_ey', 0,
  'prev_x', 0,
  'prev_y', 0,
  'x', 0,
  'y', 0,
  'debug', false,
})

Comp.define('screen_grid', { 'spacex', 10, 'spacey', '', 'color', { 1, 1, 1, 0.3 } })

return Comp
