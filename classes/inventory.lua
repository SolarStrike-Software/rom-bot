include("memorytable.lua");
include("inventoryitem.lua");

-- Tooltip parser keywords
ITEM_TOOLTIP_DURABILITY = {
	DE		= "Haltbarkeit",
	FR		= "Structure",
	ENEU	= "Durability",
	ENUS	= "Durability",
	PH		= "Durability",
	RU		= "\143\224\174\231\173\174\225\226\236",
	PL		= "Trwa\136o\152\143",
	ES		= "Durabilidad",
	SA 		= "Durabilidad",
	ENAR 	= "Durability",
};

CInventory = class(
	function (self)
		RoMCode("ToggleBackpack() BagFrame:Hide()"); -- Make sure the client loads the tables first.
		RoMCode("GoodsFrame:Show() GoodsFrame:Hide()"); -- Make sure the client loads the tables first.

		self.MaxSlots = 240;
		self.BagSlot = {};
		self.Money = memoryReadInt( getProc(), addresses.moneyPtr );

		local timeStart = getTime();

		for slotNumber = 1, self.MaxSlots, 1 do
			self.BagSlot[slotNumber] = CInventoryItem( slotNumber );
		end

		if( settings.profile.options.DEBUG_INV ) then
			printf( "Inventory update took: %d\n", deltaTime( getTime(), timeStart ) );
		end;

		self.NextItemToUpdate = 1;
	end
);

function CInventory:update( _maxslot )

	self.Money = memoryReadInt( getProc(), addresses.moneyPtr );

	if( not _maxslot ) then _maxslot = self.MaxSlots; end;

	for slotNumber = 1, _maxslot, 1 do
		self.BagSlot[slotNumber]:update();
	end

end;

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
		if (self.NextItemToUpdate > self.MaxSlots) then
			self.NextItemToUpdate = 1;
		end;

	end;
end;

-- return is true or false. false if there was no ammunition in the bag, type is "thrown" or "arrow"
function CInventory:reloadAmmunition(type)
	local item = self:bestAvailableConsumable(type);
	-- if theres no ammunition, open a ammunition bag
	if not item then
		local openItem
		if type == "arrow" then
			openItem = self:bestAvailableConsumable("arrow_quiver");
		elseif type == "thrown" then
			openItem = self:bestAvailableConsumable("thrown_bag");
		end

		if not openItem then
			return false;
		end

		local checkItemName = openItem.Name;
		yrest(300);
		item = self:bestAvailableConsumable(type);
		if( item and checkItemName ~= item.Name ) then
			cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name)); -- NOTICE: Item mismatch
			openItem:update();
		else
			openItem:use();
			yrest( 500 ); --give time to server to respond with the opened item
		end

		item = self:bestAvailableConsumable(type);
	end

	if item then
		-- use it
		-- local unused,unused,checkItemName = RoMScript("GetBagItemInfo(" .. item.SlotNumber .. ")");
		local checkItemName = item.Name;
		item:update();
		if( checkItemName ~= item.Name ) then
			cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name)); -- NOTICE: Item mismatch
			item:update();
		else
			item:use();
		end
	end
end;

-- Here for compatibility reasons
function CInventory:getItemCount(itemId, range)
	if(itemId == nil) then
		cprintf(cli.yellow, "Inventory:getItemCount with itemId=nil, please (do not) inform the developers.\n" );
		return 0;
	end

	return self:itemTotalCount( itemId, range );
end;

