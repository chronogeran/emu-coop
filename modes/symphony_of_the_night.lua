-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "48455393-c02a-4ad0-b3ab-aca847e7128f",
	format = "1.2",
	name = "Castlevania: Symphony of the Night",
	pipe = "tcp",
	match = {"stringtest", addr=0x8000b8b0, value="cdrom:SLUS_000.67"},
	running = function(value, size)
		return
			memory.readdword(0x80097c30) ~= 0 or
			memory.readdword(0x80097c34) ~= 0 or
			memory.readdword(0x80097c38) ~= 0 or
			memory.readdword(0x80097c3c) ~= 0
	end, -- Using game clock as running test
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

-- Events
-- TODO alignment, range
for i=0,0xff,4 do
	spec.sync[0x8003be20 + i] = {size=4, kind="bitOr"}
end

local function pixelDataOffset(pixelX, pixelY)
	return 0x89e80 + (pixelY * 0x800) + math.floor(pixelX / 2)
end

spec.custom["mapData"] = function(payload)
	local pixelX, pixelY = payload[1], payload[2]
	local i = 3
	for y=pixelY, pixelY + 4 do
		for x=pixelX, pixelX + 4, 2 do
			-- TODO perhaps only write the first nibble on the third x byte
			local offset = pixelDataOffset(x, y)
			memory.writebyte(offset, payload[i], "GPURAM")
			i = i + 1
		end
	end
end

-- Rooms count
-- Delta could be bad if both people explore the same room at the same time
spec.sync[0x8003c760] = {size=4, kind="delta"}

-- Map exploration
-- Strategy here: calculate graphics offset from exploration change, then send graphics data
-- TODO figure out inverted castle
for i=0,0x32f do
	spec.sync[0x8006bbc4 + i] = {kind="bitOr", 
	writeTrigger=function(value, previousValue, forceSend)
		if value == previousValue then return end
		local changedBits = XOR(value, previousValue)
		local changedBitNumber = 0
		local b = changedBits
		while AND(b, 1) ~= 1 and changedBitNumber < 8 do
			b = SHIFT(b, 1)
			changedBitNumber = changedBitNumber + 1
		end
		local smallX = 0
		if changedBitNumber == 6 then smallX = 0
		elseif changedBitNumber == 4 then smallX = 1
		elseif changedBitNumber == 2 then smallX = 2
		elseif changedBitNumber == 0 then smallX = 3
		else return end
		local mapX = (i % 0x10) * 4 + smallX
		local mapY = math.floor(i / 0x10)
		local pixelX = mapX * 4
		local pixelY = mapY * 4 + 1
		table.insert(spec.nextFrameTasks, function()
			local payload = {pixelX, pixelY}
			local i = 3
			for y=pixelY, pixelY + 4 do
				for x=pixelX, pixelX + 4, 2 do
					local offset = pixelDataOffset(x, y)
					payload[i] = memory.readbyte(offset, "GPURAM")
					i = i + 1
				end
			end
			send("mapData", payload)
		end)
	end}
end

-- Relics
-- TODO alignment
for i=0,0x1d do
	-- TODO equip when receiving, but not familiars?
	spec.sync[0x80097964 + i] = {size=1, mask=0x01, kind="bitOr"}
end

-- Spells
-- TODO alignment
for i=0,7,4 do
	spec.sync[0x80097982 + i] = {size=4}
end

-- Inventory
-- TODO alignment
for i=0,0xff,4 do
	spec.sync[0x8009798c + i] = {size=4, kind="delta"}
end

-- HP
--spec.sync[0x80097ba0] = {size=4, kind="delta", deltaMin=0}
-- Max HP
--spec.sync[0x80097ba4] = {size=4, kind="delta", deltaMin=0}
-- Hearts
--spec.sync[0x80097ba8] = {size=4, kind="delta", deltaMin=0}
-- Max Hearts
--spec.sync[0x80097bac] = {size=4, kind="delta", deltaMin=0}
-- MP
--spec.sync[0x80097bb0] = {size=4, kind="delta", deltaMin=0}
-- Max MP
--spec.sync[0x80097bb4] = {size=4, kind="delta", deltaMin=0}

-- EXP
spec.sync[0x80097bec] = {size=4, kind="delta", deltaMin=0}
-- Gold
spec.sync[0x80097bf0] = {size=4, kind="delta", deltaMin=0}
-- Kills
spec.sync[0x80097bf4] = {size=4, kind="delta", deltaMin=0}

-- Familiar Levels
spec.sync[0x80097c44] = {size=4, kind="delta"}
spec.sync[0x80097c48] = {size=4, kind="delta"}
spec.sync[0x80097c50] = {size=4, kind="delta"}
spec.sync[0x80097c54] = {size=4, kind="delta"}
spec.sync[0x80097c5c] = {size=4, kind="delta"}
spec.sync[0x80097c60] = {size=4, kind="delta"}
spec.sync[0x80097c68] = {size=4, kind="delta"}
spec.sync[0x80097c6c] = {size=4, kind="delta"}
spec.sync[0x80097c74] = {size=4, kind="delta"}
spec.sync[0x80097c78] = {size=4, kind="delta"}
spec.sync[0x80097c80] = {size=4, kind="delta"}
spec.sync[0x80097c84] = {size=4, kind="delta"}
spec.sync[0x80097c8c] = {size=4, kind="delta"}
spec.sync[0x80097c90] = {size=4, kind="delta"}

return spec