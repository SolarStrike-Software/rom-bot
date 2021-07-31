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
printLine(colWidth, "HP:", player.HP .. "/" .. player.MaxHP);
printLine(colWidth, "MP:", player.MP .. "/" .. player.MaxMP);
printLine(colWidth, "MP2:", player.MP2 .. "/" .. player.MaxMP2);
print("");

printHeader("Craft Levels");
local colWidth = 20;
printLine(colWidth, "Blacksmithing:", player:getCraftLevel(CRAFT_BLACKSMITHING));
printLine(colWidth, "Carpentry:", player:getCraftLevel(CRAFT_CARPENTRY));
printLine(colWidth, "Armorcrafting:", player:getCraftLevel(CRAFT_ARMORCRAFTING));
printLine(colWidth, "Tailoring:", player:getCraftLevel(CRAFT_TAILORING));
printLine(colWidth, "Cooking:", player:getCraftLevel(CRAFT_COOKING));
printLine(colWidth, "Alchemy:", player:getCraftLevel(CRAFT_ALCHEMY));
printLine(colWidth, "Mining:", player:getCraftLevel(CRAFT_MINING));
printLine(colWidth, "Woodcutting:", player:getCraftLevel(CRAFT_WOODCUTTING));
printLine(colWidth, "Herbalism:", player:getCraftLevel(CRAFT_HERBALISM));
print("");


printHeader("Game/Loading Check");
printLine(colWidth, "In-Game:", isInGame())
printLine(colWidth, "Loading:", isLoading())
print("")

printHeader("Casting")
CPawn.updateCasting(player)
printLine(colWidth, "Casting (Pawn):", player.Casting);
player:updateCasting()
printLine(colWidth, "Casting (Player):", player.Casting);
printLine(colWidth, "Harvesting:", player.Harvesting);
printLine(colWidth, "Collecting Type", player:getCollectingType());
print("")


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
local expectations = {
	['AC_INSTRUCTION_01'] = 'AC command (Zone 81)',
	['AC_INSTRUCTION_02'] = 'Set season',
	['ZONE955_JOLIN_S1'] = 'Only I can sing on my stage!'
}
for i,key in pairs({'AC_INSTRUCTION_01', 'AC_INSTRUCTION_02', 'ZONE955_JOLIN_S1'}) do
	printLine(colWidth, key, sprintf("%-25s", getTEXT(key)), sprintf("%-25s", expectations[key]));
end

print("\nLoading data for additional testing...");
attach(getWin(player.Name));
include("/language/english.lua")
database.load();
settings.loadProfile("Default")
inventory = CInventory();
inventory:update()

print("\n")
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
for i = 60,239 do
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
printHeader("Bank", ' ');
bank = CBank()
found = 0
for i,v in pairs(bank.BagSlot) do
	if( v and not v.Empty ) then
		printLine(colWidth, i, sprintf("ID: %-8d Count: %-5d %s", v.Id or 0, v.ItemCount or 0, v.Name));
		found = found + 1
	end
end
if( found == 0 ) then
	print("No items were found in the bank")
end


print("")
printHeader("Object List");
local olist = CObjectList();
olist:update()
local displayCount = math.min(10, #olist.Objects)
printLine(colWidth, "Objects found:", #olist.Objects);
printLine(colWidth, sprintf("Top %d items", displayCount));
for i = 1, displayCount do
	v = olist.Objects[i];
	local lootable = memoryReadRepeat("byte", getProc(), v.Address + addresses.game_root.pawn.lootable_flags) or -1;
	printLine(colWidth, i, sprintf("ID: %-8d Address: 0x%08x Type: %d Name: %s, Lootable: %d", v.Id or 0, v.Address or 0, v.Type or -1, v.Name or "", lootable));
end


print("")
printHeader("Cursor Item");
local cursor = CCursor();
cursor:update()
printLine(colWidth, "Cursor item ID:", cursor.ItemId or '<invalid>');
printLine(colWidth, "Cursor item Bag ID:", cursor.ItemBagId or '<invalid>');


print("")
printHeader("Code Mods");
printHeader("Check Code In Memory", ' ');
local installableCodemods = {}
for i,v in pairs(addresses.code_mod) do
	local codemod = CCodeMod(v.base,
		v.original_code,
		v.replace_code
	);

	if( codemod:checkModified() == false ) then
		cprintf_ex("%s|green|[+]|white| %s looks good\n", string.rep(" ", 12), i);
		installableCodemods[i] = codemod;
	else
		cprintf_ex("%s|red|[x]|white| %s appears malformed/modified\n", string.rep(" ", 12), i);
	end
end

print("");
printHeader("Test if installable", ' ');
for i,codemod in pairs(installableCodemods) do
	local success = codemod:safeInstall();
	if( success ) then
		yrest(1000);
		success = codemod:safeUninstall();
		yrest(200);
	end

	if( success ) then
		cprintf_ex("%s|green|[+]|white| %s OK!\n", string.rep(" ", 12), i);
	else
		cprintf_ex("%s|red|[x]|white| Failed\n", string.rep(" ", 12), i);
	end
end