-- No longer uses cached information, it updates before checking
function CInventory:itemTotalCount(itemNameOrId, range)
	local first, last, location = getInventoryRange(range) -- get bag slot range

	if location and location ~= "inventory" then
		print("inventory:itemTotalCount() only supports ranges in the inventory, eg. \"bags\",\"bag1\",\"bag2\",etc.")
		return
	end

	if first == nil then
		-- Default values - 1-240 for items, 61-240 for empties.
		if itemNameOrId == "<EMPTY>" or itemNameOrId == 0 then
			first = 61
		else
			first = 1
		end
		last = 240 -- default, search only bags
	end

	local item
	local totalCount = 0;
	for slot = first, last do
		item = inventory.BagSlot[slot]
		item:update()

 	    if item.Available and (item.Id == itemNameOrId or item.Name == itemNameOrId) then
			if itemNameOrId == "<EMPTY>" or itemNameOrId == 0 then -- so you can count empty slots
				totalCount = totalCount + 1
			else
				totalCount = totalCount + item.ItemCount;
			end
		end;
	end;

	return totalCount;
end;

function CInventory:findItem (itemNameOrIdOrPattern, range, usePattern)
	local itemList = {}
	local first, last, location = getInventoryRange(range) -- get bag slot range
	local smallestStack = nil
	local item

	if location ~= "inventory" and location ~= nil then
		printf("You can only use inventory ranges with 'inventory:findItem'. You cannot use '%s' which is in %s\n", range, location)
	end

	if type(itemNameOrIdOrPattern)=='number' then
		usePattern = false
	end

	if first == nil then
		first , last = 1, 240 -- default, search all
	end

	for slot = first, last do
		item = self.BagSlot[slot]
		item:update()
		if item.Available and (not item.InUse) and (usePattern and string.find (item.Name, itemNameOrIdOrPattern) or (item.Name == itemNameOrIdOrPattern or item.Id == itemNameOrIdOrPattern)) then
			if (os.clock() - item.LastMovedTime) > ITEM_REUSE_DELAY then
				-- Make table of matching items
				table.insert (itemList, item)
				-- find smallest stack
				if smallestStack == nil or smallestStack.ItemCount > item.ItemCount then
					smallestStack = item
				end
			end
		end
	end

	itemList = #itemList>0 and itemList or nil -- Make list nil if empty.

	return smallestStack, itemList
end

function CInventory:useItem(itemNameOrId)
	local item = self:findItem(itemNameOrId)
	if item then
		item:use();
		return true, item.Id, item.Name;
	end;

	return false;
end;

-- Make a full update
-- or update slot 1 to _maxslot
-- Returns item name or false, takes in type, example: "hot" or "mot" or "arrow" or "thrown"
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
	if( type == "mot" ) then
		if( settings.profile.options.USE_MANA_POTION == select_strategy_minstack ) then
			select_strategy = select_strategy_minstack;
		else
			select_strategy = select_strategy_default;
		end
	elseif(type == "hot" ) then
		if( settings.profile.options.USE_HP_POTION == select_strategy_minstack ) then
			select_strategy = select_strategy_minstack;
		else
			select_strategy = select_strategy_default;
		end
	else
		select_strategy = select_strategy_default;	-- default = 'best'
	end

	self:update();
	-- check item slots slot by slot
	for slot,item in pairs(self.BagSlot) do
		local consumable = database.consumables[item.Id];

		if( consumable  and							-- item in database
		    consumable.Type == type and	 			-- right type (mana, arrow, ...)
		 	consumable.Level <= player.Level and	-- level ok
		 	item.ItemCount > 0 and					-- use only if some available
			item.Available) then					-- not in unrented bag

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

-- Kept for backward compatibility. Use store:buyItem(nameIdOrIndex, quantity) instead
function CInventory:storeBuyItem(nameIdOrIndex, quantity)
	return store:buyItem(nameIdOrIndex, quantity)
end

-- Kept for backward compatibility. Use store:buyConsumable(type, quantity) instead
function CInventory:storeBuyConsumable(type, quantity)
	return store:buyConsumable(type, quantity)
end

function CInventory:deleteItemInSlot(slot)
 	self.BagSlot[slot]:delete();
end


