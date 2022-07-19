-- ACTUAL WORK HAPPENS HERE

local cache = {}
local cacheSize = {}

function memoryRead(addr, size)
	if not size or size == 1 then
		return memory.readbyte(addr)
	elseif size == 2 then
		return memory.readword(addr)
	elseif size == 4 then
		return memory.readdword(addr)
	else
		error("Invalid size to memoryRead")
	end
end

function memoryWrite(addr, value, size)
	if cache[addr] then
		cache[addr] = value
		if not cacheSize[addr] then
			cacheSize[addr] = size
		elseif (size or 1) ~= (cacheSize[addr] or 1) then
			error(string.format("Size argument to memoryWrite [%s] doesn't match previous size [%s] for address %x", size, cacheSize[addr], addr))
		end
	end
	if not size or size == 1 then
		memory.writebyte(addr, value)
	elseif size == 2 then
		memory.writeword(addr, value)
	elseif size == 4 then
		memory.writedword(addr, value)
	else
		error("Invalid size to memoryWrite")
	end
end

function recordChanged(record, value, previousValue, receiving)
	if record.kind == "trigger" then
		return false -- Don't mess with masking or conds
	end

	local unalteredValue = value -- "value" might change below; here's its initial value
	local allow = true

	-- Unwrap the value
	if receiving and record.kind == "flags" then value = value[1] end

	-- Value 
	local maskedValue = value
	local mask = 0xff
	if record.size == 2 then mask = 0xffff
	elseif record.size == 4 then mask = 0xffffffff
	end
	local inverseMask = 0

	if record.mask then
		-- If it's masked, rework value so that all non-masked bits in value are replaced
		-- with the corresponding bits from previousValue. This will affect both whether
		-- a change is recognized and what (when receiving is true) is written to memory
		mask = record.mask
		inverseMask = BNOT(record.mask)
		maskedValue = OR(AND(mask, value), AND(inverseMask, previousValue))
	end

	if type(record.kind) == "function" then -- Note: function ignores masks
		allow, value = record.kind(value, previousValue, receiving)
		if not value then value = unalteredValue end -- support nil value
	elseif record.kind == "high" then
		allow = AND(maskedValue, value) > AND(maskedValue, previousValue)
		value = maskedValue
	elseif record.kind == "bitOr" then
		allow = maskedValue ~= previousValue               -- Did operated-on bits change?
		if receiving then
			value = OR(maskedValue, previousValue)
		end
	elseif record.kind == "flags" then
		if receiving then
			-- value is value from the message, previousValue is current value locally
			local changedBits = unalteredValue[2]
			-- Set any bits that should be set
			value = OR(previousValue, AND(changedBits, maskedValue))
			-- Clear any bits that should be cleared
			value = AND(value, BNOT(AND(changedBits, BNOT(maskedValue))))
			-- Only accept if changed
			allow = value ~= previousValue
		else
			-- Sending out. maskedValue is current value locally, previousValue is value from the memory cache
			allow = maskedValue ~= previousValue -- Did operated-on bits change?
			local changedBits = XOR(maskedValue, previousValue)
			-- stuff both into a single value for the message
			value = { maskedValue, changedBits }
		end
	elseif record.kind == "delta" then
		if not receiving then
			allow = maskedValue ~= previousValue
			value = AND(mask, value) - AND(mask, previousValue)
		else
			allow = value ~= 0
			-- Notice: This assumes the emulator AND implementation converts negative values to 2s compliment elegantly
			local maskedSum = previousValue + value
			if record.deltaMin and maskedSum < record.deltaMin then maskedSum = record.deltaMin end
			if record.deltaMax and maskedSum > record.deltaMax then maskedSum = record.deltaMax end
			value = OR( AND(inverseMask, previousValue), AND(mask, maskedSum) )
			maskedValue = maskedSum
		end
	else
		allow = maskedValue ~= previousValue
		value = maskedValue
	end
	if allow and record.cond then
		allow = performTest(record.cond, maskedValue, record.size) -- Note: Value tested is masked, but not ORed
	end
	return allow, value
end

function performTest(record, valueOverride, sizeOverride)
	if not record then return true end

	if type(record) == "function" then
		return record(valueOverride, sizeOverride)
	elseif record[1] == "test" then
		if record.addr + (sizeOverride or record.size or 1) >= memory.getbussize() then return false end
		local value = valueOverride or memoryRead(record.addr, sizeOverride or record.size)
		return (not record.gte or value >= record.gte) and
			   (not record.lte or value <= record.lte)
	elseif record[1] == "stringtest" then
		local test = record.value
		local len = #test
		local addr = record.addr
		if addr + len >= memory.getbussize() then return false end

		for i=1,len do
			if string.byte(test, i) ~= memory.readbyte(addr + i - 1) then
				return false
			end
		end
		return true
	end
	
	return false
