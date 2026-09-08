-- Lua library loader (port of scm/lib/lib.scm). Load every lib so a
-- script can start with a single dofile:
--
--   dofile("lua/lib/lib.lua")

dofile("lua/lib/midi.lua")
dofile("lua/lib/modal.lua")
dofile("lua/lib/string.lua")
dofile("lua/lib/lsystem.lua")
dofile("lua/lib/sequencer.lua")