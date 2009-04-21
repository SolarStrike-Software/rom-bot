include("database.lua");
include("addresses.lua");
include("classes/player.lua");
include("classes/waypoint.lua");
include("classes/waypointlist.lua");
include("functions.lua");
include("settings.lua");

if( getVersion() < 100 ) then
	startKey = key.VK_DELETE;
	stopKey = key.VK_END;
else
	setStartKey(key.VK_DELETE);
	setStopKey(key.VK_END);
end


__WPL = CWaypointList();

function main()
	if( getVersion() < 100 ) then
		while( keyPressed(startKey) ) do yrest(1); end;
	else
		while( keyPressed(getStartKey()) ) do yrest(1); end;
	end

	-- If run with "update" parameter, update addresses.lua.
	if( args[2] == "update" and getVersion() >= 100 ) then
		include("update.lua");
	end

	database.load();

	attach(getWin());

	local playerPtr = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
	player = CPlayer(playerPtr);
	player:update();

	printf("playerAddr: 0x%X\n", player.Address);

	settings.load();
	settings.loadProfile(player.Name);
	__WPL = CWaypointList();
	__WPL:load(getExecutionPath() .. "/waypoints/" .. settings.profile.options.WAYPOINTS);

	-- Start at the closest waypoint.
	__WPL:setWaypointIndex(__WPL:getNearestWaypoint(player.X, player.Z));

	local distBreakCount = 0; -- If exceedes 3 in a row, unstick.
	while(true) do
		player:update();

		if( player.HP == 0 ) then
			-- Take a screenshot. Only works on MicroMacro 1.0 or newer
			if( getVersion() >= 100 ) then
				showWindow(getWin(), sw.show);
				yrest(500);
				local sfn = getExecutionPath() .. "/profiles/" .. player.Name .. ".bmp";
				saveScreenshot(getWin(), sfn);
				printf("Saved a screenshot to: %s\n", sfn);
			end


			cprintf(cli.red, "You have died... Sorry.\n");
			printf("Script paused until you revive yourself. Press %s when you\'re ready to continue.\n",
				getKeyName(startKey))
			logMessage("Player died.\n");
			stopPE();
		end


		if( player:haveTarget() ) then
			if( player.Target == player.Address ) then
				player:clearTarget();
				-- Clear target so that we can more easily pick up aggroed monsters.
			end;

			local target = player:getTarget();
			if( settings.profile.options.ANTI_KS ) then
				if( target:haveTarget() and target:getTarget().Address ~= player.Address and (not player:isFriend(CPawn(target.TargetPtr))) ) then
					cprintf(cli.red, "IGNORING TARGET: Anti-KS\n");
				else
					player:fight();
				end
			else
				player:fight();
			end
		else
			local wp = __WPL:getNextWaypoint();
			cprintf(cli.green, "Moving to (%d, %d)\n", wp.X, wp.Z);
			local success, reason = player:moveTo(wp);

			player:checkPotions();
			player:checkSkills();

		
			if( player.TargetPtr ~= 0 and (not player:haveTarget()) ) then
				player:clearTarget();
			end
		

			if( success ) then
				__WPL:advance();
			else
				cprintf(cli.red, "Waypoint movement failed!\n");
				if( reason == WF_DIST ) then
					distBreakCount = distBreakCount + 1;
				else
					distBreakCount = 0;
					if( distBreakCount > 0 ) then
						printf("Dist breaks reset\n");
					end
				end

				if( reason == WF_STUCK or distBreakCount > 3 ) then
					-- Get ourselves unstuck, then!
					cprintf(cli.red, "Unsticking player...\n");
					distBreakCount = 0;
					player:unstick();
				end
			end

			yrest(100);

		end
	end
	
end
startMacro(main);