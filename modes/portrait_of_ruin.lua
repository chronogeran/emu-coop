-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "d24854ff-1c15-4720-a700-854b9a575b4a",
	format = "1.2",
	name = "Castlevania: Portrait of Ruin",
	match = {"stringtest", addr=0x023ffe00, value="CASTLEVANIA2ACBE"},
	running = {"test", addr = 0x021119e0, size=4, gte = 1}, -- Using game clock as running test
	sync = {},
	custom = {},
}

-- TODO max ups (capped at 32 for both. No hearts)

local CurrentMapIdAddress = 0x02111785
local MapExplorationDataAddress = 0x02111794
local MapPixelDataAddress = 0x02136900
local MapExplorationDataExtent = 0x1d8
require("modes.ds_castlevania_base")
addMap(CurrentMapIdAddress, MapExplorationDataAddress, MapPixelDataAddress, MapExplorationDataExtent, spec)

-- Boss Fights
spec.sync[0x021119dc] = {size=4, kind="bitOr"}

-- Subweapons/Spells/Dual Crush/Relics inventory
for i=0,0x2b,4 do
	spec.sync[0x02111a6c + i] = {size=4, kind="delta"}
end
spec.sync[0x02111a98] = {size=2, kind="delta"}
for i=0,0x7 do
	spec.sync[0x02111a9a + i] = {size=1, kind="delta",
		receiveTrigger=function (value, previousValue)
			-- TODO test
			local gotHigh = value >= 0x10
			local gotLow = AND(value, 0xf) >= 1
			local equipHigh = gotHigh and AND(previousValue, 0xf0) == 0
			local equipLow = gotLow and AND(previousValue, 0x0f) == 0
			if not (equipHigh or equipLow) then return end

			local equipsAddress = 0x02111a68 + math.floor(i / 4)
			local bitNumber = (i % 4) * 2
			local currentEquips = memory.readbyte(equipsAddress)
			if equipHigh then
				currentEquips = OR(currentEquips, BIT(bitNumber + 1)))
			end
			if equipLow then
				currentEquips = OR(currentEquips, BIT(bitNumber)))
			end
			memory.writebyte(equipsAddress, currentEquips)
		end}
end

-- Bestiary: enemies defeated
for i=0,0x13 do
	spec.sync[0x02111aac + i] = {kind="bitOr"}
end
-- Bestiary: Item 1 drop
for i=0,0x13 do
	spec.sync[0x02111ac4 + i] = {kind="bitOr"}
end
-- Bestiary: Item 2 drop
for i=0,0x13 do
	spec.sync[0x02111adc + i] = {kind="bitOr"}
end

-- Events/Doors/Pickups/etc.
-- TODO verify range
for i=0,0x58,4 do
	spec.sync[0x02111b9c + i] = {size=4, kind="bitOr"}
end

-- Item Inventory
for i=0,0xb4,4 do
	spec.sync[0x02111bf8 + i] = {size=4, kind="delta"}
end

-- Skill Mastery
-- TODO verify range
for i=0,0x9c,4 do
	-- TODO high 4 bits is something else, may need to mask
	spec.sync[0x02111cba + i] = {size=4, kind="delta"}
end

-- Kill Counts
for i=0,0x134,4 do
	spec.sync[0x02111d76 + i] = {size=4, kind="delta"}
end

-- Quests
-- TODO verify range
for i=0,0x40,4 do
	spec.sync[0x02111eac + i] = {size=4, kind="bitOr"}
end

-- HP
--spec.sync[0x02---] = {size=2, kind="delta"}

-- EXP
spec.sync[0x021121c0] = {size=4, kind="delta", deltaMin=0, deltaMax=99999999}
-- Gold
spec.sync[0x021121c4] = {size=4, kind="delta", deltaMin=0, deltaMax=9999999}

return spec