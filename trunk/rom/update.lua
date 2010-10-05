include("addresses.lua");
include("functions.lua");

-- Note: We get 'char' and 'macro' data from functions.lua
-- because it is used in other scripts.

-- Note: These all need to be global, not local, because
-- they will be used in function 'update()', which will
-- cause it to fail if there are more than 60 upvalues.

charPtrUpdatePattern = string.char(0x8B, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0x85, 0xC0, 0x74, 0xFF, 0x8B, 0x80);
charPtrUpdateMask = "xx????xxx?xx";
charPtrUpdateOffset = 2;

mousePtrUpdatePattern = string.char(0x80, 0xBD, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x8B, 0x95, 0xFF, 0xFF, 0xFF, 0xFF);
mousePtrUpdateMask = "xx????xxx????";
mousePtrUpdateOffset = 9;

camPtrUpdatePattern = string.char(0xFF, 0xD2, 0x8B, 0x8E, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0xD8);
camPtrUpdateMask = "xxxx????xx";
camPtrUpdateOffset = 4;

camXUVecUpdatePattern = string.char(0xD9, 0x5C, 0x24, 0x08, 0xD9, 0x82, 0xFF, 0xFF, 0xFF, 0xFF, 0xD9, 0x5C, 0x24);
camXUVecUpdateMask = "xxxxxx????xxx";
camXUVecUpdateOffset = 6;

camXUpdatePattern = string.char(0xD9, 0x82, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F, 0x57, 0xC9, 0xD8, 0xA2, 0xFF, 0xFF, 0xFF, 0xFF);
camXUpdateMask = "xx????xxxxx????";
camXUpdateOffset = 11;

castbarUpdatePattern = string.char(0xC2, 0x04, 0x00, 0xD9, 0x44, 0x24, 0x04, 0xD9, 0x81, 0xFF, 0xFF, 0xFF, 0xFF);
castbarUpdateMask = "xxxxxxxxx????";
castbarUpdateOffset = 9;

charAliveUpdatePattern = string.char(0x88, 0x44, 0x24, 0xFF, 0x8A, 0x87, 0xFF, 0xFF, 0xFF, 0xFF);
charAliveUpdateMask = "xxx?xx????";
charAliveUpdateOffset = 6;

pawnHarvestUpdatePattern = string.char(0x5F, 0x89, 0xAE, 0xFF, 0xFF, 0xFF, 0xFF, 0x89, 0xAE, 0xFF, 0xFF, 0xFF, 0xFF, 0x89, 0xAE);
pawnHarvestUpdateMask = "xxx????xx????xx";
pawnHarvestUpdateOffset = 9;

charBattleUpdatePattern = string.char(0x89, 0x44, 0x24, 0x20, 0x8A, 0x86, 0xFF, 0xFF, 0xFF, 0xFF, 0xF6, 0xD8);
charBattleUpdateMask = "xxxxxx????xx";
charBattleUpdateOffset = 6;

-- NOTE: Must add 10 bytes to the value here
macro1UpdatePattern = string.char(0x0F, 0x84, 0xFF, 0xFF, 0xFF, 0xFF, 0x38, 0x98, 0xFF, 0xFF, 0xFF, 0xFF, 0x8D, 0xB8);
macro1UpdateMask = "xx????xx????xx";
macro1UpdateOffset = 8;

staticTableUpdatePattern = string.char(0x7E, 0xFF, 0x53, 0x56, 0x57, 0xA1, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x3C, 0xA8, 0x8B, 0x1D);
staticTableUpdateMask = "x?xxxx????xxxxx";
staticTableUpdateOffset = 6;

staticTableSizeUpdatePattern = string.char(0x83, 0xC4, 0x04, 0x8B, 0x15, 0xFF, 0xFF, 0xFF, 0xFF, 0x52, 0x8D, 0x84, 0x24);
staticTableSizeUpdateMask = "xxxxx????xxxx";
staticTableSizeUpdateOffset = 5;

pingOffsetUpdatePattern = string.char(0xFF, 0xD2, 0xEB, 0x17, 0x8B, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0x03, 0x85);
pingOffsetUpdateMask = "xxxxxx????xx";
pingOffsetUpdateOffset = 6;


staticEquipBaseUpdatePattern = string.char(0x0F, 0x8D, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0xC8, 0xE9, 0xFF, 0xFF, 0xFF, 0xFF, 0xB8, 0xFF, 0xFF, 0xFF, 0xFF, 0xEB);
staticEquipBaseUpdateMask = "xx????xxx????x????x";
staticEquipBaseUpdateOffset = 14;

boundStatusOffsetUpdatePattern = string.char(0x51, 0xE8, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x43, 0xFF, 0x8B, 0x13);
boundStatusOffsetUpdateMask = "xx????xx?xx";
boundStatusOffsetUpdateOffset = 8;

