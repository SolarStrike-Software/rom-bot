include("addresses.lua");
include("classes/player.lua");
include("classes/waypoint.lua");
include("functions.lua");

if( getVersion() < 100 ) then
	startKey = key.VK_DELETE;
	stopKey = key.VK_END;
else
	setStartKey(key.VK_DELETE);
	setStopKey(key.VK_END);
end

wpKey = key.VK_NUMPAD1; -- insert a movement point
saveKey = key.VK_NUMPAD3; -- save the waypoints

function saveWaypoints(list)
	keyboardBufferClear();
	io.stdin:flush();
	cprintf(cli.green, "What do you want to name your path?\nName> ");
	filename = getExecutionPath() .. "/waypoints/" .. io.stdin:read() .. ".xml";

	file, err = io.open(filename, "w");
	if( not file ) then
		error(err, 0);
	end

	file:write("<waypoints>\n");
	for i,v in pairs(list) do
		local str = sprintf("\t<!-- #%2d --><waypoint x=\"%d\" z=\"%d\"></waypoint>\n", i, v.X, v.Z);
		file:write(str);
	end
	file:write("</waypoints>\n");

	file:close();
end

function main()
	local wpList = {};

	local playerPtr = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
	player = CPlayer(playerPtr);
	player:update();

	cprintf(cli.green, "RoM waypoint creator\n");
	printf("Hotkeys:\n  (%s)\tInsert new waypoint(at player position)\n"
		.. "  (%s)\tSave waypoints\n",
		getKeyName(wpKey), getKeyName(saveKey));

	local lastwpKey = false;
	while(true) do
		if( keyPressed(wpKey) == false and lastwpKey == true ) then
			player:update();
			local tmp = CWaypoint(player.X, player.Z);
			printf("Recorded [#%2d] Continue to the next. Press %s to save and quit\n",
				#wpList + 1, getKeyName(saveKey));
			table.insert(wpList, tmp);
		end
		if( keyPressed(wpKey) ) then
			lastwpKey = true;
		else
			lastwpKey = false;
		end

		if( keyPressed(saveKey) ) then
			saveWaypoints(wpList);
			break;
		end

		yrest(10);
	end

end
startMacro(main, true);