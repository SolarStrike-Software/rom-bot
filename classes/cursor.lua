CCursor = class(
	function( self )
		self.Address = 0
		self.ItemLocation = 0
		self.ItemLocationName = ""
		self.ItemId = 0
		self.ItemBagId = 0
		self.DBID = nil -- Only used for house items

		self:update();
	end
);

function CCursor:update()
	self.Address = memoryReadUInt(getProc(), addresses.cursorBase)

	self.ItemLocation = memoryReadInt(getProc(), self.Address + addresses.cursorItemLocation_offset)
	if self.ItemLocation == 0 then
		self.ItemLocationName = "<EMPTY>"
	elseif self.ItemLocation == 1 then
		self.ItemLocationName = "inventory"
	elseif self.ItemLocation == 3 then
		self.ItemLocationName = "bank"
	elseif self.ItemLocation == 4 then
		self.ItemLocationName = "equipment"
--	elseif self.ItemLocation == 6 then -- noted for possible future use
--		self.ItemLocationName = "actionbar"
--	elseif self.ItemLocation == 8 then -- noted for possible future use
--		self.ItemLocationName = "store"
	elseif self.ItemLocation == 12 then
		self.ItemLocationName = "house"
	elseif self.ItemLocation == 14 then
		self.ItemLocationName = "guildbank"
	else
		self.ItemLocationName = "other"
	end

	self.ItemId = memoryReadInt(getProc(), self.Address + addresses.cursorItemId_offset)
	if self.ItemLocation == 12 then
		self.DBID =  memoryReadInt(getProc(), self.Address + addresses.cursorItemBagId_offset)
		self.ItemBagId = memoryReadInt(getProc(), self.Address + addresses.cursorItemBagId_offset+0x4) + 1
	else
		self.DBID = nil
		self.ItemBagId = memoryReadInt(getProc(), self.Address + addresses.cursorItemBagId_offset) + 1
	end
end

function CCursor:hasItem()
	self:update()

	return self.ItemLocation ~= 0
end

function CCursor:clear()
	self:update()

	local pickupmethod
	if self.ItemLocation == 0 then
		return
	elseif self.ItemLocation == 1 then
		pickupmethod = "PickupBagItem"
	elseif self.ItemLocation == 3 then
		pickupmethod = "PickupBankItem"
	elseif self.ItemLocation == 4 then
		pickupmethod = "PickupEquipmentItem"
	elseif self.ItemLocation == 12 then
		pickupmethod = "Houses_PickupItem"
	elseif self.ItemLocation == 14 then
		pickupmethod = "GuildBank_PickupItem"
	else
		error("Unable to clear the cursor. Cursor item location not supported. "..self.ItemLocation)
	end

	if self.ItemLocation == 12 then
		RoMCode(pickupmethod.."("..self.DBID..","..self.ItemBagId..")")
	else
		RoMCode(pickupmethod.."("..self.ItemBagId..")")
	end

	if self:hasItem() then
		error("Unable to clear the cursor. Returning the item failed.")
	end
end

