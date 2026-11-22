return function(test, loadProject)
	local function fixture(options)
		local calls = { commands = {}, pauses = {}, keys = {}, setups = 0, focusReads = 0 }
		local results = options.results or { "true\t7\t" }
		local macroReads, byteReads, timeChecks = 0, 0, 0
		local env = loadProject({
			settings = { options = {}, profile = { hotkeys = { MACRO = { key = 9 } } } },
			addresses = { macro = { base = 10, size = 20, content = 5 }, input_box = { base = 50, offsets = 1 } },
			commandMacro = options.unset and 0 or 1,
			resultMacro = 2,
			COMMAND_MACRO_NAME = "command",
			RESULT_MACRO_NAME = "result",
			readMacro = function(slot)
				macroReads = macroReads + 1
				if macroReads == 1 then
					assert(slot == 1)
					return "", options.moved and "other" or "command"
				end
				assert(slot == 2)
				if macroReads == 2 then
					return "", "result"
				end
				return assert(results[macroReads - 2], "Unexpected result read")
			end,
			setupMacros = function() calls.setups = calls.setups + 1 end,
			memoryReadUInt = function(proc, address)
				assert(proc == 4 and address == 10)
				return 100
			end,
			writeToMacro = function(slot, command)
				assert(slot == 1 and #calls.commands < 4, "Unexpected command write")
				calls.commands[#calls.commands + 1] = command
			end,
			memoryWriteByte = function(proc, address, value)
				assert(proc == 4 and address == 125 and value == 6)
			end,
			memoryReadByte = function(proc, address)
				assert(proc == 4 and address == 125)
				byteReads = byteReads + 1
				return options.timeout and byteReads <= 2 and 6 or 0
			end,
			getTime = function() return 1 end,
			deltaTime = function()
				timeChecks = timeChecks + 1
				return timeChecks == 1 and 10 or 801
			end,
			rest = function(ms) calls.pauses[#calls.pauses + 1] = ms end,
			memoryReadUIntPtr = function(proc, address, offset)
				assert(proc == 4 and address == 50 and offset == 1)
				calls.focusReads = calls.focusReads + 1
				return 0
			end,
		}, "functions.lua")
		env.isInGame = function() return not options.notInGame end
		env.getProc = function() return 4 end
		env.getBaseAddress = function(offset) return offset end
		env.keyboardHold = function(key) calls.keys[#calls.keys + 1] = "hold:" .. key end
		env.keyboardRelease = function(key) calls.keys[#calls.keys + 1] = "release:" .. key end
		return env.RoMScript, calls
	end

	test("RoMScript sends 254 bytes intact and chunks longer commands", function()
		local first, middle = string.rep("a", 253), string.rep("b", 253)
		for _, case in ipairs({
			{ first .. "b", { first .. "b" } },
			{ first .. "bc", { "!" .. first, "#bc" } },
			{ first .. middle .. "c", { "!" .. first, "@" .. middle, "#c" } },
		}) do
			local execute, calls = fixture({})
			assert(execute(case[1]) == 7)
			assert(#calls.commands == #case[2])
			for i, expected in ipairs(case[2]) do
				assert(calls.commands[i] == expected)
			end
		end
	end)

	test("RoMScript joins multipart results before decoding", function()
		local value = string.rep("x", 251)
		local execute, calls = fixture({ results = {
			"true\t" .. value:sub(1, 250),
			value:sub(251) .. "\tfalse\t4.5\t\0ignored\t",
		} })
		local text, flag, number, extra = execute("test")
		assert(text == value and flag == false and number == 4.5 and extra == nil)
		assert(table.concat(calls.commands, "|") == "test|SendMore")
	end)

	test("RoMScript retries after a timeout", function()
		local execute, calls = fixture({ timeout = true })
		assert(execute("test") == 7)
		assert(table.concat(calls.commands, "|") == "test|test")
		assert(table.concat(calls.keys, "|") == "hold:9|release:9|hold:9|release:9")
		assert(#calls.pauses == 1 and calls.pauses[1] == 10)
		assert(calls.focusReads == 2)
	end)

	test("RoMScript reinitializes moved macros", function()
		local execute, calls = fixture({ moved = true })
		assert(execute("test") == 7 and calls.setups == 1)
	end)

	test("RoMScript returns nothing outside the game and rejects missing setup", function()
		local execute, calls = fixture({ notInGame = true })
		assert(select("#", execute("test")) == 0 and #calls.commands == 0)
		execute, calls = fixture({ unset = true })
		local ok, message = pcall(execute, "test")
		assert(not ok and message:find("Cannot use RoMScript until after setupMacros()", 1, true))
		assert(#calls.commands == 0)
	end)

	test("RoMScript raises the error returned by the addon", function()
		local execute, calls = fixture({ results = { "false\trejected\t" } })
		local ok, message = pcall(execute, "test")
		assert(not ok and message == "IGF:\\test\\:IGF rejected")
		assert(#calls.commands == 1)
	end)
end
