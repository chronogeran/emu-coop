-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "7844d826-c96d-4c04-abaf-6bd068b473ce",
	format = "1.2",
	name = "Castlevania: Order of Ecclesia",
	match = {"stringtest", addr=0x023ffa80, value="CASTLEVANIA3YR9E"},
	running = {"test", addr = 0x02100374, size=4, gte = 1}, -- Using game clock as running test
	sync = {},
	custom = {},
}

-- HP
--spec.sync[0x021002b4] = {size=2, kind="delta"}
-- Max HP
--spec.sync[0x021002b6] = {size=2}
-- MP
--spec.sync[0x021002b8] = {size=2, kind="delta"}
-- Max MP
--spec.sync[0x021002ba] = {size=2}
-- Hearts
--spec.sync[0x021002bc] = {size=2, kind="delta"}
-- Max Hearts
--spec.sync[0x021002be] = {size=2}

-- EXP
spec.sync[0x0210030c] = {size=4, kind="delta", deltaMin=0, deltaMax=99999999}
-- Gold
spec.sync[0x02100310] = {size=4, kind="delta", deltaMin=0, deltaMax=9999999}

local CurrentMapIdAddress = 0x020ffcb9
local MapExplorationDataAddress = 0x02100144
local MapPixelDataAddress = 0x0214b1e0
local MapExplorationDataExtent = 0x168
local MapXAddress = 0x0214617c
local MapYAddress = 0x0214617e
local GetMapCoords = function()
	return memory.readbyte(MapXAddress), memory.readbyte(MapYAddress)
end
local AreCoordsValid = function() return true end -- TODO?
-- FIXME map drawing smears (leaves traces of buddy when buddy reveals new rooms). Specific to OoE.
require("modes.ds_castlevania_base")
addMap(CurrentMapIdAddress, MapExplorationDataAddress, MapPixelDataAddress, MapExplorationDataExtent, MapXAddress, MapYAddress, spec, GetMapCoords, AreCoordsValid)

-- Bestiary: enemies defeated
for i=0,0xf,4 do
	spec.sync[0x02100344 + i] = {size=4, kind="bitOr"}
end
-- Bestiary: Item 1 drop
for i=0,0xf,4 do
	spec.sync[0x02100354 + i] = {size=4, kind="bitOr"}
end
-- Bestiary: Item 2 drop
for i=0,0xf,4 do
	spec.sync[0x02100364 + i] = {size=4, kind="bitOr"}
end

-- Flags (area visit flags, events, item pickups)
for i=0,0x4f,4 do
	spec.sync[0x02100378 + i] = {size=4, kind="bitOr"}
end
-- 3d8 may not be something I need?

-- Area Unlocks
for i=0,4 do
	spec.sync[0x021003cc + i] = {size=1, kind="bitOr"}
end

-- Bosses
spec.sync[0x021003e4] = {size=2, kind="bitOr"}

-- Glyphs
for i=0,0x31,4 do
	spec.sync[0x021003e8 + i] = {size=4, kind="bitOr"}
end
-- R Glyphs
spec.sync[0x02100420] = {size=4, kind="bitOr", receiveTrigger=function(value, previousValue)
	if value == previousValue then return end
	-- Equip Magnes when receiving for the first time
	-- TODO test
	local changedBits = XOR(value, previousValue)
	if AND(0xff00, previousValue) == 0 and AND(value, 0x0100) > 0 then
		memory.writebyte(0x021002c4, 1)
	end
end}
for i=0,0x13,4 do
	spec.sync[0x02100424 + i] = {size=4, kind="bitOr"}
end

-- Relics & Inventory
for i=0,0xf0,4 do
	spec.sync[0x02100458 + i] = {size=4, mask=0x0f0f0f0f, kind="delta", receiveTrigger=function (value, previousValue)
		-- Get guide data
		-- TODO test
		local changedBits = XOR(value, previousValue)
		if changedBits == 0 then return end
		local bitsToOr = 0x90
		if i <= 4 then bitsToOr = 0xd0 end -- Equip relics with bit 0x40
		local guideData = 0
		for j=0,3 do
			if AND(changedBits, SHIFT(0xf, -8 * j)) ~= 0 then
				guideData = OR(guideData, SHIFT(bitsToOr, -8 * j))
			end
		end
		memory.writedword(0x02100458 + i, OR(guideData, memory.readdword(0x02100458 + i)))
	end}
end

-- Kills
spec.sync[0x021005e8] = {size=4, kind="delta", deltaMin=0, deltaMax=99999}

-- Max ups
spec.sync[0x0210079c] = {size=2, kind="delta", deltaMax=600, receiveTrigger=function(value, previousValue)
	-- Update current and max when receiving
	-- TODO test
	memory.writeword(0x021002b4, memory.readword(0x021002b4) + value)
	memory.writeword(0x021002b6, memory.readword(0x021002b6) + value)
end}
spec.sync[0x0210079e] = {size=2, kind="delta", deltaMax=300, receiveTrigger=function(value, previousValue)
	-- Update current and max when receiving
	-- TODO test
	memory.writeword(0x021002b8, memory.readword(0x021002b8) + value)
	memory.writeword(0x021002ba, memory.readword(0x021002ba) + value)
end}
spec.sync[0x021007a0] = {size=2, kind="delta", deltaMax=300, receiveTrigger=function(value, previousValue)
	-- Update current and max when receiving
	-- TODO test
	memory.writeword(0x021002bc, memory.readword(0x021002bc) + value)
	memory.writeword(0x021002be, memory.readword(0x021002be) + value)
end}

return spec