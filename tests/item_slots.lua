return function(test, loadProject)
	local function fixture(stubs)
		stubs.class = function() return {} end
		stubs.include = function() end
		stubs.CItem = stubs.CItem or {}
		return loadProject(stubs, "classes/bankitem.lua", "classes/equipmentitem.lua",
			"classes/guildbank.lua", "classes/guildbankitem.lua", "classes/inventoryitem.lua")
	end

	test("Bank and inventory item pages check fixed and rented slots", function()
		local reads, rented = {}, -1
		local env = fixture({
			addresses = { inventory = { rent = { base = 100, offset = 12, bank_offset = 20 } } },
			getProc = function() return 4 end,
			getBaseAddress = function(base) return base + 1000 end,
			memoryReadIntPtr = function(proc, base, offset)
				assert(proc == 4 and base == 1100)
				reads[#reads + 1] = offset
				return rented
			end,
		})
		assert(env.CBankItem:isPageAvailable(1) and not env.CBankItem:isPageAvailable(6))
		assert(env.CInventoryItem:isPageAvailable(1) and env.CInventoryItem:isPageAvailable(2))
		assert(not env.CInventoryItem:isPageAvailable(7) and #reads == 0)
		assert(not env.CBankItem:isPageAvailable(3))
		rented = 0
		assert(env.CInventoryItem:isPageAvailable(4))
		assert(table.concat(reads, "|") == "36|16")
	end)

	test("CEquipmentItem refreshes its slot and uses the equipped ammo count", function()
		local env = fixture({
			settings = { profile = { options = {} } },
			addresses = { equipment = { base = 100 }, inventory = { item = { size = 20 } },
				item = { ammo_count = 4 } },
			getProc = function() return 4 end,
			getBaseAddress = function(base) return base + 1000 end,
			CItem = { update = function(self)
				assert(self.Address == 1280)
				self.ItemCount = 1
			end },
			memoryReadInt = function(proc, address)
				assert(proc == 4 and address == 1284)
				return 17
			end,
		})
		local item = setmetatable({ BagId = 9 }, { __index = env.CEquipmentItem })
		item:update()
		assert(item.ItemCount == 17)
	end)

	test("Guild bank counts items only while open and refreshes slot addresses", function()
		local open, refreshed = false, 0
		local env = fixture({
			settings = { profile = { options = {} } },
			addresses = { staticGuildBankBase = 100, guildBankOpen_offset = 8 },
			getProc = function() return 4 end,
			print = function() end,
			memoryReadBytePtr = function(proc, base, offset)
				assert(proc == 4 and base == 100 and offset == 8)
				return open and 1 or 0
			end,
			getInventoryRange = function() return 101, 101, "guildbank" end,
			CItem = { update = function(self)
				assert(self.Address == 2016)
				refreshed = refreshed + 1
				self.Id, self.ItemCount = 42, 7
			end },
		})
		local item = setmetatable({ BagId = 101 }, { __index = env.CGuildbankItem })
		env.guildbank = setmetatable({
			PageAddresses = { 1000, 2000 }, BagSlot = { [101] = item },
			updatePageAddresses = function() return true end,
		}, { __index = env.CGuildbank })
		item:update()
		assert(item.Available == false and env.guildbank:itemTotalCount(42) == 0 and refreshed == 0)
		open = true
		assert(env.guildbank:itemTotalCount(42, "guildbank2") == 7)
		assert(item.Available and refreshed == 1)
	end)
end
