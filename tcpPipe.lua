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

function TcpClientPipe:childWake() end

function TcpClientPipe:receivePump()
	if not self.connected then
		-- Not the most graceful, but works
		result, err = self.server:connect(self.data.server, self.data.port)
		if not result and err ~= "already connected" then
			return
		else
			self.connected = true
			print("Connected to server")
			if self.driver then self.driver:wake(self) end
		end
	end

	while not self.dead do -- Loop until no data left
		local length, err = self.server:receive(1) -- Pull one byte
		if not length then
			if err ~= "timeout" then
				errorMessage("Connection died: " .. err)
				self:exit()
				return false, err
			end
			return true
		end

		-- Got useful data
		local msg, err = self.server:receive(string.byte(length))
		if not msg then
			if err ~= "timeout" then
				errorMessage("Connection died: " .. err)
				self:exit()
				return false, err
			else
				errorMessage("Timeout getting message body")
				return false, err
			end
		end
		self:handle(msg)
	end
end

function TcpClientPipe:msg(s)
	self:send(s)
end

function TcpClientPipe:send(s)
	if pipeDebug then print("SEND: " .. s .. toHexString(s)) end

	-- Length prefixed
	s = string.char(#s) .. s
	local res, err = self.server:send(s)
	if not res then
		errorMessage("3 Connection died: " .. err)
		self:exit()
		return false
	end
	return true
end

function TcpClientPipe:handle(s)
	if pipeDebug then print("RECV: " .. toHexString(s)) end

	t = deserializeTable(s)
	self.driver:handle(t)
	
	-- TODO add handshake (version check)
end

-- TCP Client on Server

class.TcpClientOnServer(TcpClientPipe)
function TcpClientOnServer:_init(serverPipe)
	self:super(nil, nil)
	self.serverPipe = serverPipe
end

function TcpClientOnServer:handle(s)
	if pipeDebug then print("RECV: " .. toHexString(s)) end

	self.serverPipe:handle(s, self)
end

function TcpClientOnServer:wake(server)
	self.server = server
	self.server:settimeout(0)

	self:childWake()
end

-- TCP Server Pipe

class.TcpServerPipe(Pipe)
function TcpServerPipe:_init(data, driver)
	self:super()
	self.data = data
	self.driver = driver
	self.clients = {}
end

function TcpServerPipe:childWake()
	self.driver:wake(self)
end

function TcpServerPipe:receivePump()
	if not self.dead then
		-- accept new clients
		local newClient, err = self.server:accept()
		if newClient then
			local clientObject = TcpClientOnServer(self)
			clientObject.connected = true
			table.insert(self.clients, clientObject)
			clientObject:wake(newClient)
			print("Client connected")
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

function TcpServerPipe:msg(s)
	self:send(s)
end

function TcpServerPipe:send(s)
	if s:byte(1) == 1 then return end -- Don't send hello out as server

	if pipeDebug then print("SEND: " .. toHexString(s)) end

	-- Send to all clients
	for i=#self.clients,1,-1 do
		if not self.clients[i]:send(s) then
			table.remove(self.clients, i)
		end
	end
end

function TcpServerPipe:handle(s, originClient)
	if pipeDebug then print("RECV: " .. toHexString(s)) end

	-- Handle for local game
	t = deserializeTable(s)
	self.driver:handle(t)

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

function isByteArray(t)
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
