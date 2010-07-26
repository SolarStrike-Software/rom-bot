local proc = getProc();

CEquipItem = class(
	function( self, slot )		
		self.Address = addresses.staticEquipBase + ( ( slot - 1 ) * 68 );
		self.BaseItemAddress = nil;
		self.Empty = true;
		self.Id = 0;
		self.Slot = slot;
		self.Name = "<EMPTY>";
		self.ItemCount = 0; -- I'll keep this for consumables like arrows
		self.Color = "ffffff";
		self.ItemLink = "|Hitem:33BF1|h|cff0000ff[Empty]|r|h";
		self.Durability = 0;
		self.MaxDurabilty = 0;
		self.Quality = 0; -- 0 = white / 1 = green / 2 = blue / 3 = purple / 4 = orange / 5 = gold
		self.Value = 0;
		self.Worth = 0;
		self.Bound = false; -- 1 = no, 2 = bound
		self.RequiredLvl = 0;
		self.MaxStack = 0;
		
		if ( self.Address ~= nil and self.Address ~= 0 ) then
			self:update();
		end;
	end
);

function CEquipItem:update()
	local oldId = self.Id;
	self.Id = memoryReadInt( proc, self.Address );
	-- printf( "Address: %X\ID: %d\n", self.Address, self.Id );
	
	if self.Id ~= oldId and self.Id ~= 0 then
		local nameAddress;
		self.BaseItemAddress = GetItemAddress( self.Id );
		-- printf( "Base item address: %X\tID: %d\n", self.BaseItemAddress, self.Id );
		self.Name = "";
		self.Empty = false;
		self.ItemCount = memoryReadInt( proc, self.Address + addresses.itemCountOffset );
		self.Durability = memoryReadInt( proc, self.Address + addresses.durabilityOffset );
		self.MaxDurability = memoryReadByte( proc, self.Address + addresses.maxDurabilityOffset );
		if ( self.Durability > 0 ) then
			self.Durability = self.Durability / 100;
		end;
		self.InUse = memoryReadInt( proc, self.Address + addresses.inUseOffset ) ~= 0;
		self.BoundStatus = memoryReadInt( proc, self.Address + addresses.boundStatusOffset );
		local plusQuality = memoryReadByte( proc, self.Address + addresses.qualityTierOffset );
		local quality, tier = math.modf ( plusQuality / 16 );
		tier = tier * 16;
		-- printf( "Quality: %X\tTier: %X\n", quality, tier );
		if ( quality > 0 ) then
			self.Quality = self.Quality + ( quality / 2 );
		end;
		self.Color = ITEMCOLOR[ self.Quality + 1 ];
		
		self.ItemLink = string.format( "|Hitem:%x|h|c%x[%s]|r|h", self.Id, self.Color or 0xffffffff, self.Name );

		if ( self.BaseItemAddress ~= nil and self.BaseItemAddress ~= 0 ) then
			nameAddress = memoryReadInt( proc, self.BaseItemAddress + addresses.nameOffset );
			if( nameAddress == nil or nameAddress == 0 ) then
				tmp = nil;
			else
				tmp = memoryReadString(proc, nameAddress);
			end;

			if tmp ~= nil then
				self.Name = self.Name .. tmp;
			else
				self.Name = "<EMPTY>";
			end;

			self.Value = memoryReadInt( proc, self.BaseItemAddress + addresses.valueOffset );
			if ( self.Value > 0 ) then
				self.Worth = self.Value / 10;
			end;
			self.RequiredLvl = memoryReadInt( proc, self.BaseItemAddress + addresses.requiredLevelOffset );
			self.MaxStack = memoryReadInt( proc, self.BaseItemAddress + addresses.maxStackOffset );
			self.Quality = memoryReadInt( proc, self.BaseItemAddress + addresses.qualityBaseOffset );
		else
			self.Name = "<UNKNOWN>";
		end;
	elseif ( self.Id == 0 ) then
		self.Empty = true;
		self.Id = 0;
		self.Name = "<EMPTY>";
		self.ItemCount = 0;
		self.Color = "ffffff";
		self.ItemLink = "|Hitem:33BF1|h|cff0000ff[Empty]|r|h";
		self.Durability = 0;
		self.Quality = 0; -- 0 = white / 1 = green / 2 = blue / 3 = purple / 4 = orange / 5 = gold
		self.Value = 0;
		self.Worth = 0;
		self.RequiredLvl = 0;
		self.Bound = false;
	else
		-- if id is not 0 and hasn't changed we only update these values
		self.ItemCount = memoryReadInt( proc, self.Address + addresses.itemCountOffset );
		self.Durability = memoryReadInt( proc, self.Address + addresses.durabilityOffset );
		if ( self.Durability > 0 ) then
			self.Durability = self.Durability / 100;
		end;
		self.InUse = memoryReadInt( proc, self.Address + addresses.inUseOffset ) ~= 0;
	end;
	
	if( settings.profile.options.DEBUG_INV ) then	
		if ( self.Empty ) then
			printf( "Slot: %d <EMPTY>.\n", self.Slot );
		else
			local _color = cli.white;
			printf( "Slot: %d\tcontains: %d\t (%d) ", self.Slot, self.ItemCount, self.Id );
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
