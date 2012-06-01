include("memorytable.lua");
include("bankitem.lua");

CBank = class(
	function (self)

		self.MaxSlots = 200;

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
		first , last = 1, 200 -- default, search all
	end

	local smallestStack = nil
	local item

	for slot = first, last do
		item = self.BagSlot[slot]
		item:update()
 	    if item.Available and (item.Name == itemNameOrId or item.Id == itemNameOrId) then
			if item.ItemCount > 1 then
				-- find smallest stack
				if smallestStack == nil or smallestStack.ItemCount > item.ItemCount then
					smallestStack = item
				end
			else
				return item
			end
		end;
	end;

	return smallestStack
end
