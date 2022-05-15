-- Author: Chronogeran
-- Common functionality for DS castlevania games to update the map graphics as they are revealed by other players

function addMap(CurrentMapIdAddress, MapExplorationDataAddress, MapPixelDataAddress, MapExplorationDataExtent, MapXAddress, MapYAddress, spec, GetMapCoords, AreCoordsValid)

local MapPixelDataSize = 0x6000
local MapTileRowSize = 0x400
local MapTileSize = 0x20

-- Pixels are stored 4 bits per pixel,
-- 8x8 pixel tiles
local function pixelDataOffset(x, y)
	local tileRowIndex = math.floor(y / 8)
	local tileColIndex = math.floor(x / 8)
	return MapPixelDataAddress + tileRowIndex * MapTileRowSize + tileColIndex * MapTileSize + (y % 8) * 4 + math.floor((x % 8) / 2)
end

local function pixelCoordinates(pixelOffset)
	local localOffset = pixelOffset - MapPixelDataAddress
	local tileX = math.floor((localOffset % MapTileRowSize) / MapTileSize)
	local pixelX = (tileX * 8) + (localOffset % 4) * 2
	local tileY = math.floor(localOffset / MapTileRowSize)
	local pixelY = tileY * 8 + math.floor((localOffset % MapTileSize) / 4)
	return pixelX, pixelY
end

local function readSinglePixel(x, y)
	local offset = pixelDataOffset(x, y)
	local current = memory.readbyte(offset)
	if x % 2 == 1 then
		-- Odd, high
		return AND(0xf, SHIFT(current, 4))
	else
		-- Even, low
		return AND(0xf, current)
	end
end

local function writeSinglePixel(x, y, value)
	local offset = pixelDataOffset(x, y)
	local p = value
	local current = memory.readbyte(offset)
	if x % 2 == 1 then
		-- Odd, high
		p = OR(SHIFT(value, -4), AND(0xf, current))
	else
		-- Even, low
		p = OR(value, AND(0xf0, current))
	end
	memory.writebyte(offset, p)
end

local function theseOverlap(p1, p2)
	return p1.x <= p2.x + 1 and p1.x >= p2.x - 1 and p1.y <= p2.y + 1 and p1.y >= p2.y - 1
end

local function copyApplicablePixels(from, to)
	if not theseOverlap(from, to) then return end
	local relativeX = to.x - from.x
	local relativeY = to.y - from.y
	local relativeIndex = relativeX + (relativeY * 2)
	local topLeftIndex = 1 + relativeIndex
	local topRightIndex = 2 + relativeIndex
	local bottomLeftIndex = 3 + relativeIndex
	local bottomRightIndex = 4 + relativeIndex
	if relativeX >= 0  and relativeX <= 1 and from[topLeftIndex]     then to[1] = from[topLeftIndex] end
	if relativeX >= -1 and relativeX <= 0 and from[topRightIndex]    then to[2] = from[topRightIndex] end
	if relativeX >= 0  and relativeX <= 1 and from[bottomLeftIndex]  then to[3] = from[bottomLeftIndex] end
	if relativeX >= -1 and relativeX <= 0 and from[bottomRightIndex] then to[4] = from[bottomRightIndex] end
end

local pixelsByClientId = {}

local function updatePixels(pixels)
	pixels[1] = readSinglePixel(pixels.x,     pixels.y)
	pixels[2] = readSinglePixel(pixels.x + 1, pixels.y)
	pixels[3] = readSinglePixel(pixels.x,     pixels.y + 1)
	pixels[4] = readSinglePixel(pixels.x + 1, pixels.y + 1)
	-- After reading from the map, read from any other overlapp;ing players so we don't use
	-- their dot as the background
	for k,v in pairs(pixelsByClientId) do
		if v ~= pixels then
			copyApplicablePixels(v, pixels)
		end
	end
end

