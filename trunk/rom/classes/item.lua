local proc = getProc();

-- Tooltip parser keywords
ITEM_TOOLTIP_DURABILITY = {
	DE		= "Haltbarkeit",
	FR		= "Structure",
	ENEU	= "Durability", 
	ENUS	= "Durability",
	PH		= "Durability",
	RU		= "\143\224\174\231\173\174\225\226\236",
	PL		= "Trwa\136o\152\143",
	ES		= "Durabilidad",
};

-- itemquality -> color code
ITEMCOLOR = { 
	WHITE =  tonumber("0xFFFFFFFF"),
	GREEN =  tonumber("0xFF00FF00"),
	BLUE =   tonumber("0xFF0072BC"),
	PURPLE = tonumber("0xFFA864A8"),
	ORANGE = tonumber("0xFFF68E56"),
	GOLD =   tonumber("0xFFA37D50"),
};

-- making a new one because i dont know if the other is used elsewhere
ITEMQUALITYCOLOR = { 
	tonumber("0xFFFFFFFF"),
	tonumber("0xFF00FF00"),
	tonumber("0xFF0072BC"),
	tonumber("0xFFA864A8"),
	tonumber("0xFFF68E56"),
	tonumber("0xFFA37D50"),
	0,
	0,
	tonumber("0xFFA864A8"),
};

CItem = class(
	function( self, bagId )		
		self.Address = addresses.staticInventory + ( ( bagId - 61 ) * 68 );
		self.BaseItemAddress = nil;
		self.Empty = true;
		self.Id = 0;
		self.BagId = bagId;
		self.Name = "<EMPTY>";
		self.ItemCount = 0;
		self.Color = "ffffff";
		self.SlotNumber = -1; -- No idea how to get this one, i think is not used, at least not in inventory...
		self.Icon = "";
		self.ItemLink = "|Hitem:33BF1|h|cff0000ff[Empty]|r|h";
		self.Durability = 0;
		self.Quality = 0; -- 0 = white / 1 = green / 2 = blue / 3 = purple / 4 = orange / 5 = gold
		self.Value = 0;
		self.Worth = 0;
		self.InUse = false;
		self.BoundStatus = 1; -- 0 = pick, 1 = no, 2 = bound 3 = equip
		self.RequiredLvl = 0;
		self.CoolDownTime = 0;
		self.LastTimeUsed = 0;
		self.MaxStack = 0;
		self.ObjType = 0;
		
		if ( self.Address ~= nil and self.Address ~= 0 ) then
			self:update();
		end;
	end
);


