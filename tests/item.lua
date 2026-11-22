return function(test, loadProject)
	local function fixture(stubs, fields)
		stubs.class = function() return {} end
		local env = loadProject(stubs, "classes/item.lua")
		return setmetatable(fields, { __index = env.CItem }), env
	end

	test("CItem resolves its type hierarchy and rejects empty or unavailable items", function()
		local item = fixture({
			itemtypes = { [1] = { Name = "Weapons", [2] = {
				Name = "Ranged", [3] = { Name = "Bow", UniqueName = "Longbow" },
			} } },
		}, { Available = true, Empty = false, ObjType = 1, ObjSubType = 2, ObjSubSubType = 3 })
		assert(table.concat({ item:getTypes() }, "|") == "Weapons|Ranged|Bow|Longbow")
		assert(item:isType("Weapons") and item:isType("Bow") and item:isType("Longbow"))
		assert(item:isType("Armor") == false)
		item.Empty = true
		assert(item:getTypes() == false and item:isType("Bow") == false)
		item.Empty, item.Available = false, false
		assert(item:isType("Bow") == false)
	end)

	test("CItem maps known quality colors to their names", function()
		local item, env = fixture({}, {})
		item.Color = env.ITEMCOLOR.BLUE
		assert(item:getColorString() == "BLUE")
		item.Color = 0
		assert(item:getColorString() == false)
	end)

	test("CItem distinguishes cooldown values from unavailable cooldown data", function()
		local reads, remaining = 0, 2.5
		local item = fixture({
			RoMScript = function(command)
				assert(command == "GetBagItemCooldown(17)")
				reads = reads + 1
				return 10, remaining
			end,
		}, { BagId = 17 })
		local value, available = item:getRemainingCooldown()
		assert(value == 2.5 and available == true)
		remaining = 0
		value, available = item:getRemainingCooldown()
		assert(value == 0 and available == true)
		remaining = nil
		value, available = item:getRemainingCooldown()
		assert(value == 0 and available == false)
		item.BagId = nil
		value, available = item:getRemainingCooldown()
		assert(value == 0 and available == false and reads == 3)
	end)
end
