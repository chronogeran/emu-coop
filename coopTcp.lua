class   = require "pl.class"
pretty  = require "pl.pretty"
List    = require "pl.list"
stringx = require "pl.stringx"
tablex  = require "pl.tablex"

require "version"
require "util"

require "modes.index"
require "dialog"
require "pipe"
require "driver"


pipeDebug = true
driverDebug = true

-- PROGRAM

if emu.emulating() then
	local spec = nil -- Mode specification
	
	local usableModes = {} -- Mode files that can be loaded in this version of coop.lua
	for i,v in ipairs(modes) do
		if versionMatches(version.modeFormat, v.format) then
			table.insert(usableModes, v)
		else
			print("Could not load a game mode because it is not compatible with this version of the emulator. The game's name was: " .. tostring(v.name))
		end
	end

	local specOptions = {} -- Mode files that match the currently running ROM
	for i,v in ipairs(usableModes) do
		if performTest(v.match) then
			table.insert(specOptions, v)
		end
	end

	if #specOptions == 1 then -- The current game's mode file has been found
		spec = specOptions[1]
	elseif #specOptions > 1 then -- More than one mode file was found that could be this game
		spec = selectDialog(specOptions, "multiple matches")
	else                         -- No matches
		spec = selectDialog(usableModes, "no matches")
	end

	if spec then -- If user did not hit cancel
		print("Playing " .. spec.name)

		local data = tcpDialog()

		if data then -- If user did not hit cancel
			local failed = false

			function scrub(invalid) errorMessage(invalid .. " not valid") failed = true end

			-- Strip out stray whitespace (this can be a problem on FCEUX)
			for _,v in ipairs{"server", "nick", "partner"} do
				if data[v] then data[v] = data[v]:gsub("%s+", "") end
			end

			-- Check input valid
			if not data.startAsServer then
				if not nonempty(data.server) then scrub("Server")
				elseif not nonzero(data.port) then scrub("Port")
				end
			end

			function connect()
				local socket = require "socket"
				local clientConnection = socket.tcp()

				if data.startAsServer then
					local server = socket.tcp()
					result, err = server:bind("*", data.port)
					if not result then
						errorMessage("Could not start server: " .. err)
						failed = true
						return
					end
					result, err = server:listen(3)
					if not result then
						errorMessage("Could not listen on server: " .. err)
						failed = true
						return
					end
					-- For now, block
					server:settimeout(60)
					clientConnection = server:accept()
				else
					result, err = clientConnection:connect(data.server, data.port)
					if not result then
						errorMessage("Could not connect to server: " .. err)
						failed = true
						return
					end
					statusMessage("Connected to server...")
				end


				mainDriver = GameDriver(spec, data.forceSend) -- Notice: This is a global, specs can use it
				TcpClientPipe(data, mainDriver):wake(clientConnection)
			end

			if not failed then connect() end

			if failed then gui.register(printMessage) end
		end
	end
else
	refuseDialog()
end
