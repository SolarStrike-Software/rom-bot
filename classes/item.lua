-- A little class

CItem = class(
	function(self,slotNumber)
		self.Id = 0;
		self.BagId = 0;
    	self.Name = "Empty";
    	self.ItemCount = 0;
    	self.Color = "ffffff";
    	self.SlotNumber = slotNumber;
    	self.ItemLink = "|Hitem:33BF1|h|cff0000ff[Empty]|r|h";
	end
)

function CItem:use()
	RoMScript("UseBagItem("..self.BagId..");");

	if( settings.profile.options.DEBUG_INV) then	
		cprintf(cli.lightblue, "DEBUG - UseBagItem: %s\n", self.BagId );				-- Open/eqipt item:
	end;

	self:update();
	
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

	if( settings.profile.options.DEBUG_INV) then	
		local msg;
		if(slotNumber) then msg = "DEBUG - "..slotNumber..": "; end;
		if(itemLink) then msg = msg.."/"..itemLink; end;
		if(name) then msg = msg.."/"..name.."/"; end;
		cprintf(cli.lightblue, msg);				-- Open/eqipt item:
	end;
	
	if (itemLink ~= "") then
		local id, color = self:parseItemLink(itemLink);

		if( settings.profile.options.DEBUG_INV) then	
			if(id) then msg = id; end;
			if(bagId) then msg = msg.."/"..bagId; end;
			if(itemCount) then msg = msg.."/"..itemCount; end;
			if(color) then msg = msg.."/"..color; end;
			cprintf(cli.lightblue, msg.."\n");				-- Open/eqipt item:
		end

		self.Id = id			     -- The real item id
		self.BagId = bagId;          -- GetBagItemLink and other RoM functins need this..
    	self.Name = name;
    	self.ItemCount = itemCount;  -- How many?
    	self.Color = color; 		 -- Rarity
    	self.ItemLink = itemLink     -- Item link, so that you can use it in chat messages
	end
end

-- Parse from |Hitem:33BF1|h|cff0000ff[eeppine ase]|r|h
-- hmm, i whonder if we could get more information out of it than id, color and name.
function CItem:parseItemLink(itemLink)
	if itemLink == "" or itemLink == nil then
		return;
 	end
	id = tonumber(string.sub(itemLink, 8, 12), 16);  -- Convert to decimal
	color = string.sub(itemLink, 19, 24);
	-- this is causing some problems so lets be safe
	name_parse_from = string.find(itemLink, '[\[]');
	name_parse_to = string.find(itemLink, '[\]]');
	name = "Error parsing name";
	if not name_parse_from == nil or not name_parse_to == nil then
		name = string.sub(itemLink, name_parse_from+1, name_parse_to-1);
	end
	return id, color, name;
end