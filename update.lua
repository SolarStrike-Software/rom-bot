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
macroBodyUpdatePattern = string.char(0x0F, 0x84, 0xFF, 0xFF, 0xFF, 0xFF, 0x38, 0x98, 0xFF, 0xFF, 0xFF, 0xFF, 0x8D, 0xB8);
macroBodyUpdateMask = "xx????xx????xx";
macroBodyUpdateOffset = 8;

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

maxDurabilityOffsetUpdatePattern = string.char(0x0F, 0xB6, 0x4D, 0xFF, 0x0F, 0xAF, 0x8E);
maxDurabilityOffsetUpdateMask = "xxx?xxx";
maxDurabilityOffsetUpdateOffset = 3;

charMaxExpTableUpdatePattern = string.char(
0x56, 0xFF, 0x15, 0xFF, 0xFF, 0xFF, 0xFF,
0x83, 0xC4, 0xFF, 0x89, 0x1D, 0xFF, 0xFF,
0xFF, 0xFF, 0xA1, 0xFF, 0xFF, 0xFF, 0xFF,
0x8B, 0x35, 0xFF, 0xFF, 0xFF, 0xFF, 0x3B,
0xF0, 0x8B, 0xF8, 0x76, 0x18, 0xFF, 0xD5,
0xA1, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x35,
0xFF, 0xFF, 0xFF, 0xFF, 0x3B, 0xF0, 0x76,
0x07, 0xFF, 0xD5, 0xA1, 0xFF, 0xFF, 0xFF,
0xFF, 0x3B, 0xF7, 0x74, 0x26, 0x2B, 0xC7,
0xC1, 0xF8, 0xFF, 0x85, 0xC0, 0x8D, 0x0C,
0x85, 0x00, 0x00, 0x00, 0x00, 0x8D, 0x1C,
0x0E, 0x7E, 0x0D, 0x51, 0x57, 0x51, 0x56,
0xFF, 0x15, 0xFF, 0xFF, 0xFF, 0xFF, 0x83,
0xC4, 0xFF, 0x89, 0x1D, 0xFF, 0xFF, 0xFF,
0xFF, 0xA1, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B,
0x35, 0xFF, 0xFF, 0xFF, 0xFF, 0x3B, 0xF0
);
charMaxExpTableUpdateMask = "xxx????xx?xx????x????xx????xxxxxxxxx????xx????xxxxxxx????xxxxxxxx?xxxxxxxxxxxxxxxxxxxx????xx?xx????x????xx????xx";
charMaxExpTableUpdateOffset = 106;

pawnLootableOffsetUpdatePattern = string.char(0x8A, 0x8D, 0xFF, 0xFF, 0xFF, 0xFF, 0x8A, 0x95, 0xFF, 0xFF, 0xFF, 0xFF, 0x80, 0xA5);
pawnLootableOffsetUpdateMask = "xx????xx????xx";
pawnLootableOffsetUpdateOffset = 8;

charPtrMountedOffsetUpdatePattern = string.char(0x83, 0x79, 0xFF, 0x00, 0x74, 0x0C, 0xF6, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x74, 0x03, 0xB0, 0x01);
charPtrMountedOffsetUpdateMask = "xx?xxxxx?????xxxx";
charPtrMountedOffsetUpdateOffset = 2;

realItemIdOffsetUpdatePattern = string.char(0x8B, 0xF0, 0xEB, 0xA5, 0x8B, 0x89, 0xFF, 0xFF, 0xFF, 0xFF, 0x85, 0xC9);
realItemIdOffsetUpdateMask = "xxxxxx????xx";
realItemIdOffsetUpdateOffset = 6;

coolDownOffsetUpdatePattern = string.char(0x75, 0x4F, 0xF3, 0x0F, 0x2A, 0x88, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F, 0x2F, 0xC1);
coolDownOffsetUpdateMask = "xxxxxx????xxx";
coolDownOffsetUpdateOffset = 6;

idOffsetUpdatePattern = string.char(0x8B, 0x46, 0xFF, 0x8B, 0xFA, 0x99);
idOffsetUpdateMask = "xx?xxx";
idOffsetUpdateOffset = 2;

