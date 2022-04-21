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

spec.nextFrameTasks = {}
spec.tick = function()
	for k,v in pairs(spec.nextFrameTasks) do
		v()
	end
	spec.nextFrameTasks = {}
end

local CurrentMapIdAddress = 0x02111785 -- TODO unknown
local MapExplorationDataAddress = 0x020f6e34
local MapExplorationDataExtent = 0x19b
local MapPixelDataAddress = 0x0210f040
local MapPixelDataSize = 0x6000
local MapTileRowSize = 0x400
local MapTileSize = 0x20

-- Pixels are stored 4 bits per pixel,
-- 8x8 pixel tiles
function getPixelByteIndex(x, y)
	local tileRowIndex = math.floor(y / 8)
	local tileColIndex = math.floor(x / 8)
	return 0x10f040 + tileRowIndex * 0x400 + tileColIndex * 0x20 + (y % 8) * 4 + math.floor((x % 8) / 2)
end

-- Pixels are stored 4 bits per pixel,
-- 8x8 pixel tiles
function pixelDataOffset(x, y)
	local tileRowIndex = math.floor(y / 8)
	local tileColIndex = math.floor(x / 8)
	return MapPixelDataAddress + tileRowIndex * MapTileRowSize + tileColIndex * MapTileSize + (y % 8) * 4 + math.floor((x % 8) / 2)
end

function pixelCoordinates(pixelOffset)
	local localOffset = pixelOffset - MapPixelDataAddress
	local tileX = math.floor((localOffset % MapTileRowSize) / MapTileSize)
	local pixelX = (tileX * 8) + (localOffset % 4) * 2
	local tileY = math.floor(localOffset / MapTileRowSize)
	local pixelY = tileY * 8 + math.floor((localOffset % MapTileSize) / 4)
	return pixelX, pixelY
end

spec.custom["mapData"] = function(payload)
	local mapId, pixelX, pixelY = payload[1], payload[2], payload[3]
	if mapId ~= memory.readbyte(CurrentMapIdAddress) then return end
	local i = 4
	for y=pixelY, pixelY + 4 do
		for x=pixelX, pixelX + 4, 2 do
			local offset = pixelDataOffset(x, y)
			memory.writebyte(offset, payload[i])
			i = i + 1
		end
	end
end

function sendMapData(localOffset)
	local pixelX, pixelY = pixelCoordinates(MapPixelDataAddress + localOffset)
	local payload = {memory.readbyte(CurrentMapIdAddress), pixelX, pixelY}
	local i = 4
	for y=pixelY, pixelY + 4 do
		for x=pixelX, pixelX + 4, 2 do
			local offset = pixelDataOffset(x, y)
			payload[i] = memory.readbyte(offset)
			i = i + 1
		end
	end
	send("mapData", payload)
end

-- Map exploration
-- Strategy here: compare graphics data changes on exploration change, then send
for i=0,MapExplorationDataExtent do
	spec.sync[MapExplorationDataAddress + i] = {kind="bitOr", writeTrigger=function(value, previousValue)
		if value == previousValue then return end
		local pixelDataBefore = memory.read_bytes_as_array(MapPixelDataAddress, MapPixelDataSize)
		table.insert(spec.nextFrameTasks, function()
			local pixelDataAfter = memory.read_bytes_as_array(MapPixelDataAddress, MapPixelDataSize)
			for i=2,MapPixelDataSize do
				if pixelDataBefore[i] ~= pixelDataAfter[i] then
					sendMapData(i - 1) -- account for 1-based array
					return
				end
			end
		end)
	end}
end

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