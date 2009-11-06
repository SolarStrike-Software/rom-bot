IGF_INSTALLED = true;	-- so we can detect if the addon is installed

-- read the tooltip values for a given item in the bag (bagid)
function igf_GetTooltip(_side, _bagid)

	if( _side ~= "Left"  and  _side ~= "Right" ) then
		_side = "Right";
	end

	if( not _bagid ) then
		ChatFrame1:AddMessage("IGF: pls call igf_GetTooltip() with a valid bagid.");
		return false
	end
	
	GameTooltip:ClearLines();			-- seems not to work, still sometimes old values there ???
	GameTooltip:SetBagItem(_bagid);		-- set tooltip for given bagid
--	GameTooltip:Show()		-- ok
--	GameTooltip:Hide()		-- ok

	-- tooltip values for one side
	local tt = {};
	for i=1,40,1 do
		local lineobj, text = nil, nil;
		lineobj = _G["GameTooltipText".._side..i];
		if(lineobj) then
			text = lineobj:GetText();
			lineobj:SetText("");		-- there was a problem with old values, so one more try to clear them
		end
		
		-- set space is text empty, because RoMScript can't handle back empty strings
		if (not text  or
			text == "") then
			text = " ";
		end
		
		tt[i] = text;
	end

	if( #tt > 0 ) then
		-- RoMScript can't handle tables, so we return single values
		return tt[1],tt[2],tt[3],tt[4],tt[5],tt[6],tt[7],tt[8],tt[9],tt[10],
		  tt[11],tt[12],tt[13],tt[14],tt[15],tt[16],tt[17],tt[18],tt[19],tt[20];
	else
		return false;
	end
-- /script ReloadUI();
-- /script GameTooltip:SetBagItem(68);
-- /script igf_GetTooltip("Right", 68)
	
end


-- Parse from |Hitem:7efa5|h|cffffffff[Qufdsfdsickness I]|r|h
-- hmm, i wonder if we could get more information out of it than id, color and name.
function igf_parseItemLink(_itemlink)
	if _itemlink == "" or _itemlink == nil then
		return;
 	end
	
	local hf_itemlink = string.sub(_itemlink, 2);
	local id = tonumber(string.sub(_itemlink, 8, 12), 16);  -- Convert to decimal
	local color = string.sub(_itemlink, 19, 24);
	local name_parse_from = string.find(_itemlink, '[', 1, true);
	local name_parse_to = string.find(_itemlink, ']', 1, true);
	local name = "Error parsing name";
	if not name_parse_from == nil or not name_parse_to == nil then
		name = string.sub(_itemlink, name_parse_from+1, name_parse_to-1);
	end
	return id, color, name;
end


function igf_getSlotData(_slotnr)
	local itemlink, bagid, icon, name, itemcount = GetBagItemLink(GetBagItemInfo(_slotnr)),GetBagItemInfo(_slotnr);
	
--	local _type, _data, _name = ParseHyperlink( itemLink );
	local itemid, color = Fusion_parseItemLink( itemlink );
	local tmp = { bagid = nil, icon = nil, name = nil, itemcount = nil, itemid = nil, color = nil };
	
	-- from GetBagItemInfo()
	if(bagid)		then tmp.bagid = bagid;			end
	if(icon)		then tmp.icon = icon;			end
	if(name)		then tmp.name = name;			end
	if(itemcount)	then tmp.itemcount = itemcount; end
	-- from GetBagItemLink()
	if(itemlink)	then tmp.itemlink = itemlink;	end
	if(color)		then tmp.color = color;			end
	if(itemid)		then tmp.itemid = itemid;		end
	
	-- also return empty slots, because the allways have a bagid
	return tmp;
end


-- print Item-Ids, Bag-Ids der Taschen into the chat
-- just enter: '/script igf_printBagInfo()' into the ingame chat
function igf_printBagInfo(_maxslots)
    local occupiedSlots, totalSlots = GetBagCount()
    if(_maxslots) then totalSlots = _maxslots; end;

    for i = 1, totalSlots do
	    local itemdata = igf_getSlotData(i);
        if (itemdata.itemid) then
			ChatFrame1:AddMessage(itemdata.itemid.."/"..itemdata.name.."/"..itemdata.bagid.."/"..itemdata.color);
		end
    end

end