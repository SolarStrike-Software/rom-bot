include("item.lua");

CGuildbankItem = class(CItem,
	function( self, slot )
		self.Location = "guildbank"
		self.SlotNumber = slot
		self.BagId = slot
		self.Available = false

		if ( self.BagId ~= nil and self.BagId ~= 0 ) then
			self:update();
		end;
	end
);

function CGuildbankItem:update()
	local baseAddress = memoryReadIntPtr(getProc(),addresses.staticGuildBankBase,{0xB4, 0x0}) + 0x10
	self.Address = baseAddress + ( (self.BagId - 1) * 68 );

	-- Check if available
	local GuildBankClosed = memoryReadBytePtr(getProc(),addresses.staticGuildBankBase, addresses.guildBankOpen_offset) ~= 1
	if GuildBankClosed then
		self.Available = false
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


