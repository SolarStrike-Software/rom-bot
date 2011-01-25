include("memorytable.lua");
include("item.lua");
include("equipitem.lua");

local proc = getProc();

CInventory = class(
	function (self)
		RoMScript("ToggleBackpack(), BagFrame:Hide()"); -- Make sure the client loads the tables first.
		LoadTables();

		self.MaxSlots = 240;

		self.BagSlot = {};
		self.EquipSlots = {};
		self.Money = memoryReadInt( proc, addresses.moneyPtr );

		local timeStart = getTime();

		for slotNumber = 1, self.MaxSlots, 1 do
			self.BagSlot[slotNumber] = CItem( slotNumber );
		end

		if( settings.profile.options.DEBUG_INV ) then
			printf( "Inventory update took: %d\n", deltaTime( getTime(), timeStart ) );
		end;

		for slotNumber = 1, 22, 1 do
			self.EquipSlots[slotNumber] = CEquipItem( slotNumber );
		end

		self.NextItemToUpdate = 1;
	end
);

--[[function CInventory:update()
	local timeStart = getTime();

	self.Money = memoryReadInt( proc, addresses.moneyPtr );

	for slotNumber = 1, self.MaxSlots, 1 do
		self.BagSlot[slotNumber]:update();
	end

--	if( settings.profile.options.DEBUG_INV ) then
		printf( "Inventory update took: %d\n", deltaTime( getTime(), timeStart ) );
		printf( "You have: %d gold.\n", self.Money );
--	end;
end;]]

function CInventory:updateEquipment()
	local timeStart = getTime();

	for slotNumber = 1, 22, 1 do
		self.EquipSlots[ slotNumber ]:update();
	end

--	if( settings.profile.options.DEBUG_INV ) then
		printf( "Equipment update took: %d\n", deltaTime( getTime(), timeStart ) );
--	end;
end;

function CInventory:getAmmunitionCount()
	self:updateEquipment();
	-- self.EquipSlots[ 9 ]:update(); -- 9 Ammunition slot
	local count = self.EquipSlots[ 10 ].ItemCount;
	if count == nil then
		count = 0;
	end;
	return count;
end;

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

		local checkItemName = openItem.Name;
		self:update();
		yrest(200);
		item = self:bestAvailableConsumable(type);
		if( item and checkItemName ~= item.Name ) then
			cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name));
			openItem:update();
		else
			openItem:use();
			yrest( 500 ); --give time to server to respond with the opened item
		end

		-- after opening, update the inventory (this takes about 10 sec)
		self:update();

		item = self:bestAvailableConsumable(type);
	end

	if item then
		-- use it
		-- local unused,unused,checkItemName = RoMScript("GetBagItemInfo(" .. item.SlotNumber .. ")");
		local checkItemName = item.Name;
		item:update();
		if( checkItemName ~= item.Name ) then
			cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name));
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
	local first, last = getInventoryRange(range) -- get bag slot range
	if first == nil then
		first , last = 61, 240 -- default, search only bags
	end

	self:update();

	totalCount = 0;
	for slot = first, last do
		item = inventory.BagSlot[slot]
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

function CInventory:findItem( itemNameOrId, range)
	local first, last = getInventoryRange(range) -- get bag slot range
	if first == nil then
		first , last = 1, 240 -- default, search all
	end

	local smallestStack = nil

	self:update()

	for slot = first, last do
		item = inventory.BagSlot[slot]
 	    if item.Available and (item.Name == itemNameOrId or item.Id == itemNameOrId) then
			if item.ItemCount > 1 then
				-- find smallest stack
				if smallestStack == nil or smallestStack.ItemCount > item.ItemCount then
					smallestStack = item
				end
			else
				return item
			end
		end;
	end;

	return smallestStack
end

function CInventory:useItem(itemNameOrId)
	self:update();

	local item = self:findItem(itemNameOrId)
	if item then
		item:use();
		return true, item.Id, item.Name;
	end;

	return false;
end;

