
CInventory = class(
	self.bagSlot = {}
}


function CInventory:getAmmunitionCount()
	return RoMScript2("GetInventoryItemCount('player', 9);");
end

function CInventory:getMainHandDurability()
    local durability, durabilityMax = RoMScript2("GetInventoryItemDurable('player', 15);");
	return durability/durabilityMax;
end

-- Parse from |Hitem:7efa5|h|cffffffff[Qufdsfdsickness I]|r|h
-- hmm, i whonder if we could get more information out of it than id, color and name.
function CInventory:parseItemLink(itemLink)
	id = string.sub(itemLink, 8, 12);
	color = string.sub(itemLink, 19, 24);
	name = string.sub(itemLink, string.find(itemLink, '[\[]')+1, string.find(itemLink, '[\]]')-1);
	return id, color, name;
end

-- Update one slot, get item id, bagId, name, itemCount, color
function CInventory:updateBagSlot(slotNumber)
	local itemLink, bagId, icon, name, itemCount = RoMScript2("GetBagItemLink(GetBagItemInfo("..slotNumber..")),GetBagItemInfo("..slotNumber..")");
	if (itemLink) then
		local id, color = self:parseItemLink(itemLink);
		self.bagSlot[slotNumber].id = id;                -- The real item id
		self.bagSlot[slotNumber].bagId = bagId;          -- GetBagItemLink and other RoM functins need this..
    	self.bagSlot[slotNumber].name = name;
    	self.bagSlot[slotNumber].itemCount = itemCount;  -- How many?
    	self.bagSlot[slotNumber].color = color; 		 -- Rarity
	else
	    self.bagSlot[slotNumber] = nil;
end

-- Make a full update
function CInventory:update()
	for slotNumber = 1, 60, 1 do
		self:updateBagSlot(slotNumber);
	end
end

function CInventory:countItemTotal()

end

-- Check first empty slots for new loot, and filter it
function CInventory:afterLoot()

end

function CInventory:filter()

end

-- function CInfontroy:shopping..
-- shopping for potions, and ammunation

-- banking functions