function CInventory:autoSell(evalfunc)

	if( settings.profile.options.INV_AUTOSELL_ENABLE ~= true ) then
		return false
	end

	-- warning if not all inventory slots are updated
	if( settings.profile.options.INV_AUTOSELL_TOSLOT > self.MaxSlots ) then
		cprintf(cli.yellow, language[1003], self.MaxSlots, settings.profile.options.INV_AUTOSELL_TOSLOT);
	end

	-- warning if igf addon is missing
	if( bot.IgfAddon == false	and
		( settings.profile.options.INV_AUTOSELL_NOSELL_DURA > 0	or
		  settings.profile.options.INV_AUTOSELL_STATS_NOSELL ~= nil ) ) then
		cprintf(cli.yellow, language[1004]);	-- Ingamefunctions addon (igf) is not installed
		 return false;
	end

	if evalfunc == nil or type(evalfunc) ~= "function" then -- Set up default eval function
		-- move color settings into table
		local hf_quality = string.gsub (settings.profile.options.INV_AUTOSELL_QUALITY, "%s*[;,]%s*", "\n");	-- replace ; with linefeed
		local hf_quality_table = explode( hf_quality, "\n" );	-- move colors to table

		local hf_ignore_table;
		-- move ignore list into table
		if( settings.profile.options.INV_AUTOSELL_IGNORE ) then
			local hf_explode = string.gsub (settings.profile.options.INV_AUTOSELL_IGNORE, "%s*[;,]%s*", "\n");	-- replace ; with linefeed
			hf_ignore_table = explode( hf_explode, "\n" );	-- move ignore list
			for i,v in pairs(hf_ignore_table) do local m = string.match(v,"^'(.*)'$") if m then hf_ignore_table[i] = m end end -- remove quotes
		end

		local hf_stats_nosell;
		-- move ignore stats list into table
		if( settings.profile.options.INV_AUTOSELL_STATS_NOSELL ) then
			local hf_explode = string.gsub (settings.profile.options.INV_AUTOSELL_STATS_NOSELL, "[;,]", "\n");	-- replace ; with linefeed/ no trim
			hf_stats_nosell = explode( hf_explode, "\n" );	-- move ignore list
			for i,v in pairs(hf_stats_nosell) do local m = string.match(v,"^'(.*)'$") if m then hf_stats_nosell[i] = m end end -- remove quotes
		end

		local hf_stats_sell;
		-- move stats list into table
		if( settings.profile.options.INV_AUTOSELL_STATS_SELL ) then
			local hf_explode = string.gsub (settings.profile.options.INV_AUTOSELL_STATS_SELL, "[;,]", "\n");	-- replace ; with linefeed/ no trim
			hf_stats_sell = explode( hf_explode, "\n" );	-- move ignore list
			for i,v in pairs(hf_stats_sell) do local m = string.match(v,"^'(.*)'$") if m then hf_stats_sell[i] = m end end -- remove quotes
		end

		local hf_type_sell;
		-- move type list into table
		if( settings.profile.options.INV_AUTOSELL_TYPES ) then
			local hf_explode = string.gsub(settings.profile.options.INV_AUTOSELL_TYPES, "[;,]", "\n");	-- replace ; with linefeed/ no trim
			hf_type_sell = explode( hf_explode, "\n" );
		end

		local hf_type_nosell;
		-- move type list into table
		if( settings.profile.options.INV_AUTOSELL_TYPES_NOSELL ) then
			local hf_explode = string.gsub(settings.profile.options.INV_AUTOSELL_TYPES_NOSELL, "[;,]", "\n");	-- replace ; with linefeed/ no trim
			hf_type_nosell = explode( hf_explode, "\n" );
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

		local function isInTypeSell(_slotitem)

			if ( not hf_type_sell  ) then
				return true
			end

			for i,v in pairs(hf_type_sell) do

				if _slotitem:isType(v) then
					return true
				end
			end

			return false

		end

		local function isInTypeNosell(_slotitem)

			if ( not hf_type_nosell  ) then
				return false
			end

			for i,v in pairs(hf_type_nosell) do
				if _slotitem:isType(v) then
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
					_item.Id == tonumber(ignorelistitem) ) then
					debugMsg(settings.profile.options.DEBUG_AUTOSELL,
					  "Itemname/id is in ignore list INV_AUTOSELL_IGNORE:", _item.Id, _item.Name, "=>", "'"..ignorelistitem.."'");
					return true
				end

			end

			return false

		end

		local function isInStatsNoSell(_item)

			if ( not hf_stats_nosell ) then
				return false
			end

			for i1,stat in pairs(_item.Stats) do
				for i2,nosellstat in pairs(hf_stats_nosell) do

					debugMsg(settings.profile.options.DEBUG_AUTOSELL,
					  "Check nosellstat line:", i1, tooltipline, "=>", nosellstat);

					if( string.find( string.lower(stat.Name), string.lower(nosellstat), 1, true)  ) then
						debugMsg(settings.profile.options.DEBUG_AUTOSELL,
						  "Not to sell stat found:", stat.Name);
						return true
					end

				end
			end

			return false

		end

		local function isInStatsSell(_item)

			if ( not hf_stats_sell ) then
				return false
			end

			for i,stat in pairs(_item.Stats) do
				for i,sellstat in pairs(hf_stats_sell) do

					if( string.find( string.lower(stat.Name), string.lower(sellstat), 1, true)  ) then
						debugMsg(settings.profile.options.DEBUG_AUTOSELL,
						  "Allways sell stat found:", stat.Name);
						return true
					end

				end
			end

			return false

		end

		function evalfunc(slotitem)

			debugMsg(settings.profile.options.DEBUG_AUTOSELL,
			  "Check item so sell:", slotitem.SlotNumber, slotitem.Id, slotitem.Name);

			-- Check if can be sold
			if slotitem.CannotBeSold then
				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Item can not be sold");
				return false
			end

			-- check item quality color
			if( sellColor(slotitem.Color) == false ) then
				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Itemcolor not in option INV_AUTOSELL_QUALITY:", slotitem:getColorString() );
				return false
			end

			-- check if on type sell lists
			if (isInTypeSell(slotitem) == false ) then
				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Item is not in type option INV_AUTOSELL_TYPE:", settings.profile.options.INV_AUTOSELL_TYPE);
				return false
			elseif (isInTypeNosell(slotitem) == true ) then
				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Item is in type option INV_AUTOSELL_TYPE_NOSELL:", settings.profile.options.INV_AUTOSELL_TYPE_NOSELL);
				return false
			end

			-- check itemname against ignore list
			if( isInIgnorelist(slotitem) == true ) then
				return false
			end

			-- check number of named stats
			if #slotitem.Stats >= settings.profile.options.INV_AUTOSELL_NOSELL_STATSNUMBER then
				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Number of stats not less than INV_AUTOSELL_NOSELL_STATSNUMBER", settings.profile.options.INV_AUTOSELL_NOSELL_STATSNUMBER );
				return false
			end

			-- check max durability value
			if( settings.profile.options.INV_AUTOSELL_NOSELL_DURA > 0	and
				slotitem.MaxDurability > 0 and
				slotitem.MaxDurability > settings.profile.options.INV_AUTOSELL_NOSELL_DURA )then
				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Don't sell, durability > INV_AUTOSELL_NOSELL_DURA:",
				  settings.profile.options.INV_AUTOSELL_NOSELL_DURA );
				return false
			end

			-- check if stats / text strings are on the ingnore list
			if( isInStatsNoSell(slotitem) == true ) then

				-- check if in sell always stats
				if( isInStatsSell(slotitem) == true ) then
					-- don't change the sell flag
				else
					return false
				end

			end

			return true
		end
	end

	local sellstartstring = "} local U=UseBagItem; if StoreFrame:IsVisible() then a={true};"
	local sellstring = sellstartstring
	local hf_wesell = false;
	-- check the given slot numbers to autosell
	for slotNumber = settings.profile.options.INV_AUTOSELL_FROMSLOT + 60, settings.profile.options.INV_AUTOSELL_TOSLOT + 60, 1 do
		local slotitem = self.BagSlot[slotNumber];

		if( slotitem  and  tonumber(slotitem.Id) > 0 and slotitem.Available and slotitem.CanBeSold) then
			if evalfunc(slotitem) == true then
				-- Passed eval function. Then sell the item
				sellstring = sellstring .. "U("..slotitem.BagId..");"
			end
		end		-- end of: if( slotitem  and  slotitem.Id > 0 )
	end

	-- Sell if any items were added
	if #sellstring > #sellstartstring then
		sellstring = sellstring .. "end;z={"
		if RoMScript(sellstring) then
			yrest(100)
			hf_wesell = true;
		end
	end

	if( hf_wesell == true ) then
		return true;
	else
		return false;
	end

