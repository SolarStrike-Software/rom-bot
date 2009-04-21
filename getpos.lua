include("addresses.lua");
include("classes/player.lua");
include("functions.lua");

function main()
	local playerPtr = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
	player = CPlayer(playerPtr);


	while( true ) do
		if( keyPressed(startKey) ) then
			player:update();
			cprintf(cli.green, "Player position: (%d, %d)\n", player.X, player.Z);
		end;

		yrest(100);
	end
end
startMacro(main);