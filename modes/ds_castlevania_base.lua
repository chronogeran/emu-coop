-- Author: Chronogeran
-- Common functionality for DS castlevania games to update the map graphics as they are revealed by other players

function addMap(CurrentMapIdAddress, MapExplorationDataAddress, MapPixelDataAddress, MapExplorationDataExtent, spec)

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
for i=0,MapExplorationDataExtent,2 do
	spec.sync[MapExplorationDataAddress + i] = {kind="bitOr", size=2, writeTrigger=function(value, previousValue)
		if value == previousValue then return end
		local pixelDataBefore = memory.read_bytes_as_array(MapPixelDataAddress, MapPixelDataSize)
		mainDriver:executeNextFrame(function()
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

end