end

function CInventory:getMount()
    mounts = {
	-- Id of all mounts
	-- Add single mounts or ranges of mounts.
	{first = 200876, last = 200879},
	201130,
	201468,
	201482,
	{first = 201488, last = 201490},
	201698,
	{first = 201927, last = 201928},
	{first = 201965, last = 201966},
	202095,
	{first = 202217, last = 202218},
	{first = 202226, last = 202232},
	{first = 202245, last = 202248},
	{first = 202450, last = 202486},
	202821,
	{first = 202931, last = 202936},
	{first = 203285, last = 203290},
	{first = 203296, last = 203341},
	{first = 203553, last = 203573},
	{first = 203669, last = 203678},
	{first = 203913, last = 203915},
	{first = 203968, last = 203971},
	204072,
	{first = 204083, last = 204085},
	{first = 204142, last = 204151},
	{first = 204276, last = 204295},
	{first = 204929, last = 204948},
	{first = 204950, last = 204979},
	{first = 204982, last = 204999},
	205025,
	{first = 205748, last = 205749},
	{first = 206016, last = 206020},
	206044,
	{first = 206196, last = 206207},
	{first = 206212, last = 206215},
	{first = 206234, last = 206239},
	{first = 206275, last = 206292},
	{first = 206314, last = 206319},
	{first = 206326, last = 206329},
	{first = 206352, last = 206361},
	{first = 206556, last = 206573},
	{first = 206594, last = 206596},
	{first = 206705, last = 206710},
	{first = 206715, last = 206720},
	{first = 206904, last = 206906},
	{first = 206934, last = 206936},
	{first = 206939, last = 206941},
	{first = 206944, last = 206946},
	{first = 206949, last = 206951},
	207348,
	{first = 207501, last = 207503},
	{first = 207509, last = 207551},
	{first = 207558, last = 207560},
	{first = 207563, last = 207571},
	207624,
	207958,
	{first = 208159, last = 208161},
	{first = 208570, last = 208572},
	208691,
	{first = 208693, last = 208695},
	{first = 208697, last = 208700},
	208702,
	{first = 208704, last = 208707},
	{first = 208910, last = 208912},
	208960,
	{first = 209480, last = 209481},
	{first = 209485, last = 209487},
	209490,
	{first = 209500, last = 209502},
	{first = 209505, last = 209508},
	209591,
	{first = 209601, last = 209602},
	{first = 209605, last = 209618},
	{first = 209961, last = 209966},
	{first = 240036, last = 240038},
	{first = 240081, last = 240083},
	{first = 240086, last = 240088},
	{first = 240499, last = 240501},
	{first = 240916, last = 240918},
	{first = 240928, last = 240930},
	{first = 240933, last = 240935},
	241101,
	{first = 241103, last = 241104},
	{first = 241182, last = 241183},
	{first = 241316, last = 241318},
	{first = 241620, last = 241622},
	{first = 241632, last = 241634},
	{first = 241772, last = 241774},
	{first = 241777, last = 241779},
	{first = 241786, last = 241788},
	{first = 241791, last = 241793},
	{first = 241805, last = 241808},
	{first = 241997, last = 241999},
	{first = 242149, last = 242157},
	242161,
	{first = 242447, last = 242449},
	494474,
	505113,
	};

 	for slot,item in pairs(self.BagSlot) do
		if item.Available then
			for i, mount in ipairs(mounts) do
				if type(mount) == "number" then
					if item.Id == mount then
						return item;
					end
				else -- table
					if item.Id >= mount.first and item.Id <= mount.last then
						return item
					end
				end
			end
		end
	end

	return false;
