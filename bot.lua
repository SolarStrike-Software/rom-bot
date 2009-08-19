BOT_VERSION = 2.45;

include("database.lua");
include("addresses.lua");
include("classes/player.lua");
include("classes/camera.lua");
include("classes/waypoint.lua");
include("classes/waypointlist.lua");
include("classes/waypointlist_wander.lua");
include("classes/node.lua");
include("settings.lua");
include("functions.lua");


settings.load();
setStartKey(settings.hotkeys.START_BOT.key);
setStopKey(settings.hotkeys.STOP_BOT.key);



__WPL = nil; -- Way Point List
__RPL = nil; -- Return Point List


print("\n\169\83\111\108\97\114\83\116\114\105\107\101\32" ..
"\83\111\102\116\119\97\114\101\44\32\119\119\119\46\115" ..
"\111\108\97\114\115\116\114\105\107\101\46\110\101\116\n");
function main()
	local forcedProfile = nil;
	local forcedPath = nil;
	local forcedRetPath = nil;

	for i = 2,#args do
		if( args[i] == "update" ) then
			include("update.lua");
		end

		local foundpos = string.find(args[i], ":", 1, true);
		if( foundpos ) then
			local var = string.sub(args[i], 1, foundpos-1);
			local val = string.sub(args[i], foundpos+1);

			if( var == "profile" ) then
				forcedProfile = val;
			elseif( var == "path" ) then
				forcedPath = val;
			elseif( var == "retpath" ) then
				forcedRetPath = val;
			end
		end
	end

	local versionMsg = sprintf("RoM Bot Version %0.2f", BOT_VERSION);
	cprintf(cli.lightblue, versionMsg .. "\n");
	logMessage(versionMsg);

	-- Load "english" first, to fill in any gaps in the users' set language.
	local function setLanguage(name)
		include(getExecutionPath() .. "/language/" .. name .. ".lua");
	end

	local lang_base = {};
	setLanguage("english");
	for i,v in pairs(language) do lang_base[i] = v; end;
	setLanguage(settings.options.LANGUAGE);
	for i,v in pairs(lang_base) do
		if( language[i] == nil ) then
			language[i] = v;
		end
	end;
	lang_base = nil; -- Not needed anymore, destroy it.
	logMessage("Language: " .. settings.options.LANGUAGE);

	database.load();

	attach(getWin());

	if( not checkExecutableCompatible() ) then
		cprintf(cli.yellow, "!! Notice: !!\n");
		printf("The game may have been updated or altered.\n" ..
			"It is recommended that you run rom/update.lua\n\n");

		logMessage("Game exectuable may have changed. You should run rom/update.lua");
	end

	local playerAddress = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
	printf("Attempt to read playerAddress\n");

	if( playerAddress == nil ) then playerAddress = 0; end;
	logMessage(sprintf("Using static char address 0x%X, player address 0x%X",
		tonumber(staticcharbase_address), tonumber(playerAddress)));

	player = CPlayer(playerAddress);
	player:initialize();
	player:update();

	local cameraAddress = memoryReadIntPtr(getProc(), staticcharbase_address, camPtr_offset);
	if( cameraAddress == nil ) then cameraAddress = 0; end;

	camera = CCamera(cameraAddress);

	mousePawn = CPawn( memoryReadIntPtr(getProc(), staticcharbase_address, mousePtr_offset) );
	printf("mousePawn: 0x%X\n", mousePawn.Address);

	printf("playerAddr: 0x%X\n", player.Address);
	printf("playerTarget: 0x%X\n", player.TargetPtr);

	local hf_x, hf_y, hf_wide, hf_high = windowRect( getWin());
	cprintf(cli.turquoise, "RoM windows size is %dx%d, upper left corner at %d,%d\n", hf_wide, hf_high, hf_x, hf_y );	-- RoM windows size

	
	-- local functions to convert string (e.g. player name) from UTF-8 to ASCII
	local function convert_utf8_ascii_character( _str, _ascii )
		local found;
		local tmp = database.utf8_ascii[_ascii];
		_str, found = string.gsub(_str, string.char(tmp.utf8_1, tmp.utf8_2), string.char(tmp.ascii) );
		return _str, found;
	end
	
	local function convert_utf8_ascii( _str )
		local found, found_all;
		found_all = 0;
		for i,v in pairs(database.utf8_ascii) do
			_str, found = convert_utf8_ascii_character( _str, v.ascii  );	-- replace special characters
			found_all = found_all + found;			-- count replacements
		end
	
		if( found_all > 0) then
			return _str, true;
		else
			return _str, false;
		end
	end

	-- local functions to replace special ASCII characters (e.g. in player name) 
	local function replace_special_ascii_character( _str, _ascii )
		local found;
		local tmp = database.utf8_ascii[_ascii];
		_str, found = string.gsub(_str, string.char(tmp.ascii), tmp.dos_replace );
		return _str, found;
	end

	local function replace_special_ascii( _str )
		local found, found_all;
		found_all = 0;
		for i,v in pairs(database.utf8_ascii) do
			_str, found = replace_special_ascii_character( _str, v.ascii  );	-- replace special characters
			found_all = found_all + found;			-- count replacements
		end
	
		if( found_all > 0) then
			return _str, true;
		else
			return _str, false;
		end
	end

	local load_profile_name, new_profile_name;	-- name of profile to load
	if( forcedProfile ) then
		load_profile_name = forcedProfile;
	else
		load_profile_name = player.Name;
	end

	-- convert player name from UTF-8 to ASCII
	load_profile_name = convert_utf8_ascii(load_profile_name);

	-- replace special ASCII characters like צüהת / hence open.XML() can't handle them
	new_profile_name , hf_convert = replace_special_ascii(load_profile_name);	-- replace characters

	if( hf_convert ) then		-- we replace some special characters

		-- check if profile with replaced characters allready there
		local file = io.open(getExecutionPath() .. "/profiles/" .. new_profile_name..".xml" , "r");
		if( file ) then	-- file exits
			file:close();
			load_profile_name = new_profile_name;
		else
			cprintf(cli.yellow,"Due to technical reasons, we can't use the character/profile name \'%s\' as "..
			        "a profile name. Please use profile name \'%s.xml\' instead or start "..
			        "the bot with a forced profile: \'rom\\bot.lua profile:xyz\'\n", 
			        load_profile_name, new_profile_name);
			error("Bot finished due of errors above.\n", 0);
		end;
	else				

		-- check if profile exist
		local file = io.open(getExecutionPath() .. "/profiles/" .. load_profile_name..".xml" , "r");
		if( not file ) then	
			cprintf(cli.yellow,"We can't find your profile \'%s.xml'\. "..
			        "Please create a valid profile within the folder \'rom\\profiles\' "..
			        "or start the bot with a forced profile: \'rom\\bot.lua "..
			        "profile:xyz\'\n", load_profile_name );
			        error("Bot finished due of errors above.\n", 0);
		else
			file:close();
		end
	end;

	-- Set window name, install timer to automatically do it once a second
	local displayname = string.sub(load_profile_name, 1, 4) .. "****";
	setWindowName(getHwnd(), sprintf("RoM Bot %s [%s]", BOT_VERSION, displayname));
	settings.loadProfile(load_profile_name);
	registerTimer("timedSetWindowName", secondsToTimer(1), timedSetWindowName, load_profile_name);

	if( settings.profile.options.PATH_TYPE == "wander" or forcedPath == "wander" ) then
		__WPL = CWaypointListWander();
		__WPL:setRadius(settings.profile.options.WANDER_RADIUS);
		__WPL:setMode("wander");
	elseif( settings.profile.options.PATH_TYPE == "waypoints" or forcedPath ) then
		__WPL = CWaypointList();
	else
		error("Unknown PATH_TYPE in profile.", 0);
	end


	-- This logic prevents files from being loaded if wandering was forced
	local wp_to_load, rp_to_load;
	if( forcedPath and not (forcedPath == "wander") ) then
		wp_to_load = forcedPath;
	else
		if( settings.profile.options.WAYPOINTS ) then
			wp_to_load = settings.profile.options.WAYPOINTS;
		end
	end

	if( forcedRetPath ) then
		rp_to_load = forcedRetPath;
	else
		if( settings.profile.options.RETURNPATH ) then
			rp_to_load = settings.profile.options.RETURNPATH;
		end
	end

	load_paths(wp_to_load, rp_to_load);	-- load the waypoint path / return path
	
	-- special option for use waypoint file from profile in a reverse order / not if forced path
	if( settings.profile.options.WAYPOINTS_REVERSE == true  and
	    not forcedPath  ) then 
		__WPL:reverse();
	end;
	
	-- look for the closest waypoint / return path point to start
	if( __RPL ) then	-- return path points available ?
		-- compare closest waypoint with closest returnpath point
		__WPL:setWaypointIndex( __WPL:getNearestWaypoint(player.X, player.Z ) );
		local hf_wp = __WPL:getNextWaypoint();
		local dist_to_wp = distance(player.X, player.Z, hf_wp.X, hf_wp.Z)
		
		__RPL:setWaypointIndex( __RPL:getNearestWaypoint(player.X, player.Z ) );
		local hf_wp = __RPL:getNextWaypoint();
		local dist_to_rp = distance(player.X, player.Z, hf_wp.X, hf_wp.Z)
		
		if( dist_to_rp < dist_to_wp ) then	-- returnpoint is closer then next normal wayoiint
			player.Returning = true;	-- then use return path first
			cprintf(cli.yellow, language[12]);	-- Starting with return path
		else
			player.Returning = false;	-- use normale waypoint path
		end;
	end;
	
	local distBreakCount = 0; -- If exceedes 3 in a row, unstick.
	while(true) do
		player:update();
		player:logoutCheck();

		if( not player.Alive ) then
			-- Make sure they aren't still trying to run off
			keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
			keyboardRelease(settings.hotkeys.MOVE_BACKWARD.key);
			keyboardRelease(settings.hotkeys.ROTATE_LEFT.key);
			keyboardRelease(settings.hotkeys.ROTATE_RIGHT.key);
			keyboardRelease(settings.hotkeys.STRAFF_LEFT.key);
			keyboardRelease(settings.hotkeys.STRAFF_RIGHT.key);
			player.Death_counter = player.Death_counter + 1;

			-- Take a screenshot. Only works on MicroMacro 1.0 or newer
			showWindow(getWin(), sw.show);
			yrest(500);
			local sfn = getExecutionPath() .. "/profiles/" .. player.Name .. ".bmp";
			saveScreenshot(getWin(), sfn);
			printf(language[2], sfn);

			if( type(settings.profile.events.onDeath) == "function" ) then
				local status,err = pcall(settings.profile.events.onDeath);
				if( status == false ) then
					local msg = sprintf("onDeath error: %s", err);
					error(msg);
				end
			end

			-- msg how to activate automatic resurrection
			if( settings.profile.options.RES_AUTOMATIC_AFTER_DEATH == false ) then
				cprintf(cli.yellow, "If you want to use automatic resurrection " ..
				   "then set option \'RES_AUTOMATIC_AFTER_DEATH = \"true\"\' "..
				   "within your profile.\n");
			end;

			local hf_res_from_priest; 		-- for check if priest resurrect
			if( settings.profile.options.RES_AUTOMATIC_AFTER_DEATH == true ) then
				cprintf(cli.red, language[3]);			-- Died. Resurrecting player...
				
				-- try mouseclick to reanimate
				cprintf(cli.green, "We will try to resurrect in 10 seconds.\n");  
				yrest(10000);
				
				-- try resurrect at the place, click button far right
				if ( foregroundWindow() == getWin() ) then
					cprintf(cli.green, "Try to resurrect at the place of death ...\n");  
					player:mouseclickL(1276, 272, 1920, 1180);	-- mouseclick to resurrec
					yrest(3000);		-- wait time after resurrec ( no load screen)
					player:update();
				end

				if( player.Alive ) then		-- if allready alive it must be from the priest/buff
					hf_res_from_priest = true;
				end;
				
				-- if still death, click button more left, normal resurrect at spawnpoint
				if ( not player.Alive  and
				     foregroundWindow() == getWin() ) then
					cprintf(cli.green, "Try to resurrect at the spawnpoint ...\n");  
					player:mouseclickL(875, 272, 1920, 1180);	-- mouseclick to resurrec
					-- wait time after resurrec (loading screen), needs more time on slow PC's
					yrest(settings.profile.options.WAIT_TIME_AFTER_RES);	
					player:update();
				end;

				-- if still death, try macro if one defined
				if ( not player.Alive  and 
				     settings.profile.hotkeys.RES_MACRO.key ) then
					cprintf(cli.green, "Try to use the ingame resurrect macro ...\n");  
					keyboardPress(settings.profile.hotkeys.RES_MACRO.key);
					-- wait time after resurrec (loading screen), needs more time on slow PC's
					yrest(settings.profile.options.WAIT_TIME_AFTER_RES);	
					player:update();
				end;

				if( not player.Alive ) then
					cprintf(cli.yellow, "You are still dead. There "..
					  "is a problem with automatic resurrection." ..
					  " Did you set your ingame macro \'/script AcceptResurrect();\' to the key %s?\n",
					  getKeyName(settings.profile.hotkeys.RES_MACRO.key));
				end;

				-- death counter message
				cprintf(cli.green, "You have died %s times from at most %s "..
				   "deaths/automatic resurrections.\n",
				   player.Death_counter, settings.profile.options.MAX_DEATHS);
				
				-- check maximal death if automatic mode
				if( player.Death_counter > settings.profile.options.MAX_DEATHS ) then
					player:logout();
				end

				if( player.Level > 9  and 
				    player.Alive      and
				    hf_res_from_priest ~= true ) then	-- no wait if resurrect at the place of death / priest / buff
					cprintf(cli.red, language[4]);		-- Returning to waypoints after 1 minute.
					player:rest(60); -- wait 1 minute before going about your path.
				end;

			end

			-- print out the reasons for not automatic returning
