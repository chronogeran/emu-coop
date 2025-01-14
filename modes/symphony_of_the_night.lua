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

-- Events
for i=0,0x128 do
	spec.sync[0x8003be20 + i] = {kind="bitOr", receiveTrigger=function(value, previousValue)
		if i ~= 1 then return end
		if AND(XOR(value, previousValue), 0x01) == 0 then return end
		-- Encounter with Death. Remove equipment if applicable.
		-- Just zero out all locations since there may be many players with the items in different places
		local rightHand = memory.readbyte(0x80097c00)
		if rightHand == 0x10 or rightHand == 0x7b then memory.writebyte(0x80097c00, 0) end
		local leftHand = memory.readbyte(0x80097c04)
		if leftHand == 0x10 or leftHand == 0x7b then memory.writebyte(0x80097c04, 0) end
		if memory.readbyte(0x80097c08) == 0x2d then memory.writebyte(0x80097c08, 0x1a) end
		if memory.readbyte(0x80097c0c) == 0x0f then memory.writebyte(0x80097c0c, 0) end
		if memory.readbyte(0x80097c10) == 0x38 then memory.writebyte(0x80097c10, 0x30) end
		if memory.readbyte(0x80097c14) == 0x4e then memory.writebyte(0x80097c14, 0x39) end
		if memory.readbyte(0x80097c18) == 0x4e then memory.writebyte(0x80097c18, 0x39) end
		memory.writebyte(0x8009799a, 0) -- Alucard Shield
		memory.writebyte(0x80097a05, 0) -- Alucard Sword
		memory.writebyte(0x80097a42, 0) -- Alucard Mail
		memory.writebyte(0x80097a60, 0) -- Dragon Helm
		memory.writebyte(0x80097a6b, 0) -- Twilight Cloak
		memory.writebyte(0x80097a81, 0) -- Necklace of J
		-- TODO recalculate stats and such?
	end}
end

-- Time Attack
for i=0,0x73,4 do
	spec.sync[0x8003ca28 + i] = {size=4}
end

local function pixelDataOffset(pixelX, pixelY, isNormalCastle)
	local offset = (pixelY * 0x800) + math.floor(pixelX / 2)
	if isNormalCastle then return 0x89e80 + offset
	else return 0xee6ff - offset end
end

spec.custom["mapData"] = function(payload)
	local isNormalCastle, pixelX, pixelY = payload[1] == 1, payload[2], payload[3]
	if isNormalCastle ~= isInNormalCastle() then return end
	local i = 4
	for y=pixelY, pixelY + 4 do
		for x=pixelX, pixelX + 4, 2 do
			local offset = pixelDataOffset(x, y, isNormalCastle)
			memory.writebyte(offset, payload[i], "GPURAM")
			i = i + 1
		end
	end
end

function isInNormalCastle()
	local zoneAddress = memory.readdword(0x800987d8)
	return (zoneAddress == 0x0028c0 or
		zoneAddress == 0x009420 or
		zoneAddress == 0x00de90 or
		zoneAddress == 0x00df10 or
		zoneAddress == 0x0151c0 or
		zoneAddress == 0x016250 or
		zoneAddress == 0x016960 or
		zoneAddress == 0x018d10 or
		zoneAddress == 0x019ad0 or
		zoneAddress == 0x019ca0 or
		zoneAddress == 0x019d00 or
		zoneAddress == 0x019fd0 or
		zoneAddress == 0x01a060 or
		zoneAddress == 0x01a3a0)
end

-- Map exploration
-- Strategy here: calculate graphics offset from exploration change, then send graphics data
for i=0,0x76f do
	spec.sync[0x8006bbc4 + i] = {kind="bitOr", 
	receiveTrigger=function(value, previousValue)
		if value == previousValue then return end
		-- New exploration data: increment room count
		memory.writedword(0x8003c760, memory.readdword(0x8003c760) + 1)
	end,
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
		local isNormalCastle = i < 0x330
		local exOffset = i
		if not isNormalCastle then exOffset = i - 0x440 end
		local mapX = (exOffset % 0x10) * 4 + smallX
		local mapY = math.floor(exOffset / 0x10)
		local pixelX = mapX * 4
		local pixelY = mapY * 4 + 1
		if not isNormalCastle then
			pixelX = pixelX - 1
			pixelY = pixelY - 1
		end
		mainDriver:executeNextFrame(function()
			local payload = {1, pixelX, pixelY}
			if not isNormalCastle then payload[1] = 0 end
			local i = 4
			for y=pixelY, pixelY + 4 do
				for x=pixelX, pixelX + 4, 2 do
					local offset = pixelDataOffset(x, y, isNormalCastle)
					payload[i] = memory.readbyte(offset, "GPURAM")
					i = i + 1
				end
			end
			send("mapData", payload)
		end)
	end}
end

-- Relics
for i=0,0x1d do
	spec.sync[0x80097964 + i] = {size=1, mask=0x01, kind="bitOr", receiveTrigger=function(value, previousValue)
		-- equip when receiving, but not familiars
		if value == 1 and previousValue == 0 and (i <= 0x11 or i >= 0x19) then
			memory.writebyte(0x80097964 + i, 0x3)
		end
	end}
end

-- Spells
for i=0,7,4 do
	spec.sync[0x80097982 + i] = {size=4}
end

-- Inventory
for i=0,0x101 do
	spec.sync[0x8009798b + i] = {kind="delta"}
end

-- Sync max HP and hearts for max ups
-- HP
--spec.sync[0x80097ba0] = {size=4, kind="delta", deltaMin=0}
-- Max HP
spec.sync[0x80097ba4] = {size=4, kind="delta", deltaMin=0}
-- Hearts
--spec.sync[0x80097ba8] = {size=4, kind="delta", deltaMin=0}
-- Max Hearts
spec.sync[0x80097bac] = {size=4, kind="delta", deltaMin=0}
-- MP
--spec.sync[0x80097bb0] = {size=4, kind="delta", deltaMin=0}
-- Max MP
--spec.sync[0x80097bb4] = {size=4, kind="delta", deltaMin=0}

-- EXP
spec.sync[0x80097bec] = {size=4, kind="delta", deltaMin=0, deltaMax=9999999}
-- Gold
spec.sync[0x80097bf0] = {size=4, kind="delta", deltaMin=0, deltaMax=999999}
-- Kills
spec.sync[0x80097bf4] = {size=4, kind="delta", deltaMin=0, deltaMax=999999}

-- Familiar Levels & XP
spec.sync[0x80097c44] = {size=4}
spec.sync[0x80097c48] = {size=4, kind="delta", deltaMin=0, deltaMax=9899}
spec.sync[0x80097c50] = {size=4}
spec.sync[0x80097c54] = {size=4, kind="delta", deltaMin=0, deltaMax=9899}
spec.sync[0x80097c5c] = {size=4}
spec.sync[0x80097c60] = {size=4, kind="delta", deltaMin=0, deltaMax=9899}
spec.sync[0x80097c68] = {size=4}
spec.sync[0x80097c6c] = {size=4, kind="delta", deltaMin=0, deltaMax=9899}
spec.sync[0x80097c74] = {size=4}
spec.sync[0x80097c78] = {size=4, kind="delta", deltaMin=0, deltaMax=9899}
spec.sync[0x80097c80] = {size=4}
spec.sync[0x80097c84] = {size=4, kind="delta", deltaMin=0, deltaMax=9899}
spec.sync[0x80097c8c] = {size=4}
spec.sync[0x80097c90] = {size=4, kind="delta", deltaMin=0, deltaMax=9899}

return spec