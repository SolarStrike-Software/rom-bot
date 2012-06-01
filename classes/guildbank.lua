include("memorytable.lua");
include("guildbankitem.lua");

CGuildbank = class(
	function (self)

		self.MaxSlots = 100;

		self.BagSlot = {};

		local timeStart = getTime();

		for slotNumber = 1, self.MaxSlots, 1 do
			self.BagSlot[slotNumber] = CGuildbankItem( slotNumber );
		end

		if( settings.profile.options.DEBUG_INV ) then
			printf( "Guild Bank update took: %d\n", deltaTime( getTime(), timeStart ) );
		end;
	end
);

function CGuildbank:update()
	local timeStart = getTime();

	for slotNumber = 1, self.MaxSlots, 1 do
		self.BagSlot[ slotNumber ]:update();
	end

	if( settings.profile.options.DEBUG_INV ) then
		printf( "Guild Bank update took: %d\n", deltaTime( getTime(), timeStart ) );
	end;
end;

function CGuildbank:findItem( itemNameOrId, range)
	local first, last, location = getInventoryRange(range) -- get bag slot range

	if location ~= "guildbank" and location ~= nil then
		printf("You can only use guildbank ranges with 'guildbank:findItem'. You cannot use '%s' which is in %s\n", range, location)
	end

	if first == nil then
		first , last = 1, 100 -- default, search all
	end

	if memoryReadBytePtr(getProc(),addresses.staticGuildBankBase, addresses.guildBankOpen_offset) ~= 1 then
		print("Warning! Guild bank is not open.")
	end

	local smallestStack = nil
	local item

	for slot = first, last do
		item = self.BagSlot[slot]
		item:update()
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
