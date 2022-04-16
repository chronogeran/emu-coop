-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "f045e72d-be3f-4259-a7f4-ec54fea70cee",
	format = "1.2",
	name = "Solstice",
	match = function(valueOverride, sizeOverride)
		return (memory.readbyte(0xfffa) == 0xfd
			and memory.readbyte(0xfffb) == 0x07
			and memory.readbyte(0xfffc) == 0x00
			and memory.readbyte(0xfffd) == 0xfe
			and memory.readbyte(0xfffe) == 0x26
			and memory.readbyte(0xffff) == 0xfe)
	end,
	--running = {"test", addr = 0x6c, lte = 0xfe}, TODO
	sync = {},
	custom = {},
}

-- TODO detonators (might be part of progress data)
-- TODO credits

-- Green Potion
spec.sync[0x784] = {}
-- Yellow Potion
spec.sync[0x785] = {}
-- Purple Potion
spec.sync[0x786] = {}
-- Blue Potion
spec.sync[0x787] = {}
-- Lives
spec.sync[0x789] = {kind="delta"}
-- Jump height (boots)
spec.sync[0x791] = {}
-- Staff pieces (6 bits)
spec.sync[0x795] = {kind="bitOr"}
-- Keys (4 bits)
spec.sync[0x796] = {kind="bitOr"}

-- TODO FCEUX support
spec.custom["progress"] = function(payload)
	memory.write_bytes_as_array(0x1fc8, payload, "PPU Bus")
end

-- Can't have a callback on the PPU, so we'll read it every frame
-- Pickups (ppu 0x1fc8-1fcf) and Map (ppu 0x1fd0-1fef)
local previousProgressData = nil
spec.tick = function()
	local currentProgressData = memory.read_bytes_as_array(0x1fc8, 40, "PPU Bus")
	if previousProgressData then
		for i = 1,40 do
			if previousProgressData[i] ~= currentProgressData[i] then
				send("progress", currentProgressData)
				break
			end
		end
	end
	previousProgressData = currentProgressData
end

return spec
