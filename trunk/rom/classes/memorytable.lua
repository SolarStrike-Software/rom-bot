local tablePointer;
local endTablePointer;
local itemSize = 32;
local proc = getProc();
local tables = {};
local threshold = 150; -- We look back a maximum of "threshold" items to check if the table continues
local idThreshold = 50; -- How many items we look back or forward to get the right address for a skill, i would like to keep this as small as we can to get better performance...

-- Internal debuging use only...
local debugTableIndexes = false;
local debugTableRanges = false;

CTRange = class(
	function(self, _start, _end, startAddress)
		self.Start = _start;
		self.End = _end;
		self.StartAddress = startAddress;
	end
);


CTDef = class(
	function (self, ptr)
		self.Address = ptr;
		self.EnAddress = 0;
		self.StartId = 0;
		self.EndId = 0;
		self.Name = "<UNKNOWN>";
		self.Ranges = {};
		
		if( self.Address ~= nil and self.Address ~= 0 ) then self:Update(); end;
	end
);

function CTDef:Update()
	self.StartId = memoryReadInt(proc, self.Address + addresses.idOffset );
	if ( self.StartId > 800000 ) then -- Special case for one table that starts 32 bytes before...
		self.Address = self.Address - 32;
		self.StartId = memoryReadInt(proc, self.Address + addresses.idOffset );
	end;
	self.EndId = 0;
	local lastId = self.StartId;
	local currId;
	local lastStartId = self.StartId;
	local lastStartDir = self.Address;
	local currItemDir = self.Address;
	local lastItemDir = self.Address;

	if ( debugTableIndexes ) then
		printf("Table starts with id: %d\t\t Dir: %X\n", self.StartId, self.Address);
	end;

	while ( lastId ~= nil and lastId ~= 0 ) do
		currItemDir = currItemDir - itemSize; -- We move itemSize bytes up to go to next one
		currId = memoryReadInt(proc, currItemDir + addresses.idOffset ); -- 12 bytes offset id object
			
		if ( currId == nil or currId == 0 or ( ( currId > ( lastId + 3 ) ) or ( currId < ( lastId - 3 ) ) ) ) then
			-- Fiors we add the recently found range if its needed...
			local found = false;
			for _, _table in ipairs(tables) do
				if ( lastStartId >= _table.StartId and lastId <= _table.EndId ) then
					found = true;
					break;
				end;
			end;
			for _, _range in ipairs(self.Ranges) do
				if ( lastStartId >= _range.Start and lastId <= _range.End ) then
					found = true;
					break;
				end;
			end;

			if ( (lastId and not self.EndId) or self.EndId < lastId ) then
				self.EndId = lastId;
			end;
			
			if ( found == false ) then
				-- We dind't find any more ids in range, add this one to the table
				table.insert(self.Ranges, CTRange(lastStartId, lastId, lastStartDir));
				if ( debugTableRanges ) then
					cprintf( cli.yellow, "Adding range. Start: %d\tEnd: %d\tAddress: %X\tTable#: %d\n", lastStartId, lastId, lastStartDir, #tables );
				end;
			end;

			currItemDir = GetNextTableAddress( lastItemDir );

			if ( currItemDir ~= nil ) then
				currId = memoryReadInt(proc, currItemDir + addresses.idOffset ); -- 12 bytes offset object id
				if ( currId == nil or currId == 0 or ( ( currId > ( lastId + 3 ) ) or ( currId < ( lastId - 3 ) ) ) ) then
					-- no more ids for current table
					break;
				else
					self.EndId = currId;
					lastStartId = currId;
					lastStartDir = currItemDir;
				end;
			else
				break;
			end;
		end;

		if ( currId and currItemDir and self.StartId > currId ) then
			lastStartId = currId;
			lastStartDir = currItemDir;
			self.StartId = currId;
			self.Address = currItemDir;
		end;

		lastId = currId;
		lastItemDir = currItemDir;
	end;
end;

function GetTablesPointers()
	local tablePointerDir = memoryReadIntPtr( proc, addresses.tablesBase, addresses.tablesBaseOffset );
	tablePointer = tablePointerDir;
	endTablePointer = memoryReadInt(proc, tablePointerDir + 0x4);
	-- cprintf(cli.yellow, "Tables dir: %x \t Final: %X\n\n\n", tablePointer, endTablePointer);
end;

function IdIsInRange( newId, lastId, _threshold )
	if ( newId == nil ) then
		return false;
	end;
	if ( _threshold == nil ) then
		_threshold = threshold;
	end;
	if ( newId > lastId and newId < ( lastId + _threshold ) ) then
		return true;
	end;
	
	return false;
end;

function GetNextTableAddress( ptr )
	local _address;
	local lastId = memoryReadInt( proc,  ptr + addresses.idOffset ); -- 12 bytes offset id
	local found = true;
	local tmpID;
	
	local function CheckAddress( addressToCheck )
		local tmp = memoryReadInt( proc, addressToCheck + 0x4 );
		local tmpOffset, tmpOffset4;
		
		if ( tmp ~= nil ) then
			tmpOffset = memoryReadInt( proc, tmp ) or 0;
			tmpOffset4 = memoryReadInt( proc, tmp + 0x4 ) or 0;
			tmpID = memoryReadInt( proc, tmp + addresses.idOffset ) or 0;
			
			if debugTableIndexes then
				cprintf( cli.green, "Readed from %X\t at 0x4 %X\tOriginal pointer: %X\n", addressToCheck, tmp, ptr );
				if tmpOffset ~= addressToCheck and tmpOffset4 ~= addressToCheck then
					printf( cli.red, "Offset at 0x0 points to: %X\tOffset at 0x4 points to: %X\n", tmpOffset or 0, tmpOffset4 or 0 );
				end;
			end;
			
			if ( ( tmp ~= addressToCheck and tmp ~= ptr ) and ( tmpOffset == addressToCheck or tmpOffset4 == addressToCheck ) and IdIsInRange( tmpID, lastId ) ) then
				if debugTableIndexes then
					cprintf( cli.lightblue, "Returning: %X\n", tmp );
				end;
				return tmp;
			end;
		end;
		tmp = memoryReadInt( proc, addressToCheck + 0x8 );

		if ( tmp ~= nil ) then
			tmpOffset = memoryReadInt( proc, tmp );
			tmpOffset4 = memoryReadInt( proc, tmp + 0x4 );
			tmpID = memoryReadInt( proc, tmp + addresses.idOffset );

			if debugTableIndexes then
				cprintf( cli.green, "Readed at %X\t in 0x8 %X\tID: %d\n", addressToCheck, tmp, tmpID or 0 );
				if tmpOffset ~= addressToCheck and tmpOffset4 ~= addressToCheck then
					printf( cli.red, "Offset at 0x0 points to: %X\tOffset at 0x4 points to: %X\n", tmpOffset or 0, tmpOffset4 or 0 );
				end;
			end;

			if ( ( tmp ~= addressToCheck and tmp ~= ptr ) and ( tmpOffset == addressToCheck or tmpOffset4 == addressToCheck ) and IdIsInRange( tmpID, lastId ) ) then
				if debugTableIndexes then
					cprintf( cli.lightblue, "Returning: %X\n", tmp );
				end;
				return tmp;
			end;
		end;
		
		if debugTableIndexes then
			cprintf( cli.turquoise, "Returning NIL\n" );
		end;
		return nil;
	end;
	
	_address = CheckAddress( ptr );
	
	if _address == nil then -- Lets try to find an addres backwards
		found = false;
		for i = 1, threshold do
			_address = CheckAddress( ( ptr + ( i * itemSize ) ) );
			if _address ~= nil then 
				found = true;
				break;
			end; -- found a match
		end;
	end
	
	if found then -- we found an address now check if id is in the right range
		tmpID = memoryReadInt( proc,  _address + addresses.idOffset ); -- 12 bytes id offset

		if ( tmpID ~= ( lastId + 1 ) ) then
			if debugTableIndexes then
				print("Falla 3\n");
				printf("\rTenemos ID: %d\tEn dir: %X\n", lastId or 0, _address );
			end;
			found = false;
			for i = 1, threshold do -- 10 lines should be enough...
				_address = _address + itemSize; -- we go back one item to see if it fits the id we are looking for
				tmpID = memoryReadInt( proc, _address + addresses.idOffset ); -- 12 bytes offset del id
				if debugTableIndexes then
					printf("\rReaded 2: %d\n", tmpID or 0 );
				end;
				if ( tmpID == ( lastId + 1 ) ) then
					-- We found it, we can exit and return the address.
					found = true;
					if debugTableIndexes then
						print("Found by brute force 2\n");
					end;
					return _address;
				end;
			end;
		end;
	end;

	if not found then
		_address = nil;
	end;
	
	if debugTableIndexes then
		cprintf( cli.red, "Received: %X\tReturning: %X\n" ,ptr, _address or 0 );
	end;
	return _address;
end;

function GetTableForID( id )

	for _, _table in ipairs( tables ) do
		if ( id >= _table.StartId and id <= _table.EndId ) then
			return _table;
		end;
	end;
	
	printf( "Table not found for ID: %d\n", id );
	return nil;
end;

function GetItemAddress( id )
   local _table = GetTableForID( id );
   local _address;
   local tmpAddress;
   
   if _table ~= nil then
      for _, _range in ipairs( _table.Ranges ) do
         if ( id >= _range.Start and id <= _range.End ) then
            tmp = id - _range.Start;
            -- We substract 32 bytes (itemSize) multiplied by the the number that is the difference between the id we get and the range start
            _address = _range.StartAddress - ( tmp * 32 );
            if ( debugTableIndexes and id >= 550000 and id <= 560000 ) then
               cprintf( cli.yellow, "We got id: %d\range starts at: %d and ends at: %d\n", id, _range.Start, _range.End );
            end;
            -- We check if this is the right one, there are mixed ids, don't know why i think is just instantiation of tables problem...
            tmpAddress = memoryReadIntPtr(proc, _address + 0x10, 0x8);
            local tmpId = memoryReadInt( proc, tmpAddress );
            if ( debugTableIndexes and id >= 550000 and id <= 560000 ) then
               cprintf( cli.yellow, "We readed id: %d\tat address; %X\n", id, tmpAddress );
            end;
            if ( id ~= tmpId and IdIsInRange( tmpId, id, idThreshold ) ) then
               -- Look forward
               for i = 1, idThreshold do
                  _address = _range.StartAddress - ( ( tmp - i ) * 32 );
                  tmpAddress = memoryReadIntPtr(proc, _address + 0x10, 0x8);
                  tmpId = memoryReadInt( proc, tmpAddress );
                  if ( id == tmpId ) then
                     break;
                  elseif ( debugTableIndexes and id >= 550000 and id <= 560000 ) then
                     cprintf( cli.yellow, "We readed id: %d\tat address; %X\n", id, tmpAddress );
                  end;
               end;
               -- Look backwards
               for i = 1, idThreshold do
                  _address = _range.StartAddress - ( ( tmp + i ) * 32 );
                  tmpAddress = memoryReadIntPtr(proc, _address + 0x10, 0x8);
                  tmpId = memoryReadInt( proc, tmpAddress );
                  if ( id == tmpId ) then
                     break;
                  elseif ( debugTableIndexes and id >= 550000 and id <= 560000 ) then
                     cprintf( cli.yellow, "We readed id: %d\tat address; %X\n", id, tmpAddress );
                  end;
               end;
               -- Couldn't find it, we give up...
               _address = nil;
            end;
         end;
      end;
   end;
   if ( _address ~= nil ) then
      _address = tmpAddress;
   end;
   return _address;
end;

function LoadTables_cached(filename)
	GetTablesPointers();

	include(filename);
	tables = {};
	for i,v in pairs(cached_tables) do
		local nt = CTDef();
		nt.Address = v.Address;
		nt.EnAddress = v.EnAddress;
		nt.StartId = v.StartId;
		nt.EndId = v.EndId;
		nt.Name = v.Name;
		nt.Ranges = {};
		for i,v in pairs(v.Ranges) do
			table.insert(nt.Ranges, CTRange(v.Start, v.End, v.StartAddress));
		end
		--nt:Update();
		table.insert(tables, nt);
	end

	cached_tables = nil;
end

function LoadTables_memory()
	GetTablesPointers();
	
	local realTablePointer = memoryReadInt(proc, tablePointer);
	local punteroTablaDatos;
	
	if( not settings.profile.options.DEBUG_INV ) then
		cprintf( cli.yellow, "Loading items tables.\n" );
	end;

		local i = 0;
	while ( i < 28 ) do
		local name = memoryReadString( proc, realTablePointer + 38 ); -- This isn't really necessary but is here for debuging purposes...
		
		if debugTableIndexes or debugTableRanges then
			printf("Name: %s\n", name);
		end;

		if( not settings.profile.options.DEBUG_INV ) then
			displayProgressBar( ( i + 1 ) / 28 * 100, 50);
		end;

		local dataPointerTemporal = memoryReadIntPtr( proc, realTablePointer, addresses.tableStartPtrOffset );
		if dataPointerTemporal ~= nil then
			local dataPointer = memoryReadInt( proc, dataPointerTemporal + addresses.tableDataStartPtrOffset );
			-- We move up 32 bytes from the name line
			dataPointer = dataPointer - itemSize;
			local primerId = memoryReadInt( proc, dataPointer + addresses.idOffset ); -- 12 bytes offset del id de objeto
			local _table = CTDef(dataPointer);
			_table.Name = name;
			_table:Update();
			table.insert( tables, _table);
		end;
		i = i + 1;
		realTablePointer = memoryReadInt( proc, tablePointer + ( i * 4 ) );
	end;
	print( "\n" );
end;

function LoadTables()
	FlushOldCachedTables();
	local fname = getExecutionPath() .. "/cache/itemstables." .. getWin() .. ".lua";
	if( fileExists(fname) ) then
		LoadTables_cached(fname);
	else
		LoadTables_memory();
		CacheTables();
	end
end

function FlushOldCachedTables()
	local dir = getDirectory(getExecutionPath() .. "/cache");

	for i,v in pairs(dir) do
		local valid = true;
		local win = string.match(v, "^itemstables.(%d+).lua");
		if( win ) then
			if( windowValid(win) ) then
				if( getWindowClassName(win) ~= "Radiant Arcana" ) then
					valid = false;
				end
			else
				valid = false;
			end
		end

		-- if not valid, delete it.
		if( valid == false ) then
			local function fixSlashes(path)
				--path = string.gsub(path, "\\+", "/");
				path = string.gsub(path, "/+", "\\");

				return path;
			end

			printf("Deleting %s (old cache file)\n", v);
			system("del " .. fixSlashes(getExecutionPath() .. "/cache/" .. v));
		end
	end
end

function CacheTables()
	local outFile = io.open(getExecutionPath() .. "/cache/itemstables." .. getWin() .. ".lua", "w");
	outFile:write("cached_tables = {\n");
	for i,v in pairs(tables) do
		local rangesString = "";
		for i,v in pairs(v.Ranges) do
			rangesString = rangesString .. sprintf("{Start = 0x%X, End = 0x%X, StartAddress = 0x%X}, ", v.Start, v.End, v.StartAddress);
		end
		outFile:write(sprintf("\t{Address = 0x%X, EnAddress = 0x%x, StartId = 0x%X, EndId = 0x%x, Name = \"%s\", Ranges = {%s}},\n",
			v.Address, v.EnAddress, v.StartId, v.EndId, v.Name, rangesString));
	end
	outFile:write(sprintf("}\n\n"));
end
-- LoadTables();