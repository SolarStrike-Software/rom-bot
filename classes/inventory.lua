include("item.lua");


CInventory = class(
	function (self)
		self.BagSlot = {}
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
	if item.Id == 0 then
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
	
	-- use it
	item:use();
end

function CInventory:getMainHandDurability()
    local durability, durabilityMax = RoMScript("GetInventoryItemDurable('player', 15);");
	return durability/durabilityMax;
end

-- Parse from |Hitem:7efa5|h|cffffffff[Qufdsfdsickness I]|r|h
-- hmm, i whonder if we could get more information out of it than id, color and name.
function CInventory:parseItemLink(itemLink)
	if itemLink == "" or itemLink == nil then
		return;
 	end
	id = tonumber(string.sub(itemLink, 8, 12), 16);  -- Convert to decimal
	color = string.sub(itemLink, 19, 24);
	-- this is causing some problems so lets be safe
	name_parse_from = string.find(itemLink, '[\[]');
	name_parse_to = string.find(itemLink, '[\]]');
	name = "Error parsing name";
	if not name_parse_from == nil or not name_parse_to == nil then
		name = string.sub(itemLink, name_parse_from+1, name_parse_to-1);
	end
	return id, color, name;
end

-- Update one slot, get item id, bagId, name, itemCount, color
function CInventory:updateBagSlot(slotNumber)
	local itemLink, bagId, icon, name, itemCount = RoMScript("GetBagItemLink(GetBagItemInfo("..slotNumber..")),GetBagItemInfo("..slotNumber..")");

	self.BagSlot[slotNumber] = CItem();

	if( settings.profile.options.DEBUG_INV) then	
		local msg;
		if(slotNumber) then msg = "DEBUG - "..slotNumber..": "; end;
		if(itemLink) then msg = msg.."/"..itemLink; end;
		if(name) then msg = msg.."/"..name.."/"; end;
		cprintf(cli.lightblue, msg);				-- Open/eqipt item:
	end;
	
	if (itemLink ~= "") then
		local id, color = self:parseItemLink(itemLink);

		if( settings.profile.options.DEBUG_INV) then	
			if(id) then msg = id; end;
			if(bagId) then msg = msg.."/"..bagId; end;
			if(itemCount) then msg = msg.."/"..itemCount; end;
			if(color) then msg = msg.."/"..color; end;
			cprintf(cli.lightblue, msg.."\n");				-- Open/eqipt item:
		end

		self.BagSlot[slotNumber].Id = id			     -- The real item id
		self.BagSlot[slotNumber].BagId = bagId;          -- GetBagItemLink and other RoM functins need this..
    	self.BagSlot[slotNumber].Name = name;
    	self.BagSlot[slotNumber].ItemCount = itemCount;  -- How many?
    	self.BagSlot[slotNumber].Color = color; 		 -- Rarity
	end
end

-- Make a full update
-- or update slot 1 to _maxslot
function CInventory:update(_maxslot)
	if( not _maxslot ) then _maxslot = settings.profile.options.INV_MAX_SLOTS; end;

	printf(language[1000], _maxslot);  -- Updating
	
	for slotNumber = 1, _maxslot, 1 do
		self:updateBagSlot(slotNumber);
		--printf(".");
		displayProgressBar(slotNumber/_maxslot*100, 50);
	end
	printf("\n");
end

-- uses romscript
function CInventory:getItemCount(itemId)
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
 	local bestItem = CItem();
 	local bestFound;
 	for slot,item in pairs(self.BagSlot) do
		for num,consumable in pairs(database.consumables) do
			if consumable.Type == type and 
			   consumable.Level <= player.Level  then
				if item.Id == consumable.Id and
				   item.ItemCount > 0 then			-- use only if some available
					if consumable.Level > bestLevel then
						bestLevel = consumable.Level;
						bestItem = item;
						bestFound = true;
					end
		        end
			end
		end
	end
	if (bestFound) then
		return bestItem;
	else
		return false;
	end
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
 	    
 	    storeItemId, storeItemColor, storeItemName = self:parseItemLink(storeItemLink);
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
end

function CInventory:deleteItemInSlot(slot)
 	self.BagSlot[slot]:delete();
end


-- TODO: banking functions
-- TODO: loot filter functions
-- TODO: keeping inventory slots open