include("item.lua");

CEquipmentItem = class(CItem,
	function( self, slot )
		self.Location = "equipment"
		self.SlotNumber = slot
		self.BagId = slot

		if self.SlotNumber ~= nil then
			self:update();
		end;
	end
);

function CEquipmentItem:update()
	self.Address = addresses.staticEquipBase + ( self.BagId * 68 );

	CItem.update(self)

	if( settings.profile.options.DEBUG_INV ) then
		if ( self.Empty ) then
			printf( "Slot: %d <EMPTY>.\n", self.Slot );
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

function CEquipmentItem:use()
	self:update()

	if self.Empty then
		return
	end

	if self.InUse then
		printf("Can't use equipment item %S, item is in use.\n", self.Name)
	end;

	RoMCode("UseEquipmentItem("..self.BagId..")"); yrest(500)
	self:update()

	if ( settings.profile.options.DEBUG_INV ) then
		cprintf( cli.lightblue, "DEBUG - Use Equipment Item BagId: #%s \n", self.BagId);
	end;

	return
end
