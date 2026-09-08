-- Direct port of examples/scheme/sequence2.scm (melody + bass sequenced
-- from step patterns), using the Lua libs instead of inlined helpers.
dofile("lib/lua/lib.lua")

set_tick_speed(150)

local seq1 = string_split_space_line([[
1 5 6 7 1 5 6 7
1 5 6 7 3 5 6 7
1 5 6 7 3 5 6 7
1 r 6 r 3 r 6 r
1 5 6 7 1 5 6 7
1 5 6 7 3 5 6 7
1 5 6 7 3 5 6 7
1 r 6 r 3 r 6 r
7 7 8 6 1 5 6 7
7 7 8 6 1 5 6 7
7 7 8 9 1 5 6 7
7 r 8 r 1 r 6 r
1 r 6 r 3 r 6 r
7 r 8 r 1 r 6 r
1 r 6 r 3 r 6 r
7 r 8 r 1 r 6 r
]])

local seq2 = string_split_space_line([[
1 r r r 1 r 6 r
1 r r r 3 r 6 r
1 r r r 3 r 6 r
1 r 6 r 3 r 6 r
]])

local t = 0

function tickfn()
  sequencer(0, seq1, 48, 0, 1, 127, t)
  sequencer(1, seq2, 36, 0, 1, 127, t)
  t = t + 1
end