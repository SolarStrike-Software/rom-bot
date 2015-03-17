-- A simple script to simply tell you your in-game location

include("addresses.lua");
include("functions.lua");
include("classes/memorytable.lua");

setStartKey(key.VK_DELETE);
setStopKey(key.VK_END);

function pauseCallback()
	printf("\nPaused.\n");
end
atPause(pauseCallback);

function exitCallback()

	printf("exitcakkback\n");
end
atExit(exitCallback);

function main()
	local playerAddress
	local playerId
	local playerHP
	local playerX = 0
	local playerZ = 0
	local playerY = 0

	while(true) do
		yrest(500);
		playerAddress = memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.charPtr_offset);
		playerId = memoryReadInt(getProc(), playerAddress + addresses.pawnId_offset) or 0
		playerHP = memoryReadInt(getProc(), playerAddress + addresses.pawnHP_offset) or 0
		if not isInGame() or playerId < PLAYERID_MIN or playerId > PLAYERID_MAX or playerHP < 1 then
			repeat
				yrest(1000)
				playerAddress = memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.charPtr_offset);
				playerId = memoryReadInt(getProc(), playerAddress + addresses.pawnId_offset) or 0
				playerHP = memoryReadInt(getProc(), playerAddress + addresses.pawnHP_offset) or 0
			until isInGame() and playerId >= PLAYERID_MIN and playerId <= PLAYERID_MAX and playerHP > 1
		end
		playerX = memoryReadFloat(getProc(), playerAddress + addresses.pawnX_offset) or playerX
		playerY = memoryReadFloat(getProc(), playerAddress + addresses.pawnY_offset) or playerY
		playerZ = memoryReadFloat(getProc(), playerAddress + addresses.pawnZ_offset) or playerZ
		mousePawnAddress = memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.mousePtr_offset) or 0
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
