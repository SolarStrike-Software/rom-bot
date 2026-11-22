return function(test, loadProject)
	local function fixture(dualClass)
		local rangeReads = {}
		local ranges = {
			[1000] = 2000, [1004] = 2064,
			[1008] = 3000, [1012] = 3032,
			[1020] = 4000, [1024] = 4032,
		}
		local ids = { [2000] = 41, [2032] = 42, [3000] = 43, [4000] = 44 }
		local names = { [41] = "Fireball", [42] = "Strike", [43] = "Volley", [44] = "Focus Shot" }
		local resources = {
			[4100] = 11, [4104] = 10, [4108] = 12, [4112] = 3,
			[4200] = 14, [4204] = 5, [4208] = 0,
			[4300] = 17, [4304] = 2, [4308] = 0,
			[4400] = 13, [4404] = 7, [4408] = 16, [4412] = 1,
		}
		local env = loadProject({
			settings = { options = {}, profile = { options = {} } },
			player = { Class2 = dualClass and 2 or 0, Level = 60 },
			MemDatabase = { forceLoadSkills = function() end },
			addresses = {
				skillbook = {
					base = 1000, offset = 0, tabinfo_size = 8,
					book1_start = 0, book1_end = 4, book2_start = 20, book2_end = 24,
					skill = { size = 32, name = 2, tp_to_level = 5, level = 6, required_level = 7 },
				},
				skill = { uses = 0 },
			},
			SKILLUSES_MANA = 11, SKILLUSES_RAGE = 12, SKILLUSES_FOCUS = 13,
			SKILLUSES_ENERGY = 14, SKILLUSES_ITEM = 15, SKILLUSES_PROJECTILE = 16,
			SKILLUSES_ARROW = 17, SKILLUSES_PSI = 18,
			memoryReadInt = function(_, address)
				return ({ [5] = 20, [2006] = 50, [2007] = 55 })[address]
			end,
			GetIdName = function(id) return assert(names[id]) end,
			GetItemAddress = function(id) return id * 100 end,
		}, "functions.lua")
		env.getProc = function() return 4 end
		env.getBaseAddress = function(base) return base end
		env.memoryReadRepeat = function(kind, proc, address)
			assert(proc == 4)
			if kind == "uint" then
				rangeReads[#rangeReads + 1] = address
				return assert(ranges[address], "Unexpected tab address")
			end
			assert(kind == "int")
			return assert(ids[address] or resources[address], "Unexpected skill or resource address")
		end
		return env.GetSkillBookData, rangeReads
	end

	test("GetSkillBookData maps single-class records to tabs 2 and 4", function()
		local read, ranges = fixture(false)
		local skills = read()
		assert(skills.Fireball.skilltab == 2 and skills.Fireball.skillnum == 1)
		assert(skills.Strike.skilltab == 2 and skills.Strike.skillnum == 2)
		assert(skills.Volley.skilltab == 4 and skills.Volley.skillnum == 1)
		assert(skills["Focus Shot"] == nil)
		assert(table.concat(ranges, "|") == "1000|1004|1008|1012")
	end)

	test("GetSkillBookData reads the separate secondary-class tab", function()
		local read, ranges = fixture(true)
		local skills = read()
		assert(skills.Fireball.skilltab == 2 and skills.Volley.skilltab == 4)
		assert(skills["Focus Shot"].skilltab == 3 and skills["Focus Shot"].skillnum == 1)
		assert(table.concat(ranges, "|") == "1000|1004|1020|1024|1008|1012")
	end)

	test("GetSkillBookData returns resource costs and consumable fields", function()
		local read = fixture(true)
		local skills = read()
		local fireball = skills.Fireball
		assert(fireball.Id == 41 and fireball.Address == 2000 and fireball.BaseItemAddress == 4100)
		assert(fireball.TPToLevel == 20 and fireball.Level == 50 and fireball.aslevel == 55)
		assert(math.abs(fireball.Mana - 60) < 1e-10 and fireball.Rage == 3)
		assert(skills.Strike.Energy == 5 and skills.Strike.Consumable == nil)
		assert(skills.Volley.Consumable == "arrow" and skills.Volley.ConsumableNumber == 2)
		local focusShot = skills["Focus Shot"]
		assert(focusShot.Focus == 7 and focusShot.Consumable == "projectile" and focusShot.ConsumableNumber == 1)
	end)

	local function assertSameSkills(actual, expected)
		for name, expectedSkill in pairs(expected) do
			local skill = assert(actual[name], "Missing skill: " .. name)
			for field, value in pairs(expectedSkill) do
				assert(skill[field] == value, name .. "." .. field)
			end
			for field in pairs(skill) do
				assert(expectedSkill[field] ~= nil, "Unexpected field: " .. name .. "." .. field)
			end
		end
		for name in pairs(actual) do
			assert(expected[name], "Unexpected skill: " .. name)
		end
	end

	test("GetSkillBookData ignores tab selections for both class layouts", function()
		for _, dualClass in ipairs({ false, true }) do
			local read, ranges = fixture(dualClass)
			local expected = read()
			local expectedRanges = table.concat(ranges, "|")
			for _, tabs in ipairs({ 2, "3", { 4 }, {} }) do
				read, ranges = fixture(dualClass)
				assertSameSkills(read(tabs), expected)
				assert(table.concat(ranges, "|") == expectedRanges)
			end
		end
	end)
end
