-- A little class

-- Tooltip parser keywords
ITEM_TOOLTIP_DURABILITY = {
	DE		= "Haltbarkeit",
	FR		= "Structure",
	ENEU	= "Durability", 
	ENUS	= "Durability"
	};

-- itemquality -> color code
ITEMCOLOR = { 
	WHITE =  tonumber("0xFFFFFFFF"),
	GREEN =  tonumber("0xFF00FF00"),
	BLUE =   tonumber("0xFF0072BC"),
	PURPLE = tonumber("0xFFA864A8"),
	ORANGE = tonumber("0xFFF68E56"),
	GOLD =   tonumber("0xFFA37D50"),
	}

CItem = class(
	function(self,slotNumber)
		self.Id = 0;
		self.BagId = 0;
		self.Name = "";
		self.ItemCount = 0;
		self.Color = "ffffff";
		self.SlotNumber = slotNumber;
		self.Icon = "";
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

--	local old_BagId = self.BagId;	-- remember bagId before update
	local itemLink, bagId, icon, name, itemCount = RoMScript("GetBagItemLink(GetBagItemInfo("..self.SlotNumber..")),GetBagItemInfo("..self.SlotNumber..")");
	local id, color;

-- FIX: THERE SEEM TO BE A BUG IN THE ROM CLIENT COMMUNICATION
-- in very rar cases, the client deliver an empty or wrong bagId
-- e.g. if we press a modifier while running the bot in background
-- sometimes slot 1-10 don't have bagid 61-70? I don't know the rule :-(
-- so we can only check missing bagIds, but not wrong bagIds
--	if( old_BagId ~= nil  and				-- not the default value
--		old_BagId ~= 0	  and
--		old_BagId ~= bagId ) then			-- but a wrong value back, so we skip that item update
	if( type(bagId) ~= "number" or			-- no valid bagId return
		bagId < 1	or						-- bag I-VI are from 61-240 / itemshop bag from 1-50 / arcaner transmutor from 51-55
		bagId > 240 ) then
		cprintf(cli.yellow, "Item:update(): empty or wrong bagid return, we don't update slot %s name %s\n", self.SlotNumber, self.Name);
		return;		-- dont' change the values, the new ones are wrong
	end

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
    	self.Icon = icon;
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

	local s,e, id, color, name = string.find(itemLink, "|Hitem:(%x+).*|h|c(%x+)%[([%w%p%s]+)");
	id    = tonumber( "0x" .. tostring(id) );
	color = tonumber( "0x" .. tostring(color) );

	return id, color, name;
end

function CItem:getGameTooltip(_place)
-- _place = Left | Right
--
-- here the whole ingame function more clear:
-- ------------------------------------------
--	GameTooltip:SetBagItem(_bagid);
--	local tooltip_right = {};
--	for i=1,40,1 do
--		local lineobj, text = _G["GameTooltipTextRight"..i];
--		
--		if(lineobj) then
--			text = lineobj:GetText();
--			lineobj:SetText("");
--		end;
--		
--		if (text) then
--			table.insert(tooltip_right, text);
--		end;
--	end;
--
--	return tooltip_right;
-- ----------------------------------

	local t = {};
	
	t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],
	t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],
	t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],
	t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40]
	= RoMScript("igf_GetTooltip('Right',"..self.BagId..")");

--cprintf(cli.yellow, "it %s\n", t[1]);
--cprintf(cli.yellow, "it %s\n", t[2]);
--cprintf(cli.yellow, "it %s\n", t[3]);
--cprintf(cli.yellow, "it %s\n", t[4]);
--cprintf(cli.yellow, "it %s\n", t[5]);
--cprintf(cli.yellow, "it %s\n", t[6]);
--
--	local code1 = "GameTooltip:SetBagItem("..self.BagId..");";
--	local code2 = "local t={};for i=1,40,1 do local l,t=_G[\"GameTooltipText".._place.."\"..i];x=l:GetText();l:SetText(\"\");t[i]=x;end;return t;";
--	RoMScript(code1);	-- load the tooltip for the item
--	local tooltip = RoMScript(code2);	-- read the tooltip

	if( t[1]  and
		t[1] ~= false ) then
		return t;
	else
		return false
	end
	
end

-- translate the hex color code into the color string
function CItem:getColorString()

	for i,v in pairs(ITEMCOLOR) do

		if( v == self.Color ) then
			return i;
		end
	end

	return false

end