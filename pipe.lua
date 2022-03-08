-- NETWORKING

-- A Pipe class is responsible for, somehow or other, connecting to the internet and funnelling data between driver objects on different machines.

class.Pipe()
function Pipe:_init()
	self.buffer = ""
end

function Pipe:wake(server)
	if pipeDebug then print("Connected") end
	--statusMessage("Logging in to server...") -- This creates an unfortunate implicit contract where the driver needs to statusMessage(nil)
	self.server = server
	self.server:settimeout(0)

	emu.registerexit(function()
		self:exit()
	end)

	self:childWake()

	gui.register(function()
		if not self.dead then self:tick() end
		printMessage()
	end)
end

function Pipe:exit()
	if pipeDebug then print("Disconnecting") end
	self.dead = true
	self.server:close()
	self:childExit()
end

function Pipe:fail(err)
	self:exit()
end

function Pipe:send(s)
	if pipeDebug then print("SEND: " .. s) end

	local res, err = self.server:send(s .. "\r\n")
	if not res then
		errorMessage("Connection died: " .. s)
		self:exit()
		return false
	end
	return true
end

function Pipe:receivePump()
	while not self.dead do -- Loop until no data left
		local result, err = self.server:receive(1) -- Pull one byte
		if not result then
			if err ~= "timeout" then
				errorMessage("Connection died: " .. err)
				self:exit()
			end
			return
		end

		-- Got useful data
		self.buffer = self.buffer .. result
		if result == "\n" then -- Only 
			self:handle(self.buffer)
			self.buffer = ""
		end
	end
end

function Pipe:tick()
	self:receivePump()
	self:childTick()
end

function Pipe:childWake() end
function Pipe:childExit() end
function Pipe:childTick() end
function Pipe:handle() end

-- IRC

-- TODO: nickserv, reconnect logic, multiline messages

local IrcState = {login = 1, searching = 2, handshake = 3, piping = 4, aborted=5}
local IrcHello = "!! Hi, I'm a matchmaking bot for SNES games. This user thinks you're running the same bot and typed in your nick. If you're a human and seeing this, they made a mistake!"
local IrcConfirm = "@@ " .. version.ircPipe

class.IrcPipe(Pipe)
function IrcPipe:_init(data, driver)
	self:super()
	self.data = data
	self.driver = driver
	self.state = IrcState.login
	self.sentVersion = false
end

function IrcPipe:childWake()
	self:send("NICK " .. self.data.nick)
	self:send("USER " .. self.data.nick .."-bot 8 * : " .. self.data.nick .. " (snes bot)")
end

function IrcPipe:childTick()
	if self.state == IrcState.piping then
		self.driver:tick()
	end
end

function IrcPipe:abort(msg)
	self.state = IrcState.aborted -- FIXME: I guess this is maybe redundant with .dead?
	self:exit()
	errorMessage(msg)
end

