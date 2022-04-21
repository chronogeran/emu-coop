-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- Data source: 
-- This file is available under Creative Commons CC0

local spec = {
	guid = "993a2e9d-a255-45d5-9856-c7aa4a5ef442",
	format = "1.2",
	name = "Castlevania: Aria of Sorrow",
	match = {"stringtest", addr=0x080000a0, value="CASTLEVANIA2"},
	--running = {"test", addr = 0x020f703c, size=4, gte = 1}, -- Using game clock as running test
	sync = {},
	custom = {},
}

-- Map
-- AC
for i=0,0x27c,4 do
	spec.sync[0x020000b8 + i] = {kind="bitOr", size=4}
end

-- Flags
-- AC
-- TODO range
for i=0,0x1c,4 do
	spec.sync[0x02000360 + i] = {kind="bitOr", size=4}
end

-- EXP
spec.sync[0x0201328c] = {kind="delta", size=4}
-- Gold
spec.sync[0x02013290] = {kind="delta", size=4, deltaMin=0, deltaMax=999999}

-- Inventory
-- AC
for i=0,0xfc,2 do
	spec.sync[0x02013294 + i] = {kind="delta", size=2}
end

-- Ability Souls
local equippedAbilitiesAddr = 0x02013396
spec.sync[0x02013392] = {kind="delta", size=4, receiveTrigger=function(value, previousValue)
	local val = value
	local bitsToSet = 0
	for i=0,5 do
		if AND(0x0f, val) == 1 then
			bitsToSet = OR(bitsToSet, BIT(i))
		end
		val = SHIFT(val, 4)
	end
	if bitsToSet ~= 0 then
		local currentEquips = memory.readbyte(equippedAbilitiesAddr)
		memory.writebyte(equippedAbilitiesAddr, OR(currentEquips, bitsToSet))
	end
}
--for i=0,2 do
	--spec.sync[0x02013392 + i] = {kind="delta", receiveTrigger=function(value, previousValue)
		-- Equip abilities when receiving them
		--if AND(value, 0xf) == 1 and AND(previousValue, 0xf) == 0 then
			--local existingByte = memory.readbyte(equippedAbilitiesAddr)
			--memory.writebyte(equippedAbilitiesAddr, OR(existingByte, 0x1)

-- Enemy data
-- AC
for i=0,0xc,4 do
	spec.sync[0x020133a0 + i] = {kind="bitOr", size=4}
end
for i=0,0xc,4 do
	spec.sync[0x020133b0 + i] = {kind="bitOr", size=4}
end
for i=0,0xc,4 do
	spec.sync[0x020133c0 + i] = {kind="bitOr", size=4}
end

return spec