-- Direct port of examples/scheme/simple.scm, exercising the Lua libs:
-- Lua's % is 0-based, so notes run 21..80 (vs Scheme's 1-based modulo).
dofile("lib/lua/lib.lua")

set_tick_speed(250)

local t = 0

function tick()
  midi_note_on(0, 21 + t % 60, 127)
  t = t + 1
end