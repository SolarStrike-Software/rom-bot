-- A simple script to simply tell you your in-game location

include("addresses.lua");
include("functions.lua");
include("classes/memorytable.lua");

setStartKey(0);
setStopKey(0);

function pauseCallback()
	printf("\nPaused.\n");
end
atPause(pauseCallback);

function exitCallback()
	printf("\n");
end
atExit(exitCallback);

function main()
	local playerAddress
	local playerX = 0
	local playerZ = 0
	local playerY = 0

	while(true) do
		yrest(500);
		playerAddress = memoryReadIntPtr(getProc(), addresses.staticbase_char, addresses.charPtr_offset);
		playerX = memoryReadFloat(getProc(), playerAddress + addresses.pawnX_offset) or playerX
		playerY = memoryReadFloat(getProc(), playerAddress + addresses.pawnY_offset) or playerY
		playerZ = memoryReadFloat(getProc(), playerAddress + addresses.pawnZ_offset) or playerZ
		mousePawnAddress = memoryReadIntPtr(getProc(), addresses.staticbase_char, addresses.mousePtr_offset) or 0
		if( mousePawnAddress ~= 0) then
			mousePawnId = memoryReadUInt(getProc(), mousePawnAddress + addresses.pawnId_offset) or 0
			mousePawnName = GetIdName(mousePawnId) or "<UNKNOWN>"
			mousePawnX = memoryReadFloat(getProc(), mousePawnAddress + addresses.pawnX_offset) or mousePawnX
			mousePawnY = memoryReadFloat(getProc(), mousePawnAddress + addresses.pawnY_offset) or mousePawnY
			mousePawnZ = memoryReadFloat(getProc(), mousePawnAddress + addresses.pawnZ_offset) or mousePawnZ
			printf("\rObject found id %d %s distance %d\t\t", mousePawnId, mousePawnName, distance(playerX, playerZ, playerY, mousePawnX, mousePawnZ, mousePawnY));
		else
			printf("\rNo id at current mouse location\t\t\t\t");
		end
	end
end
startMacro(main, true);
