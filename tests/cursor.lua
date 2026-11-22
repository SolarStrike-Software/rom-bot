return function(test, loadProject)
	local function fixture(location, clears)
		local data, commands = { [106] = location, [110] = 42, [114] = 7, [118] = 11 }, {}
		local env = loadProject({
			class = function() return {} end,
			addresses = { cursor = { base = 10, offset = 2, item = { location = 4, id = 8, bag_id = 12 } } },
			getProc = function() return 5 end,
			getBaseAddress = function(offset) return offset + 200 end,
			memoryReadUInt = function(proc, address)
				assert(proc == 5 and address == 210)
				return 100
			end,
			memoryReadInt = function(proc, address)
				assert(proc == 5)
				return assert(data[address])
			end,
			RoMCode = function(command)
				commands[#commands + 1] = command
				if clears then data[106] = 0 end
			end,
		}, "classes/cursor.lua")
		return setmetatable({}, { __index = env.CCursor }), commands
	end

	test("CCursor reads its location and returns the item to the correct slot", function()
		for _, case in ipairs({
			{ 1, "inventory", "PickupBagItem(8)" },
			{ 3, "bank", "PickupBankItem(8)" },
			{ 4, "equipment", "PickupEquipmentItem(8)" },
			{ 12, "house", "Houses_PickupItem(7,12)" },
			{ 14, "guildbank", "GuildBank_PickupItem(8)" },
		}) do
			local cursor, commands = fixture(case[1], true)
			assert(cursor:hasItem() and cursor.ItemLocationName == case[2] and cursor.ItemId == 42)
			cursor:clear()
			assert(#commands == 1 and commands[1] == case[3])
			assert(cursor.ItemLocationName == "<EMPTY>" and cursor.DBID == nil)
			cursor:clear()
			assert(#commands == 1)
		end
	end)

	test("CCursor reports unsupported locations and failed item returns", function()
		local cursor, commands = fixture(8, false)
		local ok, message = pcall(cursor.clear, cursor)
		assert(not ok and message:find("Cursor item location not supported", 1, true))
		assert(#commands == 0)
		cursor, commands = fixture(1, false)
		ok, message = pcall(cursor.clear, cursor)
		assert(not ok and message:find("Returning the item failed", 1, true))
		assert(#commands == 1)
	end)
end
