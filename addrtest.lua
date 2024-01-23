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

local logfile = io.open(getExecutionPath() .. '/addrtest-debug.txt', 'w')
function tee(...)
	log_debug(...)
	print(...)
end

function log_debug(...)
	for i,v in pairs(unpack2(...)) do
		local str = tostring(v):gsub("\\r", "");
		if( player ~= nil ) then
			-- Hide player's name from output
			str = str:gsub(player.Name, "<redacted>");
		end
		logfile:write(str);
	end
	logfile:write("\n")
end

function printHeader(name, padchar)
	local width = 79;
	local padchar = padchar or '=';
	local midpoint = math.ceil((width + #name)/2);
	local left = width - midpoint;
	local right = width - #name - left;

	tee(string.rep(padchar, left) .. name .. string.rep(padchar, right));
end

function printLine(headWidth, header, ...)
	header = sprintf("%" .. headWidth .. "s", header)
	tee(header, ...);
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

local colWidth = 20;


printHeader("State info")
printLine(colWidth, "Game version:", getGameVersion());
printLine(colWidth, "Git revison:", getCurrentRevision());
tee("");

printHeader("Player Info");
player = CPlayer.new();
printLine(colWidth, "Address:", sprintf("0x%X", player.Address));
printLine(colWidth, "Level:", memoryReadInt(getProc(), player.Address + addresses.game_root.pawn.level));
printLine(colWidth, "Name:", player.Name);
--print(sprintf("%" .. colWidth .. "s", "Name:"), player.Name);
printLine(colWidth, "Class 1:", getClassName(player.Class1) .. " lvl " .. player.Level);
printLine(colWidth, "Class 2:", getClassName(player.Class2) .. " lvl " .. player.Level2);
printLine(colWidth, "HP:", player.HP .. "/" .. player.MaxHP);
printLine(colWidth, "MP:", player.MP .. "/" .. player.MaxMP);
printLine(colWidth, "MP2:", player.MP2 .. "/" .. player.MaxMP2);
printLine(colWidth, "Target:", sprintf('0x%X', player.TargetPtr or 0) .. ' (' .. (player:getTarget().Id or 0) .. ')');
tee("");

printHeader("Class Info");
local classInfoBase = memoryReadUInt(getProc(), getBaseAddress(addresses.class_info.base)) + addresses.class_info.offset;
printLine(colWidth, "Warrior:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_WARRIOR - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Scout:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_SCOUT - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Rogue:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_ROGUE - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Mage:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_MAGE - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Priest:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_PRIEST - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Knight:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_KNIGHT - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Warden:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_WARDEN - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Druid:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_DRUID - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Warlock:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_WARLOCK - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Champion:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_CHAMPION - 1) + addresses.class_info.level)) or 'failed to read');
tee("");

printHeader("Player Buffs");
player:updateBuffs()
for i,v in pairs(player.Buffs) do
	tee(i, v.Id, v.Name)
end
tee("");

printHeader("Party");
for i = 1,6 do
	pcheck = GetPartyMemberAddress(i)
	if pcheck then
		member = CPawn(pcheck.Address)
		printLine(colWidth, member.Id, member.Name);
	end
end
tee("")

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
tee("");


printHeader("Game/Loading Check");
printLine(colWidth, "In-Game:", isInGame())
printLine(colWidth, "Loading:", isLoading())
tee("")

printHeader("Casting")
CPawn.updateCasting(player)
printLine(colWidth, "Casting (Pawn):", player.Casting);
player:updateCasting()
printLine(colWidth, "Casting (Player):", player.Casting);
printLine(colWidth, "Harvesting:", player.Harvesting);
printLine(colWidth, "Collecting Type", player:getCollectingType());
tee("")


printHeader("Equipment Info");
equipment = CEquipment();

for i = 0,#equipment.BagSlot do
	local item = equipment.BagSlot[i];
	printLine(colWidth, getEquipSlotName(i), sprintf("0x%X\tID: %6d\tName: %s\tDura: %s/%s", item.Address, item.Id, item.Name, item.Durability, item.MaxDurability));
end
tee("")
printLine(colWidth, "Ammo: ", equipment.BagSlot[9].ItemCount)

tee("");
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

tee("");
printHeader("Texts");
local expectations = {
	['AC_INSTRUCTION_01'] = 'AC command (Zone 81)',
	['AC_INSTRUCTION_02'] = 'Set season',
	['ZONE955_JOLIN_S1'] = 'Only I can sing on my stage!'
}
for i,key in pairs({'AC_INSTRUCTION_01', 'AC_INSTRUCTION_02', 'ZONE955_JOLIN_S1'}) do
	printLine(colWidth, key, sprintf("%-25s", getTEXT(key) or 'not found'), sprintf("%-25s", expectations[key]));
end

tee("\nLoading data for additional testing...");
attach(getWin(player.Name));
include("/language/english.lua")
database.load();
settings.loadProfile("Default")
inventory = CInventory();
inventory:update()

tee("\n")
printHeader("Inventory");
tee("")
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
	tee("No items were found in this inventory")
end

tee("\n")
printHeader("Backpack(s)", ' ');
found = 0;
local foundItem = nil;
for i = 60,239 do
	v = inventory.BagSlot[i]
	if( v and not v.Empty ) then
		if( foundItem == nil and v.Id == 200663) then
			-- We'll dump more details on this item later
			foundItem = v;
		end
		printLine(colWidth, i, sprintf("ID: %-8d Bound: %d Count: %-5d 0x%X  %s", v.Id or 0, v.Bound and 1 or 0, v.ItemCount or 0, v.Address, v.Name or ""));
		found = found + 1
	end
end
if( found == 0 ) then
	tee("No items were found in this inventory")
end

if( foundItem ) then
	tee("\n")
	printHeader("Item details", ' ');

	printLine(colWidth, 'Address', sprintf("0x%X", foundItem.Address));
	printLine(colWidth, 'ID', foundItem.Id);
	printLine(colWidth, 'Name', foundItem.Name);
	printLine(colWidth, 'Empty', foundItem.Empty);
	printLine(colWidth, 'Location', foundItem.Location);
	printLine(colWidth, 'SlotNumber', foundItem.SlotNumber);
	printLine(colWidth, 'BagId', foundItem.BagId);
	printLine(colWidth, 'Available', foundItem.Available);
	printLine(colWidth, 'Quality', foundItem.Quality);
	printLine(colWidth, 'Color', sprintf("0x%X", foundItem.Color));
	printLine(colWidth, 'BoundStatus', foundItem.BoundStatus);
	printLine(colWidth, 'Bound', foundItem.Bound);
	printLine(colWidth, 'InUse', foundItem.InUse);
	printLine(colWidth, 'CoolDownTime', foundItem.CoolDownTime);
	printLine(colWidth, 'ItemCount', foundItem.ItemCount);
	printLine(colWidth, 'RequiredLvl', foundItem.RequiredLvl);
end

tee("")
printHeader("Inventory rent", ' ')
for page = 3,6 do -- Pages 1 & 2 are free; always unlocked
	local tested = CInventoryItem.isPageAvailable(nil, page)
	printLine(colWidth, sprintf("Page %d", page), tested)
end


tee("\n")
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
	tee("No items were found in the bank")
end

tee("")
printHeader("Bank rent", ' ')
for page = 2,5 do -- Page 1 is free; always unlocked
	local tested = CBankItem.isPageAvailable(nil, page)
	printLine(colWidth, sprintf("Page %d", page), tested)
end

tee("")
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


tee("")
printHeader("Cursor Item");
local cursor = CCursor();
cursor:update()
printLine(colWidth, "Cursor item ID:", cursor.ItemId or '<invalid>');
printLine(colWidth, "Cursor item Bag ID:", cursor.ItemBagId or '<invalid>');


tee("")
printHeader("Mount test");
local mount, mountMethod = player:getMount();
if( mount ~= nil ) then
	tee("Mounting...");
	player:mount()
	local start = os.time();
	repeat
		yrest(500);
		player:updateCasting()
		if( os.time() - start > 5 ) then
			player.Casting = false;
			tee("Took too long.")
		end
	until player.Casting == false

	tee("Dismounting...");
	player:mount(true)
else
	tee("Could not find mount for player; skipping mount test.")
end

tee("");
printHeader("Skills", ' ');
settings.loadSkillSet(player.Class1)

getResourceName = function (skill)
	if skill.Mana > 0 then
		return "Mana";
	end

	if skill.Rage > 0 then
		return "Rage";
	end

	if skill.Energy > 0 then
		return "Energy";
	end

	if skill.Focus > 0 then
		return "Focus";
	end

	if skill.Nature > 0 then
		return "Nature";
	end

	if skill.Psi > 0 then
		return "Psi";
	end
end

tee("\n")
printf(" %-8s %-26s %-6s %-4s %-12s %-10s\n", "ID", "Name", "Level", "As", "Resource", "Hotkey");
for i,v in pairs(settings.profile.skills) do
	local resource = getResourceName(v)
	local amount = v[resource] or 0
	local resourceDesc = '---';
	if resource then
		resourceDesc = sprintf("%d %s", amount, resource or '--')
	end
	printf(" %-8d %-26s %-6d %-4d %-12s %-10s\n", v.Id, v.Name, v.Level, v.aslevel, resourceDesc, v.hotkey);
end

tee("")
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
		log_debug(sprintf("%s looks good", i))
		installableCodemods[i] = codemod;
	else
		cprintf_ex("%s|red|[x]|white| %s appears malformed/modified\n", string.rep(" ", 12), i);
		log_debug(sprintf("%s appears malformed/modified", i))
	end
end

tee("");
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
		log_debug(sprintf("%s OK!", i))
	else
		cprintf_ex("%s|red|[x]|white| Failed\n", string.rep(" ", 12), i);
		log_debug(sprintf("%s Failed", i))
	end
end
