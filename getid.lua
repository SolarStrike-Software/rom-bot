-- A simple script to simply tell you your in-game location

include("addresses.lua");
include("functions.lua");
include("classes/pawn.lua");
include("classes/player.lua");
include("classes/memorytable.lua");

setStartKey(key.VK_DELETE);
setStopKey(key.VK_END);

function pauseCallback()
	printf("\nPaused.\n");
end
atPause(pauseCallback);

function exitCallback()

	printf("exitcallback\n");
end
atExit(exitCallback);

function main()	
	local displayWidth = 74;

	printf("\n\n");
	printf("%" .. displayWidth .. "s\n", string.rep('-', displayWidth));
	printf(" %-10s| %-16s| %-20s| %-20s|\n", "Player", "X,Y,Z", "Target", "Mouseover");
	printf("%" .. displayWidth .. "s\n", string.rep('-', displayWidth));
	while(true) do
		local gameroot = getBaseAddress(addresses.game_root.base);
		local playerAddress = memoryReadUIntPtr(getProc(), gameroot, addresses.game_root.player.base) or 0;
		local targetAddress = memoryReadRepeat("uint", getProc(), playerAddress + addresses.game_root.pawn.target) or 0;
		local mouseOverAddress = memoryReadRepeat("uintptr", getProc(),
			getBaseAddress(addresses.game_root.base), addresses.game_root.mouseover_object_ptr) or 0;
		
		
		local X = memoryReadRepeat("float", getProc(), playerAddress + addresses.game_root.pawn.x) or 0;
		local Y = memoryReadRepeat("float", getProc(), playerAddress + addresses.game_root.pawn.y) or 0;
		local Z = memoryReadRepeat("float", getProc(), playerAddress + addresses.game_root.pawn.z) or 0;
		
		local playerId = PLAYERID_MIN;
		if( isInGame() and playerAddress ~= nil and playerId >= PLAYERID_MIN and playerId <= PLAYERID_MAX ) then
			local targetId = memoryReadRepeat("uint", getProc(), targetAddress + addresses.game_root.pawn.id) or 0;
			local mouseOverId = memoryReadRepeat("uint", getProc(), mouseOverAddress + addresses.game_root.pawn.id) or 0;
			
			local pos = sprintf("%d,%d,%d", X, Y, Z);
			local target = sprintf("%X (%d)", targetAddress, targetId);
			local mouseOver = sprintf("%X (%d)", mouseOverAddress, mouseOverId);
			printf("\r%10X |%16s |%20s |%20s |", playerAddress, pos, target, mouseOver);
		else
			printf("\r");
		end
		
		yrest(500);
	end
end
startMacro(main, true);