function IrcPipe:handle(s)
	if pipeDebug then print("RECV: " .. s) end

	splits = stringx.split(s, nil, 2)
	local cmd, args = splits[1], splits[2]

	if cmd == "PING" then -- On "PING :msg" respond with "PONG :msg"
		if pipeDebug then print("Handling ping") end

		self:send("PONG " .. args)

	elseif cmd:sub(1,1) == ":" then -- A message from a server or user
		local source = cmd:sub(2)
		if self.state == IrcState.login then
			if source == self.data.nick then -- This is the initial mode set from the server, we are logged in
				if pipeDebug then print("Logged in to server") end

				self.state = IrcState.searching
				self:whoisCheck()
			end
		else
			local partnerlen = #self.data.partner

			if source:sub(1,partnerlen) == self.data.partner and source:sub(partnerlen+1, partnerlen+1) == "!" then
				local splits2 = stringx.split(args, nil, 3)
				if splits2[1] == "PRIVMSG" and splits2[2] == self.data.nick and splits2[3]:sub(1,1) == ":" then -- This is a message from the partner nick
					local msg = splits2[3]:sub(2)
					
					if self.state == IrcState.piping then       -- Message with payload
						if msg:sub(1,1) == "#" then
							self.driver:handle(msg:sub(2))
						end
					else                                        -- Handshake message
						local prefix = msg:sub(1,2)
						local exclaim = prefix == "!!"
						local confirm = prefix == "@@" 
						if exclaim or confirm then
							if not self.sentVersion then
								if pipeDebug then print("Handshake started") end
								self:msg(IrcConfirm)
								self.sentVersion = true
							end

							if confirm then
								local splits3 = stringx.split(msg, nil, 2)
								local theirIrcVersion = splits3[2]
								if not versionMatches(version.ircPipe, theirIrcVersion) then
									self:abort("Your partner's emulator version is incompatible")
									print("Other user is using IRC pipe version " .. tostring(theirIrcVersion) .. ", you have " .. tostring(version.ircPipe))
								else
									if pipeDebug then print("Handshake finished") end
									statusMessage(nil)
									message("Connected to partner")

									self.state = IrcState.piping
									self.driver:wake(self)
								end
							end
						elseif msg:sub(1,1) == "#" then
							self:abort("Tried to connect, but your partner is already playing the game! Try resetting?")
						else
							self:abort("Your partner's emulator responded in... English? You probably typed the wrong nick!")
						end
					end
				end

			elseif self.state == IrcState.searching and source == self.data.server then
				local splits2 = stringx.split(args, nil, 2)
				local msg = tonumber(splits2[1])
				if msg and msg >= 311 and msg <= 317 then -- This is a whois response
					if pipeDebug then print("Whois response") end

					statusMessage("Connecting to partner...")
					self.state = IrcState.handshake
					self:msg(IrcHello)
				end 
			end
		end
	end
end

function IrcPipe:whoisCheck() -- TODO: Check on timer
	self:send("WHOIS " .. self.data.partner)
	statusMessage("Searching for partner...")
end

function IrcPipe:msg(s)
	self:send("PRIVMSG " .. self.data.partner .. " :" .. s)
end

-- TCP Pipe

class.TcpClientPipe(Pipe)
function TcpClientPipe:_init(data, driver)
	self:super()
	self.data = data
	self.driver = driver
	self.sentVersion = false
end

function TcpClientPipe:childWake()
	self.driver:wake(self)
end

function TcpClientPipe:receivePump()
	while not self.dead do -- Loop until no data left
		local length, err = self.server:receive(1) -- Pull one byte
		if not length then
			if err ~= "timeout" then
				errorMessage("Connection died: " .. err)
				self:exit()
			end
			return
		end

		-- Got useful data
		local msg, err = self.server:receive(string.byte(length))
		if not msg then
			if err ~= "timeout" then
				errorMessage("Connection died: " .. err)
				self:exit()
			else
				errorMessage("Timeout getting message body")
			end
			return
		end
		self:handle(msg)
	end
end

function TcpClientPipe:msg(s)
	self:send(s)
end

