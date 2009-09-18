BOT_VERSION = 3.00;

include("database.lua");
include("addresses.lua");
include("classes/player.lua");
include("classes/inventory.lua");
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
			else
				-- invalid option
				local msg = sprintf(language[61], args[i]);
				error(msg, 0 ); 
			end
		end

		-- check the options
		if(not foundpos  and  args[i] ~= "update" ) then
			local msg = sprintf(language[61], args[i]);
			error(msg, 0 ); 
		end;

	end

	local versionMsg = sprintf("RoM Bot Version %0.2f", BOT_VERSION);
	cprintf(cli.lightblue, versionMsg .. "\n");
	logMessage(versionMsg);

	database.load();

	keyboardSetDelay(0);
	attach(getWin());

	if( not checkExecutableCompatible() ) then
		cprintf(cli.yellow, "!! Notice: !!\n");
		printf(language[43]);	-- is recommended that you run rom/update.lua

		logMessage("Game exectuable may have changed. You should run rom/update.lua");
	end

	local playerAddress = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
	if( settings.options.DEBUGGING ) then
		printf(language[44]);	-- Attempt to read playerAddress
	end

	if( playerAddress == nil ) then 
		local msg = sprintf(language[48], "playerAddress");	-- pls update to current version
		error(msg, 0);
	end;
	logMessage(sprintf("Using static char address 0x%X, player address 0x%X",
		tonumber(staticcharbase_address), tonumber(playerAddress)));

	player = CPlayer(playerAddress);
	player:initialize();
	player:update();
	if( settings.options.DEBUGGING ) then
		-- Player debugging info
		printf("[DEBUG] playerAddr: 0x%X\n", player.Address);
		printf("[DEBUG] Player target: 0x%X\n", player.TargetPtr);

		if( player.TargetPtr ~= 0 ) then
			local target = CPawn(player.TargetPtr);
			printf("[DEBUG] Player target type: 0x%X\n", target.Type);
			printf("[DEBUG] Player target attackable: %s\n", target.Attackable);
		end
	end

	mousePawn = CPawn( memoryReadIntPtr(getProc(), staticcharbase_address, mousePtr_offset) );

	if( settings.options.DEBUGGING ) then
		-- Mouse pawn debugging info
		printf("[DEBUG] mousePawn: 0x%X\n", mousePawn.Address);
		printf("[DEBUG] mousePawn id: %d\n", mousePawn.Id);
	end

	local cameraAddress = memoryReadIntPtr(getProc(), staticcharbase_address, camPtr_offset);
	if( cameraAddress == nil ) then cameraAddress = 0; end;

	camera = CCamera(cameraAddress);
	if( settings.options.DEBUGGING ) then
		-- Camera debugging info
		printf("[DEBUG] Cam X: %0.2f, Y: %0.2f, Z: %0.2f\n", camera.X, camera.Y, camera.Z);
		printf("[DEBUG] Cam XU: %0.2f, YU: %0.2f, ZU: %0.2f\n", camera.XUVec, camera.YUVec, camera.ZUVec);
	end

	local hf_x, hf_y, hf_wide, hf_high = windowRect( getWin());
	cprintf(cli.turquoise, language[42], hf_wide, hf_high, hf_x, hf_y );	-- RoM windows size

	-- convert player name to profile name and check if profile exist
	local load_profile_name;	-- name of profile to load
	if( forcedProfile ) then
		load_profile_name = convertProfileName(forcedProfile);
	else
		load_profile_name = convertProfileName(player.Name);
	end

	-- Set window name, install timer to automatically do it once a second
	local displayname = string.sub(load_profile_name, 1, 4) .. "****";
	setWindowName(getHwnd(), sprintf("RoM Bot %s [%s]", BOT_VERSION, displayname));
	settings.loadProfile(load_profile_name);
	settingsPrintKeys();		-- print keyboard settings to MM and log
	registerTimer("timedSetWindowName", secondsToTimer(1), timedSetWindowName, load_profile_name);
	player.BotStartTime_nr = os.time();	-- remember bot start time no reset
	player.level_detect_levelup = player.Level;	-- remember actual player level
	
	-- Register and update inventory
	inventory = CInventory();
	inventory:update();

	-- onLoad event
	-- possibility for users to overwrite profile settings
	if( type(settings.profile.events.onLoad) == "function" ) then
		local status,err = pcall(settings.profile.events.onLoad);
		if( status == false ) then
			local msg = sprintf("onLoad error: %s", err);
			error(msg);
		end
	end


	-- list waypoint files and files in folders
	-- only files with filetype '.xml' are listed
	-- only folders without '.' are listed
	-- only 1 level of subfolders will be listed
	local function list_waypoint_files()

		local hf_counter = 0;
		local pathlist = { }
		
		local function read_subdirectory(_folder)
			local subdir = getDirectory(getExecutionPath() .. "/waypoints/".._folder);
			if( not subdir) then return; end
			
			for i,v in pairs(subdir) do
				if( string.find (v,".xml",1,true) ) then
					hf_counter = hf_counter + 1;
						pathlist[hf_counter] = { };
						pathlist[hf_counter].folder = _folder;
						pathlist[hf_counter].filename = v;
				end
			end
			
		end		-- end of: local function read_subdirectory(_folder)


		local function concat_filename(_i, _folder, _filename)
			
			local hf_newname;
			local hf_folder = "";
			local hf_dots = "";
			local hf_slash = "";
			
			if( _folder  and  string.len(_folder) > 8 )  then 
				hf_folder = string.sub(_folder, 1, 6); 
				hf_dots = "..";
				hf_slash = "/";
			elseif( _folder  and  string.len(_folder) > 0 )  then 
				hf_folder = _folder;
				hf_slash = "/";
			end
			
			hf_newname = sprintf("%s%s%s%s",
			  hf_folder,
			  hf_dots,
			  hf_slash,
			  _filename);
			
			hf_nr = sprintf("%3d:", _i);
			
			return hf_nr, hf_newname;

		end

		-- choose a path from the waypoints folder
		local dir = getDirectory(getExecutionPath() .. "/waypoints/")

		cprintf(cli.green, language[144], getExecutionPath());	-- Waypoint files in %s


		-- copy table dir to table pathlist
		-- select only xml files
		pathlist[0] = { };
		pathlist[0].filename = "wander";
		for i,v in pairs(dir) do
		
			-- no . means perhaps folder
			if( not string.find (v,".",1,true) ) then
				read_subdirectory(v);
				
			-- only list files with extension .xml
			elseif( string.find (v,".xml",1,true) ) then
				hf_counter = hf_counter + 1;
				pathlist[hf_counter] = { };
				pathlist[hf_counter].filename = v;
			end
		end

		local inc = math.ceil(#pathlist/3);
		
		for i = 0, inc do
			
			local column1 = ""; local column2 = ""; local column3 = "";
			local col1nr = ""; local col2nr = ""; local col3nr = "";
			
			col1nr, column1 = concat_filename(i, pathlist[i].folder, pathlist[i].filename)
			
			if ( (i + inc) <= #pathlist ) then
				col2nr, column2 = concat_filename(i+inc, pathlist[i+inc].folder, pathlist[i+inc].filename);
			end
			if ( (i+inc*2) <= #pathlist ) then
				col3nr, column3 = concat_filename(i+inc*2, pathlist[i+inc*2].folder, pathlist[i+inc*2].filename);
			end

			cprintf(cli.green,"%s %s %s %s %s %s\n", 
				col1nr,
				string.sub(column1.."                    ", 1, 21),
				col2nr,
				string.sub(column2.."                    ", 1, 21),
				col3nr,
				string.sub(column3.."                    ", 1, 20) );

		end

		-- ask for pathname to choose
		keyboardBufferClear();
		io.stdin:flush();
		cprintf(cli.green, language[145], getKeyName(_G.key.VK_ENTER) );	-- Enter the number of the path 
		local hf_choose_path_nr = tonumber(io.stdin:read() );
		if( hf_choose_path_nr == nil) then hf_choose_path_nr = 0; end;
		if( hf_choose_path_nr >= 0 and
			hf_choose_path_nr <= #pathlist ) then 
			printf(language[146], hf_choose_path_nr );	-- You choose %s\n
			if( pathlist[hf_choose_path_nr].folder ) then
				wp_to_load = pathlist[hf_choose_path_nr].folder.."/"..pathlist[hf_choose_path_nr].filename;
			else
				wp_to_load = pathlist[hf_choose_path_nr].filename;
			end
			
			return wp_to_load;
		else
			cprintf(cli.yellow, language[147]);	-- Wrong selection
			return false;
		end

	end	
	-- end of local function list_waypoint_files()
	

	-- This logic prevents files from being loaded if wandering was forced
	local wp_to_load, rp_to_load;
	if( forcedPath ) then			-- waypointfile or 'wander'
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

	if( settings.profile.options.PATH_TYPE == "wander") then
	    wp_to_load = "wander";
	end
	
	-- if we don't have a wp file to load, list them
	while(wp_to_load == nil	or
	  wp_to_load == ""		or
	  wp_to_load == false	or		  
	  wp_to_load == " ") do
		wp_to_load = list_waypoint_files();
	end;
		
	if( wp_to_load == "wander" ) then
		__WPL = CWaypointListWander();
		__WPL:setRadius(settings.profile.options.WANDER_RADIUS);
		__WPL:setMode("wander");
	    cprintf(cli.green, language[168], settings.profile.options.WANDER_RADIUS );	-- we wander around
	else
		__WPL = CWaypointList();
		loadPaths(wp_to_load, rp_to_load);	-- load the waypoint path / return path
	end;

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
			resurrect();
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


		-- update one slot at a time, or next 3
		inventory:updateNextSlot();
		inventory:updateNextSlot();
		inventory:updateNextSlot();

		-- trigger timed inventory update
		--if( os.difftime(os.time(), player.InventoryLastUpdate) > 
			--settings.profile.options.INV_UPDATE_INTERVAL ) then
			--player.InventoryDoUpdate = true;
		--end

		-- update inventory if update flag is set
		-- TODO: rolling update while resting?
		--if(player.InventoryDoUpdate == true and
		   --not player.Battling ) then
--			player.InventoryDoUpdate = false;
--			player.InventoryLastUpdate = os.time();		-- remember update time
			--inventory:update();
		--end;


		-- check if levelup happens / execute after aggro is gone
		-- we do it here , to be sure, aggro flag is gone
		--  aggro flag would needs a wait (if no loot), so we don't check it
		if(player.Level > player.level_detect_levelup   and
		   not player.Battling )  then
		
			player.level_detect_levelup = player.Level;

			-- check if onLevelup event is used in profile
			if( type(settings.profile.events.onLevelup) == "function" ) then
				local status,err = pcall(settings.profile.events.onLevelup);
				if( status == false ) then
					local msg = sprintf(language[85], err);
					error(msg);
				end
			end
		end


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
				cprintf(cli.green, language[113]);	-- we don't stop and don't fight back
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
							cprintf(cli.yellow, language[55], 
							  player.Unstick_counter, 
							  settings.profile.options.MAX_UNSTICK_TRIALS );	-- max unstick reached
							player:logout(); 
						end;
						cprintf(cli.red, language[9], player.X, player.Z, 	-- unsticking player... at position
						   player.Unstick_counter, settings.profile.options.MAX_UNSTICK_TRIALS);
					else
						cprintf(cli.red, language[114], 	-- unsticking player... at position
						   player.X, player.Z, player.Unstick_counter);
					end
					player:unstick();
				end
			end

			coroutine.yield();

		end
	end
	
end

function resurrect()
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
		cprintf(cli.yellow, language[103]); -- If you want to use automatic resurrection
	end

	local hf_res_from_priest; 		-- for check if priest resurrect
	if( settings.profile.options.RES_AUTOMATIC_AFTER_DEATH == true ) then
		cprintf(cli.red, language[3]);			-- Died. Resurrecting player...
				
		-- try mouseclick to reanimate
		cprintf(cli.green, language[104]);  -- try to resurrect in 10 seconds
		yrest(10000);

		-- if still dead, try macro if one defined
		if( not player.Alive and settings.profile.hotkeys.MACRO ) then
			cprintf(cli.green, language[107]);  -- use the ingame resurrect macro
			RoMScript("AcceptResurrect();");
			yrest(settings.profile.options.WAIT_TIME_AFTER_RES);	
			player:update();
		end

		if( not player.Alive ) then
			local hf_keyname ;
			if( settings.profile.hotkeys.MACRO ) then
				hf_keyname = getKeyName(settings.profile.hotkeys.MACRO.key)
			else
				hf_keyname = "";
			end
			cprintf(cli.yellow, language[108], -- still death, did you set your macro?
				hf_keyname);
			if( hf_keyname == "")  then
				cprintf(cli.yellow, language[166]); -- Please set new profile option MACRO
			end

		end

		-- death counter message
		cprintf(cli.green, language[109],	-- You have died %s times 
		   player.Death_counter, settings.profile.options.MAX_DEATHS);
				
		-- check maximal death if automatic mode
		if( player.Death_counter > settings.profile.options.MAX_DEATHS ) then
			cprintf(cli.yellow, language[54], player.Death_counter, 
			  settings.profile.options.MAX_DEATHS );	-- to much deaths
			player:logout();
		end
-- TODO: check for buff.
		if( player.Level > 9  and 
		    player.Alive      and
		    hf_res_from_priest ~= true ) then	-- no wait if resurrect at the place of death / priest / buff
			cprintf(cli.red, language[4]);		-- Returning to waypoints after 1 minute.
			
			-- check the first debuff that player has. (it has to be the weakness!)
			local debuff = RoMScript("GetPlayerBuffLeftTime(GetPlayerBuff(1,'HARMFUL'))");
			debuff = tonumber(debuff);
			if (debuff == 0) then
				print("this was a PK, or no xp debt, and it will not be counted as a death");
				player.Death_counter = player.Death_counter + 1;
			end
			
			player:rest(debuff); -- wait off the debuff before going about your path.
		end

	end

	player:update();
	-- pause if still death
	if( not player.Alive ) then
		pauseOnDeath();
	end

	-- use/compare return path if defined, if not use normal one and give a warning
	-- wen need to search the closest, hence we also accept resurrection at the death place
	player:rest(10); -- give some time to be really sure that loadscreen is gone
	-- if not it could result in loading NOT the returnpath, becaus we dont hat the new position
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
		end
	else
		cprintf(cli.yellow, language[111], __WPL:getFileName() ); -- don't have a defined return path
	end
			
	-- not using returnpath, so we use the normal waypoint path
	if( player.Returning == nil) then
		player.Returning = false;
		__WPL:setWaypointIndex( __WPL:getNearestWaypoint(player.X, player.Z ) );
		cprintf(cli.green, language[112], 	-- using normal waypoint file
		__WPL:getFileName() );
	end
end
startMacro(main);