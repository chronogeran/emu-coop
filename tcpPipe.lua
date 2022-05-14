-- NETWORKING

-- TCP Pipe

function toHexString(s)
	local hexString = ""
	for i = 1,#s do
		hexString = hexString .. string.format("%02x ", s:byte(i))
	end
	return hexString
end

class.TcpClientPipe(Pipe)
function TcpClientPipe:_init(data, driver)
	self:super()
	self.data = data
	self.driver = driver
	self.connected = false
end

function TcpClientPipe:getPartnerName(clientId)
	for i=1,#self.playerlist do
		if self.playerlist[i].id == clientId then
			return self.playerlist[i].nickname
		end
	end
	return "Partner"
end

function TcpClientPipe:childWake() end

function TcpClientPipe:childTick()
	if self.connected and self.confirmed then
		self.driver:tick()
	end
end

function TcpClientPipe:receivePump()
	if not self.connected then
		-- Not the most graceful, but works
		local result, err = self.socket:connect(self.data.server, self.data.port)
		if not result and err ~= "already connected" then
			return
		end
		self.connected = true
		print("Connected to server")
		if self.driver then self.driver:wake(self) end
	end

	while not self.dead do -- Loop until no data left
		local length, err = self.socket:receive(1) -- Pull one byte
		if not length then
			if err ~= "timeout" then
				errorMessage("Connection died on receive: " .. err)
				self:exit()
				return false, err
			end
			return true
		end

		-- Got useful data
		local msg, err = self.socket:receive(string.byte(length))
		if not msg then
			if err ~= "timeout" then
				errorMessage("Connection died on receive: " .. err)
				self:exit()
				return false
			else
				errorMessage("Timeout getting message body")
				return false, err
			end
		end
		self:handle(msg)
	end

	return true
end

function TcpClientPipe:msg(t)
	self:send(serializeTable(t))
end

