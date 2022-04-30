-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "68f7a87e-277f-470c-9160-f5e18cec5237",
	format = "1.2",
	name = "Castlevania: Harmony of Dissonance",
	match = {"stringtest", addr=0x080000a0, value="CASTLEVANIA1"},
	--running = {"test", addr = 0x020f703c, size=4, gte = 1}, -- Using game clock as running test
	sync = {},
	custom = {},
}

-- Map
for i=0,0x278,4 do
	spec.sync[0x02000090 + i] = {kind="bitOr", size=4}
end

-- Visit flags
spec.sync[0x0200030e] = {kind="bitOr", size=2}
-- Flags
-- RC
for i=0,0x70,4 do
	spec.sync[0x02000310 + i] = {kind="bitOr", size=4}
end

-- HP
--spec.sync[0x0201854e] = {kind="delta", size=2}
-- MP
--spec.sync[0x02018550] = {kind="delta", size=2}
-- Hearts
--spec.sync[0x02018794] = {kind="delta", size=2}

-- Not using delta on these so we don't get double level ups
-- Max HP
spec.sync[0x02018786] = {size=2}
-- Max MP
--spec.sync[0x02018788] = {size=2}
-- Max Hearts
spec.sync[0x0201878a] = {size=2}

-- EXP
spec.sync[0x02018798] = {kind="delta", size=4}
-- Gold
spec.sync[0x0201879c] = {kind="delta", size=4}

-- Inventory
-- Items
for i=0,0x1b do
	spec.sync[0x020187a0 + i] = {kind="delta"}
end
-- Whips
spec.sync[0x020187bc] = {kind="bitOr"}
spec.sync[0x020187bd] = {kind="bitOr"}
-- Equipment
for i=0,0x7f do
	spec.sync[0x020187be + i] = {kind="delta"}
end
-- Spell Books
spec.sync[0x0201883e] = {kind="bitOr"}
-- Relics
spec.sync[0x0201883f] = {kind="bitOr", receiveTrigger=function(value, previousValue)
	local changedBits = XOR(value, previousValue)
	local currentEquips = memory.readword(0x02018841)
	memory.writeword(0x02018841, OR(currentEquips, changedBits))
end}
spec.sync[0x02018840] = {kind="bitOr", receiveTrigger=function(value, previousValue)
	local changedBits = XOR(value, previousValue)
	local currentEquips = memory.readword(0x02018842)
	memory.writeword(0x02018842, OR(currentEquips, changedBits))
end}

-- Collectibles
spec.sync[0x02018843] = {kind="bitOr", size=4}

-- Enemy Info
for i=0,0xc,4 do
	spec.sync[0x02018854 + i] = {kind="bitOr", size=4}
end
for i=0,0xc,4 do
	spec.sync[0x02018864 + i] = {kind="bitOr", size=4}
end
for i=0,0xc,4 do
	spec.sync[0x02018874 + i] = {kind="bitOr", size=4}
end

return spec