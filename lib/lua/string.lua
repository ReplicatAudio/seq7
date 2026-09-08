-- String helpers (port of lib/scheme/string.scm). Mimics the Scheme
-- semantics exactly: consecutive delimiters produce empty strings, and the
-- split is character-based on the literal delimiter.

--- Split a string on every occurrence of the single-character delimiter.
-- string_split("a b  c", " ")  => {"a", "b", "", "c"}
function string_split(str, delim)
  local words = {}
  local cur = ""
  for i = 1, #str do
    if str:sub(i, i) == delim then
      words[#words + 1] = cur
      cur = ""
    else
      cur = cur .. str:sub(i, i)
    end
  end
  words[#words + 1] = cur
  return words
end

-- Trim leading/trailing whitespace (space, tab, newline, ...).
function string_trim(str)
  return str:match("^%s*(.-)%s*$") or ""
end

function string_split_space(str)
  return string_split(str, " ")
end

--- Trim, replace newlines with spaces, then split on space.
-- Used for the multiline step-pattern literals in the examples.
function string_split_space_line(str)
  return string_split_space(string_trim(str:gsub("\n", " ")))
end