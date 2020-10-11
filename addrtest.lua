include('qword.lua');
include("addresses.lua");
include("database.lua");
include("functions.lua");
include("classes/player.lua");
include("classes/equipment.lua");
include("classes/inventory.lua");
include("classes/bank.lua");
include("classes/guildbank.lua");
include("classes/cursor.lua");
include("classes/camera.lua");
include("classes/waypoint.lua");
include("classes/waypointlist.lua");
include("classes/waypointlist_wander.lua");
include("classes/node.lua");
include("classes/object.lua");
include("classes/objectlist.lua");
include("classes/eggpet.lua");
include("classes/store.lua");
include("classes/party.lua");
include("classes/itemtypes.lua");
include("classes/pet.lua");
include("classes/memdatabase.lua");
include("classes/codemod.lua");
include("settings.lua");
include("macros.lua");

function printHeader(name, padchar)
	local width = 79;
	local padchar = padchar or '=';
	local midpoint = math.ceil((width + #name)/2);
	local left = width - midpoint;
	local right = width - #name - left;
	
	print(string.rep(padchar, left) .. name .. string.rep(padchar, right));
end

function printLine(headWidth, header, ...)
	header = sprintf("%" .. headWidth .. "s", header)
	print(header, ...);
end

function getClassName(classId)
	if( classId == nil ) then
		return "Nil";
	end
	
	if( classId == CLASS_NONE ) then
		return "none";
	elseif( classId == CLASS_GM ) then
		return "GM";
	elseif( classId == CLASS_WARRIOR ) then
		return "Warrior";
	elseif( classId == CLASS_SCOUT ) then
		return "Scout"
	elseif( classId == CLASS_ROGUE ) then
		return "Rogue";
	elseif( classId == CLASS_MAGE ) then
		return "Mage";
	elseif( classId == CLASS_PRIEST ) then
		return "Priest"
	elseif( classId == CLASS_KNIGHT ) then
		return "Knight";
	elseif( classId == CLASS_WARDEN ) then
		return "Warden";
	elseif( classId == CLASS_DRUID ) then
		return "Druid";
	elseif( classId == CLASS_WARLOCK ) then
		return "Warlock";
	elseif( classId == CLASS_CHAMPION ) then
		return "Champion";
	else
		return "Unknown class " .. classId;
	end
end

function getEquipSlotName(slotId)
	if( slotId == 0 ) then
		return "Head";
	elseif( slotId == 1 ) then
		return "Hands";
	elseif( slotId == 2 ) then
		return "Feet";
	elseif( slotId == 3 ) then
		return "Upper body";
	elseif( slotId == 4 ) then
		return "Lower body";
	elseif( slotId == 5 ) then
		return "Cape";
	elseif( slotId == 6 ) then
		return "Belt";
	elseif( slotId == 7 ) then
		return "Shoulders";
	elseif( slotId == 8 ) then
		return "Necklace";
	elseif( slotId == 9 ) then
		return "Ammo";
	elseif( slotId == 10 ) then
		return "Ranged weapon";
	elseif( slotId == 11 ) then
		return "Ring 1";
	elseif( slotId == 12 ) then
		return "Ring 2";
	elseif( slotId == 13 ) then
		return "Earring 1";
	elseif( slotId == 14 ) then
		return "earring 2";
	elseif( slotId == 15 ) then
		return "Main hand";
	elseif( slotId == 16 ) then
		return "Offhand";
	elseif( slotId == 17 ) then
		return "Gathering tool";
	elseif( slotId == 18 ) then
		return "Amulet 1";
	elseif( slotId == 19 ) then
		return "Amulet 2";
	elseif( slotId == 20 ) then
		return "Amulet 3";
	elseif( slotId == 21 ) then
		return "Back/wings";
	else
		return "Unknown slot " .. (slotId or 'nil');
	end
end

printHeader("Player Info");
local colWidth = 20;
player = CPlayer.new();
printLine(colWidth, "Name:", player.Name);
printLine(colWidth, "Class 1:", getClassName(player.Class1) .. " lvl " .. player.Level);
printLine(colWidth, "Class 2:", getClassName(player.Class2) .. " lvl " .. player.Level2);
printLine(colWidth, "MP:", player.MP .. "/" .. player.MaxMP);
printLine(colWidth, "MP2:", player.MP2 .. "/" .. player.MaxMP2);
print("");

printHeader("Equipment Info");
equipment = CEquipment();

for i = 0,#equipment.BagSlot do
	local item = equipment.BagSlot[i];
	printLine(colWidth, getEquipSlotName(i), sprintf("ID: %6d\tName: %s", item.Id, item.Name));
end


print("");
printHeader("Memdatabase");
attackId = 540000
attackAddress = GetItemAddress(attackId)
printLine(colWidth, "Attack skill address:", sprintf("0x%X", attackAddress or 0));
if( attackAddress ~= nil and attackAddress > 0 ) then
	skill = CItem()
	skill.Address = attackAddress
	skill:update()
	printLine(colWidth, "Skill ID:", skill.Id, "Expecting " .. attackId);
	printLine(colWidth, "Skill Name:", skill.Name);
end

print("");
printHeader("Texts");
for i,key in pairs({'AC_INSTRUCTION_01', 'AC_INSTRUCTION_02', 'ZONE955_JOLIN_S1'}) do
	printLine(colWidth, key, getTEXT(key));	
end

print("\nLoading data for additional testing...");
attach(getWin(player.Name));
include("/language/english.lua")
database.load();
settings.loadProfile("Default")
inventory = CInventory();
inventory:update()

printHeader("Inventory");
print("")
printHeader("Item Shop Backpack", ' ');
found = 0
for i = 0,49 do
	v = inventory.BagSlot[i]
	if( v and not v.Empty ) then
		printLine(colWidth, i, sprintf("ID: %-8d Count: %-5d %s", v.Id or 0, v.ItemCount or 0, v.Name));
		found = found + 1
	end
end
if( found == 0 ) then
	print("No items were found in this inventory")
end

print("\n")
printHeader("Backpack(s)", ' ');
found = 0
for i = 50,239 do
	v = inventory.BagSlot[i]
	if( v and not v.Empty ) then
		printLine(colWidth, i, sprintf("ID: %-8d Count: %-5d %s", v.Id or 0, v.ItemCount or 0, v.Name));
		found = found + 1
	end
end
if( found == 0 ) then
	print("No items were found in this inventory")
end
