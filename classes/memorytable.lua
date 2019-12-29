

local AddresslineTree = {} -- Holds representation of id tree in memory for quicker navigation.
local IdAddressTables = {} -- Holds results for previous addresslines for ids, for quick re-use.
function GetItemAddress(IdToFind)
	return -1; -- TODO: Fix this eventually
--[[
	local proc = getProc()
	-- Initial set up, and if client is restarted.
	local tmpBase = memoryReadUIntPtr(proc, addresses.item.table_base, 0xC)
	if AddresslineTree.BaseAddress ~= tmpBase then
		IdAddressTables = {}
		AddresslineTree = {}
		AddresslineTree.BaseAddress = tmpBase
		AddresslineTree.Root = memoryReadUInt( proc, AddresslineTree.BaseAddress + 0x4 )
	end

	-- Navigate AddresslineTree to find correct addressline
	local addressline = IdAddressTables[IdToFind] or AddresslineTree.Root
	while addressline ~= AddresslineTree.BaseAddress do
		-- Only read memory if node does not exist in tree
		if not AddresslineTree[addressline] then
			-- Add node ([1]= Low branch address, [2]= High branch address, [3]= Id, [4]= Item data address)
			AddresslineTree[addressline] = memoryReadBatch(proc, addressline, "i4_iii")
			-- Remember id addressline
			IdAddressTables[AddresslineTree[addressline][3] ] = addressline
		end
		if AddresslineTree[addressline][3] == IdToFind then -- Match. Return data address
			local address = memoryReadUInt( proc, AddresslineTree[addressline][4] + 0x8)
			if address == 0 then
				-- Item data not substanciated yet. Do "GetCraftRequestItem", then the address will exist.
				if commandMacro ~= 0 and SlashCommand then -- SlashCommand because it's faster.
					SlashCommand("/script GetCraftRequestItem(".. IdToFind ..",-1)")
					-- Wait until data address appears
					repeat
						yrest(5)
						address = memoryReadUInt( proc, AddresslineTree[addressline][4] + 0x8)
					until address ~= 0
				end
			end
			return address
		elseif AddresslineTree[addressline][3] > IdToFind then
			addressline = AddresslineTree[addressline][1] -- Lower id
		else
			addressline = AddresslineTree[addressline][2] -- Higher id
		end
	end

	if settings.options.DEBUGGING == true then printf("Id %d not found\n", id) end
	--]]
end

-- Returns the name for a given id
function GetIdName(itemId, plural)
	return "<Unknown>"; -- TODO: Fix this eventually
--[[
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

	local proc = getProc()
	-- If card or recipe, update itemId, itemAddress and prefix name
	local name = ""
	if itemId >= 770000 and itemId <= 772000 then
		itemId = memoryReadInt( proc, itemAddress + addresses.item.card_or_npc_id );
		if itemId == 0 then return end
		itemAddress = GetItemAddress( itemId );
		name = getTEXT("SYS_CARD_TITLE")	-- "Card - "
	elseif itemId >= 550000 and itemId <= 553000 then
		itemId = memoryReadInt( proc, itemAddress + addresses.item.recipe_id );
		if itemId == 0 then return end
		itemAddress = GetItemAddress( itemId );
		name = getTEXT("SYS_RECIPE_TITLE")	-- "Recipe - "
	end

	-- Get name/plural address
	local nameaddress = memoryReadInt(proc, itemAddress + addresses.item.name + pluralOffset)
	if nameaddress == 0 and commandMacro ~= 0 and SlashCommand then
		SlashCommand("/script GetCraftRequestItem(".. itemId ..",-1)")
		local starttime = getTime()
		repeat
			yrest(5)
			nameaddress = memoryReadInt(proc, itemAddress + addresses.item.name + pluralOffset)
		until nameaddress ~= 0 or deltaTime(getTime(),starttime) > 200
	end

	return name .. memoryReadString(proc, nameaddress)
	--]]
end