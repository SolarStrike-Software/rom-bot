-- A simple script to simply tell you your in-game location

include("addresses.lua");
include("functions.lua");
include("classes/player.lua");

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
	local playerId
	local playerHP
	local playerX = 0
	local playerZ = 0
	local playerY = 0

	local gameroot = getBaseAddress(addresses.game_root.base);
	while(true) do
		yrest(500);
		playerAddress = memoryReadRepeat("uintptr", getProc(), gameroot, addresses.game_root.player.base);
		playerId = memoryReadInt(getProc(), playerAddress + addresses.game_root.pawn.id) or 0
		playerHP = memoryReadInt(getProc(), playerAddress + addresses.game_root.pawn.hp) or 0
		if not isInGame() or playerId < PLAYERID_MIN or playerId > PLAYERID_MAX or playerHP < 1 then
			repeat
				yrest(1000)
				playerAddress = memoryReadRepeat("uintptr", getProc(), gameroot, addresses.game_root.player.base);
				playerId = memoryReadInt(getProc(), playerAddress + addresses.game_root.pawn.id) or 0
				playerHP = memoryReadInt(getProc(), playerAddress + addresses.game_root.pawn.hp) or 0
			until isInGame() and playerId >= PLAYERID_MIN and playerId <= PLAYERID_MAX and playerHP > 1
		end
		playerX = memoryReadFloat(getProc(), playerAddress + addresses.game_root.pawn.x) or playerX
		playerY = memoryReadFloat(getProc(), playerAddress + addresses.game_root.pawn.y) or playerY
		playerZ = memoryReadFloat(getProc(), playerAddress + addresses.game_root.pawn.z) or playerZ

		printf("\rPosition: (%d, %d, %d)\t", playerX, playerZ, playerY);
	end
end
startMacro(main, true);
