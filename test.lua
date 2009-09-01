include("addresses.lua");
include("functions.lua");

attach( findWindow("Runes of Magic") );  

--- Run rom scripts, usage: RoMScript("AcceptResurrect();");
function RoMScript2(script)
	--- Get the real offset of the address
	local macro_address = memoryReadUInt(getProc(), staticmacrobase_address);

	--- Macro length is max 255, and after we add the return code,
	--- we are left with 120 character limit.
	local text = "/script r='' a={" .. script ..
	"} for i=1,#a do if a[i] then r=r..a[i]..'" .. string.char(9) .. "' end end" ..
	" EditMacro(2,'',7,r);";

	--- Write the macro
	for i = 0, 254, 1 do
		local byte = string.byte(text, i + 1);
		if( byte == null ) then
			memoryWriteByte(getProc(), macro_address + macro1_offset + i, 0);
			break;
		end
		memoryWriteByte(getProc(), macro_address + macro1_offset + i, byte);
	end
   
	-- Write something on the first address, to see when its over written
	memoryWriteByte(getProc(), macro_address + macro2_offset, 6);

	--- Execute it
	if( settings.profile.hotkeys.MACRO ) then
		keyboardPress(settings.profile.hotkeys.MACRO.key);
	end
	keyboardPress(key.VK_7);
                                               
	cnt = 0;														                     
	--- Wait for RoM to process to overwrite the first byte
	while memoryReadByte(getProc(), macro_address + macro2_offset) == 6 do
		yrest(1);
		
		-- We dont want to be caught in infinite loop
		cnt = cnt+1;
		if cnt == 200 then
			break;
		end
	end

	--- Read the outcome from macro 2
	readsz = "";
	ret = {};--{false, false, false, false, false, false, false, false, false, false};
	cnt = 0;
	for i = 0, 254, 1 do
		local byte = memoryReadByte(getProc(), macro_address + macro2_offset + i);

		if byte > 0 then
			if byte == 9 then -- Use @ to seperate
				--ret[cnt] = readsz;
				table.insert(ret, readsz);
				cnt = cnt+1;
				readsz = "";
			else
				readsz = readsz .. string.char(byte);
			end
		end
	end

	return unpack(ret);
	--return ret[0],ret[1],ret[2],ret[3],ret[4],ret[5],ret[6],ret[7],ret[8],ret[9];
end


function getItemTotal(itemName)
   local itemTotal = 0;
   for i = 1, 60, 1 do
      local bagid, icon, name, itemCount = RoMScript2("GetBagItemInfo("..i..");");
		print(name);
      if (itemName == name) then
         itemTotal = itemTotal + itemCount;
      end
   end
   return itemTotal;
end

function getItems()

	local slot = {};
   for i = 1, 60, 1 do
      local itemLink, bagid, icon, name, itemCount = RoMScript2("GetBagItemLink(GetBagItemInfo("..i..")),GetBagItemInfo("..i..")");
      if (itemLink) then
      local id, color = parseItemLink(itemLink);
      	slot[i].id = id;
      	slot[i].bagid = bagid;
      	slot[i].name = name;
      	slot[i].itemCount = itemCount;
      	slot[i].color = color;
      else
      	slot[i] = nil;
		end	
   end
end
              
      -- ammunitionCount = RoMScript2("GetInventoryItemCount('player', 9);");
      -- mainhandDurabilityValue, mainhandDurabilityValueMax = RoMScript2("GetInventoryItemDurable('player', 15);");
function needRepair()
   for i = 1, 20, 1 do
      durableValue, durableMax, itemName = RoMScript2("GetInventoryItemDurable('player', "..i..");");
      if durableValue then print(i.." "..durableValue..' '..durableMax..itemName); end
   end
   return false;
end



function parseItemLink(itemLink)
     id = string.sub(itemLink, 8, 12);
     color = string.sub(itemLink, 19, 24);
     name = string.sub(itemLink, string.find(itemLink, '[\[]')+1, string.find(itemLink, '[\]]')-1);
	  return id, color, name;
end
local id, color, name = parseItemLink("|Hitem:7efa5|h|cffbcffaf[Qufdsfdsickness I]|r|h");
print(needRepair());

--- print(getItemLinks());