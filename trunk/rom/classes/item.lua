
-- itemquality -> color code
ITEMCOLOR = {
	WHITE =  tonumber("0xFFFFFFFF"),
	GREEN =  tonumber("0xFF00FF00"),
	BLUE =   tonumber("0xFF0072BC"),
	PURPLE = tonumber("0xFFA864A8"),
	ORANGE = tonumber("0xFFF68E56"),
	GOLD =   tonumber("0xFFA37D50"),
};

-- making a new one because i dont know if the other is used elsewhere
ITEMQUALITYCOLOR = {
	tonumber("0xFFFFFFFF"),
	tonumber("0xFF00FF00"),
	tonumber("0xFF0072BC"),
	tonumber("0xFFA864A8"),
	tonumber("0xFFF68E56"),
	tonumber("0xFFA37D50"),
	0,
	0,
	tonumber("0xFFA864A8"),
};

ITEM_REUSE_DELAY = 1 -- How long it wont use the item after being placed.

ITEMFLAGs_ITEMSHOPITEM_MASK = 0X4
ITEMFLAGs_CANBESOLD_MASK = 0X200
-- ITEMFLAGs_NOTDROPEDONPKDEATH_MASK = 0X2 -- noted for possible future use

CItem = class(
	function( self )
		self.BaseItemAddress = nil;
		self.Empty = true;
		self.Id = 0;
		self.Name = "<EMPTY>";
		self.ItemCount = 0;
		self.Color = "ffffff";
		self.Icon = "";
		self.ItemLink = "|Hitem:33BF1|h|cff0000ff[Empty]|r|h";
		self.Durability = 0;
		self.MaxDurability = 0;
		self.Quality = 0; -- 0 = white / 1 = green / 2 = blue / 3 = purple / 4 = orange / 5 = gold
		self.Value = 0;
		self.Worth = 0;
		self.InUse = false;
		self.BoundStatus = 1; -- 0 = bound on pickup, 1 = not bound, 2 = binds on equip and bound, 3 = binds on equip and not bound
		self.Bound = true
		self.RequiredLvl = 0;
		self.CoolDownTime = 0;
		self.LastTimeUsed = 0;
		self.MaxStack = 0;
		self.ObjType = 0;
		self.ObjSubType = 0;
		self.ObjSubSubType = 0;
		self.Stats = {}; -- list of named stats and their ids.
		self.ItemShopItem = false
		self.CanBeSold = false
		self.LastMovedTime = 0
	end
);

