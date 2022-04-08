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
	-- some duck typing on memory prefixes
	if tableHasValue(memoryDomains, "EWRAM") and tableHasValue(memoryDomains, "IWRAM") then
		-- gba
		memoryDomainsTable[2] = "EWRAM"
		memoryDomainsTable[3] = "IWRAM"
		memoryDomainsTable[6] = "VRAM"
		memoryDomainsTable[7] = "OAM"
		memoryDomainsTable[0xe] = "SRAM"
	elseif tableHasValue(memoryDomains, "Main RAM") and tableHasValue(memoryDomains, "ARM9 BIOS") then
		-- ds
		memoryDomainsTable[2] = "Main RAM"
	elseif tableHasValue(memoryDomains, "MainRAM") and tableHasValue(memoryDomains, "GPURAM") then
		-- psx
		memoryDomainsTable[0x80] = "MainRAM"
	end

	local function getMemoryDomainFromAddress(addr)
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
		memory.usememorydomain(domainToUse)
		-- If not passing in a domain, mask the address
		if not domain then
			addr = AND(addr, 0xffffff)
		end
		write_function(addr, val)
		-- Always default back to System Bus
		memory.usememorydomain("System Bus")
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
	local read_wrapper = function(addr, domain, read_function)
		local domainToUse = domain or "System Bus"
		memory.usememorydomain(domainToUse)
		local readValue = read_function(addr)
		-- Always default back to System Bus
		memory.usememorydomain("System Bus")
		return readValue
	end
	memory.readbyte = function(addr, domain)
		return read_wrapper(addr, domain, memory.read_u8)
	end
	memory.readword = function(addr, domain)
		return read_wrapper(addr, domain, memory.read_u16_le)
	end
	memory.readdword = function(addr, domain)
		return read_wrapper(addr, domain, memory.read_u32_le)
	end
	--memory.readword = memory.read_u16_le
	--memory.readdword = memory.read_u32_le

	-- Events
	gui.register = event.onframeend
	emu.registerexit = event.onexit
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