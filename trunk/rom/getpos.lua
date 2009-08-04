-- A simple script to simply tell you your in-game location
include("settings.lua");
include("functions.lua");
include("classes/player.lua");
include("addresses.lua");

settings.load();
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
	local playerAddress = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
	player = CPlayer(playerAddress);

	while(true) do
		yrest(500);
		player:update();

		printf("\rPosition: (%d, %d)\t", player.X, player.Z);
	end
end
startMacro(main, true);