local function drawAllFriends()
	for k,v in pairs(pixelsByClientId) do
		writeSinglePixel(v.x,     v.y,     2)
		writeSinglePixel(v.x + 1, v.y,     2)
		writeSinglePixel(v.x,     v.y + 1, 2)
		writeSinglePixel(v.x + 1, v.y + 1, 2)
	end
end

spec.custom["mapData"] = function(payload)
	local mapId, pixelX, pixelY = payload[1], payload[2], payload[3]
	if mapId ~= memory.readbyte(CurrentMapIdAddress) then return end
	-- Update map
	local i = 4
	for y=pixelY, pixelY + 4 do
		for x=pixelX, pixelX + 4, 2 do
			local offset = pixelDataOffset(x, y)
			memory.writebyte(offset, payload[i])
			i = i + 1
		end
	end
	-- Write true background pixels right after update
	-- this gets messier when sender also has someone else in the room, but that shouldn't happen since they're the one who revealed the room
	for k,v in pairs(pixelsByClientId) do
		if v.mapId == mapId and ((v.x >= pixelX - 1 and v.x <= pixelX + 4) or (v.y >= pixelY - 1 and v.y <= pixelY + 4)) then
			updatePixels(v)
		end
	end
	-- Redraw friends as one was pasted over
	drawAllFriends()
end

local function sendMapData(localOffset)
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
		mainDriver:executeAfterFrames(function()
			local pixelDataAfter = memory.read_bytes_as_array(MapPixelDataAddress, MapPixelDataSize)
			for i=2,MapPixelDataSize do
				if pixelDataBefore[i] ~= pixelDataAfter[i] then
					local offset = i - 1 -- account for 1-based array
					offset = offset - (offset % 2) -- always align with a square
					sendMapData(offset)
					return
				end
			end
		end, 3)
	end}
end

-- Show friends on map

spec.custom["mapPosition"] = function(payload, clientId)
	local mapId, pixelX, pixelY = payload[1], payload[2], payload[3]
	-- Repaint old pixels
	if pixelsByClientId[clientId] then
		local old = pixelsByClientId[clientId]
		writeSinglePixel(old.x,     old.y,     old[1])
		writeSinglePixel(old.x + 1, old.y,     old[2])
		writeSinglePixel(old.x,     old.y + 1, old[3])
		writeSinglePixel(old.x + 1, old.y + 1, old[4])
	end

	if mapId ~= memory.readbyte(CurrentMapIdAddress) then return end
	-- TODO handle changing map on my side

	-- Record pixels
	local pixels = {}
	pixels.x = pixelX
	pixels.y = pixelY
	pixels.mapId = mapId
	updatePixels(pixels)
	pixelsByClientId[clientId] = pixels

	-- Draw new pixels
	drawAllFriends()
end

local previousX,previousY = 0
local sendMapPosThisFrame = false

local function sendMapPosition()
	local x,y = GetMapCoords()
	--if x ~= previousX or y ~= previousY then
		--previousX,previousY = x,y
		send("mapPosition", {memory.readbyte(CurrentMapIdAddress), x, y})
	--end
end
--[[
spec.sync[MapXAddress] = {kind="trigger", writeTrigger=function(value, previousValue)
	if value == previousValue then return end
	if not AreCoordsValid() then return end
	sendMapPosThisFrame = true
end}
spec.sync[MapYAddress] = {kind="trigger", writeTrigger=function(value, previousValue)
	if value == previousValue then return end
	if not AreCoordsValid() then return end
	sendMapPosThisFrame = true
end}
--]]

spec.tick = function()
	-- TODO test this still works with DoS
	-- Only want to trigger update once per frame
	-- PoR is still a bit glitchy sometimes, especially when changing rooms
	local x,y = GetMapCoords()
	if x ~= previousX or y ~= previousY then
		previousX,previousY = x,y
		sendMapPosThisFrame = true
		return
	end
	if sendMapPosThisFrame then
		sendMapPosition()
		sendMapPosThisFrame = false
	end
end

end