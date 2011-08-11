local function GetIdAddressLine(id)
	local lineSize = 0x20;

	-- Finds the nearest address in 'IdAddressTables' with the closest id to '_id'
	local function FindNearestIdAddress(_id)
		local closestId
		for i,v in pairs(IdAddressTables) do
			if closestId == nil or math.abs(_id - i) < math.abs(_id - closestId) then
				closestId = i
			end
		end

		return IdAddressTables[closestId]
	end

	-- Searches for the address in memoery for the id 'IdToFind'
	local function FindIdAddress(IdToFind)
		-- Get closest existing address from IdAddressTables to start search
		local dataPointer = FindNearestIdAddress(IdToFind)

		local loopTest = 0 -- Used to make sure it doesn't get stuck in a loop if bad id
		repeat
			loopTest = loopTest + 1

			-- Get 0 and 8 offsets
			local offset8 = memoryReadInt( getProc(), dataPointer + 8);
			-- Has it reached the end of the table?
			if offset8 < 0x100000 then
				return
			end
			local offset0 = memoryReadInt( getProc(), dataPointer );

			-- Get the id
			local currentId = memoryReadInt( getProc(), dataPointer + addresses.idOffset );

			-- Check the id.
			if currentId == nil or currentId < 1 or currentId > 999999 then
				return
			end

			-- Add to table to speed future searches
			if not IdAddressTables[currentId] then
				IdAddressTables[currentId] = dataPointer
			end

			-- Id not found. Get next dataPointer.
			if currentId > IdToFind then
				if offset0 == offset8 then
					dataPointer = dataPointer + lineSize
				else
					dataPointer = offset0
				end
			elseif currentId < IdToFind then
				if offset0 == offset8 then
					dataPointer = dataPointer - lineSize
				else
					dataPointer = offset8
				end
			end

			--printf("currentAddress %X , current ID %X:%d IdToFind %X:%d\n",dataPointer,currentId,currentId,IdToFind,IdToFind)
			--yrest(5)

		until currentId == IdToFind or loopTest > 500

		return dataPointer
	end

	--first initialization
	if not IdAddressTables then
		local tablePointer = memoryReadIntPtr( getProc(), addresses.tablesBase, addresses.tablesBaseOffset )
		local startAddressOffsets = {0,addresses.tableStartPtrOffset, addresses.tableDataStartPtrOffset}

		local dataPointer = memoryReadIntPtr( getProc(), tablePointer, startAddressOffsets) - lineSize
		local id = memoryReadInt(getProc(), dataPointer + addresses.idOffset )

		IdAddressTables = {[id] = dataPointer}
	end

	-- Is it already in the table
	if IdAddressTables[id] then
		return IdAddressTables[id]
	end

	-- Else find it in memory
	return FindIdAddress(id)
end

function GetItemAddress(id)
	if id then
		local addressline = GetIdAddressLine(id)
		if addressline then
			local address = memoryReadIntPtr( getProc(), addressline + 0x10, 0x8)
			if address == 0 then
				-- Item data not substanciated yet. Do "GetCraftRequestItem", then the address will exist.
				RoMScript("GetCraftRequestItem("..id..", -1)")
				address = memoryReadIntPtr( getProc(), addressline + 0x10, 0x8);
			end
			return address
		else
			printf("Id %d not found\n", id)
		end
	else
		printf("Id is nil\n")
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
