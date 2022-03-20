--[[require "iuplua"

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
--]]