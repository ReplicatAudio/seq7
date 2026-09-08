-- Direct port of scm/time.scm.
dofile("lua/lib/lib.lua")

set_tick_speed(150)

function tickfn()
  midi_note_off(0, 60)
  midi_note_on(0, 60, 127)
end