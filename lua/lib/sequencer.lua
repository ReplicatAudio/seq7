-- Step sequencer (port of scm/lib/sequencer.scm). Depends on the globals
-- provided by lua/lib/midi.lua and lua/lib/modal.lua; load them first (see
-- lua/lib/lib.lua).

-- Per-channel state: the note currently sounding on each channel, or nil.
-- sequencer releases the previous note on every step so patterns don't
-- pile up sustained voices.
local last = {}

--- Advance one step on a channel.
-- ch:       MIDI channel (0-based)
-- notes:    pattern array of step tokens ("r" = rest, else scale degree)
-- off:      pitch offset added to each voiced step
-- root:     modal root
-- mode:     modal mode (0=Ionian .. 6=Locrian)
-- vel:      note velocity
-- interval: global step counter (0-based)
function sequencer(ch, notes, off, root, mode, vel, interval)
  local nt = notes[(interval % #notes) + 1]
  local prev = last[ch]
  if prev then midi_note_off(ch, prev) end
  if nt == "r" then
    last[ch] = nil
  else
    local note = off + modal(root, mode, tonumber(nt))
    last[ch] = note
    midi_note_on(ch, note, vel)
  end
end