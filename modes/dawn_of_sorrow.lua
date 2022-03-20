-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "8b59da11-ab34-4e72-8e86-845cfe03e34f",
	format = "1.2",
	name = "Castlevania: Dawn of Sorrow",
	pipe = "tcp",
	match = function(valueOverride, sizeOverride)
		return (memory.readbyte(0xfffa) == 0xb6
			and memory.readbyte(0xfffb) == 0xf3
			and memory.readbyte(0xfffc) == 0xa4
			and memory.readbyte(0xfffd) == 0xf2
			and memory.readbyte(0xfffe) == 0x43
			and memory.readbyte(0xffff) == 0xf4)
	end,
	running = {"test", addr = 0x6c, lte = 0xfe},
	sync = {},
	custom = {},
}

-- Assumes a 1-byte value
local deltaWithVariableMax = function(address, deltaMaxAddress, deltaMin)
	spec.sync[address] = {kind=function(value, previousValue, receiving)
		-- A modification of the existing delta kind to read max from memory
		if not receiving then
			allow = value ~= previousValue
			value = value - previousValue
		else
			allow = value ~= 0
			-- Notice: This assumes the emulator AND implementation converts negative values to 2s compliment elegantly
			local sum = previousValue + value
			if deltaMin and sum < deltaMin then sum = deltaMin end
			local deltaMax = memory.readbyte(deltaMaxAddress)
			if sum > deltaMax then sum = deltaMax end
			value = sum
		end
		return allow, value
	end}
end

-- HP
spec.sync[0x020f7410] = {size=2}

return spec
