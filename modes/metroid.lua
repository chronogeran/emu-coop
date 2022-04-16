-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- Data source: https://datacrystal.romhacking.net/wiki/Metroid:RAM_map
-- This file is available under Creative Commons CC0

local spec = {
	guid = "5d870f93-4b41-49b5-a682-1f06c543df1b",
	format = "1.2",
	name = "Metroid",
	pipe = "tcp",
	match = {"stringtest", addr=0xffe9, value="METROID"},
	--running = {"test", addr = 0x6c, lte = 0xfe}, TODO
	sync = {},
	custom = {},
}

-- Health
spec.sync[0x106] = {size=2}

-- Energy tanks
spec.sync[0x6877] = {}

-- Power ups
-- Ice and wave are mutually exclusive, so don't use bitOr
spec.sync[0x6878] = {}

-- Missiles
spec.sync[0x6879] = {kind="delta"}
-- Max missiles
spec.sync[0x687a] = {}
-- Kraid
spec.sync[0x687b] = {}
-- Ridley
spec.sync[0x687c] = {}

-- Opened doors/obtained items
for i=0,0x75 do
	spec.sync[0x6887 + i] = {}
end

return spec
