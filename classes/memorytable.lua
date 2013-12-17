local function GetIdAddressLine(id)
	local lineSize = 0x20;

	local tablePointer = memoryReadUIntPtr( getProc(), addresses.tablesBase, addresses.tablesBaseOffset )
	local startAddressOffsets = {0,addresses.tableStartPtrOffset, addresses.tableDataStartPtrOffset}

	local dataPointer = memoryReadUIntPtr( getProc(), tablePointer , startAddressOffsets ) - lineSize
	local IdTableHeader

	--Reads into the table to get a 'IdTableHeader' address
	for i=0,10 do
		local offset0 = memoryReadUInt( getProc(),  dataPointer - lineSize * i )
		local offset8 = memoryReadUInt( getProc(), (dataPointer - lineSize * i ) + 0x8)
		if offset0 == offset8 then
			IdTableHeader = offset0
			break
		end
	end

	if IdTableHeader == nil then
		error("Unable to find a valid IdTableAddress")
	end

	--Get informations from the 'IdTableHeader'
	local smallestIdAddress   = memoryReadUInt( getProc(), IdTableHeader )
	local middleIdAddress     = memoryReadUInt( getProc(), IdTableHeader + 0x4 )
	local largestIdAdress     = memoryReadUInt( getProc(), IdTableHeader + 0x8 )

	local smallestId    	  = memoryReadInt( getProc(), smallestIdAddress + addresses.idOffset )
	local largestId     	  = memoryReadInt( getProc(), largestIdAdress + addresses.idOffset )

	-- Searches for the address in memory for the id 'IdToFind'
	local function FindIdAddress(IdToFind)
		-- Check the 'IdToFind'.
		if IdToFind == nil or IdToFind < smallestId or IdToFind > largestId then
			return
		end
		-- Use the middleIdAddress from IdAddressTables to start search
		local dataPointer = middleIdAddress

		local loopTest = 0 -- Used to make sure it doesn't get stuck in a loop if bad id
		repeat
			loopTest = loopTest + 1

			-- Get 0 and 8 offsets
			local offset8 = memoryReadUInt( getProc(), dataPointer + 8)
			-- Read a valid value? Has it reached the end of the table?
			if offset8 == nil or offset8 < 0x100000 then
				return
			end
			local offset0 = memoryReadUInt( getProc(), dataPointer )

			-- Get the id
			local currentId = memoryReadInt( getProc(), dataPointer + addresses.idOffset )

			--printf("currentAddress %X , current ID %X:%d IdToFind %X:%d\n",dataPointer,currentId,currentId,IdToFind,IdToFind)

			-- Check the id.
			if currentId == nil or currentId < smallestId or currentId > largestId then
				return
			end

			-- Add to table to speed future searches
			if not IdAddressTables[currentId] then
				IdAddressTables[currentId] = dataPointer
			end

			-- Id not found. Get next dataPointer.
			if currentId > IdToFind then
				if offset0 == offset8 or offset0 == IdTableHeader then
					dataPointer = dataPointer + lineSize
				else
					dataPointer = offset0
				end
			elseif currentId < IdToFind then
				if offset0 == offset8 or offset8 == IdTableHeader then
					dataPointer = dataPointer - lineSize
				else
					dataPointer = offset8
				end
			end

		until currentId == IdToFind or loopTest > 500

		return dataPointer
	end

	if IdAddressTables == nil then
		IdAddressTables = {}
	end

	-- Is it already in the table
	if IdAddressTables[id] then
		return IdAddressTables[id]
	end

	-- Else find it in memory
	return FindIdAddress(id)
end

function GetItemAddress(id)
	if not id then
		if settings.options.DEBUGGING == true then printf("Id is nil\n") end
		return
	end

	local addressline = GetIdAddressLine(id)
	if not addressline then
		if settings.options.DEBUGGING == true then printf("Id %d not found\n", id) end
		return
	end

	local address = memoryReadUIntPtr( getProc(), addressline + 0x10, 0x8)
	if address == 0 then
		-- Item data not substanciated yet. Do "GetCraftRequestItem", then the address will exist.
		if RoMScript then RoMScript("GetCraftRequestItem("..id..", -1)") end
		address = memoryReadUIntPtr( getProc(), addressline + 0x10, 0x8);
	end

	return address
end

-- Returns the name for a given id
function GetIdName(itemId, plural)
	-- Check itemId
	if itemId == nil or itemId == 0 then
		return
	end

	-- Check plural
	local pluralOffset
	if plural == true then pluralOffset = 4 else pluralOffset = 0 end

	-- Get and check item address
	local itemAddress = GetItemAddress(itemId)
	if itemAddress == nil or itemAddress == 0 then
		return
	end

	-- If card or recipe, update itemId, itemAddress and prefix name
	local name = ""
	if itemId >= 770000 and itemId <= 772000 then
		itemId = memoryReadInt( getProc(), itemAddress + addresses.idCardNPCOffset );
		if itemId == 0 then return end
		itemAddress = GetItemAddress( itemId );
		name = getTEXT("SYS_CARD_TITLE")	-- "Card - "
	elseif itemId >= 550000 and itemId <= 553000 then
		itemId = memoryReadInt( getProc(), itemAddress + addresses.idRecipeItemOffset );
		if itemId == 0 then return end
		itemAddress = GetItemAddress( itemId );
		name = getTEXT("SYS_RECIPE_TITLE")	-- "Recipe - "
	end

	-- Get name/plural address
	local nameaddress = memoryReadInt(getProc(), itemAddress + addresses.nameOffset + pluralOffset)
	if nameaddress == 0 and RoMScript then
		RoMScript("GetCraftRequestItem("..itemId..", -1)")
		nameaddress = memoryReadInt(getProc(), itemAddress + addresses.nameOffset + pluralOffset)
	end

	return name .. memoryReadString(getProc(), nameaddress)
end
