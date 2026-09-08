-- Lua library loader (port of lib/scheme/lib.scm). Load every lib so a
-- script can start with a single dofile:
--
--   dofile("lib/lua/lib.lua")

dofile("lib/lua/midi.lua")
dofile("lib/lua/modal.lua")
dofile("lib/lua/string.lua")
dofile("lib/lua/lsystem.lua")
dofile("lib/lua/sequencer.lua")