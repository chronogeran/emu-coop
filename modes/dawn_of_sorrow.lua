-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- Data source: https://datacrystal.romhacking.net/wiki/Crystalis:RAM_map
-- This file is available under Creative Commons CC0

local spec = {
	guid = "9f4d9002-51df-4a4e-966a-650adda6c3ad",
	format = "1.2",
	name = "Castlevania: Dawn of Sorrow",
	pipe = "tcp",
	match = {"stringtest", addr=0x0219c980, value="CASTLEVANIA1ACVE"},
	-- por {"stringtest", addr=0x3ffa80, value="CASTLEVANIA2ACBE"},
	-- OOE {"stringtest", addr=0x3ffa80, value="CASTLEVANIA3YR9E"},
	running = {"test", addr = 0x020f703c, size=4, gte = 1}, -- Using game clock as running test
	sync = {},
	custom = {},
}

-- Pixels are stored 4 bits per pixel,
-- 8x8 pixel tiles
function getPixelByteIndex(x, y)
	local tileRowIndex = math.floor(y / 8)
	local tileColIndex = math.floor(x / 8)
	return 0x111840 + tileRowIndex * 0x400 + tileColIndex * 0x20 + (y % 8) * 4 + math.floor((x % 8) / 2)
end

-- Max exploration
for i=0,0x19b do
	spec.sync[0x020f6e34 + i] = {kind="bitOr", receiveTrigger=function(value, previousValue)
		if value == previousValue then return end
		local changedBits = XOR(value, previousValue)
		local changedBitNumber = 0
		local b = changedBits
		while AND(b, 1) ~= 1 and changedBitNumber < 8 do
			SHIFT(b, 1)
			changedBitNumber = changedBitNumber + 1
		end
		if i % 2 == 1 then changedBitNumber = changedBitNumber + 8 end
		-- changedBitNumber should be 0-15
		-- TODO check if abyss
		local mapColumn = math.floor(i / 90)
		local mapRow = math.floor(i / 2) % 45
		local leftBorderX = 16
		local pixelX = leftBorderX + (mapColumn * 64) + changedBitNumber * 4
		-- topBorderY is 0
		local pixelY = mapRow * 4
		-- draw starting in pixelX, pixelY, +4 each direction
		-- TODO look up actual map data
		for x=0,4 do
			for y=0,4 do
				local pixelIndex = getPixelByteIndex(pixelX + x, pixelY + y)
				
				local pixels = mainmemory.readbyte(pixelIndex)
				if x % 2 == 1 then
					pixels = OR(0xf0, pixels)
				else
					pixels = OR(0x0f, pixels)
				end
				mainmemory.writebyte(pixels)
			end
		end
	end}
end

-- Boss Fights (needs verification)
spec.sync[0x020f7038] = {kind="bitOr"}
spec.sync[0x020f7039] = {kind="bitOr"}
spec.sync[0x020f703a] = {kind="bitOr"}

-- Souls owned
for i=0,0x37 do
	spec.sync[0x020f70d2 + i] = {kind="delta"}
end

-- Ability souls
for i=0,3 do
	spec.sync[0x020f710a + i] = {kind="delta",
		receiveTrigger=function (value, previousValue)
			-- Equip abilities when receiving them
			local bitsToSet = 0
			if AND(0xf0, value) == 1 and AND(0xf0, previousValue) == 0 then
				bitsToSet = LSHIFT(1, i * 2 + 1)
			end
			if AND(0x0f, value) == 1 and AND(0x0f, previousValue) == 0 then
				bitsToSet = OR(bitsToSet, LSHIFT(1, i * 2))
			end
			if bitsToSet ~= 0 then
				local currentEquips = memory.readbyte(0x020f741e)
				memory.writebyte(0x0f741e, OR(currentEquips, bitsToSet))
			end
		end}
end

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

-- Area visit flags (for area name popup)
spec.sync[0x020f7183] = {kind="bitOr"}
-- Room type tutorials
spec.sync[0x020f7187] = {kind="bitOr"}
-- Events, item pickups (todo: don't know end range)
for i=0,0x1f do
	spec.sync[0x020f7188 + i] = {kind="bitOr"}
end
-- Warp Rooms visited
spec.sync[0x020f71a8] = {kind="bitOr"}
spec.sync[0x020f71a9] = {kind="bitOr"}

-- Item Inventory
for i=0,0x6a do
	spec.sync[0x020f71bc + i] = {kind="delta"}
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