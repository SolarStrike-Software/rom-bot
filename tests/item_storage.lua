return function(test, loadProject)
	local function fixture()
		return loadProject({
			class = function() return {} end,
			include = function() end,
			ITEM_REUSE_DELAY = 5,
			os = { clock = function() return 100 end },
		}, "classes/inventory.lua", "classes/bank.lua", "classes/equipment.lua")
	end

	local function item(count, available, movedAt, inUse)
		return {
			Id = 101, Name = "Healing Potion", ItemCount = count, Available = available,
			LastMovedTime = movedAt, InUse = inUse, update = function() end,
		}
	end

	test("getInventoryRange maps inventory, bank, and equipment slots", function()
		local env = fixture()
		for _, case in ipairs({
			{ "BAG1", 60, 89, "inventory" },
			{ "bank2", 41, 80, "bank" },
			{ "main hand", 15, 15, "equipment" },
		}) do
			local first, last, location = env.getInventoryRange(case[1])
			assert(first == case[2] and last == case[3] and location == case[4])
		end
	end)

	test("CInventory finds the smallest usable stack and returns all matches", function()
		local env = fixture()
		local large, small = item(9, true, 0), item(3, true, 0)
		local inventory = setmetatable({
			MaxSlots = 4,
			BagSlot = {
				[0] = large, small, item(1, true, 98), item(1, true, 0, true), item(1, false, 0),
			},
		}, { __index = env.CInventory })
		local found, matches = inventory:findItem("^Healing", nil, true)
		assert(found == small and #matches == 2 and matches[1] == large and matches[2] == small)
		assert(inventory:findItem(101, nil, true) == small)
		found, matches = inventory:findItem("Missing")
		assert(found == nil and matches == nil)
		env.inventory = inventory
		assert(inventory:itemTotalCount(101) == 14)
	end)

	test("CBank finds available stacks and totals their item counts", function()
		local env = fixture()
		local large, small = item(7, true, 0), item(2, true, 0)
		local slot = { large, small, item(1, false, 0) }
		env.bank = setmetatable({ BagSlot = slot }, { __index = env.CBank })
		env.getInventoryRange = function() return 1, 3, "bank" end
		assert(env.bank:findItem("Healing Potion", "bank1") == small)
		assert(env.bank:itemTotalCount(101, "bank1") == 9)
	end)

	test("CEquipment refreshes ammunition and checks equipped durability", function()
		local env = fixture()
		local updates = 0
		local function update() updates = updates + 1 end
		local weapon = { Durability = 30, MaxDurability = 40, Empty = false, update = update }
		local equipment = setmetatable({
			BagSlot = { [9] = { ItemCount = 17, update = update }, [15] = weapon },
		}, { __index = env.CEquipment })
		assert(equipment:getAmmunitionCount() == 17)
		assert(equipment:getDurability() == 75)
		assert(equipment:isEquipped("main hand"))
		weapon.Durability = 0
		assert(not equipment:isEquipped("main hand"))
		weapon.Durability, weapon.Empty = 30, true
		assert(not equipment:isEquipped("main hand") and updates == 5)
	end)
end
