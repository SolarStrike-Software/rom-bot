local proc = getProc()
local tablePointer = memoryReadIntPtr( proc, addresses.tablesBase, addresses.tablesBaseOffset )
local itemSize = 0x20
local tables = {}
local threshold = 10 -- We look back a maximum of "threshold" items to check if the table continues
local maxId = 800000
local CACHE_PATH = getExecutionPath() .. "/../cache"

CTRange = class(
	function(self, _start, _end, startAddress)
		self.Start = _start
		self.End = _end
		self.StartAddress = startAddress
	end
)

-- This function searches for the address where the current range continues
-- It accepts the last address of the last item and returns the address where the range continues or nil.
function GetNextTableAddress( lastStartAddress, ptr )

	local lastId = memoryReadInt( proc,  ptr + addresses.idOffset ) -- 12 bytes offset id
	local _address
	local tmpID

	-- This function checks an address to see if the 4 and 8 offset hold the address where the range continues.
	-- It returns this range if found or returns nil.
	local function CheckAddress( addressToCheck )

		-- Check the 0x4 offset address
		local tmpAddress = memoryReadInt( proc, addressToCheck + 0x4 )
		if ( tmpAddress ~= nil ) then
			if tmpAddress > lastStartAddress then
				return tmpAddress
			end
		end

		-- Check the 0x8 offset address
		local tmpAddress = memoryReadInt( proc, addressToCheck + 0x8 )
		if ( tmpAddress ~= nil ) then
			if tmpAddress > lastStartAddress then
				return tmpAddress
			end
		end

		return nil
	end

	-- Find address pointing to where the range continues
	-- The address pointing to where the range continues may not be in the last item so we search backwards for it
	for t = 0, threshold do
		_address = CheckAddress( ( ptr + ( t * itemSize ) ) )
		if _address ~= nil then
			break
		end -- found a match
	end

	-- The new address might not point to the first item so we look back until we find the first one
	if _address then
		for i = 0, threshold do -- 10 lines should be enough...
			local tmpID = memoryReadInt( proc, _address + addresses.idOffset ) -- 12 bytes offset del id
			if ( tmpID == ( lastId + 1 ) ) then
				-- We found it, we can exit and return the address.
				return _address
			end
			_address = _address + itemSize -- we search back to find first id that continues range
		end

		-- Continuing id not found
		_address = nil
	end

	return _address
end

-- This function finds which subtable and range the id belongs to
function GetRangeForID( id )
	-- If tables hasn't been loaded yet then exit
	if #tables == 0 then return end

	for _, _table in ipairs( tables ) do
		if ( id >= _table.StartId and id <= _table.EndId ) then
			-- make sure the id is in one of the ranges
			for _, _range in pairs(_table.Ranges) do
				if ( id >= _range.Start and id <= _range.End ) then
					return _range
				end
			end
		end
	end

	printf( "Table range not found for ID: %d\n", id )
	return nil
end

-- This function returns the address where the item info is located.
function GetItemAddress( id )
	-- Gets the address for the item
	local function GetTmpAddress( _address, _id )
		local address = memoryReadIntPtr(proc, _address + 0x10, 0x8)
		if address == 0 then
			-- Item data not substanciated yet. Do "GetCraftRequestItem", then the address will exist.
			RoMScript("GetCraftRequestItem(".._id..", -1)")
			address = memoryReadIntPtr(proc, _address + 0x10, 0x8)
		end
		return address
	end

	local _range = GetRangeForID( id )

	if _range ~= nil then
		local _address

		-- Get the address. Check that it's the right one, else check the one before and after it.
		for _,i in pairs({ 0, -1, 1 }) do
			local tmpAddress = _range.StartAddress - (id - _range.Start + i) * itemSize
			local testId = memoryReadInt(proc, tmpAddress + addresses.idOffset)
			if testId == id then -- right address
				_address = tmpAddress
				break
			end
		end

		if _address == nil then
			printf("Failed to find correct address in range for id %d.\n", id)
			return
		end

		local itemAddress = GetTmpAddress( _address, id )
		local itemId = memoryReadInt( proc, itemAddress )

		if itemId == id then
			return itemAddress
		else
			printf("Failed to find correct item address for id %d.\n", id)
		end
	end
end

-- Returns the name for a given id
function GetIdName(itemId)
	if itemId ~= nil and itemId > 0 then
		local itemAddress = GetItemAddress(itemId)
		if itemAddress ~= nil and itemAddress > 0 then
			return memoryReadStringPtr(getProc(), itemAddress + addresses.nameOffset, 0)
		end
	end
end

-- This function loads 'tables' from cache file.
function LoadTables_cached(filename)
	local status, err = pcall(dofile, filename)
	if( not status ) then
		-- Failed to load the cache file.
		cprintf(cli.red, "[DEBUG] Failed to load cache file; Dropping bad file.\n")

		LoadTables_memory()
		CacheTables()
		return
	end

	tables = {}
	for i,v in pairs(cached_tables) do
		tables[i] = {
			StartId = v.StartId,
			EndId = v.EndId,
			Name = v.Name,
			Ranges = {},
		}

		for k,v in pairs(v.Ranges) do
			table.insert(tables[i].Ranges, CTRange(v.Start, v.End, v.StartAddress))
		end
	end
	cached_tables = nil
