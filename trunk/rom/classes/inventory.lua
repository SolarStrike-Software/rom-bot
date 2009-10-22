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

	-- prevent aritmetic on a nil value if RoMScript failed/wrong values come back
	if( type(durability) ~= "number" or  
		type(durabilityMax) ~= "number" 
		or durabilityMax == 0) then
		return 1
	end

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
	local bestLevel = 0;		-- required player level of a potion
	local bestPotency = 0;		-- power of a potion
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
			else	-- select best available consumable (& smallest stack by default)
				-- select better level
				if( consumable.Level > bestLevel  ) then
					bestLevel = consumable.Level;
					bestPotency = consumable.Potency;
					bestSmallStack = item.ItemCount;
					bestItem = item;
				-- same level but select better potency
				elseif( consumable.Level == bestLevel  and
				  		consumable.Potency > bestPotency) then
					bestLevel = consumable.Level;
					bestPotency = consumable.Potency;
					bestSmallStack = item.ItemCount;
					bestItem = item;
				-- same/same but select smaller stack
				elseif( consumable.Level == bestLevel  and
						consumable.Potency == bestPotency  and
						item.ItemCount < bestSmallStack ) then
					bestLevel = consumable.Level;
					bestPotency = consumable.Potency;
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
-- type: healing|mana|arrow_quiver|thrown_bag|poison
function CInventory:storeBuyConsumable(type, quantity)
	local bestLevel = 0;
	for storeSlot = 1, 20, 1 do
		local storeItemLink, icon, name, storeItemCost = RoMScript("GetStoreSellItemLink("..storeSlot.."),GetStoreSellItemInfo("..storeSlot..")");

		if (storeItemLink == "" or storeItemLink == nil) then
			break;
		end
		
		storeItemId, storeItemColor, storeItemName = CItem:parseItemLink(storeItemLink);
--		printf("%s %s\n", storeItemId, storeItemName);

		local consumable = database.consumables[storeItemId];

		if( consumable 
		  and consumable.Type == type 
		  and consumable.Level <= player.Level ) then
			if consumable.Level > bestLevel then
				bestLevel = consumable.Level;
				bestItem = storeItemId;
				bestItemSlot = storeSlot;
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


function CInventory:autoSell()

	if( settings.profile.options.INV_AUTOSELL_ENABLE ~= true ) then
		return false
	end

	-- warning if not all inventory slots are updated
	if( settings.profile.options.INV_AUTOSELL_TOSLOT > settings.profile.options.INV_MAX_SLOTS ) then
		cprintf(cli.yellow, language[1003], settings.profile.options.INV_MAX_SLOTS, settings.profile.options.INV_AUTOSELL_TOSLOT);
	end

	-- move color settings into table
	local hf_quality = string.gsub (settings.profile.options.INV_AUTOSELL_QUALITY, "%s*[;,]%s*", "\n");	-- replace ; with linefeed
	local hf_quality_table = stringExplode( "\n", hf_quality );	-- move colors to table

	local hf_ignore_table;
	-- move ignore list into table
	if( settings.profile.options.INV_AUTOSELL_IGNORE ) then
		local hf_ignore = string.gsub (settings.profile.options.INV_AUTOSELL_IGNORE, "%s*[;,]%s*", "\n");	-- replace ; with linefeed
		hf_ignore_table = stringExplode( "\n", hf_ignore );	-- move ignore list
	end

	--	ITEMCOLORS table is defined in item.lua
	local function sellColor(_itemcolor)
		
		for i,v in pairs(hf_quality_table) do
		
			if( ITEMCOLOR[string.upper(v)] == _itemcolor ) then
				return true
			end
		end
		
		return false
		
	end

	-- check if itemname or itemid is in the ignorelist
	local function isInIgnorelist(_item)
	
		if ( not hf_ignore_table ) then
			return false
		end
	
		for i,ignorelistitem in pairs(hf_ignore_table) do

			if( string.find( string.lower(_item.Name), string.lower(ignorelistitem), 1, true) or
				_item.ItemId == ignorelistitem ) then
				return true
			end

		end
		
		return false
		
	end
	
	local hf_wesell = false;
	-- check the given slot numbers to autosell
	for slotNumber = settings.profile.options.INV_AUTOSELL_FROMSLOT, settings.profile.options.INV_AUTOSELL_TOSLOT, 1 do
		local sell_item = true
		local slotitem = self.BagSlot[slotNumber];

		if( not slotitem  or  slotitem.Id == 0  or  slotitem.Id == nil) then
			sell_item = false;
		end

		-- check item quality color
		if( sellColor(slotitem.Color) == false ) then
			sell_item = false;
		end
		
		-- check itemname against ignore list
		if( isInIgnorelist(slotitem) == true ) then
			sell_item = false;
		end
		
		-- sell the item
		if( sell_item == true ) then
			hf_wesell = true;
			slotitem:use();
		end

	end
	
	if( hf_wesell == true ) then
		return true;
	else
		return false;
	end
	
end

function CInventory:getMount()
	-- Id of all mounts (except 15 minute, and 2 hour mounts)
    mounts = {
	203559,203556,203553,203568,203565,204942,204943,204941,204988,204987,202227,
	202230,202217,203297,203320,202229,202232,202226,203299,203322,204997,204998,
	204999,205748,205749,204279,204278,204277,204281,204280,203573,202452,202450,
	201966,203301,203324,202481,202473,202465,203309,203332,203288,203286,203290,
	203318,203341,204292,204293,204276,204295,204294,203571,201698,202246,202248,
	203296,203319,202479,202471,202463,203307,203330,202486,202478,202470,203314,
	203337,202480,202472,202464,203308,203331,204954,204955,204953,204994,204993,
	202461,202458,201927,203305,203328,204144,204142,204146,204148,204150,202484,
	202476,202468,203312,203335,204936,204937,204935,204984,204983,202482,202474,
	202466,203310,203333,204963,204964,204962,204972,204971,203287,203285,203289,
	203317,203340,204960,204961,204959,204948,204947,204939,204940,204938,204986,
	204985,203913,203914,203915,203968,203970,204286,204285,204287,204291,204290,
	202228,202231,202218,203298,203321,203669,203670,203671,203672,203673,204945,
	204946,204944,204990,204989,202456,202455,202454,203303,203326,202483,202475,
	202467,203311,203334,204930,204931,204929,204978,204977,204145,204143,204147,
	204149,204151,202485,202477,202469,203313,203336,202933,202931,202935,203315,
	203338,204933,204934,204932,204982,204979,203560,203557,203554,203569,203566,
	204084,204083,204085,202821,204072,202460,202457,201130,203304,203327,204951,
	204952,204950,204992,204991,202462,202459,201928,203306,203329,203674,203675,
	203676,203677,203678,203561,203558,203555,203570,203567,203572,202245,202095,
	202247,203300,203323,204969,204970,204968,204976,204975,202453,202451,201965,
	203302,203325,203562,203563,203564,203969,203971,204283,204282,204284,204289,
	204288,204966,204967,204965,204974,204973,202934,202932,202936,203316,203339,
	204957,204958,204956,204996,204995,201468 };

	print(self);
 	for slot,item in pairs(self.BagSlot) do
	    for i, mount in pairs(mounts) do
			if item.Id == mount then
				return item;
			end
		end
	end
	
	return false;
end