end

function getInventoryRange(range)
	if range == nil then
		return
	end
	local rangeLower = string.lower(range)
	if rangeLower == "all" then
		return 1, 240, "inventory"
	elseif rangeLower == "itemshop" then
		return 1, 50, "inventory"
	elseif rangeLower == "magicbox" then
		return 51, 60, "inventory"
	elseif rangeLower == "bag1" then
		return 61, 90, "inventory"
	elseif rangeLower == "bag2" then
		return 91, 120, "inventory"
	elseif rangeLower == "bag3" then
		return 121, 150, "inventory"
	elseif rangeLower == "bag4" then
		return 151, 180, "inventory"
	elseif rangeLower == "bag5" then
		return 181, 210, "inventory"
	elseif rangeLower == "bag6" then
		return 211, 240, "inventory"
	elseif rangeLower == "bag" or rangeLower == "bags" then
		return 61, 240, "inventory"

	elseif rangeLower == "bank1" then
		return 1, 40, "bank"
	elseif rangeLower == "bank2" then
		return 41, 80, "bank"
	elseif rangeLower == "bank3" then
		return 81, 120, "bank"
	elseif rangeLower == "bank4" then
		return 121, 160, "bank"
	elseif rangeLower == "bank5" then
		return 161, 200, "bank"
	elseif rangeLower == "isbank" then
		return 201, 300, "bank"
	elseif rangeLower == "bank" or rangeLower == "banks" then
		return 1, 200, "bank"

	elseif rangeLower == "equipment" then
		return 0, 21, "equipment"
	elseif rangeLower == "head" then
		return 0, 0, "equipment"
	elseif rangeLower == "hands" then
		return 1, 1, "equipment"
	elseif rangeLower == "feet" then
		return 2, 2, "equipment"
	elseif rangeLower == "chest" then
		return 3, 3, "equipment"
	elseif rangeLower == "legs" then
		return 4, 4, "equipment"
	elseif rangeLower == "cape" then
		return 5, 5, "equipment"
	elseif rangeLower == "belt" then
		return 6, 6, "equipment"
	elseif rangeLower == "shoulders" then
		return 7, 7, "equipment"
	elseif rangeLower == "necklace" then
		return 8, 8, "equipment"
	elseif rangeLower == "ammunition" then
		return 9, 9, "equipment"
	elseif rangeLower == "ranged weapon" then
		return 10, 10, "equipment"
	elseif rangeLower == "left ring" then
		return 11, 11, "equipment"
	elseif rangeLower == "right ring" then
		return 12, 12, "equipment"
	elseif rangeLower == "left earring" then
		return 13, 13, "equipment"
	elseif rangeLower == "right earring" then
		return 14, 14, "equipment"
	elseif rangeLower == "main hand" then
		return 15, 15, "equipment"
	elseif rangeLower == "off hand" then
		return 16, 16, "equipment"
	elseif rangeLower == "unknown" then
		return 17, 17, "equipment"
	elseif rangeLower == "amulets" then
		return 18, 20, "equipment"
	elseif rangeLower == "amulet1" then
		return 18, 18, "equipment"
	elseif rangeLower == "amulet2" then
		return 19, 19, "equipment"
	elseif rangeLower == "amulet3" then
		return 20, 20, "equipment"
	elseif rangeLower == "wings" then
		return 21, 21, "equipment"

	elseif rangeLower == "guildbank" or rangeLower == "guild" then
		guildbank:updatePageAddresses()
		return 1, #guildbank.PageAddresses*100, "guildbank"
	elseif string.match(rangeLower, "guild") then
		local page = string.match(rangeLower,"^guildbank(%d%d?)$") or string.match(rangeLower,"^guild(%d%d?)$")
		page = tonumber(page)
		if page and page > 0 and page <= 10 then
			return (page-1)*100+1, page*100, "guildbank"
		end
	end