pawnClass1OffsetUpdatePattern = string.char(0xC7, 0x40, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x91, 0xFF, 0xFF, 0xFF, 0xFF, 0x83, 0xFA);
pawnClass1OffsetUpdateMask = "xx?????xx????xx";
pawnClass1OffsetUpdateOffset = 9;

pawnClass2OffsetUpdatePattern = string.char(0x89, 0x10, 0x8B, 0x89, 0xFF, 0xFF, 0xFF, 0xFF, 0x83, 0xF9, 0xFF, 0x77);
pawnClass2OffsetUpdateMask = "xxxx????xx?x";
pawnClass2OffsetUpdateOffset = 4;

pawnDirXUVecOffsetUpdatePattern = string.char(0xCC, 0x8B, 0x44, 0x24, 0xFF, 0xD9, 0x41, 0xFF, 0xD9, 0x18, 0xD9, 0x41, 0xFF, 0xD9, 0x58, 0xFF, 0xD9,
											0x41, 0xFF, 0xD9, 0x58, 0xFF, 0xC2, 0x04, 0x00, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xF3);
pawnDirXUVecOffsetUpdateMask = "xxxx?xx?xxxx?xx?xx?xx?xxxxxxxxxxxx";
pawnDirXUVecOffsetUpdateOffset = 7;

pawnDirYUVecOffsetUpdatePattern = string.char(0xD9, 0x58, 0xFF, 0xD9, 0x41, 0xFF, 0xD9, 0x58, 0xFF, 0xC2, 0x04, 0x00, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xF3);
pawnDirYUVecOffsetUpdateMask = "xx?xx?xx?xxxxxxxxxxxx";
pawnDirYUVecOffsetUpdateOffset = 5;

pawnHPOffsetUpdatePattern = string.char(0x74, 0xFF, 0x8B, 0x88, 0xFF, 0xFF, 0xFF, 0xFF, 0x2B, 0x88);
pawnHPOffsetUpdateMask = "x?xx????xx";
pawnHPOffsetUpdateOffset = 4;

pawnIdOffsetUpdatePattern = string.char(0x55, 0x8B, 0x6C, 0x24, 0x08, 0x56, 0x8B, 0xF1, 0x39, 0x6E, 0xFF, 0x75, 0x07, 0x5E);
pawnIdOffsetUpdateMask = "xxxxxxxxxx?xxx";
pawnIdOffsetUpdateOffset = 10;

pawnLevelOffsetUpdatePattern = string.char(0x56, 0x89, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0x89, 0x91, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x35);
pawnLevelOffsetUpdateMask = "xxx????xx????xx";
pawnLevelOffsetUpdateOffset = 3;

pawnLevel2OffsetUpdatePattern = string.char(0x56, 0x89, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0x89, 0x91, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x35);
pawnLevel2OffsetUpdateMask = "xxx????xx????xx";
pawnLevel2OffsetUpdateOffset = 9;

pawnMPOffsetUpdatePattern = string.char(0x74, 0xFF, 0x8B, 0x8E, 0xFF, 0xFF, 0xFF, 0xFF, 0x33, 0xD2, 0x85, 0xC9);
pawnMPOffsetUpdateMask = "x?xx????xxxx";
pawnMPOffsetUpdateOffset = 4;

pawnMaxHPOffsetUpdatePattern = string.char(0x52, 0x8B, 0xCE, 0x89, 0x86, 0xFF, 0xFF, 0xFF, 0xFF, 0xE8);
pawnMaxHPOffsetUpdateMask = "xxxxx????x";
pawnMaxHPOffsetUpdateOffset = 5;

pawnMaxMPOffsetUpdatePattern = string.char(0x33, 0xD2, 0x85, 0xC9, 0x0F, 0x9C, 0xC2, 0x89, 0x86, 0xFF, 0xFF, 0xFF, 0xFF, 0x83, 0xEA, 0x01);
pawnMaxMPOffsetUpdateMask = "xxxxxxxxx????xxx";
pawnMaxMPOffsetUpdateOffset = 9;

pawnMountOffsetUpdatePattern = string.char(0xCC, 0x8A, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0xA8, 0x01, 0x74, 0xFF, 0xA8, 0x02);
pawnMountOffsetUpdateMask = "xxx????xxx?xx";
pawnMountOffsetUpdateOffset = 3;