--			if( not settings.profile.hotkeys.RES_MACRO ) then
--				cprintf(cli.yellow, "You don't have a RES_MACRO defined in your profile! "..
--				"Hence no automatic returning.\n");
--			end
--			if(__RPL == nil) then
--				cprintf(cli.yellow, "You don't have a defined return path in your profile. "..
--				"Hence no automatic returning.\n");
--			end

			-- use/compare return path if defined, if not use normal one and give a warning
			-- wen need to search the closest, hence we also accept resurrection at the death place
			player.Returning = nil;
			if( __RPL ) then
				-- compare closest waypoint with closest returnpath point
				__WPL:setWaypointIndex( __WPL:getNearestWaypoint(player.X, player.Z ) );
				local hf_wp = __WPL:getNextWaypoint();
				local dist_to_wp = distance(player.X, player.Z, hf_wp.X, hf_wp.Z)

				__RPL:setWaypointIndex( __RPL:getNearestWaypoint(player.X, player.Z ) );
				local hf_wp = __RPL:getNextWaypoint();
				local dist_to_rp = distance(player.X, player.Z, hf_wp.X, hf_wp.Z)

				if( dist_to_rp < dist_to_wp ) then	-- returnpoint is closer then next normal wayoiint
					player.Returning = true;	-- then use return path first
					cprintf(cli.yellow, language[12]);	-- Starting with return path
				end;
			else
				cprintf(cli.yellow, "You don't have a defined return path!!! We use the "..
				"normal waypoint file \'%s\' instead. Please check that.\n", __WPL:getFileName() );
			end;
			
			-- not using returnpath, so we use the normal waypoint path
			if( player.Returning == nil) then
				player.Returning = false;
				__WPL:setWaypointIndex( __WPL:getNearestWaypoint(player.X, player.Z ) );
				cprintf(cli.green, "Using normal waypoint file \'%s\' after resurrection.\n", 
				   __WPL:getFileName() );
			end

			player:update();
			-- pause if still death
			if( not player.Alive ) then