function CItem:use()
	local canUse = true;
	self:update();
	
	-- If the item can't be used now we should be able to set a timer or something like that to recall this function and check again...
	if not self.InUse then
		if ( self.CoolDownTime > 0 and self.LastTimeUsed ~= 0 and
		( deltaTime( getTime(), self.LastTimeUsed ) / 1000 ) < self.CoolDownTime ) then -- Item is on CoolDown we can't use it
			canUse = false;
		end;
	else -- Item is in use, locked, we can't use it
		canUse = false;
	end;
	
	if ( canUse ) then
		RoMScript("UseBagItem("..self.BagId..");");
		self.LastTimeUsed = getTime();
	end;

	self:update();

	if ( settings.profile.options.DEBUG_INV ) then	
		cprintf( cli.lightblue, "DEBUG - Use Item BagId: #%s ItemCount: %s\n", self.BagId, self.ItemCount );				-- Open/eqipt item:
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
	local nameAddress;
	local oldId = self.Id;
	self.Id = memoryReadInt( proc, self.Address ) or 0;
	
	if ( self.Id ~= nil and self.Id ~= oldId and self.Id ~= 0 ) then
		self.BaseItemAddress = GetItemAddress( self.Id );		
		if ( self.BaseItemAddress == nil or self.BaseItemAddress == 0 ) then
			cprintf( cli.yellow, "Wrong value returned in update of item id: %d\n", self.Id );
			logMessage(sprintf("Wrong value returned in update of item id: %d", self.Id));
			return;
		end;
		
		self.Name = "";
		self.Empty = false;
		self.ItemCount = memoryReadInt( proc, self.Address + addresses.itemCountOffset );
		self.Durability = memoryReadInt( proc, self.Address + addresses.durabilityOffset );
		if ( self.Durability > 0 ) then
			self.Durability = self.Durability / 100;
		end;
		self.Value = memoryReadInt( proc, self.BaseItemAddress + addresses.valueOffset );
		if ( self.Value > 0 ) then
			self.Worth = self.Value / 10;
		end;
		self.InUse = memoryReadInt( proc, self.Address + addresses.inUseOffset ) ~= 0;
		self.BoundStatus = memoryReadInt( proc, self.Address + addresses.boundStatusOffset );
		self.RequiredLvl = memoryReadInt( proc, self.BaseItemAddress + addresses.requiredLevelOffset );
		self.MaxStack = memoryReadInt( proc, self.BaseItemAddress + addresses.maxStackOffset );
		self.ObjType = memoryReadInt( proc, self.BaseItemAddress + addresses.typeOffset );
		
		if ( self.ObjType == 2 ) then -- Consumables, lets try to get CD time
			local skillItemId = memoryReadInt( proc, self.BaseItemAddress + addresses.realItemIdOffset );
			if ( skillItemId ~= nil and skillItemId ~= 0 ) then
				local skillItemAddress = GetItemAddress( skillItemId );
				if ( skillItemAddress ~= nil and skillItemAddress ~= 0 ) then
					self.CoolDownTime = memoryReadInt( proc, skillItemAddress + addresses.coolDownOffset );
				end;
			end;
			-- cprintf( cli.yellow, "Cool down for consumable: %d\n", self.CoolDownTime );
		end;
		
		-- Special case for cards
		if ( self.Id >= 770000 and self.Id <= 771000 ) then
			-- We need to get info from NPC...
			tmp = memoryReadInt( proc, self.BaseItemAddress + addresses.idCardNPCOffset );
			npcInfoAddress = GetItemAddress( tmp );
			nameAddress = memoryReadInt( proc, npcInfoAddress + addresses.nameOffset );
			self.Name = "Card - "; -- We should add a string so we can localize this
		else
			nameAddress = memoryReadInt( proc, self.BaseItemAddress + addresses.nameOffset );
		end;

		if( nameAddress == nil or nameAddress == 0 ) then
			tmp = nil;
		else
			tmp = memoryReadString(proc, nameAddress);
		end;

		if tmp ~= nil then
			self.Name = self.Name .. tmp;
		else
			self.Name = "<EMPTY>";
		end;

		self.Quality = memoryReadInt( proc, self.BaseItemAddress + addresses.qualityBaseOffset );
		local plusQuality = memoryReadByte( proc, self.Address + addresses.qualityTierOffset );
		local quality, tier = math.modf ( plusQuality / 16 );
		-- tier = tier * 16; -- Tier not really used yet...
		if ( quality > 0 ) then
			self.Quality = self.Quality + ( quality / 2 );
		end;
		
		-- Assign color based on quality
		self.Color = ITEMQUALITYCOLOR[ self.Quality + 1 ];
		
		-- Build an usable ItemLink		
		self.ItemLink = string.format( "|Hitem:%x|h|c%x[%s]|r|h", self.Id, self.Color, self.Name );
	elseif ( self.Id == 0 ) then
		self.Empty = true;
		self.Id = 0;
		self.Name = "<EMPTY>";
		self.ItemCount = 0;
		self.Color = "ffffff";
		self.SlotNumber = -1;
		self.Icon = "";
		self.ItemLink = "|Hitem:33BF1|h|cff0000ff[Empty]|r|h";
		self.Durability = 0;
		self.Quality = 0; -- 0 = white / 1 = green / 2 = blue / 3 = purple / 4 = orange / 5 = gold
		self.Value = 0;
		self.Worth = 0;
		self.InUse = false;
		self.RequiredLvl = 0;
	else
		-- if id is not 0 and hasn't changed we only update these values
		self.ItemCount = memoryReadInt( proc, self.Address + addresses.itemCountOffset );
		self.Durability = memoryReadInt( proc, self.Address + addresses.durabilityOffset );
		if ( self.Durability > 0 ) then
			self.Durability = self.Durability / 100;
		end;
		self.InUse = memoryReadInt( proc, self.Address + addresses.inUseOffset ) ~= 0;
		self.BoundStatus = memoryReadInt( proc, self.Address + addresses.boundStatusOffset );
	end;
	
	if( settings.profile.options.DEBUG_INV ) then	
		if ( self.Empty ) then
			printf( "BagID: %d is <EMPTY>.\n", self.BagId );
		else
			local _color = cli.white;
			printf( "BagID: %d\tcontains: %d\t (%d) ", self.BagId, self.ItemCount, self.Id );
			if ( self.Quality == 1 ) then
				_color = cli.lightgreen;
			end;
			if ( self.Quality == 2 ) then
				_color = cli.blue;
			end;
			if ( self.Quality == 3 ) then
				_color = cli.purple;
			end;
			if ( self.Quality == 4 ) then
				_color = cli.yellow;
			end;
			if ( self.Quality == 5 ) then
				_color = cli.forestgreen;
			end;
			cprintf(  _color, "[%s]\n", self.Name );
		end;
	end;
--[[
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
		if(self.Id) then msg = msg.." Id "..self.Id; else msg = msg .. "<unable to parse Id> "; end;
--		if(itemLink) then msg = msg.."/"..itemLink; end;
		if(self.Name) then msg = msg.." name "..self.Name; end;
		if(self.ItemCount) then msg = msg.." qty "..self.ItemCount; end;
		cprintf(cli.lightblue, "%s\n", msg);				-- Open/eqipt item:
	end;
	
]]--
end

-- Parse from |Hitem:33BF1|h|cff0000ff[eeppine ase]|r|h
-- hmm, i whonder if we could get more information out of it than id, color and name.
function CItem:parseItemLink(itemLink)
	if itemLink == "" or itemLink == nil then
		return;
 	end

	local s,e, id, color, name = string.find(itemLink, "|Hitem:(%x+).*|h|c(%x+)%[(.+)%]|r|h");
	id = id or "000000"; color = color or "000000";
	id    = tonumber(tostring(id), 16) or 0;
	color = tonumber(tostring(color), 16) or 0;
	name = name or "<invalid>";

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