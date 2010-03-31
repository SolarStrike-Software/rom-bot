-- A simple script to simply tell you your in-game location

include("addresses.lua");
include("database.lua");
include("classes/player.lua");
include("classes/node.lua");
include("settings.lua");
include("functions.lua");


setStartKey(settings.hotkeys.START_BOT.key);
setStopKey(settings.hotkeys.STOP_BOT.key);

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

		printf("\rPosition: (%d, %d)\t", player.X, player.Z);
	end
end
startMacro(main, true);