function CItem:update()
	local nameAddress;
	local oldId = self.Id;

	self.Id = memoryReadInt( getProc(), self.Address ) or 0;
	self.Available = (self.Available ~= false)

	if ( self.Id ~= nil and self.Id ~= oldId and self.Id ~= 0 ) then
		self.BaseItemAddress = GetItemAddress( self.Id );
		if ( self.BaseItemAddress == nil or self.BaseItemAddress == 0 ) then
			cprintf( cli.yellow, "Wrong value returned in update of item id: %d\n", self.Id );
			logMessage(sprintf("Wrong value returned in update of item id: %d", self.Id));
			return;
		end;

		self.Name = "";
		self.Empty = false;
		self.ItemCount = memoryReadInt( getProc(), self.Address + addresses.itemCountOffset );
		self.Durability = memoryReadInt( getProc(), self.Address + addresses.durabilityOffset );
		self.MaxDurability = memoryReadByte( getProc(), self.Address + addresses.maxDurabilityOffset );
		if ( self.Durability > 0 ) then
			self.Durability = self.Durability / 100;
		end;
		self.Value = memoryReadInt( getProc(), self.BaseItemAddress + addresses.valueOffset );
		if ( self.Value > 0 ) then
			self.Worth = self.Value / 10;
		end;
		self.InUse = memoryReadInt( getProc(), self.Address + addresses.inUseOffset ) ~= 0;
		self.BoundStatus = memoryReadByte( getProc(), self.Address + addresses.boundStatusOffset );
		self.Bound = not bitAnd(self.BoundStatus,1)
		self.RequiredLvl = memoryReadInt( getProc(), self.BaseItemAddress + addresses.requiredLevelOffset );
		self.MaxStack = memoryReadInt( getProc(), self.BaseItemAddress + addresses.maxStackOffset );
		self.ObjType = memoryReadInt( getProc(), self.BaseItemAddress + addresses.typeOffset );
		self.ObjSubType = memoryReadInt( getProc(), self.BaseItemAddress + addresses.typeOffset + 4);
		self.ObjSubSubType = memoryReadInt( getProc(), self.BaseItemAddress + addresses.typeOffset + 8);

		self.CoolDownTime = 0
		if ( self.ObjType == 2 ) then -- Consumables, lets try to get CD time
			local skillItemId = memoryReadInt( getProc(), self.BaseItemAddress + addresses.realItemIdOffset );
			if ( skillItemId ~= nil and skillItemId ~= 0 ) then
				local skillItemAddress = GetItemAddress( skillItemId );
				if ( skillItemAddress ~= nil and skillItemAddress ~= 0 ) then
					self.CoolDownTime = memoryReadInt( getProc(), skillItemAddress + addresses.coolDownOffset );
				end;
			end;
			-- cprintf( cli.yellow, "Cool down for consumable: %d\n", self.CoolDownTime );
		end;

		-- Special case for cards
		if ( self.Id >= 770000 and self.Id <= 772000 ) then
			-- We need to get info from NPC...
			local tmp = memoryReadInt( getProc(), self.BaseItemAddress + addresses.idCardNPCOffset );
			npcInfoAddress = GetItemAddress( tmp );
			if npcInfoAddress then
				nameAddress = memoryReadInt( getProc(), npcInfoAddress + addresses.nameOffset );
			else
				cprintf(cli.lightred,"Failed to get Address for NPC Id %s", tostring(tmp));
			end
			self.Name = "Card - "; -- We should add a string so we can localize this
		elseif ( self.Id >= 550000 and self.Id <=552000 ) then
			-- We need to get info from item...
			local tmp = memoryReadInt( getProc(), self.BaseItemAddress + addresses.idRecipeItemOffset )
			itemInfoAddress = GetItemAddress(  tmp );
			if itemInfoAddress then
				nameAddress = memoryReadInt( getProc(), itemInfoAddress + addresses.nameOffset );
			else
				cprintf(cli.lightred,"Failed to get Address for item Id %s", tostring(tmp));
			end
			self.Name = "Recipe - "; -- We should add a string so we can localize this
		else
			nameAddress = memoryReadInt( getProc(), self.BaseItemAddress + addresses.nameOffset );
		end;

		if( nameAddress == nil or nameAddress == 0 ) then
			tmp = "<EMPTY>";
		else
			tmp = memoryReadString(getProc(), nameAddress);
		end;


		self.Name = self.Name .. tmp;

		self.Quality = memoryReadInt( getProc(), self.BaseItemAddress + addresses.qualityBaseOffset );
		local plusQuality = memoryReadByte( getProc(), self.Address + addresses.qualityTierOffset );
		local quality, tier = math.modf ( plusQuality / 16 );
		-- tier = tier * 16; -- Tier not really used yet...
		if ( quality > 0 ) then
			self.Quality = self.Quality + ( quality / 2 );
		end;

		-- Assign color based on quality
		self.Color = ITEMQUALITYCOLOR[ self.Quality + 1 ];

		-- Build an usable ItemLink
		self.ItemLink = string.format( "|Hitem:%x|h|c%x[%s]|r|h", self.Id, self.Color or 0, self.Name );

		-- Get Stats (only named stats)
		self.Stats = {}
		for i = 1, 6 do
			local tmpid = memoryReadUShort( getProc(), self.Address + addresses.itemStatsOffset + 0x2*(i-1) );
			if tmpid == 0 then -- No More stats
				break
			end
			tmpid = tmpid + 500000
			local tmpname = GetIdName(tmpid)
			self.Stats[i] = {Id = tmpid, Name = tmpname}
		end

		-- Get base item flag values
		local flags = memoryReadInt(getProc(),self.BaseItemAddress + addresses.itemFlagsOffset)
		self.ItemShopItem = bitAnd(flags,ITEMFLAGs_ITEMSHOPITEM_MASK)
		self.CanBeSold = bitAnd(flags,ITEMFLAGs_CANBESOLD_MASK)

	elseif ( self.Id == 0 ) then
		self.Empty = true;
		self.Id = 0;
		self.Name = "<EMPTY>";
		self.ItemCount = 0;
		self.Color = "ffffff";
		self.Icon = "";
		self.ItemLink = "|Hitem:33BF1|h|cff0000ff[Empty]|r|h";
		self.Durability = 0;
		self.Quality = 0; -- 0 = white / 1 = green / 2 = blue / 3 = purple / 4 = orange / 5 = gold
		self.Value = 0;
		self.Worth = 0;
		self.InUse = false;
		self.RequiredLvl = 0;
		self.Stats = {};
	else
		-- if id is not 0 and hasn't changed we only update these values
		self.ItemCount = memoryReadInt( getProc(), self.Address + addresses.itemCountOffset );
		self.Durability = memoryReadInt( getProc(), self.Address + addresses.durabilityOffset );
		if ( self.Durability > 0 ) then
			self.Durability = self.Durability / 100;
		end;
		self.InUse = memoryReadInt( getProc(), self.Address + addresses.inUseOffset ) ~= 0;
		self.BoundStatus = memoryReadInt( getProc(), self.Address + addresses.boundStatusOffset );
		self.Bound = not bitAnd(self.BoundStatus,1)
	end;
