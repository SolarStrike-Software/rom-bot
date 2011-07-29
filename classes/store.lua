CStore = class(
	function( self )
		self.Name = "<UNKNOWN>"
		self.Id = 0
		self.Item = {}

		player:update()
		if player:getTarget() then
			self:update()
		end
	end
)

function CStore:update()
	player:update()
	local target = player:getTarget()

	-- NPC not targeted
	if target.Type ~= PT_NPC then
		return
	end

	-- store not open
	if not RoMScript("StoreFrame:IsVisible()") then
		return
	end

	-- Already holds info on this store. No need update
	if self.Id == target.Id then
		return
	end

	self.Id = target.Id
	self.Name = target.Name

	-- number of items in store
	local sellItems = RoMScript("GetStoreSellItems()")

	-- get item data
	self.Item = {}
	for i = 1, sellItems do
		self.Item[i] = {}
		local __, name, price, __, __, __, maxheap = RoMScript("GetStoreSellItemInfo(".. i ..")")
		local id = parseItemLink(RoMScript("GetStoreSellItemLink(".. i ..")"));
		self.Item[i].Name = name
		self.Item[i].Price = price
		self.Item[i].MaxHeap = maxheap
		self.Item[i].Id = id
	end

	-- Is there a repair button.
	self.CanRepair = RoMScript("IsStoreCanFix()")
end

-- buys 'quantity' of items by name, id or shop index.
function CStore:buyItem(nameIdOrIndex, quantity)
	if quantity == nil then
		-- Assume they want to buy 1
		quantity = 1
	end

	self:update()

	-- First find the store index number
	local buyIndex = 0
	if type(nameIdOrIndex) == "number" and nameIdOrIndex <= #self.Item then
		-- buying by index
		buyIndex = nameIdOrIndex
	elseif type(nameIdOrIndex) == "number" or type(nameIdOrIndex) == "string" then
		-- buying by id or name, search for id or name
		for i,item in pairs(self.Item) do
			if nameIdOrIndex == item.Id or nameIdOrIndex == item.Name then
				buyIndex = i
				break
			end
		end
	else
		printf(cli.yellow,"Wrong first argument to 'store:BuyItem'.")
		return false
	end

	if buyIndex == 0 then
		-- Item not found
		return false
	end

	-- Then get the maxheap
	buyMaxHeap = self.Item[buyIndex].MaxHeap

	-- Buy the item/s
	printf(language[1001]);  -- Shopping
	repeat
		if quantity > buyMaxHeap then
			RoMScript("StoreBuyItem(" .. buyIndex .. "," .. buyMaxHeap .. ")")
			quantity = quantity - buyMaxHeap
		else
			RoMScript("StoreBuyItem(" .. buyIndex .. "," .. quantity .. ")")
			quantity = 0
		end
		printf(" .")
		yrest(1000)
	until quantity == 0
	printf("\n")

	return true
end

-- Returns item name or false, takes in type, example: "hot" or "mot" or "arraw_quver" or "thrown_bag"
-- quantity is how many of them do we need, for example, for potions its 99 or 198
-- but for arraws it might be 1 or 2
-- type: hot|mot|arrow_quiver|thrown_bag|poison
function CStore:buyConsumable(type, quantity)
	if quantity == nil or quantity == "" then
		return
	end

	self:update()

	-- Find best store item
	local bestLevel = 0;
	for i,item in pairs(self.Item) do
		local storeItemId = item.Id

		local consumable = database.consumables[storeItemId];

		if( consumable
		  and consumable.Type == type
		  and consumable.Level <= player.Level ) then
			if consumable.Level > bestLevel then
				bestLevel = consumable.Level;
				bestItem = item.Id;
				bestItemSlot = i;
			end
		end
	end

	if bestLevel == 0 then
	    return false;
 	end

	-- Count number of better items in inventory
	inventory:update();

	local totalCount = 0;
 	for slot,item in pairs(inventory.BagSlot) do
		local consumable = database.consumables[item.Id];
	    if item.Available and
		  consumable and
		  consumable.Type == type and
		  consumable.Level >= bestLevel and
		  consumable.Level <= player.Level then
			totalCount = totalCount + item.ItemCount
		end;
	end;

	-- See how many needed
	if totalCount < quantity then
	    numberToBuy = quantity - totalCount;
		self:buyItem(bestItemSlot, numberToBuy)
	end

	return true;
end