end

-- Returns item name or false, takes in type, example: "hot" or "mot" or "arrow" or "thrown"
function CInventory:bestAvailablePhirius(type)

	local bestPer = 0;		-- power of a potion
	local bestItem = false;
	local select_strategy = "best";

	self:update();
	-- check item slots slot by slot
	for slot,item in pairs(self.BagSlot) do
		local consumable = database.consumables[item.Id];

		if consumable  and							-- item in database
		    (consumable.Type == type and	-- right type (mana, hp, both)
		 	item.ItemCount > 0 and					-- use only if some available
			item.Available) then			-- not in unrented bag

			if( consumable.Potency > bestPer) then
				bestPer = consumable.Potency;
				bestSmallStack = item.ItemCount;
				bestItem = item;
			-- same/same but select smaller stack
			elseif( consumable.Potency == bestPer  and
				item.ItemCount < bestSmallStack ) then
				bestPer = consumable.Potency;
				bestSmallStack = item.ItemCount;
				bestItem = item;
			end

		end
	end

	if bestItem == false then
		for slot,item in pairs(self.BagSlot) do
			local consumable = database.consumables[item.Id];
			if consumable  and							-- item in database
				(consumable.Type == "phirusboth" and	-- right type (mana, hp, both)
				item.ItemCount > 0 and					-- use only if some available
				item.Available) then			-- not in unrented bag

				if( consumable.Potency > bestPer) then
					bestPer = consumable.Potency;
					bestSmallStack = item.ItemCount;
					bestItem = item;
				-- same/same but select smaller stack
				elseif( consumable.Potency == bestPer  and
					item.ItemCount < bestSmallStack ) then
					bestPer = consumable.Potency;
					bestSmallStack = item.ItemCount;
					bestItem = item;
				end
			end
		end
	end
	return bestItem;