end


function CItem:delete()
	if self.Available and not self.Empty then
		self:pickup()

		if RoMScript("CursorHasItem()") then
			RoMScript("DeleteCursorItem()")
		end

		self:update()
	end
end

function CItem:getGameTooltip(_place)
-- _place = Left | Right
--
-- here the whole ingame function more clear:
-- ------------------------------------------
--	GameTooltip:SetBagItem(_bagid);
--	local tooltip_right = {};
--	for i=1,40,1 do
--		local lineobj, text = _G["GameTooltipTextRight"..i];
--
--		if(lineobj) then
--			text = lineobj:GetText();
--			lineobj:SetText("");
--		end;
--
--		if (text) then
--			table.insert(tooltip_right, text);
--		end;
--	end;
--
--	return tooltip_right;
-- ----------------------------------

	local setcommand
	if self.Location == "inventory" then
		setcommand = "SetBagItem"
	elseif self.Location == "equipment" then
		setcommand = "SetEquipmentItem"
	elseif self.Location == "bank" then
		setcommand = "SetBankItem"
	else
		print("No getGameTooltip \"SetItem\" function defined for \""..self.Location.."\"class.")
	end

	if _place ~= "Left" then
		_place = "Right"
	end

	local t = { RoMScript("igf_GetTooltip('".._place.."','"..setcommand.."',"..self.BagId..")") }

--cprintf(cli.yellow, "it %s\n", t[1]);
--cprintf(cli.yellow, "it %s\n", t[2]);
--cprintf(cli.yellow, "it %s\n", t[3]);
--cprintf(cli.yellow, "it %s\n", t[4]);
--cprintf(cli.yellow, "it %s\n", t[5]);
--cprintf(cli.yellow, "it %s\n", t[6]);

	if( t[1]  and
		t[1] ~= false ) then
		return t;
	else
		return false
	end

end

-- translate the hex color code into the color string
function CItem:getColorString()

	for i,v in pairs(ITEMCOLOR) do

		if( v == self.Color ) then
			return i;
		end
	end

	return false

end

function CItem:moveTo(bag)
	self:update()

	if self.Empty or not self.Available then
		return
	end

	-- Cursor should be clear before starting a move
	if cursor:hasItem() then
		cursor:clear()
	end

	-- Check if itemshop item
	if bag == "itemshop" and not self.ItemShopItem then
		-- Item is not itemshop item. Cannot be put in itemshop bag
		return
	end

	-- Get range to move to
	local first, last, location = getInventoryRange(bag)
	if first == nil or bag == "all" then
		printf("You must specify a valid location to move the item to. You cannot use \"all\".\n")
		return
	end

	-- Check if already in bag
	if self.SlotNumber >= first and self.SlotNumber <= last and self.Location == location then
		return
	end

	-- Can't move bound items to guild bank
	if location == "guildbank" and self.Bound then
		return
	end

	-- Get the tolocation class
	local toLocation
	if location == "inventory" then
		toLocation = inventory
	elseif location == "bank" then
		toLocation = bank
	elseif location == "equipment" then
		toLocation = equipment
	elseif location == "guildbank" then
		toLocation = guildbank
	end

	-- Deal with moving to equipment first. It has special needs.
	if location == "equipment" then
		-- Check if is type equipment
		if self.ObjType ~= 0 and self.ObjType ~= 1 then
			return
		end

		if bag == "equipment" or bag == "amulets" then -- No particular slot. Just use item to equip.
			self:use()
		else
			self:pickup()
			equipment.BagSlot[first]:pickup()
		end

		return
	end

	-- Try to find a stack to merge with
	if self.MaxStack > 1 and self.ItemCount < self.MaxStack then
		for slot = first, last do
			local toItem = toLocation.BagSlot[slot]
			toItem:update()
			if toItem.Available and self.Id == toItem.Id and toItem.ItemCount < toItem.MaxStack then -- merge
				if (location == "guildbank" or self.Location == "guildbank") and location ~= self.Location then
					-- Guild bank need 2 step merge
					local tmpempty = toLocation:findItem(0,bag)
					if tmpempty then

						self:pickup()

						-- If couldn't pick up, give up
						if not cursor:hasItem() then
							return
						end

						tmpempty:pickup() -- put down

						-- If failed to place item then return to origin
						if cursor:hasItem() then
							self:pickup()
							return
						end

						tmpempty:pickup() -- pick up

						toItem:pickup()

						-- If failed to place item then return to origin
						if cursor:hasItem() then
							tmpempty:pickup()
						end
					end
				else
					-- Normal merge
					self:pickup()

					toItem:pickup()
				end

				if self.ItemCount + toItem.ItemCount <= self.MaxStack then
					return
				else
					yrest(ITEM_REUSE_DELAY)
				end
			end
		end
	end

	-- Put the rest in an empty slot
	if not self.Empty then
		local empty = toLocation:findItem(0, bag)

		if empty then
			self:pickup()

			empty:pickup()
			if self.Location == "guildbank" then yrest(500) end
		end
	end