durabilityOffsetUpdatePattern = string.char(0x03, 0xC2, 0x8B, 0x4B, 0xFF, 0x3B, 0xC8, 0x75);
durabilityOffsetUpdateMask = "xxxx?xxx";
durabilityOffsetUpdateOffset = 4;

idCardNPCOffsetUpdatePattern = string.char(0x75, 0xFF, 0x8B, 0x91, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x35);
idCardNPCOffsetUpdateMask = "x?xx????xx";
idCardNPCOffsetUpdateOffset = 4;

nameOffsetUpdatePattern = string.char(0x50, 0xE9, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x41, 0xFF, 0x5E);
nameOffsetUpdateMask = "xx????xx?x";
nameOffsetUpdateOffset = 8;

requiredLevelOffsetUpdatePattern = string.char(0x8B, 0x9C, 0x24, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x4B, 0xFF, 0x8B, 0xBC, 0x24);
requiredLevelOffsetUpdateMask = "xxx????xx?xxx";
requiredLevelOffsetUpdateOffset = 9;

itemCountOffsetUpdatePattern = string.char(0xEB, 0xFF, 0x8B, 0x4E, 0xFF, 0x89, 0x4C, 0x24);
itemCountOffsetUpdateMask = "x?xx?xxx";
itemCountOffsetUpdateOffset = 4;

inUseOffsetUpdatePattern = string.char(0x8B, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x6E, 0xFF, 0x56);
inUseOffsetUpdateMask = "xx????xx?x";
inUseOffsetUpdateOffset = 8;
--[[
maxDurabilityOffsetUpdatePattern = string.char();
maxDurabilityOffsetUpdateMask = "";
maxDurabilityOffsetUpdateOffset = 0;
]]

charMaxExpTableUpdatePattern = string.char(0xA1, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x35, 0xFF, 0xFF, 0xFF, 0xFF, 0x3B, 0xF0);
charMaxExpTableUpdateMask = "x????xx????xx";
charMaxExpTableUpdateOffset = 7;