pawnNameOffsetUpdatePattern = string.char(0xC3, 0x8D, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0xC3, 0x8B, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0x85, 0xC0, 0x75);
pawnNameOffsetUpdateMask = "xxx????xxx????xxx";
pawnNameOffsetUpdateOffset = 10;

pawnPetPtrOffsetUpdatePattern = string.char(0xC2, 0x08, 0x00, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0x8B, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0x85, 0xC0, 0x75, 0x06, 0x8B, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0xC3);
pawnPetPtrOffsetUpdateMask = "xxx????xxxxxx????x";
pawnPetPtrOffsetUpdateOffset = 23;

pawnRaceOffsetUpdatePattern = string.char(0xF3, 0x0F, 0x11, 0x85, 0xFF, 0xFF, 0xFF, 0xFF,
0x89, 0x9D, 0xFF, 0xFF, 0xFF, 0xFF, 0x89, 0x85, 0xFF, 0xFF, 0xFF, 0xFF,
0x89, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0x89, 0x9D, 0xFF, 0xFF, 0xFF, 0xFF,
0xC7, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0x02, 0x00, 0x00, 0x00,
0x89, 0x85, 0xFF, 0xFF, 0xFF, 0xFF);
pawnRaceOffsetUpdateMask = "xxxx????xx????xx????xx????xx????xx????xxxxxx????";
pawnRaceOffsetUpdateOffset = 44;

pawnTargetPtrOffsetUpdatePattern = string.char(0x85, 0xC0, 0x75, 0x3F, 0x85, 0xED, 0x74, 0x08, 0x8B, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xEB, 0x0C);
pawnTargetPtrOffsetUpdateMask = "xxxxxxxxxx????xx";
pawnTargetPtrOffsetUpdateOffset = 10;

pawnTypeOffsetUpdatePattern = string.char(0xFF, 0xD0, 0x8B, 0x46, 0xFF, 0x83, 0xE8, 0x02, 0x74, 0x09, 0x83, 0xE8, 0x02);
pawnTypeOffsetUpdateMask = "xxxx?xxxxxxxx";
pawnTypeOffsetUpdateOffset = 4;

pawnXOffsetUpdatePattern = string.char(0x8B, 0x44, 0x24, 0x04, 0xD9, 0x41, 0xFF, 0xD9, 0x18, 0xD9, 0x41, 0xFF, 0xD9, 0x58, 0x04, 0xD9, 0x41, 0xFF, 0xD9, 0x58, 0xFF, 0xC2, 0x04, 0x00);
pawnXOffsetUpdateMask = "xxxxxx?xxxx?xxxxx?xx?xxx";
pawnXOffsetUpdateOffset = 6;

qualityBaseOffsetUpdatePattern = string.char(0x74, 0x15, 0x85, 0xF6, 0x8B, 0x40, 0xFF, 0x74, 0x10, 0x0F, 0xB6, 0x4E);
qualityBaseOffsetUpdateMask = "xxxxxx?xxxxx";
qualityBaseOffsetUpdateOffset = 6;

qualityTierOffsetUpdatePattern = string.char(0x77, 0x19, 0x83, 0x7B, 0xFF, 0x01, 0x7F, 0x13, 0x8A, 0x4F, 0xFF, 0x80, 0xE1);
qualityTierOffsetUpdateMask = "xxxx?xxxxx?xx";
qualityTierOffsetUpdateOffset = 10;

valueOffsetUpdatePattern = string.char(0x50, 0xFF, 0xD2, 0x8B, 0x4F, 0xFF, 0x83, 0xC1, 0xFF, 0xB8);
valueOffsetUpdateMask = "xxxxx?xx?x";
valueOffsetUpdateOffset = 5;

loadingScreenOffsetUpdatePattern = string.char(0xFF, 0xD2, 0xDD, 0x05, 0xFF, 0xFF, 0xFF, 0xFF, 0xC6, 0x46, 0x0FF, 0xFF, 0xD9, 0x44, 0x24, 0xFF, 0xDF, 0xF1);
loadingScreenOffsetUpdateMask = "xxxx????xx??xxx?xx";
loadingScreenOffsetUpdateOffset = 10;