end

class.GameDriver(Driver)
function GameDriver:_init(spec, forceSend)
	self.spec = spec
	self.sleepQueue = {}
	self.nextFrameTasks = {}
	self.tasks = {}
	self.forceSend = forceSend
	self.didCache = false
end

function GameDriver:checkFirstRunning() -- Do first-frame bootup-- only call if isRunning()
	if not self.didCache then
		if driverDebug then print("First moment running") end
		message("Coop mode: " .. self.spec.guid)

		-- Initialize cache
		for k,v in pairs(self.spec.sync) do
			local value = memoryRead(k, v.size)
			if not cache[k] then cache[k] = value end

			if self.forceSend then -- Restoring after a crash send all values regardless of importance
				if value ~= 0 then -- FIXME: This is adequate for all current specs but maybe it will not be in future?!
					if driverDebug then print("Sending address " .. tostring(k) .. " at startup") end

					self:sendTable {addr=k, value=value}
				end
			end
		end

		if self.spec.startup then
			self.spec.startup(self.forceSend)
		end

		self.didCache = true
	end
end

function GameDriver:executeNextFrame(f)
	table.insert(self.nextFrameTasks, f)
end

function GameDriver:executeAfterFrames(f, n)
	table.insert(self.tasks, {f=f, n=n})
end

function GameDriver:childTick()
	-- Execute queued tasks
	for k,v in pairs(self.nextFrameTasks) do v() end
	self.nextFrameTasks = {}
	for i=#self.tasks,1,-1 do
		local task = self.tasks[i]
		task.n = task.n - 1
		if task.n == 0 then
			task.f()
			table.remove(self.tasks, i)
		end
	end

	if self:isRunning() then
		self:checkFirstRunning()

		if #self.sleepQueue > 0 then
			local sleepQueue = self.sleepQueue
			self.sleepQueue = {}
			for i, v in ipairs(sleepQueue) do
				self:handleTable(v)
			end
		end
		if self.spec.tick then
			self.spec.tick()
		end
	end
end

function GameDriver:childWake()
	self:sendTable {"hello", version=version.release, guid=self.spec.guid, nickname=self.pipe.data.nickname}

	if driverDebug then print("Registering callbacks") end
	-- Register memory callbacks
	self.registeredAddresses = {}
	-- BizHawk memory callback arguments are addr, value, flags
	-- not all cores return all args though.
	-- FCEUX callback arguments are addr, size, value
	-- snes9x callback arguments are addr, and probably flags
	-- In mgba we can't count on any captured variables since there's only one callback
	-- so we'll rely on just the address returned.
	--[[ Cores generally/only call callbacks on the base address of the write operation, meaning
		if it's a 4-byte write, the callback is called for the first of the 4. 
		In order to make the life of the modder easier, so they don't have to worry about and test
		the alignment of writes to each address, as well as to handle situations in which the game
		might use different alignments for the same address, we use this strategy where we call
		caughtWrite for all addresses that may be associated with the triggered address.
		This means caughtWrite must tolerate extra calls and ignore if nothing has changed.
	--]]
	local function theMemoryCallback(callbackAddr, value, flags)
		-- Check all addresses this callback may be associated with, both backward and forward.
		for i=-registerSize+1,registerSize-1 do
			local unalignedAddress = callbackAddr + i
			local record = mainDriver.spec.sync[unalignedAddress]
			if record then
				local recordSize = record.size or 1
				-- Only trigger records behind if their size is large enough to intersect
				if unalignedAddress + recordSize > callbackAddr then
					mainDriver:caughtWrite(unalignedAddress, 0, record, recordSize)
				end
			end
		end
	end

	-- All provided addresses
	for k,v in pairs(self.spec.sync) do
		-- Assuming the writes may be aligned with any offset, we'll have to register for both aligned and unaligned
		-- This loops through 4,2, and 1-byte aligned, depending on the register size of the current console
		local s = registerSize
		local size = v.size or 1
		while s >= 1 do
			local alignedAddress = k - (k % s)
			-- only register one callback per address
			if not self.registeredAddresses[alignedAddress] then
				-- size arg is used in FCEUX & snes9x
				memory.registerwrite(alignedAddress, size, theMemoryCallback)
				self.registeredAddresses[alignedAddress] = true
			end
			s = math.floor(s / 2)
		end

		-- Also register ahead in case a size was requested that's bigger than the actual writes
		-- Modes should not have any overlap in their registration. It's possible we get bad behavior if
		-- we pass a size 1 here but that conflicts with a different sync table.
		for s = 1,size-1 do
			local inflatedAddress = k + s
			if not self.registeredAddresses[inflatedAddress] then
				-- size arg is used in FCEUX & snes9x
				memory.registerwrite(inflatedAddress, 1, theMemoryCallback)
				self.registeredAddresses[inflatedAddress] = true
			end
		end
	end