-- This function will attempt to automatically find the true addresses
-- from RoM, even if they have moved.
-- Only works on MicroMacro v1.0 or newer.
function findOffsets()
	local function update(name, pattern, mask, offset, sStart, sEnd, size)
		if( name == nil or pattern == nil or mask == nil or offset == nil or sStart == nil or sEnd == nil ) then
			error("Function \'update\' received nil parameter.", 2);
		end

		local found = 0;
		found = findPatternInProcess(getProc(), pattern, mask, sStart, sEnd);

		if( found == 0 ) then
			error("Unable to find \'" .. name .. "\' in module.", 0);
		end

		local readFunc = nil;
		if( size == 1 ) then
			readFunc = memoryReadUByte;
		elseif( size == 2 ) then
			readFunc = memoryReadUShort;
		elseif( size == 4 ) then
			readFunc = memoryReadUInt
		else -- default, assume 4 bytes
			readFunc = memoryReadUInt;
		end

		addresses[name] = readFunc(getProc(), found + offset);
		local msg = sprintf("Patched addresses." .. name .. "\t (value: 0x%X, at: 0x%X)", addresses[name], found + offset);
		printf(msg.. "\n");
		logMessage(msg);
		return found;
	end

	addresses.staticpattern_char = update("staticbase_char", getCharUpdatePattern(),
		getCharUpdateMask(), getCharUpdateOffset(), 0x5A0000, 0xA0000);

	addresses.staticpattern_macro = update("staticbase_macro", getMacroUpdatePattern(),
		getMacroUpdateMask(), getMacroUpdateOffset(), 0x700000, 0xA0000);

	update("charPtr_offset", charPtrUpdatePattern, charPtrUpdateMask, charPtrUpdateOffset, 0x5A0000, 0xA0000);
	update("mousePtr_offset", mousePtrUpdatePattern, mousePtrUpdateMask, mousePtrUpdateOffset, 0x5F0000, 0xA0000);
	update("camPtr_offset", camPtrUpdatePattern, camPtrUpdateMask, camPtrUpdateOffset, 0x5E0000, 0xA0000);

	update("camXUVec_offset", camXUVecUpdatePattern, camXUVecUpdateMask, camXUVecUpdateOffset, 0x440000, 0xA0000);
	-- Assume Y is +4, and Z is +8
	addresses.camYUVec_offset = addresses.camXUVec_offset + 4;
	addresses.camZUVec_offset = addresses.camXUVec_offset + 8;

	update("camX_offset", camXUpdatePattern, camXUpdateMask, camXUpdateOffset, 0x440000, 0xA0000);
	-- Assume Y is +4, and Z is +8
	addresses.camY_offset = addresses.camX_offset + 4;
	addresses.camZ_offset = addresses.camX_offset + 8;

	update("castbar_offset", castbarUpdatePattern, castbarUpdateMask, castbarUpdateOffset, 0x820000, 0xA0000);
	update("charAlive_offset", charAliveUpdatePattern, charAliveUpdateMask, charAliveUpdateOffset, 0x5E0000, 0xA0000);
	update("charBattle_offset", charBattleUpdatePattern, charBattleUpdateMask, charBattleUpdateOffset, 0x5E0000, 0xA0000);

	-- NOTE: We must manually adjust forward 0x3C bytes
	update("pawnHarvesting_offset", pawnHarvestUpdatePattern, pawnHarvestUpdateMask, pawnHarvestUpdateOffset, 0x820000, 0xA0000);
	addresses.pawnHarvesting_offset = addresses.pawnHarvesting_offset + 0x3C;

	-- NOTE: We must manually adjust the macro forward 16 bytes
	-- Assume macro2 is macro1 + 0x508
	update("macro1_offset", macro1UpdatePattern, macro1UpdateMask, macro1UpdateOffset, 0x7A0000, 0xA0000);
	addresses.macro1_offset = addresses.macro1_offset + 0x10;
	addresses.macro2_offset = addresses.macro1_offset + 0x508;

	update("staticTablePtr", staticTableUpdatePattern, staticTableUpdateMask, staticTableUpdateOffset, 0x820000, 0xA0000);
	update("staticTableSize", staticTableSizeUpdatePattern, staticTableSizeUpdateMask, staticTableSizeUpdateOffset, 0x620000, 0xA0000);

	update("ping_offset", pingOffsetUpdatePattern, pingOffsetUpdateMask, pingOffsetUpdateOffset, 0x5FA000, 0xA0000);

	update("staticEquipBase", staticEquipBaseUpdatePattern, staticEquipBaseUpdateMask, staticEquipBaseUpdateOffset, 0x5E0000, 0xA0000);

	update("boundStatusOffset", boundStatusOffsetUpdatePattern, boundStatusOffsetUpdateMask, boundStatusOffsetUpdateOffset, 0x820000, 0xA0000, 1);
	update("durabilityOffset", durabilityOffsetUpdatePattern, durabilityOffsetUpdateMask, durabilityOffsetUpdateOffset, 0x690000, 0xA0000, 1);
	update("idCardNPCOffset", idCardNPCOffsetUpdatePattern, idCardNPCOffsetUpdateMask, idCardNPCOffsetUpdateOffset, 0x680000, 0xA0000);
	update("nameOffset", nameOffsetUpdatePattern, nameOffsetUpdateMask, nameOffsetUpdateOffset, 0x680000, 0xA0000, 1);
	update("requiredLevelOffset", requiredLevelOffsetUpdatePattern, requiredLevelOffsetUpdateMask, requiredLevelOffsetUpdateOffset, 0x790000, 0xA0000, 1);
	update("itemCountOffset", itemCountOffsetUpdatePattern, itemCountOffsetUpdateMask, itemCountOffsetUpdateOffset, 0x760000, 0xA0000, 1);
	update("inUseOffset", inUseOffsetUpdatePattern, inUseOffsetUpdateMask, inUseOffsetUpdateOffset, 0x760000, 0xA0000, 1);
	update("charMaxExpTable_address", charMaxExpTableUpdatePattern, charMaxExpTableUpdateMask, charMaxExpTableUpdateOffset, 0x615000, 0xA0000);


	-- Assumption-based updating.
	-- Not very accurate, but is quick-and-easy for those
	-- hard to track values.
	printf("\n\n");
	local function assumptionUpdate(name, newValue)
		local assumptionUpdateMsg = "Assuming information for \'addresses.%s\'; now 0x%X, was 0x%X\n";
		printf(assumptionUpdateMsg, name, newValue, addresses[name]);
		addresses[name] = newValue;
	end

	assumptionUpdate("moneyPtr", addresses.staticbase_char + 0x11898);
	assumptionUpdate("charExp_address", addresses.staticbase_char + 0x6C);
end

function rewriteAddresses()
	local filename = getExecutionPath() .. "/addresses.lua";
	getProc(); -- Just to make sure we open the process first

	printf("Scanning for updated addresses...\n");
	findOffsets();
	printf("Finished.\n");

	local addresses_new = {};
	for i,v in pairs(addresses) do
		table.insert(addresses_new, {index = i, value = v});
	end

	-- Sort alphabetically by index
	local function addressSort(tab1, tab2)
		if( tab1.index < tab2.index ) then
			return true;
		end

		return false;
	end
	table.sort(addresses_new, addressSort);

	local file = io.open(filename, "w");

	file:write(
		sprintf("-- Auto-generated by update.lua\n") ..
		"addresses = {\n"
	);

	for i,v in pairs(addresses_new) do
		file:write( sprintf("\t%s = 0x%X,\n", v.index, v.value) );
	end

	file:write("}\n");

	file:close();

end
rewriteAddresses();