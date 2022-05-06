-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- Data source: https://datacrystal.romhacking.net/wiki/Legacy_of_the_Wizard:RAM_map
-- This file is available under Creative Commons CC0

local spec = {
	guid = "09690743-bb87-4ca5-949a-7ff2799a0d48",
	format = "1.2",
	name = "Legacy of the Wizard",
	pipe = "tcp",
	match = function(valueOverride, sizeOverride)
		return (memory.readbyte(0xfffa) == 0xfe
			and memory.readbyte(0xfffb) == 0xd1
			and memory.readbyte(0xfffc) == 0xe0
			and memory.readbyte(0xfffd) == 0xff
			and memory.readbyte(0xfffe) == 0xfe
			and memory.readbyte(0xffff) == 0xd1)
	end,
	--running = {"test", addr = 0x6c, lte = 0xfe}, TODO
	sync = {},
	custom = {},
}

-- Bosses are tracked by number of crowns possessed

-- Health
spec.sync[0x58] = {}
-- Magic
spec.sync[0x59] = {}
-- Gold
spec.sync[0x5a] = {}
-- Keys
spec.sync[0x5b] = {}
-- Inventory
for i=0,0xf do
	spec.sync[0x60 + i] = {}
end
-- Chests. Bit is set initially, then cleared when item in chest is collected.
for i=0,0xf do
	spec.sync[0x300 + i] = {kind="flags"}
end
-- Checkpoint data - inventory, keys, gold
for i=0,0x11 do
	spec.sync[0x300 + i] = {}
end

return spec