end

function GameDriver:isRunning()
	return performTest(self.spec.running)
end

function GameDriver:caughtWrite(addr, arg2, record, size)
	local running = self.spec.running

	if self:isRunning() then -- TODO: Yes, we got record, but double check
		self:checkFirstRunning()

		local allow = true
		local value = memoryRead(addr, size)
		local sendValue = value

		if record.writeTrigger then
			record.writeTrigger(value, cache[addr], false)
		end

		if cache[addr] then -- It should be impossible for this to be false
			allow, sendValue = recordChanged(record, value, cache[addr], false)
		end

		if allow then
			-- Notice this is NOT set unless allow is true. Why? Imagine kind is "high" and
			-- value gets set to 3, then 255, then 4, and "cond" requires value to be < 6.
			-- If we wrote record.cache on allow false, it would get "stuck" at 255 and 4 would never send
			-- FIXME: Should this cache EVER be cleared? What about when a new game starts?
			cache[addr] = value

			self:sendTable {addr=addr, value=sendValue}
		end
		-- Also update cache for trigger types
		if record.kind == "trigger" then cache[addr] = value end
	else
		if driverDebug then print("Ignored memory write because the game is not running") end
	end
end

function GameDriver:handleTable(t)
	if t[1] then
		if t[1] == "hello" then
			if t.guid ~= self.spec.guid then
				self.pipe:abort("Partner has an incompatible .lua file for this game.")
				print("Partner's game mode file has guid:\n" .. tostring(t.guid) .. "\nbut yours has:\n" .. tostring(self.spec.guid))
			else
				self.pipe:confirm()
			end
		elseif t[1] == "custom" then
			if t[2] then
				local f = self.spec.custom and self.spec.custom[t[2]]
				if f then
					f(t[3], t[4])
				else
					print("Unrecognized custom message from partner: " .. t[2])
				end
			end
		end
		return
	end

	local addr = t.addr
	local record = self.spec.sync[addr]
	if self:isRunning() then
		self:checkFirstRunning()

		if record then
			local value = t.value
			local allow = true
			local previousValue = memoryRead(addr, record.size)

			allow, value = recordChanged(record, value, previousValue, true)

			-- Extra setup/cleanup on receive
			if record.receiveTrigger and (allow or record.kind == "trigger") then
				record.receiveTrigger(value, previousValue)
			end

			if allow then
				local name = record.name
				local names = nil

				if not name and record.nameMap then
					name = record.nameMap[value]
				end

				if name then
					names = {name}
				elseif record.nameBitmap then
					names = {}
					local maxBit = (8 * (record.size or 1)) - 1
					for b=0,maxBit do
						if 0 ~= AND(BIT(b), value) and 0 == AND(BIT(b), previousValue) then
							table.insert(names, record.nameBitmap[b + 1])
						end
					end
				end

				if names then
					local verb = record.verb or "got"
					for i, v in ipairs(names) do
						message(self.pipe:getPartnerName(t.clientId) .. " " .. verb .. " " .. v)
					end
				else
					if driverDebug then print("Updated anonymous address " .. tostring(addr) .. " to " .. tostring(value)) end
				end
				record.cache = value
				memoryWrite(addr, value, record.size)
			end
		else
			if driverDebug then print("Unknown memory address was " .. tostring(addr)) end
			message("Partner changed unknown memory address...? Uh oh")
		end
	else
		if driverDebug then print("Queueing partner memory write because the game is not running") end
		table.insert(self.sleepQueue, t)
	end
end

function GameDriver:handleError(s, err)
	print("FAILED TABLE LOAD " .. err)
end

function send(name, payload) -- Global for mode files
	if not name then
		error("Missing message name on send() call")
	end
	mainDriver:sendTable {"custom", name, payload}
end
