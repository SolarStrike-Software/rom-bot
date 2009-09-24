include("item.lua");


CInventory = class(
	function (self)
		self.BagSlot = {} 
		for slotNumber = 1, settings.profile.options.INV_MAX_SLOTS, 1 do
			self.BagSlot[slotNumber] = CItem(slotNumber);
		end
		
		self.NextItemToUpdate = 1;
		
	end
)


function CInventory:getAmmunitionCount()
	local count = RoMScript("GetInventoryItemCount('player', 9);");
	if count == nil then
		count = 0;
	end
	return count;
end

 
-- return is true or false. false if there was no ammunition in the bag, type is "thrown" or "arrow"
function CInventory:reloadAmmunition(type) 
	item = self:bestAvailableConsumable(type);
	-- if theres no ammunition, open a ammunition bag
	if not item then
		if type == "arrow" then
			openItem = self:bestAvailableConsumable("arrow_quiver");
		elseif type == "thrown" then
			openItem = self:bestAvailableConsumable("thrown_bag");
		end
		
		if not openItem then
			return false;
		end
		
		openItem:use();
		
		-- after opening, update the inventory (this takes about 10 sec)
		self:update();
		
		item = self:bestAvailableConsumable(type);
	end
	
	if item then
		-- use it
		item:use();
	end
end

function CInventory:getMainHandDurability()
    local durability, durabilityMax = RoMScript("GetInventoryItemDurable('player', 15);");
	return tonumber(durability)/tonumber(durabilityMax);
end

-- Make a full update
-- or update slot 1 to _maxslot
function CInventory:update(_maxslot)
	if( not _maxslot ) then _maxslot = settings.profile.options.INV_MAX_SLOTS; end;

	printf(language[1000], _maxslot);  -- Updating
	
	keyboardSetDelay(0);
	for slotNumber = 1, _maxslot, 1 do
		self.BagSlot[slotNumber]:update();
		displayProgressBar(slotNumber/_maxslot*100, 50);
	end
	printf("\n");
	keyboardSetDelay(50);
	
	player.InventoryDoUpdate = false;			-- set back update trigger
	player.InventoryLastUpdate = os.time();		-- remember update time

	--cprintf(cli.green, language[1002], settings.profile.options.INV_UPDATE_INTERVAL );	-- inventory update not later then
	
end


-- update x slots until given time in ms is gone
function CInventory:updateSlotsByTime(_ms)
local start_update = getTime();

	keyboardSetDelay(0);
	while ( deltaTime(getTime(), start_update ) < _ms ) do
		self:updateNextSlot();
	end
	keyboardSetDelay(50);

end

-- update x slots
function CInventory:updateNextSlot(_times)

	if(not _times) then _times = 1; end
	
	for i = 1, _times do
		local item = self.BagSlot[self.NextItemToUpdate];

--		if( settings.profile.options.DEBUG_INV) then	
--			local msg = "";
--			msg = "DEBUG updateNextSlot(): Slot #"..self.NextItemToUpdate..": ";
--			if(item.Name) then 
--				msg = msg.." name "..item.Name; 
--			else
--				msg = msg.." name ".." <Slot Empty>"; 
--			end;
--			if(item.ItemCount) then msg = msg.." ItemCount:"..item.ItemCount; end;
--			cprintf(cli.lightblue, "%s\n", msg);				
--		end;

		self.BagSlot[self.NextItemToUpdate]:update();
		self.NextItemToUpdate = self.NextItemToUpdate + 1;
		if (self.NextItemToUpdate > settings.profile.options.INV_MAX_SLOTS) then
			player.InventoryLastUpdate = os.time();		-- remember last completed round time
			self.NextItemToUpdate = 1;
		end

	end
	
end

-- uses romscript, its 
function CInventory:getItemCount(itemId)
	if(itemId == nil) then
		cprintf(cli.yellow, "Inventory:getItemCount with itemId=nil, please (do not) inform the developers.\n" );	
		return 0;
	end

	itemCount = RoMScript("GetBagItemCount("..itemId..")");
	return tonumber(itemCount);
end

