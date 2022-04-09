
-- BizHawk
if BizHawk then
	-- Dialog
	tcpDialog = function()
		local done = false
		local result = nil

		function onclose()
			done = true
		end
		local f = forms.newform(500, 200, "Connection Settings", onclose)
		local h_isServer = forms.checkbox(f, "Start Server", 5, 5)
		local h_serverName = forms.textbox(f, "127.0.0.1", 100, 25, nil, 5, 35)
		local h_port = forms.textbox(f, "5968", 50, 25, nil, 5, 65)
		function onOk()
			result = {}
			result.startAsServer = forms.ischecked(h_isServer)
			result.server = forms.gettext(h_serverName)
			result.port = tonumber(forms.gettext(h_port))
			forms.destroy(f)
		end
		local h_ok = forms.button(f, "OK", onOk, 5, 95, 75, 30)

		while not done do
			emu.frameadvance()
		end

		return result
	end

	selectDialog = function(specs, reason)
		local names = {}
		for i, v in ipairs(specs) do
			names[i] = v.name
		end

		local done = false
		local result = nil

		function onclose()
			done = true
		end
		local f = forms.newform(500, 200, "Select Game", onclose)
		local l = forms.label(f, "Can't figure out which game to load", 5, 5, 400, 20)
		local d = forms.dropdown(f, names, 5, 30, 400, 30)
		function onOk()
			local chosenGame = forms.gettext(d)
			for i, v in ipairs(specs) do
				if v.name == chosenGame then
					result = v
					forms.destroy(f)
					return
				end
			end
			print("Game " .. chosenGame .. " not found")
		end
		local ok = forms.button(f, "OK", onOk, 5, 65, 100, 50)

		while not done do
			emu.frameadvance()
		end

		return result
	end

	function refuseDialog(options)
		print("Cannot run, No ROM is running.")
		--iup.Message("Cannot run", "No ROM is running.")
	end
else
	-- Not BizHawk
	require "iuplua"

	-- Bizarre kludge: For reasons I do not understand at all, radio buttons do not work in FCEUX. Switch to menus there only
	local optionLetter = "o"
	if FCEU then optionLetter = "l" end

	function ircDialog()
		local res, server, port, nick, partner, forceSend = iup.GetParam("Connection settings", nil,
			"Enter an IRC server: %s\n" ..
			"IRC server port: %i\n" ..
			"Your nick: %s\n" ..
			"Partner nick: %s\n" ..
			"%t\n" .. -- <hr>
			"Are you restarting\rafter a crash? %" .. optionLetter .. "|No|Yes|\n"
			,"irc.speedrunslive.com", 6667, "", "", 0)

		if 0 == res then return nil end

		return {server=server, port=port, nick=nick, partner=partner, forceSend=forceSend==1}
	end

	function tcpDialog()
		local res, startAsServer, server, port = iup.GetParam("Connection Settings", nil,
			"Start Server: %" .. optionLetter .. "|No|Yes|\n" ..
			"Connect Server: %s\n" ..
			"Connect Port: %i\n", 0, "127.0.0.1", 5968) -- TODO defaults saved from last time
		if res == 0 then return nil end
		return {startAsServer=startAsServer == 1, server=server, port=port}
	end

	function selectDialog(specs, reason)
		local names = ""
		for i, v in ipairs(specs) do
			names = names .. v.name .. "|"
		end

		local res, selection = iup.GetParam("Select game", nil,
			"Can't figure out\rwhich game to load\r(" .. reason .. ")\r" ..
			"Which game is this? " ..
			"%l|" .. names .. "\n",
			0)

		if 0 == res or nil == selection then return nil end

		return specs[selection + 1]
	end

	function refuseDialog(options)
		iup.Message("Cannot run", "No ROM is running.")
	end
end