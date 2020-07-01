include("item.lua");

CInventoryItem = class(CItem,
	function( self, slotnumber )
		self.Location = "inventory"
		self.Available = false; -- If slot is in unrented bag then = false

		self.SlotNumber = slotnumber
		self.BagId = 0

		if self.SlotNumber ~= 0 and self.SlotNumber ~= nil then
			self:update()
		end
	end
);

function CInventoryItem:update()
	local oldBagId = self.BagId;

	self.BagId = self.SlotNumber

	if self.BagId ~= oldBagId then -- need new address
		--[[ Inventory is stored as a static array of basic inventory item structs.
			At +0x0 will be the Item ID, and the struct size is 0x44 bytes.
			These structs define inventory contents starting with the item shop backpack,
			and will be ordered left-to-right, top-to-bottom. Arcane Transmutor follows
			and is also ordered (center, top-left, top-right, bottom-left, bottom-right),
			and then inventory bags which may appear randomly ordered.
			
			Bags are random ordered as the in-game sorting mechanism shuffles the
			slot IDs around for efficiency rather than a memcpy the each struct.
			
			Array index		Bag ID		Description
			0-49			1-50		Item Shop Backpack
			50-54			51-55		Arcane Transmutor
			55-59			56-60		Invisible Arcane Transmutor slots
			60-89			61-90		Bag I (random order)
			90-119			91-120		Bag II (random order)
			120-149			121-150		Bag III (random order)
			150-179			151-180		Bag IV (random order)
			180-209			181-210		Bag V (random order)
			210-239			211-240		Bag V (random order)
		--]]
		local base = getBaseAddress(addresses.inventory.base);
		local inventory_address = base + ((self.SlotNumber-1) * 0x44);
		
		id = memoryReadInt(getProc(), inventory_address);
		if( (id>=200000 and id<=240000) or (id>=490000 and id<=640000)) then
			self.Id = id;
			self.Address = inventory_address;
		else
			self.BaseItemAddress = 0;
			self.Available = false;
		end
	end

	-- Check if not rented
	if self.SlotNumber > 120 then
		--[[
			RoM stores the number of minutes (from now) that each bag (starting at 3) will expire
			A value of 0xFFFFFFFF indicates it is expired, a value of 1 would indicate it expires in 1 minute
		--]]
		index = math.floor((self.SlotNumber - 121)/30);
		self.Available = memoryReadUInt(getProc(), getBaseAddress(addresses.inventory.rent.base) + index * 4) ~= 0xFFFFFFFF
	else
		self.Available = true
	end

	-- Don't waste time updating if not available.
	if not self.Available then return end

	if( self.Id > 0 ) then
		CItem.update(self)
	end

	if( settings.profile.options.DEBUG_INV ) then
		if ( self.Empty ) then
			printf( "BagID: %d Slot: %d is <EMPTY>.\n", self.BagId, self.SlotNumber );
		else
			local _color = cli.white;
			printf( "BagID: %d Slot: %d\tcontains: %d\t (%d) ", self.BagId, self.SlotNumber, self.ItemCount, self.Id );
			if ( self.Quality == 1 ) then
				_color = cli.lightgreen;
			end;
			if ( self.Quality == 2 ) then
				_color = cli.blue;
			end;
			if ( self.Quality == 3 ) then
				_color = cli.purple;
			end;
			if ( self.Quality == 4 ) then
				_color = cli.yellow;
			end;
			if ( self.Quality == 5 ) then
				_color = cli.forestgreen;
			end;
			cprintf(  _color, "[%s]\n", self.Name );
		end;
	end;
end

function CInventoryItem:use()
	local canUse = true;
	local reason = "";
	self:update();

	if self.Available == false or self.Empty then
		return
	end

	-- If the item can't be used now we should be able to set a timer or something like that to recall this function and check again...
	if not self.InUse then
		local cd, success = self:getRemainingCooldown()
		if success == true and cd ~= 0 then -- Item is on CoolDown we can't use it
		--if ( self.CoolDownTime > 0 and self.LastTimeUsed ~= 0 and
		--( deltaTime( getTime(), self.LastTimeUsed ) / 1000 ) < self.CoolDownTime ) then -- Item is on CoolDown we can't use it
			canUse = false;
			reason = "Cooldown";
		end;
	else -- Item is in use, locked, we can't use it
		reason = "In use";
		canUse = false;
	end;

	if ( canUse ) then
		RoMCode("UseBagItem("..self.BagId..")");
		self.LastTimeUsed = getTime();
		yrest( 500 ); -- give time for server to respond with new item count
	else
		cprintf( cli.yellow, "DEBUG - Cannot use Item %s\t BagId: #%s ItemCount: %s\treason: %s\n", self.Name, self.BagId, self.ItemCount, reason );
		logMessage( sprintf( "DEBUG - Cannot use Item %s\t BagId: #%s ItemCount: %s\treason: %s\n", self.Name, self.BagId, self.ItemCount, reason ) );
	end;

	self:update();

	if ( settings.profile.options.DEBUG_INV ) then
		cprintf( cli.lightblue, "DEBUG - Use Item BagId: #%s ItemCount: %s\n", self.BagId, self.ItemCount );				-- Open/eqipt item:
	end;

	return self.ItemCount;
end