end

function CItem:isType(typename)
	if not self.Available or self.Empty then
		-- Not valid
		return false
	end

	local itemtype, itemsubtype, itemsubsubtype, objsubsubuniquetype = self:getTypes()

	if itemtype == typename or
		itemsubtype == typename or
		itemsubsubtype == typename or
		objsubsubuniquetype == typename then
		return true
	else
		return false
	end
end

function CItem:getTypes()
	if not self.Available or self.Empty then
		-- Not valid
		return false
	end

	local objtype = itemtypes[self.ObjType].Name

	local objsubtype = nil
	if self.ObjSubType ~= -1 then
		objsubtype = itemtypes[self.ObjType][self.ObjSubType].Name
	end

	local objsubsubtype = nil
	local objsubsubuniquetype = nil
	if self.ObjSubSubType ~= -1 then
		objsubsubtype = itemtypes[self.ObjType][self.ObjSubType][self.ObjSubSubType].Name
		objsubsubuniquetype = itemtypes[self.ObjType][self.ObjSubType][self.ObjSubSubType].UniqueName
	end

	return objtype, objsubtype, objsubsubtype, objsubsubuniquetype
end

function CItem:pickup()
	-- FACTS ABOUT PICKING UP ITEMS
	--
	-- 1. The moment you pick up an item, the slot becomes 'InUse' and remains so until it can be used again.
	-- 2. The moment you pick up an item, the cursor has an item - 'cursor:hasItem()'.
	-- 3. The moment you put an item down, the cursor wont have an item.
	-- 4. The moment you put an item down, the 'to' slot wont neccessarily be 'InUse' yet. That's why I added the LastMovedTime to it so it doesn't get used again right away.

	self:update()

	-- Not rented or closed
	if not self.Available then
		return
	end

	-- Wait till ready.
	if self.InUse and cursor:hasItem() and cursor.ItemLocation == self.Location and cursor.ItemBagId == self.BagId then
		-- Returning item. No waiting.

	elseif self.InUse then
		-- Wait till not in use
		local starttime = os.clock()
		repeat yrest(50) self:update() until (not self.InUse) or (os.clock() - starttime) > ITEM_REUSE_DELAY

	elseif (os.clock() - self.LastMovedTime) < ITEM_REUSE_DELAY then
		-- Wait delay time. Break if becomes locked
		repeat yrest(50) self:update() until self.InUse or (os.clock() - self.LastMovedTime) > ITEM_REUSE_DELAY

		-- Wait until it is no longer locked.
		if self.InUse then
			repeat yrest(50) self:update() until (not self.InUse) or (os.clock() - self.LastMovedTime) > ITEM_REUSE_DELAY
		end
	end

	-- Still InUse. Abort
	if self.InUse then
		if cursor:hasItem() then
			printf("Failed to place item %s in slot %d of the %s. Slot is locked.\n", self.Name, self.BagId, Self.Location)
		else
			printf("Failed to pickup item %s in slot %d of the %s. Slot is locked.\n", self.Name, self.BagId, Self.Location)
		end
		return
	end

	local pickupmethod
	if self.Location == "inventory" then
		pickupmethod = "PickupBagItem"
	elseif self.Location == "equipment" then
		pickupmethod = "PickupEquipmentItem"
	elseif self.Location == "bank" then
		pickupmethod = "PickupBankItem"
	elseif self.Location == "guildbank" then
		pickupmethod = "GuildBank_PickupItem"
	else
		error("No \"pickup\" function defined for \""..self.Location.."\"class.")
	end

	-- If dropping, remember last move time
	if cursor:hasItem() then
		self.LastMovedTime = os.clock()
	end

	RoMScript(pickupmethod.."("..self.BagId..")");
end

