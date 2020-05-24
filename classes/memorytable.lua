function GetItemAddress(id)
	return MemDatabase:getAddress(id);
end

-- Returns the name for a given id
local idNameMap = {};
function GetIdName(itemId, plural)
	local tab = idNameMap[itemId]
	if( tab ~= nil ) then
		-- from cache
		if( plural ) then
			if( tab['plural'] ) then
				return tab['plural'];
			end
		else
			if( tab['single'] ) then
				return tab['single'];
			end
		end
	end
	
	-- Check itemId
	if itemId == nil or itemId == 0 then
		return
	end

	-- Check plural
	local pluralOffset
	if plural == true then pluralOffset = 4 else pluralOffset = 0 end

	-- Instead of attempting to search the memdb, it might be quicker to just
	-- parse the item link.
	if( commandMacro ~= 0 and itemId >= 490000 and itemId < 540000 and MemDatabase.database[id] == nil ) then
		local link = RoMScript(sprintf("GetItemLink(%d)", itemId));
		local name = string.match(link, "%[([^%]]+)%]");
		if( name ~= nil ) then
			idNameMap[itemId] = name;
			return name;
		end
	end

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

	
	local name2 = memoryReadString(proc, nameaddress);
	if( not validName(name2, 24) ) then
		name2 = memoryReadStringPtr(proc, nameaddress, 0);
	end
	name2 = name2 or "";
	
	local result = name .. name2;
	
	local cacheType = 'single';
	if( plural ) then
		cacheType = 'plural';
	end
	
	if( idNameMap[itemId] == nil ) then
		idNameMap[itemId] = {};
	end
	idNameMap[itemId][cacheType] = result;
	return result;
end