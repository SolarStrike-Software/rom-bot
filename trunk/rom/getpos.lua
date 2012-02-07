-- A simple script to simply tell you your in-game location

include("addresses.lua");
include("functions.lua");

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

		printf("\rPosition: (%d, %d, %d)\t", playerX, playerZ, playerY);
	end
end
startMacro(main, true);
