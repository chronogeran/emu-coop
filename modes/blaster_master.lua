-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- Data source: https://datacrystal.romhacking.net/wiki/Blaster_Master:RAM_map
-- This file is available under Creative Commons CC0

local spec = {
	guid = "be918ccb-c1cc-4121-ba2e-813a76154b0d",
	format = "1.2",
	name = "Blaster Master",
	match = function(valueOverride, sizeOverride)
		return (memory.readbyte(0xfffa) == 0x7e
			and memory.readbyte(0xfffb) == 0xeb
			and memory.readbyte(0xfffc) == 0xf4
			and memory.readbyte(0xfffd) == 0xff
			and memory.readbyte(0xfffe) == 0x97
			and memory.readbyte(0xffff) == 0xeb)
	end,
	--running = {"test", addr = 0x6c, lte = 0xfe}, TODO
	sync = {},
	custom = {},
}

-- Items
spec.sync[0x99] = {kind="bitOr"}
-- Gun gauge
--spec.sync[0xc3] = {}

-- Bosses
spec.sync[0x3fb] = {kind="bitOr"}
-- Item pickups
spec.sync[0x3fc] = {kind="bitOr"}

-- Saved Tank Health
--spec.sync[0x3ff] = {}
-- Health
--spec.sync[0x40d] = {}

-- Homing missiles
spec.sync[0x6f0] = {}
-- Lightning
spec.sync[0x6f1] = {}
-- 3-way missile
spec.sync[0x6f2] = {}

return spec
