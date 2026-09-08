-- Direct port of scm/mintek.scm (drum patterns + modal bass),
-- using the Lua libs instead of inlined helpers.
dofile("lua/lib/lib.lua")

set_tick_speed(200)

local empty  = string_split_space("r")
local kick1  = string_split_space("1 r r r 1 r r r")
local kick2  = string_split_space("1 r r r 1 r r r 1 r r r 1 r r 1")
local snare1 = string_split_space("r r 1 r r r 1 r")
local snare2 = string_split_space("r r 1 r r r 1 1")
local hat1   = string_split_space("r 1 r 1 r 1 r 1 r 1 r 1 r 1 1 1")
local hat2   = string_split_space("r 1 1 1 r 1 r 1 r 1 r 1 r 1 1 1")
local bass1  = string_split_space("r 0 r 0 r 0 r 0")
local bass2  = string_split_space("r 0 r 0 r 0 r 1")

local kick, snare, hat, bass

local function seq(notes, interval)
  return notes[(interval % #notes) + 1]
end

local function n_on(ch, n)
  if n ~= "r" then
    midi_note_on(ch, modal(0, 1, 21 + tonumber(n)), 127)
  else
    print("rest")
  end
end

local t = 0

function tickfn()
  print(t)
  if t == 0 then
    kick  = kick1
    snare = snare1
    hat   = empty
    bass  = bass1
  elseif t == 32 then
    kick  = kick2
    snare = snare2
    hat   = empty
    bass  = bass2
  elseif t == 64 then
    kick  = kick1
    snare = snare1
    hat   = hat1
    bass  = bass1
  elseif t == 96 then
    kick  = kick2
    snare = snare2
    hat   = hat2
    bass  = bass2
  end
  n_on(0, seq(kick, t))
  n_on(1, seq(snare, t))
  n_on(2, seq(hat, t))
  n_on(3, seq(bass, t))
  t = (t + 1) % 128
end