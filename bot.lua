local BOT_VERSION = 2.32;

include("database.lua");
include("addresses.lua");
include("classes/player.lua");
include("classes/waypoint.lua");
include("classes/waypointlist.lua");
include("classes/waypointlist_wander.lua");
include("functions.lua");
include("settings.lua");


DEBUG_ASSERT = true; -- Change to 'true' to debug memory reading problems.


if( getVersion() < 100 ) then
	startKey = key.VK_DELETE;
	stopKey = key.VK_END;
else
	setStartKey(key.VK_DELETE);
	setStopKey(key.VK_END);
end


__WPL = nil; -- Way Point List
__RPL = nil; -- Return Point List


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

	local versionMsg = sprintf("RoM Bot Version %0.2f", BOT_VERSION);
	cprintf(cli.lightblue, versionMsg .. "\n");
	logMessage(versionMsg);

	database.load();

	attach(getWin());

	local playerAddress = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
	printf("Attempt to read playerAddress\n");

	if( playerAddress == nil ) then playerAddress = 0; end;
	logMessage(sprintf("Using static base address 0x%X, player address 0x%X",
		tonumber(staticcharbase_address), tonumber(playerAddress)));

	player = CPlayer(playerAddress);
	player:initialize();
	player:update();


	printf("playerAddr: 0x%X\n", player.Address);
	printf("playerTarget: 0x%X\n", player.TargetPtr);

	settings.load();
	settings.loadProfile(player.Name);

	if( settings.profile.options.PATH_TYPE == "waypoints" ) then
		__WPL = CWaypointList();
	elseif( settings.profile.options.PATH_TYPE == "wander" ) then
		__WPL = CWaypointListWander();
		__WPL:setRadius(settings.profile.options.WANDER_RADIUS);
	else
		error("Unknown PATH_TYPE in profile.", 0);
	end

	__RPL = CWaypointList();

	if( settings.profile.options.WAYPOINTS ) then
		__WPL:load(getExecutionPath() .. "/waypoints/" .. settings.profile.options.WAYPOINTS);
		cprintf(cli.green, "Loaded waypoint path %s\n", settings.profile.options.WAYPOINTS);
	end

	if( settings.profile.options.RETURNPATH ) then
		__RPL:load(getExecutionPath() .. "/waypoints/" .. settings.profile.options.RETURNPATH);
		cprintf(cli.green, "Loaded return path %s\n", settings.profile.options.RETURNPATH);
	end

	-- Start at the closest waypoint.
	__WPL:setWaypointIndex(__WPL:getNearestWaypoint(player.X, player.Z));

	local distBreakCount = 0; -- If exceedes 3 in a row, unstick.
	while(true) do
		player:update();

		if( not player.Alive ) then
			-- Take a screenshot. Only works on MicroMacro 1.0 or newer
			if( getVersion() >= 100 ) then
				showWindow(getWin(), sw.show);
				yrest(500);
				local sfn = getExecutionPath() .. "/profiles/" .. player.Name .. ".bmp";
				saveScreenshot(getWin(), sfn);
				printf("Saved a screenshot to: %s\n", sfn);
			end


			if( settings.profile.hotkeys.RES_MACRO ) then
				cprintf(cli.red, "Died. Resurrecting player...\n");
				keyboardPress(settings.profile.hotkeys.RES_MACRO.key);
				yrest(5000);

				cprintf(cli.red, "Returning to waypoints after 1 minute.\n");
				yrest(60*1000); -- wait 1 minute before going about your path.
			end

			-- Must have a resurrect macro and waypoints set to be able to use
			-- a return path!
			if( settings.profile.hotkeys.RES_MACRO and player.Returning == false and
			__RPL ~= nil ) then
				player.Returning = true;
				__RPL:setWaypointIndex(1); -- Start from the beginning
			end


			if( type(settings.profile.events.onDeath) == "function" ) then
				local status,err = pcall(settings.profile.events.onDeath);
				if( status == false ) then
					local msg = sprintf("onDeath error: %s", err);
					error(msg);
				end
			else
				pauseOnDeath();
			end
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
			local wp = nil; local wpnum = nil;

			if( player.Returning ) then
				wp = __RPL:getNextWaypoint();
				wpnum = __RPL.CurrentWaypoint;
			else
				wp = __WPL:getNextWaypoint();
				wpnum = __WPL.CurrentWaypoint;
			end;

			cprintf(cli.green, "Moving to waypoint #%d, (%d, %d)\n", wpnum, wp.X, wp.Z);
			local success, reason = player:moveTo(wp);


			if( player.TargetPtr ~= 0 and (not player:haveTarget()) ) then
				player:clearTarget();
			end

			if( player.TargetPtr == 0 ) then
				player:checkPotions();
				player:checkSkills();
			end
		

			if( success ) then
				if( player.Returning ) then
					-- Completed. Return to normal waypoints.
					if( __RPL.CurrentWaypoint >= #__RPL.Waypoints ) then
						__WPL:setWaypointIndex(__WPL:getNearestWaypoint(player.X, player.Z));
						player.Returning = false;
						cprintf(cli.yellow, "Completed return path. Resuming normal waypoints.\n");
					else
						__RPL:advance();
					end
				else
					__WPL:advance();
				end
			else
				cprintf(cli.red, "Waypoint movement failed!\n");
				if( reason == WF_DIST ) then
					distBreakCount = distBreakCount + 1;
				else
					if( distBreakCount > 0 ) then
						distBreakCount = 0;
						printf("Dist breaks reset\n");
					end
				end

				if( reason == WF_STUCK or distBreakCount > 3 ) then
					-- Get ourselves unstuck, then!
					cprintf(cli.red, "Unsticking player...\n");
					distBreakCount = 0;
					player:clearTarget();
					player:unstick();
				end
			end

			yrest(100);

		end
	end
	
end
startMacro(main);