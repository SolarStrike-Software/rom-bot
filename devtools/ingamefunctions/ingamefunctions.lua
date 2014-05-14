IGF_INSTALLED = 11;	-- so we can detect if the addon is installed. The number is so we know what version is installed.
                    -- if any changes are made to any files in the 'ingamefunctions' folder, increment this number
					-- and change the check in 'settings.lua' to match this number.

-- read the tooltip values for a given item in the bag (bagid)
function igf_GetTooltip(_side, _setcommand, _arg1, ...)

	if( _side ~= "Left"  and  _side ~= "Right" ) then
		_side = "Right";
	end

	-- Check for backward compatability
	if _arg1 == nil then
		_arg1 = _setcommand
		_setcommand = "SetBagItem"
	end

	-- Check if valid GameToolip command
	if GameTooltip[_setcommand] == nil then
		ChatFrame1:AddMessage("IGF: pls call igf_GetTooltip() with a valid set command.")
		return false
	end

	if( not _arg1 ) then
		ChatFrame1:AddMessage("IGF: pls call igf_GetTooltip() with a valid bagid.");
		return false
	end

	GameTooltip:ClearLines();			-- seems not to work, still sometimes old values there ???
	GameTooltip[_setcommand](GameTooltip,_arg1,...);		-- set tooltip for given item type and id

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
function igf_questStatus(_questnameorid, _questgroup)
	if type(tonumber(_questnameorid)) == "number" then
		_questnameorid = tonumber(_questnameorid)
	else
		_questnameorid = string.lower(_questnameorid)
	end
	-- Check for valid _questgroup
	if _questgroup ~= nil then
		if type(_questgroup) == "string" then
			_questgroup = string.lower(_questgroup)
			_questgroup = string.gsub(_questgroup,"s$","") -- remove 's' at end if user used plural
		end
		if _questgroup == "normal" or _questgroup == 0 then _questgroup = 0
		elseif _questgroup == "daily" or _questgroup == 2 then _questgroup = 2
		elseif _questgroup == "public" or _questgroup == 3 then _questgroup = 3
		else _questgroup = nil
		end
	end

	--local lowername=string.lower(_questname)
	local c = 1
	local _, _, getname, _, _, _, _, _, getid, getcompleted, getquestgroup = GetQuestInfo(c)
	while getname ~= nil do
		local matched
		if type(_questnameorid) == "number" then
			matched = (_questnameorid == getid)
		else
			if string.find(_questnameorid,".",1,true) then -- Use Pattern Search
				matched = string.find(string.lower(getname), _questnameorid)
			else -- Use plain search
				matched = string.find(string.lower(getname), _questnameorid, 1, true)
			end
			if matched and _questgroup then
				matched = (_questgroup == getquestgroup)
			end
		end
		if matched then -- Quest exists
			if getcompleted == true then
				return "complete"
			else
				return "incomplete"
			end
		end
		c = c + 1
		_, _, getname, _, _, _, _, _, getid, getcompleted, getquestgroup = GetQuestInfo(c)
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

local function tableToString(_table, _formated)
	local tabs=0
	local str = ""

	local function exportstring( s )
		s = string.format( "%q",s )
		-- to replace
		s = string.gsub( s,"\\\n","\\n" )
		s = string.gsub( s,"\r","\\r" )
		s = string.gsub( s,string.char(26),"\"..string.char(26)..\"" )
		return s
	end

	local function makeString(_val, _name)

		-- first value name
		if type(_name) == "number" then
			_name = "[".. _name .. "]"
		end
		local StringValue = ""
		if _formated == true then
			StringValue = StringValue .. string.rep ("\t",tabs )
		end
		if _name ~= nil then
			StringValue = StringValue .. _name .. "="
		end

		-- Then the value
		local typ = type(_val)
		if typ == "string" then
			StringValue = StringValue .. exportstring(_val)
		elseif typ == "number" or  typ == "boolean" or  typ == "nil" then
			StringValue = StringValue .. tostring(_val)
		elseif typ == "function" or typ == "userdata" then
			StringValue = StringValue .. "\"" .. tostring(_val) .. "\""
		elseif typ == "table" then

			-- First the bracket
			StringValue = StringValue .. "{"
			if _formated == true then
				StringValue = StringValue .. "\n"
			end

			-- Then the indexed values
			tabs = tabs + 1
			local ipairsAdded = {}
			for i,v in ipairs(_val) do
				ipairsAdded[i] = true
				local tmp
				tmp = makeString(v)
				if tmp ~= "" then
					StringValue = StringValue .. tmp .. ","
					if _formated == true then
						StringValue = StringValue .. "\n"
					end
				end
			end

			-- then the values
			for i,v in pairs(_val) do
				if not ipairsAdded[i] then
					local tmp = makeString(v,i)
					if tmp ~= "" then
						StringValue = StringValue .. tmp .. ","
						if _formated == true then
							StringValue = StringValue .. "\n"
						end
					end
				end
			end
			tabs = tabs - 1

			-- Remove last comma
			if _noFormatting and StringValue:sub(#StringValue) == "," then
				StringValue = StringValue:sub(1,#StringValue - 1)
			end

			-- then the end bracket
			if _formated == true then
				StringValue = StringValue .. string.rep ("\t",tabs )
			end
			StringValue = StringValue .. "}"
		end

		return StringValue
	end

	return makeString(_table)
end

-- Highjack this function for our use
-- F9 to trigger by default
local MultiPartCommand = ""
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
	local firstChar = body:sub(1,1)
	if firstChar == "/" then -- Should be slash command
		for line in string.gmatch(body, "/[^/]*") do
			ExecuteMacroLine(line)
		end
		EditMacro(resultMacro, RESULT_MACRO_NAME ,7 , "")
	elseif body == "SendMore" then
		-- command macro to get the rest of the data from 'ResultOutput'
		-- Remove previously sent 255 char
		ResultOutput = string.sub(ResultOutput, 256)
		EditMacro(resultMacro, RESULT_MACRO_NAME ,7 , ResultOutput)
	elseif firstChar == "!" then
		-- Start of multi part command longer than 255 characters
		MultiPartCommand = body:sub(2)
		EditMacro(resultMacro, RESULT_MACRO_NAME ,7 , "")
	elseif firstChar == "@" then
		-- Continuing multi part command
		MultiPartCommand = MultiPartCommand .. body:sub(2)
		EditMacro(resultMacro, RESULT_MACRO_NAME ,7 , "")
	else
		if firstChar == "#" then -- Final part of multi part command. Reconstruct body
			body = MultiPartCommand .. body:sub(2)
			MultiPartCommand = ""
		end
		-- The initial command macro
		ResultOutput = ''
		local func = loadstring("local a={".. body .. "} return a")
		local a = {}

		if func then
			local status,err = pcall(func);
			if status == false then
				a = {err}
			else
				a = err -- Not an error but results
			end
			table.insert(a,1,status)
		else -- Faulty command that breaks the function
			a = {false, "Error in command sent to IGF."}
		end
		for i = 1, #a do
			if type(a[i]) == "table" then
				ResultOutput = ResultOutput .. tableToString(a[i]) .. string.char(9)
			else
				ResultOutput = ResultOutput .. tostring(a[i]) .. string.char(9)
			end
		end
		EditMacro(resultMacro, RESULT_MACRO_NAME ,7 , ResultOutput)
	end
end