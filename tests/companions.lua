return function(test, loadProject)
	test("CEggPet selects the first usable tool from its choices", function()
		local slots = {}
		for slot = 51, 240 do slots[slot] = { Available = false } end
		slots[51] = { Available = false, Id = 101 }
		slots[52] = { Available = true, Empty = false, Id = 102 }
		local env = loadProject({
			class = function() return {} end,
			inventory = { BagSlot = slots },
		}, "classes/eggpet.lua")
		local first, second = { Id = 101 }, { Id = 102 }
		local pet = setmetatable({
			Tool = { Id = 0 }, getToolChoices = function() return { first, second } end,
		}, { __index = env.CEggPet })
		assert(pet:getBestTool() == second and second.HaveSome)
		slots[52].Empty = true
		second.HaveSome = nil
		assert(pet:getBestTool() == nil)
	end)

	test("eventParty starts the requested chat monitor or stops it", function()
		local calls = {}
		local env = loadProject({
			include = function() end,
			print = function() end,
			EventMonitorStart = function(name, event) calls[#calls + 1] = name .. ":" .. event end,
			EventMonitorStop = function(name) calls[#calls + 1] = name .. ":stop" end,
		}, "classes/party.lua")
		env.eventParty("start")
		env.eventParty("start", true)
		env.eventParty("stop")
		assert(table.concat(calls, "|") == "pm1:CHAT_MSG_PARTY|pm1:CHAT_MSG_WHISPER|pm1:stop")
	end)

	test("petupdate refreshes the pet pawn and names the supported pets", function()
		local env = loadProject({
			CLASS_WARRIOR = 1, CLASS_SCOUT = 2, CLASS_ROGUE = 3, CLASS_MAGE = 4, CLASS_KNIGHT = 6,
			player = { Address = 100 },
			addresses = { game_root = { pawn = { pet_ptr = 8 } } },
			getProc = function() return 4 end,
			memoryReadRepeat = function(kind, proc, address)
				assert(kind == "uint" and proc == 4 and address == 108)
				return 200
			end,
			CPawn = function(address) return { Address = address } end,
			GetIdName = function(id) return "Pet " .. id end,
		}, "classes/pet.lua")
		env.petupdate()
		assert(env.pet.Address == 200 and #env.pettable == 4)
		assert(env.pettable[2].name == "Pet 102325" and env.pettable[2].skillid == 493344)
	end)
end