--				cprintf(cli.yellow, "Sorry. You are (still) dead ... \n" );
				pauseOnDeath();
			end;
			
		end

		if( player.TargetPtr ~= 0 and not player:haveTarget() ) then
			player:clearTarget();
		end


		-- go back to sleep, if in sleep mode
		if( player.Sleeping == true ) then
			yrest(800);	-- wait a little for the aggro flag
			player:update();
			if( player.Battling == false ) then 
				player:sleep(); 
			end;
		end;	-- go sleeping if sleeping flag is set


		-- rest after getting new target and before starting fight
		-- rest between 50 until 99 sec, at most until full, after that additional rnd(10)
		if( player:haveTarget()  and
		    player.Current_waypoint_type ~= WPT_RUN ) then	-- no resting if running waypoin type
			player:rest( 50, 99, "full", 10 );		-- rest befor next fight
		end;


		-- if aggro then wait for target from client
		-- we come back to that coding place if we stop moving because of aggro
		local aggroWaitStart = os.time();
		local msg_print = false;
		while(player.Battling) do

			if( player.Current_waypoint_type == WPT_RUN ) then	-- runing mode, don't wait for target
				cprintf(cli.green, "Waypoint type RUN, we don't stop "..
				  "and don't fight back\n");	-- Waiting on aggressive enemies.
				break;
			end;
			
			-- wait a second with the aggro message to avoid wrong msg 
			-- ecause of slow battle flag from the client
			if( msg_print == false  and  os.difftime(os.time(), aggroWaitStart) > 1 ) then
				cprintf(cli.green, language[35]);	-- Waiting on aggressive enemies.
				msg_print = true;
			end;
			if( player:haveTarget() ) then
				if( msg_print == false ) then
					cprintf(cli.green, language[35]);	-- Waiting on aggressive enemies.
					msg_print = true;
				end;

				break;
			end;

			if( os.difftime(os.time(), aggroWaitStart) > 4 ) then
				cprintf(cli.red, language[34]);		-- Aggro wait time out
				player.LastAggroTimout = os.time();	-- remember aggro timeout
				break;
			end;

			yrest(10);
			player:update();
		end


		if( player:haveTarget()  and
		    player.Current_waypoint_type ~= WPT_RUN ) then	-- only fight back if it's not a runnig waypoint
		-- fight the mob / target
			local target = player:getTarget();
			if( settings.profile.options.ANTI_KS ) then
				if( target:haveTarget() and 
				  target:getTarget().Address ~= player.Address and 
				  (not player:isFriend(CPawn(target.TargetPtr))) ) then
					cprintf(cli.red, language[5], target.Name);
				else
					player:fight();
				end
			else
				player:fight();
			end
		else
		-- don't fight, move to wp
			local wp = nil; local wpnum = nil;

			if( player.Returning ) then
				wp = __RPL:getNextWaypoint();
				wpnum = __RPL.CurrentWaypoint;
				cprintf(cli.green, language[13], wpnum, wp.X, wp.Z);	-- Moving to returnpath waypoint
			else
				wp = __WPL:getNextWaypoint();
				wpnum = __WPL.CurrentWaypoint;
				cprintf(cli.green, language[6], wpnum, wp.X, wp.Z);	-- Moving to waypoint
			end;

			player.Current_waypoint_type = wp.Type;		-- remember current waypoint type

			local success, reason = player:moveTo(wp);

			if( player.TargetPtr ~= 0 and (not player:haveTarget()) ) then
				player:clearTarget();
			end

			player:checkPotions();
			player:checkSkills( ONLY_FRIENDLY );	-- only cast hot spells to ourselfe

			if( success ) then
				-- if we stick directly at a wp the counter would reseted even if we are sticked
				-- hence we reset the counter only after 3 successfull waypoints
				player.Success_waypoints = player.Success_waypoints + 1;
				if( player.Success_waypoints > 3 ) then
					player.Unstick_counter = 0;	-- reset unstick counter
				end;

				if( player.Returning ) then
					-- Completed. Return to normal waypoints.
					if( __RPL.CurrentWaypoint >= #__RPL.Waypoints ) then
						__WPL:setWaypointIndex(__WPL:getNearestWaypoint(player.X, player.Z));
						player.Returning = false;
						cprintf(cli.yellow, language[7]);
					else
						__RPL:advance();
					end
				else
					__WPL:advance();
				end
			else
				if( not reason == WF_TARGET ) then
					cprintf(cli.red, language[8]);		-- Waypoint movement failed
				end

				if( reason == WF_COMBAT ) then	
					cprintf(cli.turquoise, language[14]);	-- We get aggro. Stop moving to waypoint 
				end;

				if( reason == WF_DIST ) then
					distBreakCount = distBreakCount + 1;
				else
					if( distBreakCount > 0 ) then
						distBreakCount = 0;
					end
				end

				if( reason == WF_STUCK or distBreakCount > 3 ) then

					-- Get ourselves unstuck, then!
					distBreakCount = 0;
					player:clearTarget();
					player.Success_waypoints = 0;	-- counter for successfull waypoints in row
					player.Unstick_counter = player.Unstick_counter + 1;	-- count our unstick tries

					-- Too many tries, logout
					if( settings.profile.options.LOGOUT_WHEN_STUCK ) then
						if( settings.profile.options.MAX_UNSTICK_TRIALS > 0 and
						    player.Unstick_counter > settings.profile.options.MAX_UNSTICK_TRIALS ) then 
							player:logout(); 
						end;
						cprintf(cli.red, language[9], player.X, player.Z, 	-- unsticking player... at position
						   player.Unstick_counter, settings.profile.options.MAX_UNSTICK_TRIALS);
					else
						cprintf(cli.red, "Unsticking player... at position %d,%d. Trial %d.\n", 	-- unsticking player... at position
						   player.X, player.Z, player.Unstick_counter);
					end
					player:unstick();
				end
			end

			coroutine.yield();

		end
	end
	
end
startMacro(main);