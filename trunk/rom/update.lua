include("addresses.lua");
include("functions.lua");

if( startKey == key.VK_F5 ) then
	startKey = key.VK_DELETE;
end

if( stopKey == key.VK_F6 ) then
	stopKey = key.VK_END;
end;


-- This function will attempt to automatically find the true addresses
-- from RoM, even if they have moved.
-- Only works on MicroMacro v1.0 or newer.
function findOffsets()
	local staticbase, staticcastbar;
	--local pattern = string.char(0x7C,0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xD2, 0x3D, 0xFF, 0xFF, 0xFF, 0xFF);
	local pattern = string.char(0x00,0xB4,0xFF,0xFF,0xFF,0xFF,0xFF,0x00,0xFF,0x88,0xA4,0xFF,0xFF,0xFF,0xFF,0xFF,0x01,0x00);
	staticbase = findPatternInProcess(getProc(), pattern, "xx?????x?xx?????xx", 0x00840000, 0x000A0000) + 0xD;

	--pattern = string.char(0x16, 0x01, 0x00, 0x00, 0x00, 0x00, 0xA0, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x90, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00);
	pattern = string.char(0xE0, 0xFF, 0x18, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xA0, 0xFF, 0xFF, 0xFF, 0xFF);
	staticcastbar = findPatternInProcess(getProc(), pattern, "x?x?x?x?x????", 0x00840000, 0x000A0000) + 0x8;

	staticcharbase_address = staticbase;
	castbar_staticbase = staticcastbar;
end

function rewriteAddresses()
	local filename = getExecutionPath() .. "/addresses.lua";
	getProc(); -- Just to make sure we open the process first

	printf("Scanning for updated addresses...\n");
	findOffsets();
	printf("Finished.\n");

	local file = io.open(filename, "w");

	file:write(
		sprintf("staticcharbase_address = 0x%X;\n", staticcharbase_address) ..
		sprintf("charPtr_offset = 0x%X;\n", charPtr_offset) ..
		sprintf("charX_offset = 0x%X;\n", charX_offset) ..
		sprintf("charY_offset = 0x%X;\n", charY_offset) ..
		sprintf("charZ_offset = 0x%X;\n", charZ_offset) ..
		sprintf("charDirection_offset = 0x%X;\n", charDirection_offset) ..
		sprintf("charHP_offset = 0x%X;\n", charHP_offset) ..
		sprintf("charMaxHP_offset = 0x%X;\n", charMaxHP_offset) ..
		sprintf("charMP_offset = 0x%X;\n", charMP_offset) ..
		sprintf("charMaxMP_offset = 0x%X;\n", charMaxMP_offset) ..
		sprintf("charMP2_offset = 0x%X;\n", charMP2_offset) ..
		sprintf("charMaxMP2_offset = 0x%X;\n", charMaxMP2_offset) ..
		sprintf("charLevel_offset = 0x%X;\n", charLevel_offset) ..
		sprintf("charLevel2_offset = 0x%X;\n", charLevel2_offset) ..
		sprintf("charName_offset = 0x%X;\n", charName_offset) ..
		sprintf("charSpeed_offset = 0x%X;\n", charSpeed_offset) ..
		sprintf("charTargetPtr_offset = 0x%X;\n", charTargetPtr_offset) ..
		sprintf("charDirVectorPtr_offset = 0x%X;\n", charDirVectorPtr_offset) ..
		sprintf("inBattle_offset = 0x%X;\n", inBattle_offset) ..
		sprintf("camUVec1_offset = 0x%X;\n", camUVec1_offset) ..
		sprintf("camUVec2_offset = 0x%X;\n", camUVec2_offset) ..
		sprintf("castbar_staticbase = 0x%X;\n", castbar_staticbase) ..
		sprintf("castbar_offset = 0x%X;\n", castbar_offset)
	);

	file:close();
end
rewriteAddresses();