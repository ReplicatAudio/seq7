-- L-system engine (port of scm/lib/lsystem.scm).

--- Apply the rewrite rules to one symbol.
-- rset layout (same as the Scheme version): index 1 = axiom, then rule
-- pairs (symbol, replacement); "?" marks unused rules. Rules are checked
-- in order, first match wins.
function mapfn(c, rset)
  for r = 2, #rset - 1, 2 do
    if rset[r] == c then return rset[r + 1] end
  end
  return c
end

--- Rewrite `it` generations of the axiom.
-- Returns all generations as strings (last = final generation), matching
-- `(lsystem rset it)` where the Scheme sides keep single-char strings.
-- Unlike the Scheme version (which uses lists of single-char strings),
-- generations are plain strings; index with str:sub(i, i) as needed.
--
-- Usage:
--   local rset = {
--     "a",       -- axiom
--     "a", "ab", -- r1
--     "b", "a",  -- r2
--     "?", "?",  -- r3 (empty)
--     "?", "?",  -- r4 (empty)
--   }
--   local gens = lsystem(rset, 16)  -- gens[#gens] = final generation
function lsystem(rset, it)
  local gen = rset[1]
  local gens = {}
  for i = 1, it do
    local out = {}
    for c in gen:gmatch(".") do
      out[#out + 1] = mapfn(c, rset)
    end
    gen = table.concat(out)
    gens[#gens + 1] = gen
  end
  return gens
end