loadingScreenPtrUpdatePattern = string.char(0xFF, 0xD0, 0x80, 0x7E, 0xFF, 0xFF, 0x0F, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF, 0x85, 0xC9, 0x0F, 0x84);
loadingScreenPtrUpdateMask = "xxxx??xx????xx????xxxx";
loadingScreenPtrUpdateOffset = 14;

castingBarOffsetUpdatePattern = string.char(0x57, 0xFF, 0xD2, 0x8B, 0xF8, 0x8B, 0x44, 0x24, 0xFF, 0x89, 0x46, 0xFF, 0x8B, 0x44, 0x24, 0xFF, 0x85, 0xC0, 0x75, 0x05);
castingBarOffsetUpdateMask = "xxxxxxxx?xx?xxx?xxxx";
castingBarOffsetUpdateOffset = 11;

hotkeysKeyOffsetUpdatePattern = string.char(0x50, 0x57, 0xE8, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x0D, 0xFF, 0xFF, 0xFF, 0XFF, 0x8B, 0x01, 0x8B, 0x56, 0xFF, 0x8B, 0x80);
hotkeysKeyOffsetUpdateMask = "xxx????xx????xxxx?xx";
hotkeysKeyOffsetUpdateOffset = 17;

hotkeysOffsetUpdatePattern = string.char(0xE9, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x6B, 0xFF, 0x39, 0x6B, 0xFF, 0x76, 0x06, 0xFF, 0x15, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x7B, 0xFF, 0x3B);
hotkeysOffsetUpdateMask = "x????xx?xx?xxxx????xx?x";
hotkeysOffsetUpdateOffset = 21;

hotkeysPtrUpdatePattern = string.char(0x66, 0x85, 0xC0, 0x7D, 0x06, 0x81, 0xCE, 0x00, 0x00, 0x04, 0x00, 0x8B, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x01, 0x8B, 0x90);
hotkeysPtrUpdateMask = "xxxxxxxxxxxxx????xxxx";
hotkeysPtrUpdateOffset = 13;

actionBarPtrUpdatePattern = string.char(0xBF, 0xFF, 0xFF, 0xFF, 0xFF, 0xB9, 0x07, 0x00, 0x00, 0x00, 0x33, 0xC0, 0xF3, 0xA6, 0x75, 0x68, 0x8B, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF,
0xE8, 0xFF, 0xFF, 0xFF, 0xFF, 0x5E, 0x5F, 0x5B, 0xC2, 0x14, 0x00);
actionBarPtrUpdateMask = "x????xxxxxxxxxxxxx????x????xxxxxx";
actionBarPtrUpdateOffset = 18;

