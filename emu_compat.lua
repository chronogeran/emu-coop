-- Set up compatibility with various emulators

-- BizHawk
if nds and snes and nes then
	-- Bit ops
	SHIFT = function(val, amt)
		if amt < 0 then return bit.lshift(val, math.abs(amt))
		else return bit.rshift(val, amt) end
	end
	OR = bit.bor
	BNOT = bit.bnot
	AND = bit.band
	XOR = bit.bxor
	BIT = function(num) return SHIFT(1, -num) end

	-- Memory
	memory.readword = memory.read_u16_le
	memory.writeword = memory.write_u16_le
	memory.readdword = memory.read_u32_le
	memory.writedword = memory.write_u32_le

	-- Events
	gui.register = event.onframeend
	emu.registerexit = event.onexit
	memory.registerwrite = function(addr, size, callback)
		for i=1,size do
			print("registering write at " .. (addr + i - 1))
			event.onmemorywrite(callback, addr + i - 1)
		end
	end

	-- Emu
	emu.emulating = function() return gameinfo.getromhash() ~= nil end
end

-- FCEUX
if FCEU then
	memory.writeword = function(addr, value)
		memory.writebyte(addr, AND(value, 0xff))
		memory.writebyte(addr + 1, AND(SHIFT(value, 8), 0xff))
	end
end

if not BNOT then
	local bit = require("bit") -- for binary not
	BNOT = bit.bnot
end