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
	match = {"stringtest", addr=0x0219c980, value="CASTLEVANIA1ACVE"},
	running = {"test", addr = 0x020f703c, size=4, gte = 1}, -- Using game clock as running test
	sync = {},
	custom = {},
}

local CurrentMapIdAddress = 0x020f6e25
local MapExplorationDataAddress = 0x020f6e34
local MapPixelDataAddress = 0x0210f040
local MapExplorationDataExtent = 0x19b
local MapXAddress = 0x020c8926
local MapYAddress = 0x020c8924
local GetMapCoords = function()
	return memory.readbyte(MapXAddress) + 16, memory.readbyte(MapYAddress) + 16
end
local AreCoordsValid = function()
	return memory.readbyte(MapXAddress) > 0
end
require("modes.ds_castlevania_base")
addMap(CurrentMapIdAddress, MapExplorationDataAddress, MapPixelDataAddress, MapExplorationDataExtent, MapXAddress, MapYAddress, spec, GetMapCoords, AreCoordsValid)

-- Boss Fights
spec.sync[0x020f7038] = {size=4, kind="bitOr", verb="defeated", nameBitmap={"", "Flying Armor", "Balore", "Dmitrii", "Malphas", "Dario", "Puppet Master", "", "", "Zephyr", "", "Dario/Aguni"}} -- TODO Death, Abaddon, Paranoia, Rahab, Giant Bat, Gergoth

-- Souls inventory
for i=0,0x34,4 do
	spec.sync[0x020f70d0 + i] = {size=4, kind="delta"}
end

-- Ability souls
-- Equip abilities when receiving them
spec.sync[0x020f7108] = {size=4, kind="delta", nameBitmap={[17]="Balore Ability", [21]="Malphas Ability", [25]="Doppelganger Ability", [29]="Rahab Ability"},
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
			memory.writebyte(0x020f741e, OR(currentEquips, bitsToSet))
		end
	end
}
spec.sync[0x020f710c] = {size=4, kind="delta", nameBitmap={[1]="Hippogryph Ability", [5]="Procel Ability", [9]="Mud Demon Ability"},
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
			memory.writebyte(0x020f741e, OR(currentEquips, bitsToSet))
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

-- Flags
-- Area visit flags (for area name popup) (7183)
spec.sync[0x020f7180] = {size=4, kind="bitOr", verb="visited", nameBitmap={[29]="Lost Village",[30]="Wizardry Lab", [31]="Garden of Madness", [32]="The Dark Chapel"}}
-- Room type tutorials (7187)
spec.sync[0x020f7184] = {size=4, kind="bitOr", verb="visited", nameBitmap={"Demon Guest House", "Condemned Tower", "Mine of Judgment", "", "Subterranean Hell", "Silenced Ruins", "The Pinnacle", ""}} -- TODO Cursed Clock Tower, Abyss
-- Events, item pickups
for i=0,0x1f do
	spec.sync[0x020f7188 + i] = {kind="bitOr"}
end
-- Warp Rooms visited
spec.sync[0x020f71a8] = {size=4, kind="bitOr", verb="discovered", nameBitmap={"Lost Village Warp Room", "Demon Guest House Warp Room","Wizardry Lab Warp Room","Garden of Madness Warp Room","The Dark Chapel Warp Room","Condemned Tower Warp Room","Mine of Judgment Warp Room","Subterranean Hell Warp Room","Silenced Ruins Warp Room","Cursed Clock Tower Warp Room","The Pinnacle Warp Room","The Abyss Warp Room"}}

-- Item Inventory
for i=0,0x68,4 do
	spec.sync[0x020f71bc + i] = {size=4, kind="delta"}
end

-- Magic Seals
spec.sync[0x020f7254] = {kind="bitOr", nameBitmap={"Magic Seal 1", "Magic Seal 2", "Magic Seal 3", "Magic Seal 4", "Magic Seal 5"}}
-- Soul type tutorials
spec.sync[0x020f7255] = {kind="bitOr"}

-- HP
--spec.sync[0x020f7410] = {size=2, kind="delta"}

-- EXP
spec.sync[0x020f7448] = {size=4, kind="delta", deltaMin=0, deltaMax=99999999}
-- Gold
spec.sync[0x020f744c] = {size=4, kind="delta", deltaMin=0, deltaMax=99999999}

return spec