-- uses pre existing information
function CInventory:itemTotalCount(itemNameOrId)
	totalCount = 0;
 	for slot,item in pairs(self.BagSlot) do
	    if item.Id == itemNameOrId or item.Name == itemNameOrId then
			totalCount = totalCount+item.ItemCount;
		end
	end
	return totalCount;
end

function CInventory:useItem(itemNameOrId)
	for slot,item in pairs(self.BagSlot) do
		if item.Id == itemNameOrId or item.Name == itemNameOrId then
			item:use();
			return true, item.Id, item.Name;
		end
	end
	return false
end

-- Returns item name or false, takes in type, example: "healing" or "mana" or "arrow" or "thrown"
function CInventory:bestAvailableConsumable(type)
	local bestLevel = 0;
	local bestItem = false;
	local bestSmallStack = 999;
	local select_strategy;
	local select_strategy_best = "best";
	local select_strategy_minstack = "minstack";
	local select_strategy_default = "best";


	-- set select strategy
	if( type == "mana" ) then
		if( settings.profile.options.USE_MANA_POTION == select_strategy_minstack ) then
			select_strategy = select_strategy_minstack;
		else
			select_strategy = select_strategy_default;
		end
	elseif(type == "healing" ) then
		if( settings.profile.options.USE_HP_POTION == select_strategy_minstack ) then
			select_strategy = select_strategy_minstack;
		else
			select_strategy = select_strategy_default;
		end
	else
		select_strategy = select_strategy_default;	-- default = 'best'
	end


	-- check item slots slot by slot
	for slot,item in pairs(self.BagSlot) do
		local consumable = database.consumables[item.Id];		

		if( consumable  and							-- item in database
		    consumable.Type == type and	 			-- right type (mana, arrow, ...)
		 	consumable.Level <= player.Level and	-- level ok
		 	item.ItemCount > 0 ) then				-- use only if some available

			if( select_strategy == select_strategy_minstack ) then
				-- select smallest stack
				if item.ItemCount < bestSmallStack then
					bestSmallStack = item.ItemCount;
					bestItem = item;
				end
			else
				-- select best available consumable (& smallest stack by default)
				if( consumable.Level > bestLevel and
					item.ItemCount < bestSmallStack ) then
					bestLevel = consumable.Level;
					bestSmallStack = item.ItemCount;
					bestItem = item;
				end
			end

		end

	end
	return bestItem;
end

-- Returns item name or false, takes in type, example: "healing" or "mana" or "arraw_quver" or "thrown_bag"
-- quantity is how many of them do we need, for example, for potions its 99 or 198
-- but for arraws it might be 1 or 2
function CInventory:storeBuyConsumable(type, quantity)
 	local bestLevel = 0;
 	for storeSlot = 1, 20, 1 do
 	    local storeItemLink, icon, name, storeItemCost = RoMScript("GetStoreSellItemLink("..storeSlot.."),GetStoreSellItemInfo("..storeSlot..")");

		if (storeItemLink == "" or storeItemLink == nil) then
 	        break;
 	    end
 	    
 	    storeItemId, storeItemColor, storeItemName = CItem:parseItemLink(storeItemLink);
 		-- print(storeItemName);
 	    
		for num,consumable in pairs(database.consumables) do
		    if consumable.Type == type and consumable.Level <= player.Level then
		        if consumable.Id == storeItemId then
		            if consumable.Level > bestLevel then
		                bestLevel = consumable.Level;
		                bestItem = storeItemId;
		                bestItemSlot = storeSlot;
					end
		        end
			end
		end
	end

	if bestLevel == 0 then
	    return false;
 	end

 	
	if self:getItemCount(bestItem) < quantity then
	    numberToBuy = quantity - self:itemTotalCount(bestItem);
	    printf(language[1001]);  -- Shopping
	    for i = 1, numberToBuy, 1 do
	    	RoMScript("StoreBuyItem("..bestItemSlot..")");
	    	printf(".");
		end
		printf("\n");
	end
	
	return true;
end

function CInventory:deleteItemInSlot(slot)
 	self.BagSlot[slot]:delete();
end


-- TODO: banking functions
-- TODO: loot filter functions
-- TODO: keeping inventory slots open