function CInventory:isEquipped( __space )
-- return true if equipped is equipped at slot and has durability > 0
	local slot = 16;-- Automatically set slot to 16/MainHand
	_space = string.lower(__space);

	if ( type(_space) ~= "string" ) then
		return false;
	end

	if (_space == "head") then
		slot = 1;
	elseif (_space == "gloves") then
		slot = 2;
	elseif (_space == "boots") then
		slot = 3;
	elseif (_space == "shirt") then
		slot = 4;
	elseif (_space == "pants") then
		slot = 5;
	elseif (_space == "cloak") then
		slot = 6;
	elseif (_space == "belt") then
		slot = 7;
	elseif (_space == "shoulder") then
		slot = 8;
	elseif (_space == "necklace") then
		slot = 9;
	elseif (_space == "ammo") then
		slot = 10;
	elseif (_space == "bow") then
		slot = 11;
	elseif (_space == "rightring") then
		slot = 12;
	elseif (_space == "leftring") then
		slot = 13;
	elseif (_space == "rightearring") then
		slot = 14;
	elseif (_space == "leftearring") then
		slot = 15;
	elseif (_space == "mainhand") then
		slot = 16;
	elseif (_space == "offhand") then
		slot = 17;
	elseif (_space == "trinket") then
		slot = 18; -- assumed, not confirmed
	elseif (_space == "talisman1") then
		slot = 19; -- slot next to necklace
	elseif (_space == "talisman2") then
		slot = 20; -- first slot under necklace next to shoulder
	elseif (_space == "talisman3") then
		slot = 21; -- first slot under talisman2 next to gloves
	elseif (_space == "wings") then
		slot = 22;
	end;

	self.EquipSlots[ slot ]:update();

	if( self.EquipSlots[ slot ].Empty ) then
		return false;
	end;

	local realDurability = self.EquipSlots[ slot ].Durability / self.EquipSlots[ slot ].MaxDurability * 100;

	if( realDurability <= 0 ) then
		return false;
	end;

	return true;
end;

function CInventory:getDurability( _slot )
	-- return item durability for a given slot in percent from 0 - 100

	if( not _slot) then _slot = 16; end		-- 16=MainHand | 17=OffHand | 11=Ranged

	self.EquipSlots[ _slot ]:update();
	return self.EquipSlots[ _slot ].Durability / self.EquipSlots[ _slot ].MaxDurability * 100;
end;

function CInventory:getMainHandDurability()
	-- return values between 0 - 1 for compatibility reasons
	return inventory:getDurability( 16 );		-- 16=Main Hand
end;

-- Make a full update
-- or update slot 1 to _maxslot
function CInventory:update( _maxslot )

	self.Money = memoryReadInt( proc, addresses.moneyPtr );

	if( not _maxslot ) then _maxslot = self.MaxSlots; end;

	-- printf(language[1000], _maxslot);  -- Updating

	keyboardSetDelay(0);
	for slotNumber = 1, _maxslot, 1 do
		self.BagSlot[slotNumber]:update();
	end
	--printf("\n");
	keyboardSetDelay(50);

	-- player.InventoryDoUpdate = false;			-- set back update trigger
	-- player.InventoryLastUpdate = os.time();		-- remember update time

	--cprintf(cli.green, language[1002], settings.profile.options.INV_UPDATE_INTERVAL );	-- inventory update not later then
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


