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
	local memoryDomains = memory.getmemorydomainlist()
	local function tableHasValue(t, v)
		for _,i in pairs(t) do
			if i == v then
				return true
			end
		end
		return false
	end
	
	local memoryDomainsTable = {}
	local console = nil
	registerSize = 1
	-- some duck typing on memory prefixes
	if tableHasValue(memoryDomains, "EWRAM") and tableHasValue(memoryDomains, "IWRAM") then
		console = "gba"
		registerSize = 4
		memoryDomainsTable[2] = "EWRAM"
		memoryDomainsTable[3] = "IWRAM"
		memoryDomainsTable[6] = "VRAM"
		memoryDomainsTable[7] = "OAM"
		memoryDomainsTable[0xe] = "SRAM"
	elseif tableHasValue(memoryDomains, "Main RAM") and tableHasValue(memoryDomains, "ARM9 BIOS") then
		console = "ds"
		registerSize = 4
		memoryDomainsTable[2] = "Main RAM"
	elseif tableHasValue(memoryDomains, "MainRAM") and tableHasValue(memoryDomains, "GPURAM") then
		console = "psx"
		registerSize = 4
		memoryDomainsTable[0x80] = "MainRAM"
	elseif tableHasValue(memoryDomains, "RAM") and tableHasValue(memoryDomains, "PPU Bus") then
		console = "nes"
		registerSize = 1
		-- system bus is writable
	end

	local function getMemoryDomainFromAddress(addr)
		if console == "nes" then return "System Bus" end
		local prefix = SHIFT(AND(addr, 0xff000000), 24)
		local domain = memoryDomainsTable[prefix]
		return domain
	end

	-- Writes must use specific domain
	local write_wrapper = function(addr, val, domain, write_function)
		local domainToUse = domain or getMemoryDomainFromAddress(addr)
		if not domainToUse then
			print("ERROR: nil memory domain")
			return
		end
		-- If not passing in a domain, mask the address
		if not domain then
			addr = AND(addr, 0xffffff)
		end
		write_function(addr, val, domainToUse)
	end
	memory.writebyte = function(addr, val, domain)
		write_wrapper(addr, val, domain, memory.write_u8)
	end
	memory.writeword = function(addr, val)
		write_wrapper(addr, val, domain, memory.write_u16_le)
	end
	memory.writedword = function(addr, val)
		write_wrapper(addr, val, domain, memory.write_u32_le)
	end

	-- Reads can use the prefixed address (system bus), but GPURAM isn't mapped to System Bus (I think?)
	memory.readbyte = memory.read_u8
	memory.readword = memory.read_u16_le
	memory.readdword = memory.read_u32_le

	-- Events
	gui.register = event.onframeend
	emu.registerexit = event.onexit
	memory.registerwrite = function(addr, size, callback)
		event.onmemorywrite(callback, addr)
	end

	-- Emu
	emu.emulating = function() return gameinfo.getromhash() ~= nil end
end

-- FCEUX
if FCEU then
	registerSize = 1
	memory.writeword = function(addr, value)
		memory.writebyte(addr, AND(value, 0xff))
		memory.writebyte(addr + 1, AND(SHIFT(value, 8), 0xff))
	end
end

-- Snes9x
if not FCEU and not BizHawk then
	registerSize = 2
end

if not BNOT then
	local bit = require("bit") -- for binary not
	BNOT = bit.bnot
end

-- Whichever implementation determined by emulator
require "basesocket"