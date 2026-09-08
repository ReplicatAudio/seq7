-- Direct port of examples/scheme/lsys3.scm (L-system drum pattern + two
-- melody sequencers driven by the same string), using the Lua libs instead
-- of inlined helpers.
dofile("lib/lua/lib.lua")

set_tick_speed(150)

-- Same rewrite-set layout as lib/lua/lsystem.lua: index 1 = axiom, then
-- rule pairs (symbol, replacement); "?" = unused rule.
local rset = {
  "a",           -- axiom
  "a", "ab",     -- r1
  "b", "a",      -- r2
  "?", "?",      -- r3 (empty)
  "?", "?",      -- r4 (empty)
}

local gens = lsystem(rset, 16)
local lout = gens[#gens]  -- (last (lsystem rset 16))

print("LSYSTEM OUTPUT (FINAL GEN):")
print(lout)

local mode = 1  -- Dorian

local mela = string_split_space_line([[
5 5 5 5 4 4 4 4
1 1 1 1 1 1 1 1
5 5 5 5 4 4 4 4
2 2 2 2 2 2 2 2
]])

local melb = string_split_space_line([[
7 1 5 7 1 4 3 4
1 1 1 1 1 1 1 1
]])

-- Scheme keeps lout as a list of single-char strings; index the equivalent
-- Lua string with sub(i, i).
local function ref(str, i)
  return str:sub((i % #str) + 1, (i % #str) + 1)  -- 0-based (modulo tt len)
end

local t = 0

function tickfn()
  if t == 0 then midi_start() end
  if t % 8 == 0 then midi_clock() end

  local v = ref(lout, t)
  print("v1")
  print(v)
  if v == "a" then
    midi_note_on(0, 60, 127)
  elseif v == "b" then
    midi_note_on(1, 60, 127)
  end

  local tt2 = math.floor(t / 32)
  local tt3 = math.floor(t / 2)
  local v = ref(lout, tt2)
  print("v2")
  print(v)
  if v == "a" then
    sequencer(2, mela, 48, 0, mode, 127, tt2)
  elseif v == "b" then
    sequencer(2, melb, 48, 0, mode, 127, tt2)
  end

  local tt4 = math.floor(t / 48)
  local v = ref(lout, tt3)
  print("v2")
  print(v)
  if v == "a" then
    sequencer(3, mela, 48, 0, mode, 127, tt4)
  elseif v == "b" then
    sequencer(3, melb, 48, 0, mode, 127, tt4)
  end

  t = t + 1
end