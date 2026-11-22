return function(test, loadProject)
	local function fixture(stubs)
		stubs.class = function() return {} end
		local env = loadProject(stubs, "classes/pawn.lua")
		return setmetatable({}, { __index = env.CPawn }), env
	end

	test("CPawn finds buffs by name or ID and checks stack thresholds", function()
		local pawn = fixture({})
		local focus = { Id = 101, Name = "Focus", Count = 3 }
		local refreshes = 0
		pawn.updateBuffs = function(self)
			refreshes = refreshes + 1
			self.Buffs = { focus }
		end
		assert(pawn:getBuff("Absent,Focus", 3) == focus)
		assert(pawn:getBuff({ 101 }) == focus)
		assert(pawn:getBuff("101", 4) == false)
		local found, count = pawn:hasBuff("Focus")
		assert(found == true and count == 3)
		found, count = pawn:hasDebuff("Absent")
		assert(found == false and count == 0 and refreshes == 5)
	end)

	test("parseBuffName decodes numeric and Roman stack suffixes", function()
		local _, env = fixture({})
		for _, case in ipairs({ { "Focus (3)", 3 }, { "Focus 7", 7 }, { "Focus IV", 4 }, { "Focus", 1 } }) do
			local name, count = env.parseBuffName(case[1])
			assert(name == "Focus" and count == case[2])
		end
		assert(select("#", env.parseBuffName(nil)) == 0)
	end)

	test("CPawn refreshes coordinates and keeps values when a read fails", function()
		local reads = {}
		local pawn = fixture({
			addresses = { game_root = { pawn = { x = 4, y = 8, z = 12 } } },
			getProc = function() return 9 end,
			memoryReadRepeat = function(kind, proc, address)
				assert(kind == "float" and proc == 9)
				reads[#reads + 1] = address
				return ({ [104] = 10, [112] = 0 })[address]
			end,
		})
		pawn.Address, pawn.X, pawn.Y, pawn.Z = 100, 1, 2, 3
		pawn:updateXYZ()
		assert(pawn.X == 10 and pawn.Y == 2 and pawn.Z == 0)
		assert(table.concat(reads, "|") == "104|108|112")
		pawn.Address = 0
		pawn:updateXYZ()
		assert(pawn.X == 0 and pawn.Y == 0 and pawn.Z == 0 and #reads == 3)
	end)

	test("CPawn refreshes, retains, or clears its target pointer", function()
		local memory = { [104] = 200, [208] = 101 }
		local pawn = fixture({
			addresses = { game_root = { pawn = { target = 4, id = 8 } } },
			getProc = function() return 9 end,
			memoryReadRepeat = function(kind, proc, address)
				assert(kind == "uint" and proc == 9)
				return memory[address]
			end,
		})
		pawn.Address, pawn.TargetPtr = 100, 0
		pawn:updateTargetPtr()
		assert(pawn.TargetPtr == 200)
		memory[104] = 0
		pawn:updateTargetPtr()
		assert(pawn.TargetPtr == 200)
		memory[208] = 1000000
		pawn:updateTargetPtr()
		assert(pawn.TargetPtr == 0)
	end)
end
