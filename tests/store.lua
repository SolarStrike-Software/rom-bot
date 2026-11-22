return function(test, loadProject)
	local function shopFixture(heap, isOpen, targetType)
		local requests, waits = {}, {}
		local target = { Id = 10, Type = targetType, exists = function() return true end }
		local env = loadProject({
			class = function() return {} end,
			player = { getTarget = function() return target end },
			PT_NPC = 1,
			RoMScript = function(command)
				assert(command == "StoreFrame:IsVisible()")
				return isOpen
			end,
			RoMCode = function(command)
				assert(#requests < 3, "Unexpected extra purchase request")
				requests[#requests + 1] = command
			end,
			yrest = function(ms) waits[#waits + 1] = ms end,
			printf = function() end,
			language = { [1001] = "Shopping" },
		}, "classes/store.lua")
		local shop = setmetatable({
			Id = 10,
			Item = { { Id = 101, Name = "Potion", MaxHeap = heap } },
		}, { __index = env.CStore })
		return shop, requests, waits
	end

	test("shop rejects missing or zero stack sizes", function()
		for _, input in ipairs({ {}, { 0 } }) do
			local shop, requests = shopFixture(input[1], true, 1)
			assert(shop:buyItem(101, 12) == false and #requests == 0)
		end
	end)

	test("shop rejects closed stores and non-NPC targets", function()
		for _, condition in ipairs({ { false, 1 }, { true, 2 } }) do
			local shop, requests = shopFixture(5, condition[1], condition[2])
			assert(shop:buyItem(101, 12) == false and #requests == 0)
		end
	end)

	test("shop splits purchases into stack-sized batches", function()
		local shop, requests, waits = shopFixture(5, true, 1)
		assert(shop:buyItem("Potion", 12) == true)
		assert(table.concat(requests, "|") == "StoreBuyItem(1,5)|StoreBuyItem(1,5)|StoreBuyItem(1,2)")
		assert(table.concat(waits, "|") == "1000|1000|1000")
	end)
end