function CInventory:autoSell()

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
				_item.ItemId == ignorelistitem ) then
				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Itemname/id is in ignore list INV_AUTOSELL_IGNORE:", _item.ItemId, _item.Name, "=>", ignorelistitem);
				return true
			end

		end

		return false

	end

	local function isDuraIgnore(_tooltip_right)

		local duramax;		-- durability max value (if found)
		local durakey = ITEM_TOOLTIP_DURABILITY[bot.ClientLanguage];	-- keyword to search for

		if( durakey == nil ) then
			error(language[1005], 0);
		end

		-- read durability from tooltip
		for i,text in pairs(_tooltip_right) do
			for _keyword, _dura, _duramax in string.gfind(text, "("..durakey..")%s*(%d+)/(%d+)") do
				duramax = tonumber(_duramax);
			end
		end

		debugMsg(settings.profile.options.DEBUG_AUTOSELL,
		  "Durability check, search for:", durakey, "=>", duramax);

		-- check dura
		if( settings.profile.options.INV_AUTOSELL_NOSELL_DURA 		and
			settings.profile.options.INV_AUTOSELL_NOSELL_DURA > 0	and
			duramax													and
			duramax >= settings.profile.options.INV_AUTOSELL_NOSELL_DURA ) then
			debugMsg(settings.profile.options.DEBUG_AUTOSELL,
			  "Durability check: nosell, durability > then limit =>", duramax, ">",
			    settings.profile.options.INV_AUTOSELL_NOSELL_DURA );
			return true;
		end

		return false

	end


	local function isInStatsNoSell(_tooltip_right)

		if ( not hf_stats_nosell ) then
			return false
		end

		for i1,tooltipline in pairs(_tooltip_right) do
			for i2,nosellstat in pairs(hf_stats_nosell) do

				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Check nosellstat line:", i1, tooltipline, "=>", nosellstat);

				if( string.find( string.lower(tooltipline), string.lower(nosellstat), 1, true)  ) then
					debugMsg(settings.profile.options.DEBUG_AUTOSELL,
					  "Not to sell stat found:", tooltipline);
					return true
				end

			end
		end

		return false

	end

	local function isInStatsSell(_tooltip_right)

		if ( not hf_stats_sell ) then
			return false
		end

		for i,tooltipline in pairs(_tooltip_right) do
			for i,sellstat in pairs(hf_stats_sell) do

				if( string.find( string.lower(tooltipline), string.lower(sellstat), 1, true)  ) then
					debugMsg(settings.profile.options.DEBUG_AUTOSELL,
					  "Allways sell stat found:", tooltipline);
					return true
				end

			end
		end

		return false

	end


	local hf_wesell = false;
	-- check the given slot numbers to autosell
	for slotNumber = settings.profile.options.INV_AUTOSELL_FROMSLOT + 60, settings.profile.options.INV_AUTOSELL_TOSLOT + 60, 1 do
		local sell_item = true
		local slotitem = self.BagSlot[slotNumber];

		if( slotitem  and  tonumber(slotitem.Id) > 0 and slotitem.Available) then

			debugMsg(settings.profile.options.DEBUG_AUTOSELL,
			  "Check item so sell:", slotnumber, slotitem.Id, slotitem.Name);

			-- check item quality color
			if( sellColor(slotitem.Color) == false ) then
				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Itemcolor not in option INV_AUTOSELL_QUALITY:", slotitem:getColorString() );
				sell_item = false;
			end

			-- check if on type sell lists
			if (isInTypeSell(slotitem) == false ) then
				sell_item = false
			elseif (isInTypeNosell(slotitem) == true ) then
				sell_item = false
			end

			-- check itemname against ignore list
			if( isInIgnorelist(slotitem) == true ) then
				sell_item = false;
			end

			-- read tooltip
			local tooltip_right;
			if( bot.IgfAddon == true ) then
				tooltip_right = slotitem:getGameTooltip("right");
				if( tooltip_right == false ) then	-- error while reading tooltip
					cprintf(cli.yellow, "Error reading tooltip for bagslot %s, %s %s\n",
					 slotitem.SlotNumber, slotitem.Id, slotitem.Name);
					 sell_item = false;
				end
			end

			-- check max durability value
			if( bot.IgfAddon == true	and
				tooltip_right			and
				isDuraIgnore(tooltip_right) == true ) then
				debugMsg(settings.profile.options.DEBUG_AUTOSELL,
				  "Don't sell, durability > INV_AUTOSELL_NOSELL_DURA:",
				  settings.profile.options.INV_AUTOSELL_NOSELL_DURA );
				sell_item = false;
			end

			-- check if stats / text strings are on the ingnore list
			if( bot.IgfAddon == true	and
				tooltip_right			and
				isInStatsNoSell(tooltip_right) == true ) then

				-- check if in sell always stats
				if( isInStatsSell(tooltip_right) == true ) then
					-- don't change the sell flag
				else
					sell_item = false;
				end

			end

			-- sell the item
			if( sell_item == true ) then
				hf_wesell = true;
				slotitem:use();
			end

		end		-- end of: if( slotitem  and  slotitem.Id > 0 )

	end

	if( hf_wesell == true ) then
		return true;
	else
		return false;
	end

end

function CInventory:getMount()
    mounts = {
	-- Id of all mounts (except 15 minute, and 2 hour mounts)
	-- Add single mounts or ranges of mounts.
	201130,
	201468,
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
	{first = 205748, last = 205749},
	{first = 206016, last = 206020},
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
	{first = 207501, last = 207503},
	{first = 207515, last = 207536},
	{first = 207558, last = 207560},
	{first = 207566, last = 207571},


	-- Temp mounts
	505113,494474,
	};

 	for slot,item in pairs(self.BagSlot) do
		if item.Available then
			for i, mount in pairs(mounts) do
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
		return 1, 240
	elseif rangeLower == "itemshop" then
		return 1, 50
	elseif rangeLower == "magicbox" then
		return 51, 60
	elseif rangeLower == "bag1" then
		return 61, 90
	elseif rangeLower == "bag2" then
		return 91, 120
	elseif rangeLower == "bag3" then
		return 121, 150
	elseif rangeLower == "bag4" then
		return 151, 180
	elseif rangeLower == "bag5" then
		return 181, 210
	elseif rangeLower == "bag6" then
		return 211, 240
	elseif rangeLower == "bags" then
		return 61, 240
	end
end
