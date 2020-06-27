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
	--print("Begin CInventoryItem update");
	local oldBagId = self.BagId;

	self.BagId = self.SlotNumber

	if self.BagId ~= oldBagId then -- need new address
		local base= getBaseAddress(addresses.inventory.base);
		local inventory_address = base + ((self.SlotNumber-1) * 0x44);
		
		id = memoryReadInt(getProc(), inventory_address);
		if( (id>=200000 and id<=240000) or (id>=490000 and id<=640000)) then
			self.Id = id;
			self.Address = inventory_address;
			if self.Id == 221732 then
				CItem.update(self);
			end
		else
			self.BaseItemAddress = 0;
			self.Available = false;
			return;
		end
	end
	
	if( self.Id == 0 ) then
		self.Available = false;
		return;
	end

	-- Check if not rented
	if self.BagId > 120 then
		self.Available = memoryReadUInt(getProc(), getBaseAddress(addresses.inventory.rent.base) + math.floor((self.BagId - 121)/30) * 4) ~= 0xFFFFFFFF
	else
		self.Available = true
	end

	-- Don't waste time updating if not available.
	if not self.Available then return end

	CItem.update(self)

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
	--print("End");
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

