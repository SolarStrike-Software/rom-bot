-- A little class

CItem = class(
	function(self,slotNumber)
		self.Id = 0;
		self.BagId = 0;
		self.Name = "";
		self.ItemCount = 0;
		self.Color = "ffffff";
		self.SlotNumber = slotNumber;
		self.ItemLink = "|Hitem:33BF1|h|cff0000ff[Empty]|r|h";
	end
)

function CItem:use()

	-- TODO: because client is to slow to notice the use in time, we reduce it by hand
	-- after we use it / we will have to check that if we also use other things
	-- that are not consumable like mounts, armor
	self:update();
	
	-- TODO: avoid some unclear bug / should be solved if we really clear empty slots
	-- or if we update fast enough?
	if( self.BagId == nil ) then
		cprintf(cli.yellow, "Empty BagId, that should not happen!\n" );
		return 0;
	end

	RoMScript("UseBagItem("..self.BagId..");");

	if (database.consumables[self.Id]) then 	-- is in consumable database? / could be reduced
		self.ItemCount = self.ItemCount - 1;
	end;

	if( settings.profile.options.DEBUG_INV) then	
		cprintf(cli.lightblue, "DEBUG - Use Item BagId: #%s ItemCount: %s\n", self.BagId, self.ItemCount );				-- Open/eqipt item:
	end;

	return self.ItemCount;
end

function CItem:delete()
    RoMScript("PickupBagItem("..self.BagId..");");
	RoMScript("DeleteCursorItem();");
	
	-- Update it!
	self:update();
end 

function CItem:__tonumber()
	return self.Id;
end

function CItem:update()
	local itemLink, bagId, icon, name, itemCount = RoMScript("GetBagItemLink(GetBagItemInfo("..self.SlotNumber..")),GetBagItemInfo("..self.SlotNumber..")");
	local id, color;

-- FIX: THERE SEEM TO BE A BUG IN THE ROM CLIENT COMMUNICATION
-- in very rar cases, the client deliver an empty or wrong bagId
-- could be the client or the RoMScript
-- sometimes slot 1-10 don't have bagid 61-70? I don't know the rule :-(
-- so we can only check missing bagIds, but not wrong bagIds

-- UNFIX: this fix breaks the bestAvailableConsumable function, because item HAS TO HAVE default values.

--	if( bagId == "" or bagId == nil) then
--		cprintf(cli.yellow, "Item:update(): empty bagid return, we don't update slot %s name %s\n", self.SlotNumber, self.Name);
--		return;		-- dont' change the values, the new ones are wrong
--		player.InventoryDoUpdate = true;
--	end

	if (itemLink == "") then		-- no item in slot
		self = CItem(self.SlotNumber);
		self.BagId = bagId;			-- always there
--		self.ItemCount = 0;			-- 0 if no item at the slot
--		self.Name = "";				
--		self.Id	= 0;
	else
		id, color = self:parseItemLink(itemLink);

		self.Id = id			     -- The real item id
		self.BagId = bagId;          -- GetBagItemLink and other RoM functions need this..
    	self.Name = name;
    	self.ItemCount = itemCount;  -- How many?
    	self.Color = color; 		 -- Rarity
    	self.ItemLink = itemLink     -- Item link, so that you can use it in chat messages
	end

	if( settings.profile.options.DEBUG_INV) then	
		local msg = "DEBUG item:update(): ";
		if(self.SlotNumber) then msg = msg.."slot "..self.SlotNumber; end;
		if(self.BagId) then msg = msg.." bagId "..self.BagId; end;
		if(self.Id) then msg = msg.." Id "..self.Id; end;
--		if(itemLink) then msg = msg.."/"..itemLink; end;
		if(self.Name) then msg = msg.." name "..self.Name; end;
		if(self.ItemCount) then msg = msg.." qty "..self.ItemCount; end;
		cprintf(cli.lightblue, "%s\n", msg);				-- Open/eqipt item:
	end;
	

end

-- Parse from |Hitem:33BF1|h|cff0000ff[eeppine ase]|r|h
-- hmm, i whonder if we could get more information out of it than id, color and name.
function CItem:parseItemLink(itemLink)
	if itemLink == "" or itemLink == nil then
		return;
 	end
 	
	local id = tonumber(string.sub(itemLink, 8, 12), 16);  -- Convert to decimal
	local color = string.sub(itemLink, 19, 24);
	-- this is causing some problems so lets be safe
	local name_parse_from = string.find(itemLink, '[\[]');
	local name_parse_to = string.find(itemLink, '[\]]');
	local name = "Error parsing name";
	if not name_parse_from == nil or not name_parse_to == nil then
		name = string.sub(itemLink, name_parse_from+1, name_parse_to-1);
	end
	return id, color, name;
end