function TcpClientPipe:send(s)
	local hexString = ""
	for i = 1,#s do
		hexString = hexString .. string.format("%02x ", s:byte(i))
	end
	if pipeDebug then print("SEND: " .. hexString) end

	-- Length prefixed
	s = string.char(#s) .. s
	local res, err = self.server:send(s)
	if not res then
		errorMessage("Connection died: " .. s)
		self:exit()
		return false
	end
	return true
end

function TcpClientPipe:handle(s)
	local hexString = ""
	for i = 1,#s do
		hexString = hexString .. string.format("%02x ", s:byte(i))
	end
	if pipeDebug then print("RECV: " .. hexString) end
	t = deserializeTable(s)
	self.driver:handle(t)
	
	-- TODO add handshake (version check)
end

--[[ 
Message Format
* 1 byte length prefix (outside of message)
* 1 byte opcode
	1: hello
	Default Table:
	2: 2 byte address
	3: 3 byte address
	4: 2 byte address, negative value
	5: 3 byte address, negative value
	9: custom message
* Body varies by opcode

Message Bodies by Opcode
Hello (1)
	* pretty.write of table
Default Table (2-8)
	* 2 or 3 bytes address
	* 1 byte value size
	* x bytes value
Custom Message (9)
	* 1 byte name length
	* x bytes name
	* 1 byte table type (00: byte stream, 01: generic object)
	* 1 byte table size
	* x bytes table
--]]

function bytesNeededForValue(val)
	local valueSize = 1
	if val < 0 then val = -val * 2 end
	while (valueSize < 8 and val >= SHIFT(1, -valueSize * 8))
	do
		valueSize = valueSize + 1
	end
	return valueSize
end

local function isByteArray(t)
	if type(t) ~= "table" then return false end
	local i = 0
	for _ in pairs(t) do
		i = i + 1
		if t[i] == nil then return false end
		if t[i] < 0 or t[i] > 255 then return false end
	end
	return true
end

function serializeTable(t)
	local s = ""
	if t[1] then
		if t[1] == "hello" then -- Handshake
			s = string.char(1) .. pretty.write(t)
		else
			s = string.char(9)
			-- Name
			s = s .. string.char(#t[2])
			s = s .. t[2]
			-- Payload
			if isByteArray(t[3]) then
				-- Efficient serialization of byte streams
				s = s .. string.char(0)
				s = s .. string.char(#t[3])
				for i = 1,#t[3] do s = s .. string.char(t[3][i]) end
			else
				-- Lazy serialization of generic table
				local serializedPayload = pretty.write(t[3])
				s = s .. string.char(1)
				s = s .. string.char(#serializedPayload)
				s = s .. serializedPayload
			end
		end
	else
		-- Default memory table

		-- Opcode
		local addressSize = 2
		if t.addr >= 0x10000 then addressSize = 3 end
		local opcode = addressSize
		if t.value < 0 then opcode = opcode + 2 end
		s = string.char(opcode)

		-- Address
		local addr = t.addr
		for i = 1,addressSize do
			s = s .. string.char(AND(addr, 0xff))
			addr = SHIFT(addr, 8)
		end

		-- Value Size
		local valueSize = bytesNeededForValue(t.value)
		s = s .. string.char(valueSize)

		-- x bytes value
		local val = t.value
		for i = 1,valueSize do
			s = s .. string.char(AND(val, 0xff))
			val = SHIFT(val, 8)
		end
	end
	return s
end

function deserializeTable(s)
	local opcode = s:byte(1)
	if opcode == 1 then
		-- hello
		return pretty.read(s:sub(2))
	elseif opcode >= 2 and opcode <= 5 then
		-- Default table
		
		-- address
		local addressSize = opcode
		if opcode > 3 then addressSize = opcode - 2 end
		local addr = 0
		for i = 1,addressSize do
			addr = addr + SHIFT(s:byte(i + 1), -8 * (i - 1))
		end

		-- value size
		local valueSize = s:byte(2 + addressSize)

		-- value
		local value = 0
		for i = 1,valueSize do
			value = value + SHIFT(s:byte(2 + addressSize + i), -8 * (i - 1))
		end
		if opcode > 3 then
			-- negative
			value = value - SHIFT(1, -valueSize * 8)
		end

		return {addr=addr, value=value}

	elseif opcode == 9 then
		local result = {"custom"}
		-- Name
		local nameLength = s:byte(2)
		local name = s:sub(3, 2 + nameLength)
		local i = 3 + nameLength

		-- Payload
		local payload = nil
		local payloadType = s:byte(i)
		local payloadLength = s:byte(i + 1)
		local payloadStartIndex = i + 2
		if payloadType == 0 then
			-- Byte array
			payload = {}
			for i = 1,payloadLength do
				payload[i] = s:byte(payloadStartIndex - 1 + i)
			end
		else
			-- Generic
			payload = pretty.read(s:sub(payloadStartIndex))
		end

		return {"custom", name, payload}
	end
end

-- Driver base class

class.Driver()
function Driver:_init() end

function Driver:wake(pipe)
	self.pipe = pipe
	self:childWake()
end

function Driver:sendTable(t)
	self.pipe:msg(serializeTable(t))
end

function Driver:handle(t)
	if driverDebug then print("Driver got table " .. tostring(t)) end
	if t then
		self:handleTable(t)
	else
		self.handleFailure(s, err)
	end
end

function Driver:tick()
	self:childTick()
end

function Driver:childWake() end
function Driver:childTick() end
function Driver:handleTable(t) end
function Driver:handleFailure(s, err) end
