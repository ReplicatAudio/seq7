-- MIDI helpers (port of lib/scheme/midi.scm). Requires the seq7 Lua API
-- global raw_midi_write.

function midi_note_on(ch, note, vel)
  raw_midi_write(0x90 + ch, note, vel)
end

function midi_note_off(ch, note)
  raw_midi_write(0x80 + ch, note, 0)
end

function midi_cc(ch, cc, vel)
  raw_midi_write(0xB0 + ch, cc, vel)
end

-- MIDI System Real-Time messages
function midi_clock() raw_midi_write(0xF8) end
function midi_start() raw_midi_write(0xFA) end
function midi_stop() raw_midi_write(0xFC) end
function midi_continue() raw_midi_write(0xFB) end