function TcpClientPipe:send(s, suppressDebugMessage)
	if pipeDebug and not suppressDebugMessage then print("SEND: " .. s .. toHexString(s)) end

	-- Length prefixed
	s = string.char(#s) .. s
	local res, err = self.socket:send(s)
	if not res then
		errorMessage("Connection died on send: " .. err)
		self:exit()
		return false
	end
	return true
end

function TcpClientPipe:handle(s)
	if pipeDebug then print("RECV: " .. toHexString(s)) end

	if #s == 0 then
		print("Server disconnected")
		self:exit()
		return
	end

	t = deserializeTable(s)

	if t[1] == "playerlist" then
		self.playerlist = t.list
		if pipeDebug then print("Player List received") end
	else
		self.driver:handle(t)
	end
	
	-- TODO add handshake (version check)
end

-- TCP Client on Server

class.TcpClientOnServer(TcpClientPipe)
function TcpClientOnServer:_init(serverPipe)
	self:super(nil, nil)
	self.serverPipe = serverPipe
end

function TcpClientOnServer:handle(s)
	if #s == 0 then
		print("Client disconnected")
		self:exit()
		return
	end

	self.serverPipe:handle(s, self)
end

function TcpClientOnServer:wake(sock)
	self.socket = sock
	self.socket:setTimeout(0)

	self:childWake()
end

function TcpClientOnServer:childTick() end

-- TCP Server Pipe

class.TcpServerPipe(Pipe)
function TcpServerPipe:_init(data, driver)
	self:super()
	self.data = data
	self.driver = driver
	self.clients = {}
	self.nextClientId = 1
end

function TcpServerPipe:getPartnerName(clientId)
	for i=1,#self.clients do
		if self.clients[i].id == clientId then
			return self.clients[i].nickname
		end
	end
	return "Partner"
end

function TcpServerPipe:childWake()
	local result, err = self.socket:bind("*", self.data.port)
	if not result then
		errorMessage("Could not start server: " .. err)
		return
	end
	result, err = self.socket:listen(3)
	if not result then
		errorMessage("Could not listen on server: " .. err)
		return
	end
	print("Server started")
	self.driver:wake(self)
end

function TcpServerPipe:childTick()
	if #self.clients > 0 and self.confirmed then
		self.driver:tick()
	end
end

function TcpServerPipe:receivePump()
	if not self.dead then
		-- accept new clients
		local newClient, err = self.socket:accept()
		if newClient then
			local clientObject = TcpClientOnServer(self)
			clientObject.connected = true
			table.insert(self.clients, clientObject)
			clientObject:wake(newClient)
			clientObject.id = self.nextClientId
			self.nextClientId = self.nextClientId + 1
			print("Client connected")
			clientObject:send(self.helloMessage)
		else
			if err ~= "timeout" then
				errorMessage("Error during accept: " .. err)
				self:exit()
			end
		end

		-- Pump clients
		for i=#self.clients,1,-1 do
			if not self.clients[i]:receivePump() then
				table.remove(self.clients, i)
			end
		end
	end
end

function TcpServerPipe:msg(t)
	self:send(serializeTable(t))
end

function TcpServerPipe:send(s)
	-- Server needs to send hello to each new client, not right on startup
	if s:byte(1) == 1 then
		self.helloMessage = s
		return
	end

	if #self.clients == 0 or not self.confirmed then return end

	if pipeDebug then print("SEND: " .. toHexString(s)) end

	-- Send to all clients
	for i=#self.clients,1,-1 do
		if not self.clients[i]:send(s, true) then
			table.remove(self.clients, i)
		end
	end
end

function TcpServerPipe:sendPlayerList()
	local reg = {"playerlist",list={{id=0, nickname=self.data.nickname}}}
	for i=1,#self.clients do
		table.insert(reg.list, {id=self.clients[i].id, nickname=self.clients[i].nickname})
	end

	local s = serializeTable(reg)
	-- Send to everyone including new guy so he gets server's name and other existing players
	for i=#self.clients,1,-1 do
		if not self.clients[i]:send(s, true) then
			table.remove(self.clients, i)
		end
	end
end

function TcpServerPipe:handle(s, originClient)
	if pipeDebug then print("RECV: " .. toHexString(s)) end

	if s:byte(1) ~= 1 then
		-- Set client ID of message (always byte 2)
		s = replace_char(2, s, string.char(originClient.id))
	end

	-- Handle for local game
	t = deserializeTable(s)
	self.driver:handle(t)

	if t[1] == "hello" then
		originClient.nickname = t.nickname
		if pipeDebug then print("Registered " .. originClient.nickname) end
		-- Don't need to replicate hello out, but we do need to update playerlist
		self:sendPlayerList()
		return
	end

	-- Send to all other clients
	for i=#self.clients,1,-1 do
		if self.clients[i] ~= originClient then
			if not self.clients[i]:send(s) then
				table.remove(self.clients, i)
			end
		end
	end
end

function TcpServerPipe:childExit()
	for k,v in pairs(self.clients) do
		v:exit()
	end
end

--[[ 
Message Format
* 1 byte length prefix (outside of message)
* 1 byte opcode
	1: hello (or other prettyprinted table)
	Default Table:
	2: 2 byte address
	3: 3 byte address
	4: 4 byte address
	5: 2 byte address, negative value
	6: 3 byte address, negative value
	7: 4 byte address, negative value
	8: 2 byte address, flags value
	9: 3 byte address, flags value
	10: 4 byte address, flags value
	20: custom message
* Body varies by opcode

Message Bodies by Opcode
Hello (1)
	* pretty.write of table
Default Table (2-10)
	* 1 byte client ID (ignored if sent to server)
	* 2-4 bytes address
	* 1 byte value size
	* x bytes value
Custom Message (20)
	* 1 byte client ID (ignored if sent to server)
	* 1 byte name length
	* x bytes name
	* 1 byte table type (00: byte stream, 01: generic object)
	* 1 byte table size
	* x bytes table
--]]

-- Goes max to size 4
function bytesNeededForValue(val)
	local valueSize = 1
	if val < 0 then val = -val * 2 end
	while (valueSize < 4 and val >= SHIFT(1, -valueSize * 8))
	do
		valueSize = valueSize + 1
	end
	return valueSize
end

function isByteArray(t)
	if type(t) ~= "table" then return false end
	local i = 0
	for _ in pairs(t) do
		i = i + 1
		if t[i] == nil then return false end
		if type(t[i]) ~= "number" then return false end
		if t[i] < 0 or t[i] > 255 then return false end
	end
	return true
end

function appendNumberToBuffer(s, n, size)
	for i = 1,size do
		s = s .. string.char(AND(n, 0xff))
		n = SHIFT(n, 8)
	end
	return s
end

function readNumberFromBuffer(s, offset, size)
	local value = 0
	for i = 1,size do
		value = value + SHIFT(s:byte(offset + i), -8 * (i - 1))
	end
	return value
end

function replace_char(pos, str, r)
	return str:sub(1, pos-1) .. r .. str:sub(pos+1)
end

function serializeTable(t)
	local s = ""
	if t[1] then
		if t[1] == "hello" or t[1] == "playerlist" then -- Handshake
			s = string.char(1) .. pretty.write(t)
		else
			s = string.char(20)
			-- Client ID. Always 0 because clients don't know, and server is 0
			s = s .. string.char(0)
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
		if t.addr >= 0x1000000 then addressSize = 4
		elseif t.addr >= 0x10000 then addressSize = 3 end
		local opcode = addressSize
		if type(t.value) == "table" then opcode = opcode + 6
		elseif t.value < 0 then opcode = opcode + 3 end
		s = string.char(opcode)

		-- Client ID. Always 0 because clients don't know, and server is 0
		s = s .. string.char(0)

		-- Address
		local addr = t.addr
		for i = 1,addressSize do
			s = s .. string.char(AND(addr, 0xff))
			addr = SHIFT(addr, 8)
		end

		if opcode >= 8 and opcode <= 10 then
			-- Value Size
			local valueSize = bytesNeededForValue(t.value[1])
			s = s .. string.char(valueSize)

			-- x bytes value
			s = appendNumberToBuffer(s, t.value[1], valueSize)
			s = appendNumberToBuffer(s, t.value[2], valueSize)
		else
			-- Value Size
			local valueSize = bytesNeededForValue(t.value)
			s = s .. string.char(valueSize)

			-- x bytes value
			s = appendNumberToBuffer(s, t.value, valueSize)
		end
	end
	return s
end

function deserializeTable(s)
	local opcode = s:byte(1)
	if opcode == 1 then
		-- hello
		return pretty.read(s:sub(2))
	elseif opcode >= 2 and opcode <= 19 then
		-- Default table

		-- client ID
		local clientId = s:byte(2)

		-- address
		local addressSize = opcode
		if opcode >= 5 and opcode <= 7 then addressSize = opcode - 3
		elseif opcode >= 8 and opcode <= 10 then addressSize = opcode - 6 end
		local addr = 0
		for i = 1,addressSize do
			addr = addr + SHIFT(s:byte(i + 2), -8 * (i - 1))
		end

		-- value size
		local valueSize = s:byte(3 + addressSize)

		-- value
		local value = readNumberFromBuffer(s, 3 + addressSize, valueSize)
		if opcode >= 5 and opcode <= 7 then
			-- negative
			value = value - SHIFT(1, -valueSize * 8)
		elseif opcode >= 8 and opcode <= 10 then
			-- flags
			value = { value, readNumberFromBuffer(s, 3 + addressSize + valueSize, valueSize) }
		end

		return {addr=addr, value=value, clientId=clientId}

	elseif opcode == 20 then
		local result = {"custom"}

		-- client ID
		local clientId = s:byte(2)

		-- Name
		local nameLength = s:byte(3)
		local name = s:sub(4, 3 + nameLength)
		local i = 4 + nameLength

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

		return {"custom", name, payload, clientId}
	end
end
