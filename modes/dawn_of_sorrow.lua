-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "9f4d9002-51df-4a4e-966a-650adda6c3ad",
	format = "1.2",
	name = "Castlevania: Dawn of Sorrow",
	pipe = "tcp",
	match = {"stringtest", addr=0x0219c980, value="CASTLEVANIA1ACVE"},
	running = {"test", addr = 0x020f703c, size=4, gte = 1}, -- Using game clock as running test
	sync = {},
	custom = {},
}

local CurrentMapIdAddress = 0x020f6e25
local MapExplorationDataAddress = 0x02111794
local MapPixelDataAddress = 0x02136900
local MapExplorationDataExtent = 0x1d8
require("modes.ds_castlevania_base")
addMap(CurrentMapIdAddress, MapExplorationDataAddress, MapPixelDataAddress, MapExplorationDataExtent, spec)

-- Boss Fights (needs verification)
-- AC
spec.sync[0x020f7038] = {size=4, kind="bitOr"}
--spec.sync[0x020f7039] = {kind="bitOr"}
--spec.sync[0x020f703a] = {kind="bitOr"}

-- Souls inventory
for i=0,0x34,4 do
	spec.sync[0x020f70d0 + i] = {size=4, kind="delta"}
end

-- Ability souls
-- Equip abilities when receiving them
spec.sync[0x020f7108] = {size=4, kind="delta",
	receiveTrigger=function (value, previousValue)
		local val = SHIFT(value, 16)
		local bitsToSet = 0
		for i=0,3 do
			if AND(0x0f, val) == 1 then
				bitsToSet = OR(bitsToSet, BIT(i))
			end
			val = SHIFT(val, 4)
		end
		if bitsToSet ~= 0 then
			local currentEquips = memory.readbyte(0x020f741e)
			memory.writebyte(0x0f741e, OR(currentEquips, bitsToSet))
		end
	end
}
spec.sync[0x020f710c] = {size=4, kind="delta",
	receiveTrigger=function (value, previousValue)
		local val = value
		local bitsToSet = 0
		for i=4,6 do
			if AND(0x0f, val) == 1 then
				bitsToSet = OR(bitsToSet, BIT(i))
			end
			val = SHIFT(val, 4)
		end
		if bitsToSet ~= 0 then
			local currentEquips = memory.readbyte(0x020f741e)
			memory.writebyte(0x0f741e, OR(currentEquips, bitsToSet))
		end
		
	end
}

-- Bestiary: enemies defeated
for i=0,0xe do
	spec.sync[0x020f7150 + i] = {kind="bitOr"}
end
-- Bestiary: Item 1 drop
for i=0,0xe do
	spec.sync[0x020f7160 + i] = {kind="bitOr"}
end
-- Bestiary: Item 2 drop
for i=0,0xe do
	spec.sync[0x020f7170 + i] = {kind="bitOr"}
end

-- Area visit flags (for area name popup) (7183)
spec.sync[0x020f7180] = {size=4, kind="bitOr"}
-- Room type tutorials (7187)
spec.sync[0x020f7184] = {size=4, kind="bitOr"}
-- TODO verify event alignment
-- Item pickup alignment good (719d at size 1)
-- Events, item pickups
-- RC
for i=0,0x1f do
	spec.sync[0x020f7188 + i] = {kind="bitOr"}
end
-- Warp Rooms visited
-- AC
spec.sync[0x020f71a8] = {size=2, kind="bitOr"}

-- Item Inventory
for i=0,0x68,4 do
	spec.sync[0x020f71bc + i] = {size=4, kind="delta"}
end

-- Magic Seals
spec.sync[0x020f7254] = {kind="bitOr"}
-- Soul type tutorials
spec.sync[0x020f7255] = {kind="bitOr"}

-- HP
--spec.sync[0x020f7410] = {size=2, kind="delta"}

-- EXP
spec.sync[0x020f7448] = {size=4, kind="delta", deltaMin=0, deltaMax=99999999}
-- Gold
spec.sync[0x020f744c] = {size=4, kind="delta", deltaMin=0, deltaMax=99999999}

return spec