-- Set up compatibility with various emulators

-- BizHawk
if nds and snes and nes then
	-- Dialog
	tcpDialog = function()
		local done = false
		local result = nil

		print("tcp dialog")
		function onclose()
		print("tcp dialog closed")
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
end
