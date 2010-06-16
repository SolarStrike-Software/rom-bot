-- A simple script to simply tell you your in-game location

include("addresses.lua");
include("database.lua");
include("classes/player.lua");
include("classes/node.lua");
include("settings.lua");
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
	settings.load();
	database.load();

	local playerAddress = memoryReadIntPtr(getProc(), addresses.staticbase_char, addresses.charPtr_offset);
	player = CPlayer(playerAddress);

	while(true) do
		yrest(500);
		player:update();
		mousePawn = CPawn(memoryReadIntPtr(getProc(),
		addresses.staticbase_char, addresses.mousePtr_offset));
		if( mousePawn.Address ~= 0) then
			printf("\rObject found id %d %s distance %d\t\t", mousePawn.Id, mousePawn.Name, distance(player.X, player.Z, mousePawn.X, mousePawn.Z));
		else
			printf("\rNo id at current mouse location\t\t\t\t");
		end
	end
end
startMacro(main, true);
