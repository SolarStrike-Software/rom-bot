return function(test, loadProject)
	local function fixture(options)
		local closed, warnings, waits, messages = {}, {}, {}, {}
		local env = loadProject({
			settings = { options = {}, hotkeys = { STOP_BOT = { key = "stop" } } },
			key = { VK_RETURN = "enter", VK_UP = "up", VK_DOWN = "down" },
			addresses = { game_root = { base = 1, player = { base = 2 }, pawn = { name_ptr = 3 } } },
			bot = { ClientLanguage = options.locale },
			findProcessByWindow = function(window) return window end,
			openProcess = function(pid) return pid end,
			closeProcess = function(process) closed[#closed + 1] = process end,
			showWarnings = function(enabled) warnings[#warnings + 1] = enabled end,
			getModuleAddress = function() return 100 end,
			memoryReadUInt = function(process) return process end,
			memoryReadString = function(_, address) return options.names[address] end,
			yrest = function(ms) waits[#waits + 1] = ms end,
			printf = function(format, ...) messages[#messages + 1] = string.format(format, ...) end,
			cprintf = function(color, format, ...) messages[#messages + 1] = string.format(format, ...) end,
			print = function(message) messages[#messages + 1] = message end,
		}, "functions.lua")
		env.getGameVersion = function(process) return process == 11 and 0 or "1.2" end
		env.memoryReadRepeat = function(_, process) return process end
		if options.legacy then
			env.findWindowList = function(title, class)
				assert(title == "*" and class == "Radiant Arcana")
				return options.windows
			end
		else
			env.findProcessByExeList = function(exe)
				assert(exe == "Client.exe")
				return options.processes
			end
			env.getWindowsFromProcess = function(pid) return options.windows[pid] end
			env.getWindowClassName = function(window) return options.classes[window] end
			env.getWindowParent = function(window) return window == 22 and 33 or nil end
			env.windowRect = function(window)
				assert(window == 33)
				return 0, 0, 640, 480
			end
		end
		local enterPolls = 0
		env.keyPressedLocal = function(key)
			if key == "enter" then
				enterPolls = enterPolls + 1
				local state = (options.enter or {})[enterPolls]
				assert(state ~= nil, "Unexpected Enter poll")
				return state
			end
			return key == "down" and options.down or key == "stop" and options.cancel
		end
		if options.locale then
			env.database = { utf8_ascii = { example = true } }
			env.utf82oem_russian = function(name) return "RU " .. name end
			env.utf8ToAscii_umlauts = function(name) return "ASCII " .. name end
		end
		return env, closed, warnings, waits, messages
	end

	test("selectGame discovers one window per process and accepts an IME parent", function()
		local env, closed, warnings, waits = fixture({
			processes = { 1, 2 },
			windows = { { 11, 12 }, { 22 } },
			classes = { [11] = "Radiant Arcana", [12] = "Radiant Arcana", [22] = "IME" },
			names = { [11] = "Alice", [33] = "Bob" },
		})
		assert(env.selectGame("bOb") == 33)
		assert(#closed == 2 and closed[1] == 11 and closed[2] == 33)
		assert(#warnings == 4 and not warnings[1] and warnings[2] and not warnings[3] and warnings[4])
		assert(#waits == 0)
	end)

	test("selectGame labels unreadable characters and converts known names", function()
		for _, locale in ipairs({ "RU", "EN" }) do
			local env = fixture({ legacy = true, windows = { 11, 22 }, names = { [11] = "Alice" }, locale = locale })
			local label = locale == "RU" and "RU Alice" or "ASCII Alice"
			assert(env.selectGame(label) == 11)
			assert(env.charToUse[1] == label and env.charToUse[2] == "(RoM window 2) - 1.2")
		end
	end)

	test("selectGame waits for Enter release even with one window", function()
		local env, _, _, waits = fixture({
			legacy = true, windows = { 11 }, names = { [11] = "Alice" }, enter = { true, false },
		})
		assert(env.selectGame() == 11)
		assert(#waits == 1 and waits[1] == 200)
	end)

	test("selectGame menu moves the selection and accepts Enter", function()
		local env, _, _, waits, messages = fixture({
			legacy = true, windows = { 11, 22 }, names = { [11] = "Alice", [22] = "Bob" },
			enter = { false, false, true }, down = true,
		})
		assert(env.selectGame() == 22 and env.windowChoice == 2)
		assert(table.concat(waits, "|") == "50|200")
		assert(table.concat(messages):find("Choose your character", 1, true))
	end)

	test("selectGame menu cancels with the stop key", function()
		local env = fixture({
			legacy = true, windows = { 11, 22 }, names = {}, enter = { false, false }, cancel = true,
		})
		local ok, message = pcall(env.selectGame)
		assert(not ok and message:find("User quit", 1, true))
	end)

	test("selectGame handles missing processes and unusable windows", function()
		local noProcesses = fixture({ processes = {}, windows = {} })
		local ok, message = pcall(noProcesses.selectGame)
		assert(not ok and message == "You need to run rom first!")
		local unusable = fixture({ processes = { 1 }, windows = { { 11 } }, classes = { [11] = "Other" } })
		assert(unusable.selectGame() == 0)
	end)
end
