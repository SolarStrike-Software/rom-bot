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
	local pattern = string.char(0xD9, 0x3D, 0x01, 0x00, 0x00, 0x00, 0x00, 0x10, 0xAE, 0x3D, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00);
	staticbase = findPatternInProcess(getProc(), pattern, "xxxxxxxxxx????xx", 0x00840000, 0x00100000) + 0xB;

	local pattern = string.char(0x00, 0xC0, 0xCF, 0x18, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00,0x00);
	staticcastbar = findPatternInProcess(getProc(), pattern, "xxxxxxxxx?????xx", 0x00840000, 0x00100000) + 0x9;

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