eggPetMaxExpTablePtrUpdatePattern = string.char(0x83, 0xC4, 0x10, 0x8B, 0xCB, 0x89, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF, 0xA1, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x35, 0xFF, 0xFF, 0xFF, 0xFF, 0x3B, 0xF0);
eggPetMaxExpTablePtrUpdateMask = "xxxxxxx????x????xx????xx";
eggPetMaxExpTablePtrUpdateOffset = 18;

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
	update("camX_offset", camXUpdatePattern, camXUpdateMask, camXUpdateOffset, 0x440000, 0xA0000);
	update("pawnCasting_offset", castbarUpdatePattern, castbarUpdateMask, castbarUpdateOffset, 0x820000, 0xA0000);
	update("castingBar_offset", castingBarOffsetUpdatePattern, castingBarOffsetUpdateMask, castingBarOffsetUpdateOffset, 0x770000, 0xA0000, 1);
	update("charAlive_offset", charAliveUpdatePattern, charAliveUpdateMask, charAliveUpdateOffset, 0x5E0000, 0xA0000);
	update("charBattle_offset", charBattleUpdatePattern, charBattleUpdateMask, charBattleUpdateOffset, 0x5E0000, 0xA0000);
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
	update("maxDurabilityOffset", maxDurabilityOffsetUpdatePattern, maxDurabilityOffsetUpdateMask, maxDurabilityOffsetUpdateOffset, 0x6A0000, 0xA0000, 1);
	update("charMaxExpTable_address", charMaxExpTableUpdatePattern, charMaxExpTableUpdateMask, charMaxExpTableUpdateOffset, 0x615000, 0xA0000);
	update("pawnLootable_offset", pawnLootableOffsetUpdatePattern, pawnLootableOffsetUpdateMask, pawnLootableOffsetUpdateOffset, 0x850000, 0xA0000);
	update("charPtrMounted_offset", charPtrMountedOffsetUpdatePattern, charPtrMountedOffsetUpdateMask, charPtrMountedOffsetUpdateOffset, 0x840000, 0xA0000, 1);
	update("realItemIdOffset", realItemIdOffsetUpdatePattern, realItemIdOffsetUpdateMask, realItemIdOffsetUpdateOffset, 0x6A0000, 0xA0000);
	update("coolDownOffset", coolDownOffsetUpdatePattern, coolDownOffsetUpdateMask, coolDownOffsetUpdateOffset, 0x6A0000, 0xA0000);
	update("idOffset", idOffsetUpdatePattern, idOffsetUpdateMask, idOffsetUpdateOffset, 0x820000, 0xA0000, 1);
	update("pawnClass1_offset", pawnClass1OffsetUpdatePattern, pawnClass1OffsetUpdateMask, pawnClass1OffsetUpdateOffset, 0x5E0000, 0xA0000);
	update("pawnClass2_offset", pawnClass2OffsetUpdatePattern, pawnClass2OffsetUpdateMask, pawnClass2OffsetUpdateOffset, 0x5E0000, 0xA0000);
	update("pawnDirXUVec_offset", pawnDirXUVecOffsetUpdatePattern, pawnDirXUVecOffsetUpdateMask, pawnDirXUVecOffsetUpdateOffset, 0x840000, 0xA0000, 1);
	update("pawnDirYUVec_offset", pawnDirYUVecOffsetUpdatePattern, pawnDirYUVecOffsetUpdateMask, pawnDirYUVecOffsetUpdateOffset, 0x840000, 0xA0000, 1);
	update("pawnHP_offset", pawnHPOffsetUpdatePattern, pawnHPOffsetUpdateMask, pawnHPOffsetUpdateOffset, 0x7E0000, 0xA0000);
	update("pawnId_offset", pawnIdOffsetUpdatePattern, pawnIdOffsetUpdateMask, pawnIdOffsetUpdateOffset, 0x820000, 0xA0000, 1);
	update("pawnLevel_offset", pawnLevelOffsetUpdatePattern, pawnLevelOffsetUpdateMask, pawnLevelOffsetUpdateOffset, 0x840000, 0xA0000);
	update("pawnLevel2_offset", pawnLevel2OffsetUpdatePattern, pawnLevel2OffsetUpdateMask, pawnLevel2OffsetUpdateOffset, 0x840000, 0xA0000);
	update("pawnMP_offset", pawnMPOffsetUpdatePattern, pawnMPOffsetUpdateMask, pawnMPOffsetUpdateOffset, 0x840000, 0xA0000);
	update("pawnMaxHP_offset", pawnMaxHPOffsetUpdatePattern, pawnMaxHPOffsetUpdateMask, pawnMaxHPOffsetUpdateOffset, 0x840000, 0xA0000);
	update("pawnMaxMP_offset", pawnMaxMPOffsetUpdatePattern, pawnMaxMPOffsetUpdateMask, pawnMaxMPOffsetUpdateOffset, 0x840000, 0xA0000);
	update("pawnMount_offset", pawnMountOffsetUpdatePattern, pawnMountOffsetUpdateMask, pawnMountOffsetUpdateOffset, 0x840000, 0xA0000);
	update("pawnName_offset", pawnNameOffsetUpdatePattern, pawnNameOffsetUpdateMask, pawnNameOffsetUpdateOffset, 0x840000, 0xA0000);
	update("pawnPetPtr_offset", pawnPetPtrOffsetUpdatePattern, pawnPetPtrOffsetUpdateMask, pawnPetPtrOffsetUpdateOffset, 0x84F000, 0xA0000);
	update("pawnRace_offset", pawnRaceOffsetUpdatePattern, pawnRaceOffsetUpdateMask, pawnRaceOffsetUpdateOffset, 0x850000, 0xA0000);
	update("pawnTargetPtr_offset", pawnTargetPtrOffsetUpdatePattern, pawnTargetPtrOffsetUpdateMask, pawnTargetPtrOffsetUpdateOffset, 0x5F0000, 0xA0000);
	update("pawnType_offset", pawnTypeOffsetUpdatePattern, pawnTypeOffsetUpdateMask, pawnTypeOffsetUpdateOffset, 0x850000, 0xA0000, 1);
	update("pawnX_offset", pawnXOffsetUpdatePattern, pawnXOffsetUpdateMask, pawnXOffsetUpdateOffset, 0x840000, 0xA0000, 1);
	update("qualityBaseOffset", qualityBaseOffsetUpdatePattern, qualityBaseOffsetUpdateMask, qualityBaseOffsetUpdateOffset, 0x600000, 0xA0000, 1);
	update("qualityTierOffset", qualityTierOffsetUpdatePattern, qualityTierOffsetUpdateMask, qualityTierOffsetUpdateOffset, 0x790000, 0xA0000, 1);
	update("valueOffset", valueOffsetUpdatePattern, valueOffsetUpdateMask, valueOffsetUpdateOffset, 0x790000, 0xA0000, 1);
	update("loadingScreen_offset", loadingScreenOffsetUpdatePattern, loadingScreenOffsetUpdateMask, loadingScreenOffsetUpdateOffset, 0x7B0000, 0xA0000, 1);
	update("loadingScreenPtr", loadingScreenPtrUpdatePattern, loadingScreenPtrUpdateMask, loadingScreenPtrUpdateOffset, 0x5E0000, 0xA00000);
	update("hotkeysKey_offset", hotkeysKeyOffsetUpdatePattern, hotkeysKeyOffsetUpdateMask, hotkeysKeyOffsetUpdateOffset, 0x7B0000, 0xA0000, 1);
	update("hotkeys_offset", hotkeysOffsetUpdatePattern, hotkeysOffsetUpdateMask, hotkeysOffsetUpdateOffset, 0x7B0000, 0xA0000, 1);
	update("hotkeysPtr", hotkeysPtrUpdatePattern, hotkeysPtrUpdateMask, hotkeysPtrUpdateOffset, 0x740000, 0xA0000);
	update("actionBarPtr", actionBarPtrUpdatePattern, actionBarPtrUpdateMask, actionBarPtrUpdateOffset, 0x5E0000, 0xA0000);
	update("eggPetMaxExpTablePtr", eggPetMaxExpTablePtrUpdatePattern, eggPetMaxExpTablePtrUpdateMask, eggPetMaxExpTablePtrUpdateOffset, 0x610000, 0xA0000);
	-- NOTE: We must manually adjust forward 0x3C bytes
	update("pawnHarvesting_offset", pawnHarvestUpdatePattern, pawnHarvestUpdateMask, pawnHarvestUpdateOffset, 0x820000, 0xA0000);
	addresses.pawnHarvesting_offset = addresses.pawnHarvesting_offset + 0x3C;

	-- NOTE: We must manually adjust the macro forward 16 bytes
	update("macroBody_offset", macroBodyUpdatePattern, macroBodyUpdateMask, macroBodyUpdateOffset, 0x7A0000, 0xA0000);
	addresses.macroBody_offset = addresses.macroBody_offset + 0x10;



	-- Assumption-based updating.
	-- Not very accurate, but is quick-and-easy for those
	-- hard to track values.
	printf("\n\n");
	local function assumptionUpdate(name, newValue)
		local assumptionUpdateMsg = "Assuming information for \'addresses.%s\'; now 0x%X, was 0x%X\n";
		printf(assumptionUpdateMsg, name, newValue, addresses[name]);
		addresses[name] = newValue;
	end

	assumptionUpdate("pawnMP2_offset", addresses.pawnMP_offset + 8);
	assumptionUpdate("pawnMaxMP2_offset", addresses.pawnMaxMP_offset + 8);
	assumptionUpdate("pawnY_offset", addresses.pawnX_offset + 4);
	assumptionUpdate("pawnZ_offset", addresses.pawnX_offset + 8);
	assumptionUpdate("camYUVec_offset", addresses.camXUVec_offset + 4);
	assumptionUpdate("camZUVec_offset", addresses.camXUVec_offset + 8);
	assumptionUpdate("camY_offset", addresses.camX_offset + 4);
	assumptionUpdate("camZ_offset", addresses.camX_offset + 8);
	assumptionUpdate("moneyPtr", addresses.staticbase_char + 0x118D8);
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
