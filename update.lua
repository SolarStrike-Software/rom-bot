include("addresses.lua");
include("functions.lua");

-- Note: We get 'char' and 'macro' data from functions.lua
-- because it is used in other scripts.

local charPtrUpdatePattern = string.char(0x8B, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0x85, 0xC0, 0x74, 0xFF, 0x8B, 0x80);
local charPtrUpdateMask = "xx????xxx?xx";
local charPtrUpdateOffset = 2;

local mousePtrUpdatePattern = string.char(0x80, 0xBD, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x8B, 0x95, 0xFF, 0xFF, 0xFF, 0xFF);
local mousePtrUpdateMask = "xx????xxx????";
local mousePtrUpdateOffset = 9;

local camPtrUpdatePattern = string.char(0xFF, 0xD2, 0x8B, 0x8E, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0xD8);
local camPtrUpdateMask = "xxxx????xx";
local camPtrUpdateOffset = 4;

local camXUVecUpdatePattern = string.char(0xD9, 0x5C, 0x24, 0x08, 0xD9, 0x82, 0xFF, 0xFF, 0xFF, 0xFF, 0xD9, 0x5C, 0x24);
local camXUVecUpdateMask = "xxxxxx????xxx";
local camXUVecUpdateOffset = 6;

local camXUpdatePattern = string.char(0xD9, 0x82, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F, 0x57, 0xC9, 0xD8, 0xA2, 0xFF, 0xFF, 0xFF, 0xFF);
local camXUpdateMask = "xx????xxxxx????";
local camXUpdateOffset = 11;

local castbarUpdatePattern = string.char(0xC2, 0x04, 0x00, 0xD9, 0x44, 0x24, 0x04, 0xD9, 0x81, 0xFF, 0xFF, 0xFF, 0xFF);
local castbarUpdateMask = "xxxxxxxxx????";
local castbarUpdateOffset = 9;

local charAliveUpdatePattern = string.char(0x88, 0x44, 0x24, 0xFF, 0x8A, 0x87, 0xFF, 0xFF, 0xFF, 0xFF);
local charAliveUpdateMask = "xxx?xx????";
local charAliveUpdateOffset = 6;

local charBattleUpdatePattern = string.char(0x89, 0x44, 0x24, 0x20, 0x8A, 0x86, 0xFF, 0xFF, 0xFF, 0xFF, 0xF6, 0xD8);
local charBattleUpdateMask = "xxxxxx????xx";
local charBattleUpdateOffset = 6;

-- NOTE: Must add 10 bytes to the value here
local macro1UpdatePattern = string.char(0x0F, 0x84, 0xFF, 0xFF, 0xFF, 0xFF, 0x38, 0x98, 0xFF, 0xFF, 0xFF, 0xFF, 0x8D, 0xB8);
local macro1UpdateMask = "xx????xx????xx";
local macro1UpdateOffset = 8;


-- This function will attempt to automatically find the true addresses
-- from RoM, even if they have moved.
-- Only works on MicroMacro v1.0 or newer.
function findOffsets()
	local function update(name, pattern, mask, offset, sStart, sEnd)
		local found = 0;
		found = findPatternInProcess(getProc(), pattern, mask, sStart, sEnd);

		if( found == 0 ) then
			error("Unable to find \'" .. name .. "\' in module.", 0);
		end

		addresses[name] = memoryReadInt(getProc(), found + offset);
		printf("Patched addresses." .. name .. "\t (value: 0x%X, at: 0x%X)\n", addresses[name], found + offset);
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

	-- NOTE: We must manually adjust the macro forward 16 bytes
	-- Assume macro2 is macro1 + 0x508
	update("macro1_offset", macro1UpdatePattern, macro1UpdateMask, macro1UpdateOffset, 0x7A0000, 0xA0000);
	addresses.macro1_offset = addresses.macro1_offset + 0x10;
	addresses.macro2_offset = addresses.macro1_offset + 0x508;
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