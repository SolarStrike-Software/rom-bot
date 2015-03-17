include("memorytable.lua");
include("bankitem.lua");

CBank = class(
	function (self)

		self.MaxSlots = 300;

		self.BagSlot = {};

		local timeStart = getTime();

		for slotNumber = 1, self.MaxSlots, 1 do
			self.BagSlot[slotNumber] = CBankItem( slotNumber );
		end

		if( settings.profile.options.DEBUG_INV ) then
			printf( "Bank update took: %d\n", deltaTime( getTime(), timeStart ) );
		end;
	end
);

function CBank:update()
	local timeStart = getTime();

	for slotNumber = 1, self.MaxSlots, 1 do
		self.BagSlot[ slotNumber ]:update();
	end

	if( settings.profile.options.DEBUG_INV ) then
		printf( "Bank update took: %d\n", deltaTime( getTime(), timeStart ) );
	end;
end;

function CBank:findItem( itemNameOrId, range)
	local first, last, location = getInventoryRange(range) -- get bag slot range

	if location ~= "bank" and location ~= nil then
		printf("You can only use bank ranges with 'bank:findItem'. You cannot use '%s' which is in %s\n", range, location)
	end

	if first == nil then
		first , last = 1, 300 -- default, search all
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

function CBank:itemTotalCount(itemNameOrId, range)
	local first, last, location = getInventoryRange(range) -- get bag slot range

	if location and location ~= "bank" then
		print("bank:itemTotalCount() only supports ranges in the bank, eg. \"bank\",\"bank1\",\"bank2\",etc.")
		return
	end

	if first == nil then
		-- Default values - 1-300 for items, 1-200 for empties.
		first = 1
		if itemNameOrId == "<EMPTY>" or itemNameOrId == 0 then
			last = 200
		else
			last = 300
		end
	end

	local item
	local totalCount = 0;
	for slot = first, last do
		item = bank.BagSlot[slot]
		item:update()
 	    if item.Available and (item.Id == itemNameOrId or item.Name == itemNameOrId) then
			if itemNameOrId == "<EMPTY>" or itemNameOrId == 0 then -- so you can count empty slots
				totalCount = totalCount + 1
			else
				totalCount = totalCount + item.ItemCount;
			end
		end;
	end;

	return totalCount;
end;
