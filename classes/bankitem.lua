include("item.lua");

CBankItem = class(CItem,
	function( self, slot )
		self.Location = "bank"
		self.SlotNumber = slot
		self.BagId = slot
		self.Available = false

		if ( self.BagId ~= nil and self.BagId ~= 0 ) then
			self:update();
		end;
	end
);

function CBankItem:isPageAvailable(page)
	if ( page == 1 ) then
		return true -- Always have page 1
	end

	if ( page > 5 ) then
		return false -- There's only 5 pages
	end

	return memoryReadIntPtr(getProc(),
		getBaseAddress(addresses.inventory.rent.base),
		addresses.inventory.rent.offset + addresses.inventory.rent.bank_offset + (page-2) * 4) >= 0
end

function CBankItem:update()
	self.Address = getBaseAddress(addresses.bank.base) + ( (self.BagId - 1) * addresses.inventory.item.size );

	-- Check if available
	if self.BagId > 40 and self.BagId <= 200 then
		-- self.Available = memoryReadUInt(getProc(), getBaseAddress(addresses.bank.rent.base) + math.floor((self.BagId - 41)/40) * 4) ~= 0xFFFFFFFF
		local page = math.floor((self.BagId - 41)/40);
		self.Available = self:isPageAvailable(page)
	else
		self.Available = true
	end

	CItem.update(self)

	if( settings.profile.options.DEBUG_INV ) then
		if ( self.Empty ) then
			printf( "Slot: %d <EMPTY>.\n", self.SlotNumber );
		else
			local _color = cli.white;
			printf( "Slot: %d\tcontains: %d\t (%d) ", self.SlotNumber, self.ItemCount, self.Id );
			if ( self.Quality == 1 ) then
				_color = cli.lightgreen;
			elseif ( self.Quality == 2 ) then
				_color = cli.blue;
			elseif ( self.Quality == 3 ) then
				_color = cli.purple;
			elseif ( self.Quality == 4 ) then
				_color = cli.yellow;
			elseif ( self.Quality == 5 ) then
				_color = cli.forestgreen;
			end;
			cprintf(  _color, "[%s]", self.Name );
			printf( "\tDura: %d\n", self.Durability );
		end;
	end;
end

function CBankItem:use()
	self:moveTo("bags")
end