end

-- Returns item name or false, takes in type, example: "hot" or "mot" or "arrow" or "thrown"
function CInventory:bestAvailablepotion(type)
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
	elseif(type == "heal" ) then
		if( settings.profile.options.USE_HP_POTION == select_strategy_minstack ) then
			select_strategy = select_strategy_minstack;
		else
			select_strategy = select_strategy_default;
		end
	else
		select_strategy = select_strategy_default;	-- default = 'best'
	end

	self:update();
	-- check item slots slot by slot
	for slot,item in pairs(self.BagSlot) do
		local consumable = database.consumables[item.Id];

		if( consumable  and							-- item in database
		    consumable.Type == type and	 			-- right type (mana, arrow, ...)
		 	consumable.Level <= player.Level and	-- level ok
		 	item.ItemCount > 0 and					-- use only if some available
			item.Available) then					-- not in unrented bag

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

--==     Superseded Functions     ==--

-- Obsolete. Kept for backward compatability
function CInventory:updateEquipment()
	if equipment then
		equipment:update()
	end
end;

-- Obsolete. Kept for backward compatability
function CInventory:getAmmunitionCount()
	if equipment then
		return equipment:getAmmunitionCount()
	end
end;

-- Obsolete. Kept for backward compatability
function CInventory:isEquipped( __space )
	if equipment then
		return equipment:isEquipped( __space )
	end
end;

-- Obsolete. Kept for backward compatability
function CInventory:getDurability( _slot )
	if equipment then
		return equipment:getDurability( _slot )
	else
		return 0
	end
end;

-- Obsolete. Kept for backward compatability
function CInventory:getMainHandDurability()
	-- return values in percent from 0 - 100
	if equipment then
		return equipment:getDurability( 15 );		-- 15=Main Hand
	end
end;

