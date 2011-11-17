IGF_INSTALLED = 1;	-- so we can detect if the addon is installed. The number is so we know what version is installed.
                    -- if any changes are made to any files in the 'ingamefunctions' folder, increment this number
					-- and change the check in 'settings.lua' to match this number.

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

		-- set space if text is empty, because RoMScript can't handle back empty strings
		if (not text  or
			text == "") then
			text = " ";
		end

		tt[i] = text;
	end

	-- RoMScript can't handle tables, so we return single values
	return unpack(tt)

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
	if name_parse_from ~= nil and name_parse_to ~= nil then
		name = string.sub(_itemlink, name_parse_from+1, name_parse_to-1);
	end
	return id, color, name;
end


function igf_getSlotData(_slotnr)
	local itemlink, bagid, icon, name, itemcount = GetBagItemLink(GetBagItemInfo(_slotnr)),GetBagItemInfo(_slotnr);

--	local _type, _data, _name = ParseHyperlink( itemLink );
	local itemid, color = igf_parseItemLink( itemlink );
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

	-- also return empty slots, because they always have a bagid
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

-- questname = name of quest
function igf_questStatus(_questname)
	local lowername=string.gsub(string.lower(_questname),"'","")
	local c = 1
	local getname = GetQuestRequest(c,-2)
	while getname ~= nil do
		getname=string.gsub(getname,"'","")
		if string.find(string.lower(getname), lowername) then -- Quest exists
			for i = 1, GetQuestRequest(c,-1) do -- for each goal
				__,getstatus = GetQuestRequest(c,i)
				if getstatus == 0 then -- check if not complete
					return "incomplete"
				end
			end
			return "complete"
        end
		c = c + 1
		getname = GetQuestRequest(c,-2)
	end
	return "not accepted"
end

local COMMAND_MACRO_NAME = "RB Command"
local RESULT_MACRO_NAME = "RB"
local ResultOutput
local commandMacro
local resultMacro

local function FindMacros()
	commandMacro = nil
	resultMacro = nil

	for m = 1, 48 do
		local icnum,name,body=GetMacroInfo(m)
		if name == COMMAND_MACRO_NAME then
			commandMacro = m
		elseif name == RESULT_MACRO_NAME then
			resultMacro = m
		end
		if commandMacro and resultMacro then
			break
		end
	end

	return commandMacro, resultMacro
end

-- Highjack this function for our use
-- F9 to trigger by default
function ToggleUI_TITLE()
	-- Check if macro numbers have been set
	if commandMacro == nil or resultMacro == nil then
		commandMacro, resultMacro = FindMacros()
	else -- Check if they've moved
		local __,cName=GetMacroInfo(commandMacro)
		local __,rName=GetMacroInfo(resultMacro)
		if cName ~= COMMAND_MACRO_NAME or rName ~= resultMacro then
			commandMacro, resultMacro = FindMacros()
		end
	end

	--Read command macro
	local icnum,name,body=GetMacroInfo(commandMacro)
	if string.find(body,"^/") then -- Should be slash command
		ExecuteMacroLine(body)
		EditMacro(resultMacro, RESULT_MACRO_NAME ,7 , "")
	elseif body == "SendMore" then
		-- command macro to get the rest of the data from 'ResultOutput'
		-- Remove previously sent 255 char
		ResultOutput = string.sub(ResultOutput, 256)
		EditMacro(resultMacro, RESULT_MACRO_NAME ,7 , ResultOutput)
	else
		-- The initial command macro
		ResultOutput = ''
		local func = loadstring("local a={".. body .. "} return a")
		local a = {}
		if func then
			a = func()
		end
		for i = 1, #a do
			ResultOutput = ResultOutput .. tostring(a[i]) .. string.char(9)
		end
		EditMacro(resultMacro, RESULT_MACRO_NAME ,7 , ResultOutput)
	end
end