end

-- This function creates the 'tables' table from memory.
function LoadTables_memory()
	tables = {}

	-- Get start addresses, names and startids for the 27 subTables
	for i = 1, 27 do
		tables[i] = {}

		displayProgressBar( i / 27 * 100, 50)

		-- Get initial address
		local startAddressOffsets = {0,addresses.tableStartPtrOffset, addresses.tableDataStartPtrOffset}
		local initialAddress = memoryReadIntPtr( proc, tablePointer + (4 * (i - 1)), startAddressOffsets) - 0x20

		-- Get start id but check first 2 because they could be back-to-front.
		local id1 = memoryReadInt( proc, initialAddress + addresses.idOffset )
		local id2 = memoryReadInt( proc, initialAddress - itemSize + addresses.idOffset)

		-- In at least 1 case the table starts 1 up from here
		if id1 == 0 or id1 == nil or id1 > maxId then
			initialAddress = initialAddress - itemSize
			id1 = memoryReadInt( proc, initialAddress - itemSize + addresses.idOffset )
		end

		-- Set lowest id as StartId
		if id1 > id2 then
			tables[i].StartId = id2
			tables[i].EndId = id1
		else
			tables[i].StartId = id1
			tables[i].EndId = id2
		end

		-- Get name - isn't really necessary but is here for debuging purposes...
		tables[i].Name = memoryReadStringPtr( proc, tablePointer + (4 * (i - 1)), 40)

		-- Scan for ranges
		tables[i].Ranges = {}

		local lastStartAddress = initialAddress
		local lastStartId = tables[i].StartId
		local rangeHighestAddress = initialAddress
		local count = 1 -- skip first 2 because they could be back-to-front.
		repeat
			count = count + 1
			local currAddress = lastStartAddress - itemSize * count
			local currId = memoryReadInt( proc, currAddress + addresses.idOffset )

			-- End of range detetection
			local lastId = lastStartId + count - 1
			if currId == nil or currId == 0 or currId ~= (lastStartId + count) then
				-- Save range
				table.insert(tables[i].Ranges,CTRange(lastStartId, lastId, lastStartAddress))

				-- Check min and max table values
				if lastStartId < tables[i].StartId then tables[i].StartId = lastStartId end
				if lastId > tables[i].EndId then tables[i].EndId = lastId end

				-- Does another range immediately follow
				if currId ~= nil and currId ~= 0 and currId > tables[i].StartId and currId < maxId then
					lastStartAddress = currAddress
					lastStartId = currId
				else -- Search if the range continues at another address
					lastStartAddress = GetNextTableAddress( rangeHighestAddress, currAddress + itemSize ) -- search for next address from last address
					if lastStartAddress ~= nil then
						rangeHighestAddress = lastStartAddress
						lastStartId = memoryReadInt( proc, lastStartAddress + addresses.idOffset )
					end
				end

				count = 0
			end
		until lastStartAddress == nil
	end
end

-- This function decides whether to load the 'tables' data from file or from memory.
function LoadTables()
	FlushOldCachedTables()
	local fname = CACHE_PATH .. "/itemstables." .. getWin() .. ".lua"
	if( fileExists(fname) ) then
		LoadTables_cached(fname)
	else
		LoadTables_memory()
		CacheTables()
	end
end

-- This function deletes any cache files that are no longer needed
function FlushOldCachedTables()
	local dir = getDirectory(CACHE_PATH)
	if( not dir ) then
		return
	end

	for i,v in pairs(dir) do
		local valid = true
		local win = string.match(v, "^itemstables.(%d+).lua")
		if( win ) then
			if( windowValid(win) ) then
				if( getWindowClassName(win) ~= "Radiant Arcana" ) then
					valid = false
				end
			else
				valid = false
			end
		end

		-- if not valid, delete it.
		if( valid == false ) then
			local function fixSlashes(path)
				--path = string.gsub(path, "\\+", "/")
				path = string.gsub(path, "/+", "\\")

				return path
			end

			if( system and allowSystemCommands ) then
				printf("Deleting %s (old cache file)\n", v)
				system("del \"" .. fixSlashes(CACHE_PATH .. "/" .. v) .. "\"")
			end
		end
	end
end

-- This function saves 'tables' to the cache file.
function CacheTables()
	local outFile = io.open(CACHE_PATH .. "/itemstables." .. getWin() .. ".lua", "w")
	if( not outFile ) then
		return
	end

	outFile:write("cached_tables = {\n")
	for i,v in pairs(tables) do
		local rangesString = ""
		for i,v in pairs(v.Ranges) do
			rangesString = rangesString .. sprintf("\t\t{Start = %d, End = %d, StartAddress = 0x%X},\n", v.Start, v.End, v.StartAddress)
		end
		outFile:write(sprintf("\t{StartId = %d, EndId = %d, Name = \"%s\", Ranges = {\n%s\t}},\n",
			v.StartId, v.EndId, v.Name, rangesString))
	end
	outFile:write(sprintf("}\n\n"))
	outFile:close()
end
