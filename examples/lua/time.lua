-- Direct port of examples/scheme/time.scm.
dofile("lib/lua/lib.lua")

set_tick_speed(150)

function tick()
  midi_note_off(0, 60)
  midi_note_on(0, 60, 127)
end