-- Set up compatibility with various emulators

-- BizHawk
if nds and snes and nes then
	BizHawk = true
	-- Bit ops
	SHIFT = function(val, amt)
		if not amt then amt = 0 end
		if amt < 0 then return bit.lshift(val, math.abs(amt))
		else return bit.rshift(val, amt) end
	end
	OR = bit.bor
	BNOT = bit.bnot
	AND = bit.band
	XOR = bit.bxor
	BIT = function(num) return SHIFT(1, -num) end

	stringToByteArray = function(s)
		local t = {}
		for i=1,#s do
			table.insert(t, s:byte(i))
		end
		return t
	end
	byteArrayToString = function(t)
		local s = ""
		for i=1,#t do
			s = s .. string.char(t[i])
		end
		return s
	end

	-- Memory
	-- memory.readbyte = function(addr)
		-- return mainmemory.readbyte(AND(addr, 0xffffff))
	-- end
	memory.writebyte = function(addr, val)
		mainmemory.writebyte(AND(addr, 0xffffff), val)
	end
	-- memory.readword = function(addr)
		-- return mainmemory.read_u16_le(AND(addr, 0xffffff))
	-- end
	memory.writeword = function(addr, val)
		mainmemory.write_u16_le(AND(addr, 0xffffff), val)
	end
	memory.readdword = function(addr)
		return mainmemory.read_u32_le(AND(addr, 0xffffff))
	end
	memory.writedword = function(addr, val)
		mainmemory.write_u32_le(AND(addr, 0xffffff), val)
	end
	memory.readword = memory.read_u16_le
	-- memory.writeword = memory.write_u16_le
	-- memory.readdword = memory.read_u32_le
	-- memory.writedword = memory.write_u32_le

	-- Events
	gui.register = event.onframeend
	-- emu.registerexit = event.onexit
	emu.registerexit = function(fun) end
	-- event.onexit is called when the script ends, not the emulator/game
	-- So I could approach things differently, such that there's a while loop with frameadvance,
	-- instead of frame-by-frame callbacks.
	-- Or I could run with what I have and figure out a different way to end
	memory.registerwrite = function(addr, size, callback)
		event.onmemorywrite(callback, addr)
		--for i=1,size do
			--print("registering write at " .. (addr + i - 1))
			--event.onmemorywrite(callback, addr + i - 1)
		--end
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

-- Whichever implementation determined by emulator
require "basesocket"