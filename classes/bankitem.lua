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

function CBankItem:update()
	self.Address = addresses.staticBankbase + ( (self.BagId - 1) * 68 );

	-- Check if available
	if self.BagId > 40 and self.BagId <= 200 then
		self.Available = memoryReadUInt(getProc(), addresses.rentBankBase + math.floor((self.BagId - 41)/40) * 4) ~= 0xFFFFFFFF
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
