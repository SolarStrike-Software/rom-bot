include("memorytable.lua");
include("guildbankitem.lua");

CGuildbank = class(
	function (self)

		self.PageListAddress = 0;
		self.PageAddresses = {};
		self.BagSlot = {};

		local timeStart = getTime();

		if( settings.profile.options.DEBUG_INV ) then
			printf( "Guild Bank update took: %d\n", deltaTime( getTime(), timeStart ) );
		end;
	end
);

function CGuildbank:update()
	local timeStart = getTime();

	self.PageListAddress = memoryReadUIntPtr(getProc(), addresses.staticGuildBankBase,0xC4)
	if self:updatePageAddresses() == false then
		-- Unable to update at this moment
		return
	end

	-- Flick though pages to initialize items
	for i = 1, #self.PageAddresses do
		RoMScript("GuildBank_PageRequest("..i..")")
	end

	for slotNumber = 1, #self.PageAddresses*100, 1 do
		if self.BagSlot[slotNumber] then
			self.BagSlot[ slotNumber ]:update();
		else
			self.BagSlot[slotNumber] = CGuildbankItem( slotNumber )
		end
	end

	if( settings.profile.options.DEBUG_INV ) then
		printf( "Guild Bank update took: %d\n", deltaTime( getTime(), timeStart ) );
	end;
end;

function CGuildbank:updatePageAddresses()
	local tmpPage1Address = memoryReadUIntPtr(getProc(), addresses.staticGuildBankBase,{0xC4,0x0})

	-- If update not necessary
	if self.PageAddresses[1] ~= nil and self.PageAddresses[1] == tmpPage1Address and self.PageAddresses[page] then
		return true
	end

	-- See if Guild Vault is available in this zone.
	if tmpPage1Address == self.PageListAddress then
		print ("Guild Vault not available here.")
		return false
	end

	-- Update page addresses.
	self.PageAddresses = {[1] = tmpPage1Address}
	local curPage = 1
	local nextPageAddress, newFound

	repeat
		-- Look for new page address among the 3 addresses on this page.
		newFound = false
		for i = 0, 2 do
			nextPageAddress	= memoryReadUInt(getProc(),self.PageAddresses[curPage] + i*0x4)
			-- see if we already have this address
			for k,v in pairs(self.PageAddresses) do
				if self.PageListAddress == nextPageAddress or v == nextPageAddress  then
					nextPageAddress = nil
					break
				end
			end

			if nextPageAddress then -- add it
				newFound = true
				curPage = curPage + 1
				self.PageAddresses[curPage] = nextPageAddress
				break
			end
		end
	until not newFound

	return true
end

function CGuildbank:findItem( itemNameOrId, range)
	if memoryReadBytePtr(getProc(),addresses.staticGuildBankBase, addresses.guildBankOpen_offset) ~= 1 then
		print("Warning! Guild bank is not open.")
		return
	end

	if self:updatePageAddresses() == false then
		-- Unable to update at this moment
		return
	end

	local first, last, location = getInventoryRange(range) -- get bag slot range

	if location ~= "guildbank" and location ~= nil then
		printf("You can only use guildbank ranges with 'guildbank:findItem'. You cannot use '%s' which is in %s\n", range, location)
	end

	if first == nil then
		first , last = 1, #self.PageAddresses*100 -- default, search all
	end

	local smallestStack = nil
	local item
	for slot = first, last do
		if self.BagSlot[slot] then
			item = self.BagSlot[slot]
			item:update()
		else
			self.BagSlot[slot] = CGuildbankItem(slot)
			item = self.BagSlot[slot]
		end

 	    if item.Available and (item.Name == itemNameOrId or item.Id == itemNameOrId) then
			if (os.clock() - item.LastMovedTime) > ITEM_REUSE_DELAY then
				if item.ItemCount > 1 then
					-- find smallest stack
					if smallestStack == nil or smallestStack.ItemCount > item.ItemCount then
						smallestStack = item
					end
				else
					return item
				end
			end
		end;
	end;

	return smallestStack
end

function CGuildbank:itemTotalCount(itemNameOrId, range)
	if memoryReadBytePtr(getProc(),addresses.staticGuildBankBase, addresses.guildBankOpen_offset) ~= 1 then
		print("Warning! Guild bank is not open.")
		return 0
	end

	if self:updatePageAddresses() == false then
		-- Unable to update at this moment
		return 0
	end

	local first, last, location = getInventoryRange(range) -- get bag slot range

	if location and location ~= "guildbank" then
		print("guildbank:itemTotalCount() only supports ranges in the guildbank, eg. \"guildbank\",\"guildbank1\",\"guildbank2\",etc.")
		return
	end

	if first == nil then
		first = 1
		last = #self.PageAddresses*100
	end

	local item
	local totalCount = 0;
	for slot = first, last do
		if self.BagSlot[slot] then
			item = self.BagSlot[slot]
			item:update()
		else
			self.BagSlot[slot] = CGuildbankItem(slot)
			item = self.BagSlot[slot]
		end

		if item.Available and (item.Id == itemNameOrId or item.Name == itemNameOrId) then
			if itemNameOrId == "<EMPTY>" or itemNameOrId == 0 then -- so you can count empty slots
				totalCount = totalCount + 1
			else
				totalCount = totalCount + item.ItemCount;
			end
		end
	end;

	return totalCount;
end;
