function CheckForItem(itemn)
    local occupiedSlots, totalSlots = GetBagCount()
    for i = 1, totalSlots do
        local index, texture, name, itemCount, locked, invalid = GetBagItemInfo(i)
        if name == itemn then
            return index
        end
    end
end

-- Parse from |Hitem:7efa5|h|cffffffff[Qufdsfdsickness I]|r|h
-- hmm, i whonder if we could get more information out of it than id, color and name.
function parseItemLink(itemLink)
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

function PrintBagInfo(_maxslots)
    local occupiedSlots, totalSlots = GetBagCount()
    if(_maxslots) then totalSlots = _maxslots; end;

    for i = 1, totalSlots do
        local itemLink, bagId, icon, name, itemCount = GetBagItemLink(GetBagItemInfo(i)),GetBagItemInfo(i);
        if (itemLink) then
		local id, color = parseItemLink(itemLink);
		SendSystemChat(id.."/"..name.."/"..bagId);
	end
    end

end