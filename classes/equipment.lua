include("memorytable.lua");
include("equipmentitem.lua");

CEquipment = class(
	function (self)

		self.MaxSlots = 21;

		self.BagSlot = {};

		local timeStart = getTime();

		for slotNumber = 0, self.MaxSlots, 1 do
			self.BagSlot[slotNumber] = CEquipmentItem( slotNumber );
		end

		if( settings.profile.options.DEBUG_INV ) then
			printf( "Equipment update took: %d\n", deltaTime( getTime(), timeStart ) );
		end;
	end
);

function CEquipment:update()
	local timeStart = getTime();

	for slotNumber = 0, 21, 1 do
		self.BagSlot[ slotNumber ]:update();
	end

	if( settings.profile.options.DEBUG_INV ) then
		printf( "Equipment update took: %d\n", deltaTime( getTime(), timeStart ) );
	end;
end;

function CEquipment:getAmmunitionCount()
	self.BagSlot[9]:update();

	return self.BagSlot[9].ItemCount;
end;

function CEquipment:findItem(range)
	local first, last, location = getInventoryRange(range)
	if location ~= "equipment" or range == "equipment" then
		printf("equipment:findItem(): 'range' must be a valid equipment type and not 'equipment'\n")
		return
	end

	if first == nil then
		prinf("equipment:finditem(range): Invalid range used '%s'\n",(range or "nil"))
		return
	end

	return self.BagSlot[first]
end

function CEquipment:useItem(range)
	local item = self:findItem(range)

	if item then
		item:use()
		return true, item.Id, item.Name;
	end;

	return false;
end;

function CEquipment:isEquipped( range )
-- return true if equipped is equipped at slot and has durability > 0

	local slot, __, location = getInventoryRange(range)

	if slot == nil or location ~= "equipment" then
		prinf("equipment:isEquipped(): Invalid range used '%s'\n",(range or "nil"))
		return
	end

	self.BagSlot[ slot ]:update();

	if( self.BagSlot[ slot ].Empty ) then
		return false;
	end;

	if( self.BagSlot[ slot ].Durability <= 0 ) then
		return false;
	end;

	return true;
end;

function CEquipment:getDurability( _slot )
	-- return item durability for a given slot in percent from 0 - 100

	if( not _slot) then _slot = 15; end		-- 15=MainHand | 16=OffHand | 10=Ranged

	self.BagSlot[ _slot ]:update();
	return self.BagSlot[ _slot ].Durability / self.BagSlot[ _slot ].MaxDurability * 100;
end;
