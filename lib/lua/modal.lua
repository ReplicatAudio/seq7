-- Modal helpers (port of lib/scheme/modal.scm).

-- Mode tables: 0=Ionian, 1=Dorian, 2=Phrygian, 3=Lydian,
--              4=Mixolydian, 5=Aeolian, 6=Locrian
-- Each row is the semitone offsets for degrees 1..7 (same as lib/scheme/modal.scm).
local modes = {
  {0, 2, 4, 5, 7, 9, 11},  -- 0=Ionian
  {0, 2, 3, 5, 7, 9, 10},  -- 1=Dorian
  {0, 1, 3, 5, 7, 8, 10},  -- 2=Phrygian
  {0, 2, 4, 6, 7, 9, 11},  -- 3=Lydian
  {0, 2, 4, 5, 7, 9, 10},  -- 4=Mixolydian
  {0, 2, 3, 5, 7, 8, 10},  -- 5=Aeolian
  {0, 1, 3, 5, 6, 8, 10},  -- 6=Locrian
}

local pentatonic_modes = {
  {0, 2, 4, 7, 9},   -- 0=Major pentatonic
  {0, 2, 5, 7, 10},  -- 1=Suspended pentatonic
  {0, 3, 5, 7, 10},  -- 2=Blues minor pentatonic
  {0, 2, 5, 7, 9},   -- 3=Ritusen (Japanese)
  {0, 4, 5, 7, 11},  -- 4=Prometheus
}

-- 1-based interval; degree/octave derived with Lua's 0-based floor modulo
-- (same math as lib/scheme/modal.scm).
-- modal(0, 0, 1)  => 0   ; C Ionian tonic
-- modal(0, 0, 3)  => 4   ; C Ionian 3rd
function modal(root, mode, interval)
  local offsets = modes[mode + 1]
  local d = interval - 1
  return root + offsets[(d % 7) + 1] + math.floor(d / 7) * 12
end

-- pentatonic(0, 0, 1)  => 0   ; C major pentatonic tonic
-- pentatonic(0, 0, 2)  => 2   ; 2nd
function pentatonic(root, mode, interval)
  local offsets = pentatonic_modes[mode + 1]
  local d = interval - 1
  return root + offsets[(d % 5) + 1] + math.floor(d / 5) * 12
end