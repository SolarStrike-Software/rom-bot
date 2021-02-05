BOT_VERSION = 4.0;
BOT_REVISION = '<UNKNOWN>';
;
if( type(getVersion) ~= 'function' or (getVersion() / 100) >= 1.06 ) then
		error("The RoM-Bot scripts are not compatible with your MicroMacro version.\n"
		.. "Please download and install version 1.05:\n\n"
		.. "http://solarstrike.net/project/download/44", 0);
end

include('qword.lua');
include("addresses.lua");
include("database.lua");
include("functions.lua");
include("classes/player.lua");
include("classes/equipment.lua");
include("classes/inventory.lua");
include("classes/bank.lua");
include("classes/guildbank.lua");
include("classes/cursor.lua");
include("classes/camera.lua");
include("classes/waypoint.lua");
include("classes/waypointlist.lua");
include("classes/waypointlist_wander.lua");
include("classes/node.lua");
include("classes/object.lua");
include("classes/objectlist.lua");
include("classes/eggpet.lua");
include("classes/store.lua");
include("classes/party.lua");
include("classes/itemtypes.lua");
include("classes/pet.lua");
include("classes/memdatabase.lua");
include("classes/codemod.lua");
include("settings.lua");
include("macros.lua");


functionBeingLoaded = "romglobal/userfunctions.lua"
if( fileExists(getExecutionPath().."/../romglobal/userfunctions.lua") ) then
	include("../romglobal/userfunctions.lua");
end

functionBeingLoaded = "userfunctions.lua"
if( fileExists(getExecutionPath().."/userfunctions.lua") ) then
	include("userfunctions.lua");
end

functionBeingLoaded = nil -- In case the user has no userfunctions.

-- Allow include to check global and relative folders too
if originalInclude == nil then
	originalInclude = include
end
function include(file, forceInclude)
	return originalInclude(findFile(file), forceInclude)
end

functionBeingLoaded = nil -- In case the user has no userfunctions.

printf("Installing userfunctions. ") -- Message to help tell when userfunctions are a problem
-- Install bot userfunctions
local addondir = getDirectory(getExecutionPath() .. "/userfunctions/");
for i,v in pairs(addondir) do
	local match = string.match(v, "^addon_(.*)%.lua");
	if( not match ) then match = string.match(v, "^userfunction_(.*)%.lua"); end;
	if( match ~= nil ) then
		functionBeingLoaded = match
		include("userfunctions/" .. v);
		functionBeingLoaded = nil
		logMessage("Bot userfunction \'" .. match .. "\' successfully loaded.");
	end
end

-- Install global bot userfunctions
local globaladdondir = getDirectory(getExecutionPath() .. "/../romglobal/userfunctions/");
if globaladdondir then
	local localdir = getExecutionPath() .. "/userfunctions/"
	for i,v in pairs(globaladdondir) do
		if not(fileExists(localdir .. v)) then -- if not in local 'userfunctions'
			local match = string.match(v, "^addon_(.*)%.lua");
			if( not match ) then match = string.match(v, "^userfunction_(.*)%.lua"); end;
			if( match ~= nil ) then
				functionBeingLoaded = match
				include("../romglobal/userfunctions/" .. v);
				functionBeingLoaded = nil
				logMessage("Global bot userfunction \'" .. match .. "\' successfully loaded.");
			end
		end
	end
end
printf("\n") -- Return to indicate end of userfunction installation. User wont notice this but
             -- if error is on same line as "Installing userfunctions" then we know it a userfunction error.

-- Check for old userfunction_questbyname
if compareQuestnames then
	error("The QuestByName functions are now part of the bot. The old userfunction is obsolete. Please remove the 'userfunctions_questbyname.lua' file from the userfunctions folder.")
end

setPriority(priority.high);

settings.load();
setStartKey(settings.hotkeys.START_BOT.key);
setStopKey(settings.hotkeys.STOP_BOT.key);



__WPL = nil;	-- Way Point List
__RPL = nil;	-- Return Point List






-- start message
local gitRevision = getCurrentRevision();
text = sprintf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ..
	"Welcome to rom bot! press END to quit\n" ..
	"RoM Bot Version %0.2f, Revision %s\n", BOT_VERSION, gitRevision);

printPicture("logo", text, 4);


if( (os.time() - getLastUpdateCheckedTime())  > 60*10 ) then
	if( isGitUpdateAvailable() ) then
		print("\nA new update is available. Please run `gitupdate.lua` to install");
	end
	setLastUpdateCheckedTime();
end


function main()
	local forcedProfile = nil;
	local forcedPath = nil;
	local forcedRetPath = nil;
	local forcedCharacter = nil;
	local debug_override = false

	for i = 2,#args do
		args[i] = string.lower(args[i])
		if( args[i] == "update" ) then
			include("update.lua");
		end

		if( args[i] == "debug" ) then
			debug_override = true
			settings.options.DEBUGGING = true;
			settings.options.DEBUGGING_MACRO = true;

			-- adds the numbers to the prints while in debug mode,
			-- normal language code is in settings.lua

			if( settings.options.USE_CLIENT_LANGUAGE ) then
				local hf_language;
				if( bot.ClientLanguage == "DE" ) then
					hf_language = "deutsch";
				elseif(bot.ClientLanguage  == "FR" ) then
					hf_language = "french";
				elseif(bot.ClientLanguage  == "RU" ) then
					hf_language = "russian";
				elseif(bot.ClientLanguage == "PL" ) then
					hf_language = "polish";
				else
					hf_language = "english";
				end
				local function setLanguage(_name)
					include("/language/" .. _name .. ".lua");
				end
				local lang_base = {};
				for i,v in pairs(language) do lang_base[i] = v; end;	-- remember current language value to fill gaps with that
				setLanguage(hf_language);
				for i,v in pairs(lang_base) do
					if( language[i] == nil ) then
						language[i] = "["..i.."] "..v;
					end
				end;
				lang_base = nil; -- Not needed anymore, destroy it.
				logMessage("Load Language for debugging with numbers");
			end
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
			elseif( var == "character") then
				forcedCharacter = val;
			else
				-- invalid option
				local msg = sprintf(language[61], args[i]);
				error(msg, 0 );
			end
		end

		-- check the options
		if(not foundpos  and  args[i] ~= "update" and args[i] ~= "debug" ) then
			local msg = sprintf(language[61], args[i]);
			error(msg, 0 );
		end;

	end

	database.load();
	attach(getWin(forcedCharacter));
	getTEXT(); -- Ensure that we cache game text info now rather than later

	if( not checkExecutableCompatible() ) then
		printf("Addresses seem off, trying to update.\n")
		include("update.lua")
		if( not checkExecutableCompatible() ) then
			error("The addresses didn't update, you will have to wait until there is an SVN update that updates the addresses.\n")
		else
			cprintf(cli.yellow,"update.lua seems to have worked, addresses.lua has been updated.\n")
		end
	end


	local gameroot = getBaseAddress(addresses.game_root.base);
	local playerAddress = memoryReadRepeat("uintptr", getProc(), gameroot, addresses.game_root.player.base);
	if( settings.options.DEBUGGING ) then
		printf(language[44]);	-- Attempt to read playerAddress
	end

	if( playerAddress == nil ) then
		local msg = sprintf(language[48], "playerAddress");	-- pls update to current version
		error(msg, 0);
	end;

	equipment = CEquipment()
	player = CPlayer.new();

	if( settings.options.DEBUGGING ) then
		-- Player debugging info
		printf("[DEBUG] playerAddr: 0x%X\n", player.Address);
		printf("[DEBUG] player classes: %d/%d\n", player.Class1, player.Class2);
		printf("[DEBUG] player pet: 0x%X\n", player.PetPtr);
		printf("[DEBUG] Player target: 0x%X\n", player.TargetPtr);

		if( player.TargetPtr ~= 0 ) then
			local target = CPawn(player.TargetPtr);
			printf("[DEBUG] player target type: 0x%X\n", target.Type);
			printf("[DEBUG] player target attackable: %s\n", target.Attackable);
			printf("[DEBUG] player target aggressive: %s\n", target.Aggressive);
		end

		printf("[DEBUG] player in battle: %s\n", tostring(player.Battling));
	end


	if( settings.options.DEBUGGING ) then
		-- Mouse pawn debugging info
		local mousePawn = CPawn( memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.mousePtr_offset) );
		printf("[DEBUG] mousePawn: 0x%X\n", mousePawn.Address);
		printf("[DEBUG] mousePawn id: %d\n", mousePawn.Id);
	end

	camera = CCamera();
	if( settings.options.DEBUGGING ) then
		printf("[DEBUG] camAddress: 0x%X\n", camera.Address);
	end


	if( settings.options.DEBUGGING ) then
		-- Camera debugging info
		printf("[DEBUG] Cam X: %0.2f, Y: %0.2f, Z: %0.2f\n", camera.X, camera.Y, camera.Z);
		printf("[DEBUG] Cam XU: %0.2f, YU: %0.2f, ZU: %0.2f\n", camera.XUVec, camera.YUVec, camera.ZUVec);
	end

	cprintf(cli.turquoise, "Game Version is %s\n", getGameVersion())
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
	local displayname = player.Name
	if #displayname > 8 then
		displayname = string.sub(displayname, 1, 7) .. "*";
	end
	setWindowName(getHwnd(), sprintf("RoM Bot %s [%s]", BOT_VERSION, displayname));
	settings.loadProfile(load_profile_name);
	if RoMScript("GC_GetMouseMoveEnable()") == false then
		cprintf(cli.yellow, language[190],"Click to Move") -- The bot requires 'Click to Move'
		RoMCode("GC_SetMouseMoveEnable(true)")
	end
	if RoMScript("GC_GetSelfCastEnable()") == false then
		cprintf(cli.yellow, language[190],"Self Cast") -- The bot requires 'Self Cast'
		RoMCode("GC_SetSelfCastEnable(true)")
	end
	if debug_override == true then -- Needs to be after loading profile.
		--settings.profile.options.DEBUG_INV = true;
		settings.profile.options.DEBUG_LOOT = true;
		settings.profile.options.DEBUG_TARGET = true;
		settings.profile.options.DEBUG_HARVEST = true;
		settings.profile.options.DEBUG_WAYPOINT = true;
		settings.profile.options.DEBUG_AUTOSELL = true;
	end
	player:update()
	settingsPrintKeys();		-- print keyboard settings to MM and log
	registerTimer("timedSetWindowName", secondsToTimer(1), timedSetWindowName, load_profile_name);
	player.BotStartTime_nr = os.time();	-- remember bot start time no reset
	player.level_detect_levelup = player.Level;	-- remember actual player level

	store = CStore()

	if( getTimerFrequency ) then
		-- Grab the real frequency instead of calculating it, if available
		bot.GetTimeFrequency = getTimerFrequency().low / 1000;
	else
		-- calculate the CPU Frequency / used for manipulation the GetTime() values
		local calc_start = getTime();
		yrest(1000);
		local calc_end = getTime();
		bot.GetTimeFrequency = (calc_end.low - calc_start.low) / 1000;
	end

	printf("[DEBUG] CPU Frequency %s\n", bot.GetTimeFrequency);

	-- Force bank items to be loaded into memory before instantiating bank
	RoMScript(sprintf('/script for i=1,300 do GetBankItemInfo(i) end'));
	--yrest(50);

	inventory = CInventory();		-- register inventory (needs profile loaded because of maxslot)
	bank = CBank()
	guildbank = CGuildbank()
	cursor = CCursor()

	LoadItemTypes()     -- Needs macros to already be set up.


	-- list waypoint files and files in folders
	-- only files with filetype '.xml' are listed
	-- only folders without '.' are listed
	-- only 1 level of subfolders will be listed
	local current_folder = ""
	local show_subfiles = settings.profile.options.WPL_SHOW_SUBFOLDER_FILES
	if show_subfiles ~= true then show_subfiles = false end -- default true

	local function list_waypoint_files()

		local hf_counter = 0;
		local pathlist = { }

		local function read_subdirectory(_folder)
			local tmpfolder = _folder
			if current_folder ~= "" then
				tmpfolder = current_folder .. "/" .. _folder
			end
			local subdir = getDirectory(getExecutionPath() .. "/waypoints/" .. tmpfolder)

			if( not subdir) then return; end
			if show_subfiles then
				for i,v in pairs(subdir) do
					if( string.find (v,".xml",1,true) ) then
						hf_counter = hf_counter + 1;
						pathlist[hf_counter] = { };
						pathlist[hf_counter].folder = _folder;
						pathlist[hf_counter].filename = v;
					end
				end
			else
				hf_counter = hf_counter + 1
				pathlist[hf_counter] = { };
				pathlist[hf_counter].folder = _folder;
			end

		end		-- end of: local function read_subdirectory(_folder)


		local function concat_filename(_i, _folder, _filename)

			local hf_newname;
			local hf_folder = "";
			local hf_dots = "";
			local hf_slash = "";

			if _folder  then
				if _filename then
					if string.len(_folder) > 8 then
						hf_folder = string.sub(_folder, 1, 6);
						hf_dots = "..";
						hf_slash = "/";
					elseif( _folder  and  string.len(_folder) > 0 )  then
						hf_folder = _folder;
						hf_slash = "/";
					end
				else
					if string.len(_folder) > 20 then
						hf_folder = string.sub(_folder, 1, 18);
						hf_dots = "..";
						hf_slash = "/";
					elseif( _folder  and  string.len(_folder) > 0 )  then
						hf_folder = _folder;
						hf_slash = "/";
					end
				end
			end

			hf_newname = sprintf("%s%s%s%s",
			  hf_folder,
			  hf_dots,
			  hf_slash,
			  _filename or "");

			hf_nr = sprintf("%3d:", _i);

			return hf_nr, hf_newname;

		end

		-- Get file info from waypoints folder
		local dir = getDirectory(getExecutionPath() .. "/waypoints/" .. current_folder)

		-- copy table dir to table pathlist
		-- select only xml files
		pathlist[0] = { };
		if current_folder == "" then
			pathlist[0].filename = "wander";
			pathlist[1] = { filename = "resume" };
			hf_counter = 1
		else
			pathlist[0].folder = ".."
		end

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
		local last_local = hf_counter

		if current_folder == "" then
			-- Get file info from global waypoints folder
			local globdir = getDirectory(getExecutionPath() .. "/../romglobal/waypoints")

			if globdir then
				-- copy table dir to table pathlist
				-- select only xml files
				for i,v in pairs(globdir) do

					-- no . means perhaps folder
					if( not string.find (v,".",1,true) ) then
						read_subdirectory("../../romglobal/waypoints/"..v);

					-- only list files with extension .xml
					elseif( string.find (v,".xml",1,true) ) then
						hf_counter = hf_counter + 1;
						pathlist[hf_counter] = { };
						pathlist[hf_counter].folder = "../../romglobal/waypoints";
						pathlist[hf_counter].filename = v;
					end
				end
			end
		end

		-- Print local waypoint files
		cprintf(cli.green, language[144], getExecutionPath());	-- Waypoint files in %s
		if current_folder ~= "" then print("Sub folder: "..current_folder) end

		local inc = math.ceil((last_local+1)/3);
		for i = 0, inc - 1 do

			local column1 = ""; local column2 = ""; local column3 = "";
			local col1nr = ""; local col2nr = ""; local col3nr = "";

			col1nr, column1 = concat_filename(i, pathlist[i].folder, pathlist[i].filename)

			if ( (i + inc) <= last_local ) then
				col2nr, column2 = concat_filename(i+inc, pathlist[i+inc].folder, pathlist[i+inc].filename);
			end
			if ( (i+inc*2) <= last_local ) then
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

		-- Print global waypoint files
		if #pathlist > last_local then
			cprintf(cli.green, language[144], getExecutionPath() .. "/../romglobal");	-- Waypoint files in %s

			local inc = math.ceil((#pathlist-last_local)/3);
			for i = last_local + 1, last_local + inc do

				local column1 = ""; local column2 = ""; local column3 = "";
				local col1nr = ""; local col2nr = ""; local col3nr = "";

				col1nr, column1 = concat_filename(i, string.gsub(pathlist[i].folder,"%.%./%.%./romglobal/waypoints/*",""), pathlist[i].filename)

				if ( (i + inc) <= #pathlist ) then
					col2nr, column2 = concat_filename(i+inc, string.gsub(pathlist[i+inc].folder,"%.%./%.%./romglobal/waypoints/*",""), pathlist[i+inc].filename);
				end
				if ( (i+inc*2) <= #pathlist ) then
					col3nr, column3 = concat_filename(i+inc*2, string.gsub(pathlist[i+inc*2].folder,"%.%./%.%./romglobal/waypoints/*",""), pathlist[i+inc*2].filename);
				end

				cprintf(cli.green,"%s %s %s %s %s %s\n",
					col1nr,
					string.sub(column1.."                    ", 1, 21),
					col2nr,
					string.sub(column2.."                    ", 1, 21),
					col3nr,
					string.sub(column3.."                    ", 1, 20) );

			end
		end

		-- ask for pathname to choose
		keyboardBufferClear();
		io.stdin:flush();
		cprintf(cli.green, language[145], getKeyName(_G.key.VK_ENTER) );	-- Enter the number of the path
		local hf_choose_path_nr = io.stdin:read()
		if hf_choose_path_nr == "q" then
			error("Quiting.",0)
		end
		hf_choose_path_nr = tonumber(hf_choose_path_nr)
		if( hf_choose_path_nr and
			hf_choose_path_nr >= 0 and
			hf_choose_path_nr <= #pathlist ) then
			printf(language[146], hf_choose_path_nr );	-- You choose %s\n
			if pathlist[hf_choose_path_nr].filename then
				if( pathlist[hf_choose_path_nr].folder ) then
					wp_to_load = pathlist[hf_choose_path_nr].folder.."/"..pathlist[hf_choose_path_nr].filename;
				else
					if current_folder == "" then
						wp_to_load = pathlist[hf_choose_path_nr].filename;
					else
						wp_to_load = current_folder .. "/" .. pathlist[hf_choose_path_nr].filename;
					end
				end
			else
				if pathlist[hf_choose_path_nr].folder == ".." then
					current_folder = string.match(current_folder,"(.*)/[^/]*$") or ""
					if string.lower(current_folder) == "/../../romglobal/waypoints" then current_folder = "" end
				else
					current_folder = current_folder .. "/" .. pathlist[hf_choose_path_nr].folder
				end
			end
			return wp_to_load;
		else
			local filename = fixSlashes(getOpenFileName(getExecutionPath().."/waypoints/"))
			if filename == "" then
				cprintf(cli.yellow, language[147]);	-- Wrong selection
				yrest(3000);
				return false;
			else
				-- Convert to relative path
				local wpfolder = {}
				for folder in string.gmatch(getExecutionPath().."/waypoints/","([^/]+)") do
					table.insert(wpfolder,folder)
				end
				local fnfolder = {}
				for folder in string.gmatch(filename,"([^/]+)") do
					table.insert(fnfolder,folder)
				end
				if fnfolder[1] ~= wpfolder[1] then
					cprintf(cli.yellow, language[191]);	-- The RoMBot currently only supports running waypoint files located on the same drive as MicroMacro.
					yrest(3000);
					return false
				end
				local fileNameStart = ""
				local fileNameEnd = table.copy(fnfolder)
				local changefound = false
				for k,v in pairs(wpfolder) do
					if fnfolder[k] == v and changefound == false then
						table.remove(fileNameEnd,1)
					else
						changefound = true
						fileNameStart = fileNameStart .. "../"
					end
				end

				return fileNameStart .. table.concat(fileNameEnd,"/")
			end
		end

	end
	-- end of local function list_waypoint_files()


	-- This logic prevents files from being loaded if wandering was forced
	local wp_to_load, rp_to_load;
	-- get wp filename to load
	if( forcedPath ) then			-- waypointfile or 'wander'
		local filename = getExecutionPath() .. "/waypoints/" .. string.gsub(forcedPath,".xml","") .. ".xml";
		local globalfilename = getExecutionPath() .. "/../romglobal/waypoints/" .. string.gsub(forcedPath,".xml","") .. ".xml";
		local resumelogname = getExecutionPath() .. "/logs/resumes/"..player.Name..".txt"

		if fileExists(filename) or ( string.lower(forcedPath) == "wander" ) or
				( string.lower(forcedPath) == "resume" and fileExists(resumelogname) ) then
			wp_to_load = forcedPath;
		elseif fileExists(globalfilename) then
			wp_to_load = "../../romglobal/waypoints/"..forcedPath;
		else
			cprintf(cli.yellow,language[153], filename ); -- We can't find your waypoint file
		end;
	else
		if( settings.profile.options.WAYPOINTS and __WPL == nil ) then
			wp_to_load = settings.profile.options.WAYPOINTS;
		end
	end

	-- get rp filename to load
	if( forcedRetPath ) then
		rp_to_load = forcedRetPath;
	else
		if( settings.profile.options.RETURNPATH and __RPL == nil ) then
			rp_to_load = settings.profile.options.RETURNPATH;
		end
	end

	-- set wander if defined in profile
	if( settings.profile.options.PATH_TYPE == "wander") then
	    wp_to_load = "wander";
	end

	-- list the path list?
	-- if we don't have a wp file to load, list them
	if( __WPL == nil ) then		-- not allready loaded (in onLoad event)

		while( wp_to_load == nil or wp_to_load == "" or wp_to_load == false	or wp_to_load == " " ) do
			wp_to_load = list_waypoint_files();
		end;
		if( wp_to_load == "wander" ) then
			cprintf(cli.lightgray,language[187])
			keyboardBufferClear();
			io.stdin:flush();
			local radius = tonumber(io.stdin:read())
			if type(radius) ~= "number" or 0 > radius then
				cprintf(cli.lightgray,"Expecting number more than or equal to 0. Using default value.\n")
				yrest(2000)
			else
				settings.profile.options.WANDER_RADIUS = radius
			end

			loadPaths("wander", rp_to_load);
		else
			loadPaths(wp_to_load, rp_to_load);	-- load the waypoint path / return path
		end;
	end;

	player:updateXYZ() -- update player coords

	-- special option for use waypoint file from profile in a reverse order / not if forced path
	if( settings.profile.options.WAYPOINTS_REVERSE == true  and
	    not forcedPath  ) then
		__WPL:reverse();
	end;

	-- look for the closest waypoint / return path point to start
	if( __RPL and __WPL.Mode ~= "wander" ) then	-- return path points available ?
		-- compare closest waypoint with closest returnpath point
		__WPL:setWaypointIndex( __WPL:getNearestWaypoint(player.X, player.Z, player.Y ) );
		local hf_wp = __WPL:getNextWaypoint();
		local dist_to_wp = distance(player.X, player.Z, player.Y, hf_wp.X, hf_wp.Z, hf_wp.Y)

		__RPL:setWaypointIndex( __RPL:getNearestWaypoint(player.X, player.Z, player.Y ) );
		local hf_wp = __RPL:getNextWaypoint();
		local dist_to_rp = distance(player.X, player.Z, player.Y, hf_wp.X, hf_wp.Z, hf_wp.Y)

		if( dist_to_rp < dist_to_wp ) then	-- returnpoint is closer then next normal wayoiint
			player.Returning = true;	-- then use return path first
			cprintf(cli.yellow, language[12]);	-- Starting with return path
		else
			player.Returning = false;	-- use normale waypoint path
		end;
	else
		if __WPL.ResumePoint then
			__WPL:setWaypointIndex(__WPL.ResumePoint)
		else
			__WPL:setWaypointIndex( __WPL:getNearestWaypoint(player.X, player.Z, player.Y ) );
		end
	end;

	-- Update inventory
	inventory:update();

	-- Profile onLoad event
	-- possibility for users to overwrite profile settings
	if( type(settings.profile.events.onLoad) == "function" ) then
		local status,err = pcall(settings.profile.events.onLoad);
		if( status == false ) then
			local msg = sprintf("onLoad error: %s", err);
			error(msg);
		end
	end

	-- Remember login details
	CurrentLoginAcc = RoMScript("LogID")
	CurrentLoginChar = RoMScript("CHARACTER_SELECT.selectedIndex")
	CurrentLoginServer = RoMScript ("GetCurrentRealm()")
	__, CurrentLoginChannel = getZoneId()
	CurrentLoginMaxChannels = RoMScript("GetNumParalleZones()")

	local function checkClientCrash()
		if isClientCrashed() then
			if onClientCrash then
				print("Client crash detected. Running onClientCrash().")
				onClientCrash()
			else
				error("Client crash detected.")
			end
		end
	end
	registerTimer("ClientDetection", secondsToTimer(2), checkClientCrash);

	collectgarbage("collect");
	registerTimer("collectgarbage", secondsToTimer(60), function ()
		collectgarbage("collect");
	end);

	local distBreakCount = 0; -- If exceedes 3 in a row, unstick.
	while(true) do
		while __WPL.DoOnload do
			__WPL.DoOnload = false
			__WPL.onLoadEvent()
		end
		if __WPL.Mode == "waypoints" and #__WPL.Waypoints == 0 then -- Can't got to 'waypoints' with no waypoints
			error(language[114],1) -- No waypoints to go to
		end

		if( not isInGame() ) then
			MemDatabase:flush();
		end

		player:checkAddress()
		player:logoutCheck();
		player.Fighting = false;		-- we are now not in the fight routines

		player:updateAlive()
		if( not player.Alive ) then
			player:resetSkillLastCastTime();	-- set last use back, so we can rebuff
			resurrect();
		end

		-- reloading ammunition
		if ( settings.profile.options.RELOAD_AMMUNITION ) then
			local ammo = string.lower(settings.profile.options.RELOAD_AMMUNITION);
			if ammo ~= "thrown" and ammo ~= "arrow" then
				print("RELOAD_AMMUNITION can only be false, arrow or thrown!");
			elseif  ammo == "thrown" and (player.Class1 == CLASS_ROGUE or (player.Class2 == CLASS_ROGUE and player.Level > 11 and player.Level2 > 11)) then
				if inventory:getAmmunitionCount() == 0 then
					inventory:reloadAmmunition(ammo);
				end
			elseif ammo == "arrow" and (player.Class2 == CLASS_SCOUT or player.Class1 == CLASS_SCOUT) then
				if inventory:getAmmunitionCount() == 0 then
					inventory:reloadAmmunition(ammo);
				end
			end
		end


		-- go back to sleep, if in sleep mode
		if( player.Sleeping == true ) then
			yrest(800);	-- wait a little for the aggro flag
			player:updateBattling();
			if( player.Battling == false ) then
				player:sleep();
			end;
		end;	-- go sleeping if sleeping flag is set


		-- trigger timed inventory update
		if( os.difftime(os.time(), player.InventoryLastUpdate) >
			settings.profile.options.INV_UPDATE_INTERVAL ) then
			player.InventoryDoUpdate = true;
		end

		-- update inventory if update flag is set
		-- TODO: rolling update while resting?
		player:updateBattling();
		if(player.InventoryDoUpdate == true and
		   not player.Battling ) then
			player.InventoryDoUpdate = false;
			player.InventoryLastUpdate = os.time();		-- remember update time
			inventory:update();
		end;


		-- check if levelup happens / execute after aggro is gone
		-- we do it here , to be sure, aggro flag is gone
		--  aggro flag would needs a wait (if no loot), so we don't check it
		player:updateLevel()
		if(player.Level > player.level_detect_levelup   and
		   not player.Battling )  then

			player.level_detect_levelup = player.Level;

			-- check if onLevelup event is used in profile
			if( type(settings.profile.events.onLevelup) == "function" ) then
				local status,err = pcall(settings.profile.events.onLevelup);
				if( status == false ) then
					local msg = sprintf(language[75], err);
					error(msg);
				end
			end

			settings.updateSkillsAvailability()     -- Also needs macros to already be set up.
		end


		-- rest after getting new target and before starting fight
		-- rest between 50 until 99 sec, at most until full, after that additional rnd(10)
		if player.Current_waypoint_type ~= WPT_TRAVEL then	-- no resting if running waypoin type
			player:updateHP()
			player:updateMP()

			local manaRest, healthRest = false, false;
			if( player.MaxMana > 0 ) then
				manaRest = (player.Mana / player.MaxMana * 100) < settings.profile.options.MP_REST;
			end
			healthRest = (player.HP / player.MaxHP * 100) < settings.profile.options.HP_REST;

			if( manaRest or healthRest ) then
					player:rest( 50, 99, "full", 10 );		-- rest before next fight
			end
		end;


		-- If aggro, look for target
		local msg_print = false;
		player:updateBattling()
		if player.Battling then

			if( player.Current_waypoint_type == WPT_TRAVEL ) then
				cprintf(cli.green, language[113]);	-- we don't stop and don't fight back
			else
				if player:target(player:findEnemy(true,nil,evalTargetDefault)) then
					cprintf(cli.green, language[35]);	-- Got aggro. Attacking aggressive enemies.
				end
				yrest(10);
			end;
		end

		if( player.Current_waypoint_type ~= WPT_TRAVEL and player:haveTarget() ) then
			-- only fight back if it's not a TRAVEL waypoint
			-- remember players position at fight start
			local FightStartX = player.X;
			local FightStartZ = player.Z;

			-- Other check were done in defaultEvalFunction
			player:fight();

			-- check if we (as melee) can skip a waypoint because we touched it while moving to the fight place
			-- we do the check for all classes, even mostly only melees are touched by that, because only
			-- they move within the fightstart/-end
			local WPLorRPL;	-- current WP we want to reach next
			if( player.Returning ) then
				WPLorRPL = __RPL;	-- we are on a return path waypoint file
			else
				WPLorRPL = __WPL;	-- we are using a normal waypoint file
			end;
			if( WPLorRPL:getMode() ~= "wander" ) then
				local currentWp = WPLorRPL:getNextWaypoint();	-- get current wp we try to reach

				-- calculate direction in rad for: fight start postition -> current waypoint
				local dir_fightstart_to_currentwp = math.atan2(currentWp.Z - FightStartZ, currentWp.X - FightStartX);
				local dist_fightstart_to_currentwp = distance(FightStartX, FightStartZ, currentWp.X, currentWp.Z);

				-- calculate direction in rad for: fight start postition -> fight end postition
				local dir_fightstart_to_fightend = math.atan2(player.Z - FightStartZ, player.X - FightStartX);
				local dist_fightstart_to_fightend = distance(player.X, player.Z, FightStartX, FightStartZ);

				-- calculate how much  fighstart, wp and fightend are on a line, 0 = one line,
				local angleDif = angleDifference(dir_fightstart_to_currentwp, dir_fightstart_to_fightend);
				if (settings.profile.options.DEBUG_WAYPOINT) then
					printf("[DEBUG] FightStartX %s FightStartZ %s\n", FightStartX, FightStartZ );
					printf("[DEBUG] dir_FS->WP rad %.3f dir_FS->FE rad %.3f\n", dir_fightstart_to_currentwp, dir_fightstart_to_fightend );
					cprintf(cli.yellow, "[DEBUG] Line FS->WP / FS->FE: angleDif rad %.3f grad %d\n", angleDif, math.deg(angleDif) );
				end

				-- c = Wurzel (a2 + b2 - 2 a b cos (ga))
				local a = dist_fightstart_to_currentwp;
				local b = dist_fightstart_to_currentwp;
				local ga = angleDif;
				local dist_to_passed_wp = math.sqrt( math.pow(a,2) + math.pow(b,2) - 2 * a * b * math.cos(ga) );
				if (settings.profile.options.DEBUG_WAYPOINT) then
					cprintf(cli.yellow, "[DEBUG] We (would) pass(ed) wp #%s (dist %.1f) in a dist of %d (skip at %d)\n", currentWp.wpnum, dist_fightstart_to_currentwp,  dist_to_passed_wp, settings.profile.options.WAYPOINT_PASS );
				end

				if( dist_to_passed_wp < settings.profile.options.WAYPOINT_PASS  and		-- default is 100
					dist_fightstart_to_fightend >= dist_fightstart_to_currentwp ) then

					-- check position of the waypoint after the current waypoint we want to reach
					-- we don't check the closest wp, thats to much effort, we assume the distance between wp is
					-- as far, that the next one is always the closest
					local nextWp = WPLorRPL:getNextWaypoint(1);	-- get current wp we try to reach +1
					local dir_fightend_to_nextwp = math.atan2(nextWp.Z - player.Z, nextWp.X - player.X);
					local dir_fightend_to_currentwp = math.atan2(currentWp.Z - player.Z, currentWp.X - player.X );
					angleDif = angleDifference(dir_fightend_to_currentwp, dir_fightend_to_nextwp);
					if (settings.profile.options.DEBUG_WAYPOINT) then
						printf( "[DEBUG] currentWp #%s %s %s, FE->WP rad %.3f\n", currentWp.wpnum,currentWp.X,currentWp.Z,dir_fightend_to_currentwp);
						printf( "[DEBUG] nextWp #%s %s %s, FE->WP rad %.3f\n", nextWp.wpnum,nextWp.X,nextWp.Z,dir_fightend_to_nextwp);
						cprintf(cli.yellow, "[DEBUG] FE->wp#%s to FE->wp#%s is in a angle of %d grad (skip at %d)\n", nextWp.wpnum,  currentWp.wpnum, math.deg(angleDif), settings.profile.options.WAYPOINT_PASS_DEGR );
					end

					-- if next waypoint is 'in front' of current waypoint
					if( math.deg(angleDif) > settings.profile.options.WAYPOINT_PASS_DEGR ) then	-- default 90
						if (settings.profile.options.DEBUG_WAYPOINT) then
							cprintf(cli.yellow, "[DEBUG] We overrun waypoint #%d, skip it and move on to #%d\n",currentWp.wpnum, nextWp.wpnum);
						end
						cprintf(cli.green, "We overrun waypoint #%d, skip it and move on to #%d\n",currentWp.wpnum, nextWp.wpnum);
						WPLorRPL:advance();	-- set next waypoint

						-- execute the action from the skiped wp
						if( currentWp.Action and type(currentWp.Action) == "string" ) then
							local actionchunk = loadstring(currentWp.Action);
							if( not actionchunk ) then
								cprintf(cli.yellow, sprintf(language[150], WPLorRPL.CurrentWaypoint) .. "\n")
								handleLoadstringFailure(currentWp.Action, errmsg, filename)
							end
							actionchunk();
						end
						__WPL:updateResume()

					end

				end 	-- end of: check to skip a waypoint
			end


		else
		-- don't fight, move to wp
			if player.TargetPtr ~= 0 then player:clearTarget(); end

			-- First check up on eggpet
			checkEggPets()

			local wp = nil; local wpnum = nil;

			if( player.Returning ) then
				wp = __RPL:getNextWaypoint();
				wpnum = __RPL.CurrentWaypoint;
				wptag = (wp.Tag~='' and ' tag: '..wp.Tag or '')
				cprintf(cli.green, language[13], wpnum, wp.X, wp.Z, wptag);   -- Moving to returnpath waypoint
			else
				wp = __WPL:getNextWaypoint();
				wpnum = __WPL.CurrentWaypoint;
				wptag = (wp.Tag~='' and ' tag: '..wp.Tag or '')
				cprintf(cli.green, language[6], wpnum, wp.X, wp.Z, wptag);   -- Moving to waypoint
			end;

			player.Current_waypoint_type = wp.Type;		-- remember current waypoint type

			local success, reason = player:moveTo(wp,nil,true);

			player:updateMounted()
			if not player.Mounted then
				player:checkPotions();
				player:checkSkills( ONLY_FRIENDLY );	-- only cast hot spells to ourselfe
			end
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
						__WPL:setWaypointIndex(__WPL:getNearestWaypoint(player.X, player.Z, player.Y));
						if( __WPL.Mode == "wander" ) then
							__WPL.OrigX = player.X;
							__WPL.OrigZ = player.Z;
						end
						player.Returning = false;
						cprintf(cli.yellow, language[7]);

					else
						__RPL:advance();
					end

					-- Execute it's action, if it has one.
					if( wp.Action and type(wp.Action) == "string" and string.find(wp.Action,"%a") ) then
						keyboardRelease( settings.hotkeys.MOVE_FORWARD.key ); yrest(200) -- Stop moving
						local actionchunk = loadstring(wp.Action);
						if( not actionchunk ) then
							cprintf(cli.yellow, sprintf(language[150], __RPL.CurrentWaypoint) .. "\n")
							handleLoadstringFailure(wp.Action, errmsg, filename)
						end
						actionchunk();
					end
				else
					__WPL:advance();
					-- Execute it's action, if it has one.
					if( wp.Action and type(wp.Action) == "string" and string.find(wp.Action,"%a") ) then
						keyboardRelease( settings.hotkeys.MOVE_FORWARD.key ); yrest(200) -- Stop moving
						local actionchunk = loadstring(wp.Action);
						if( not actionchunk ) then
							cprintf(cli.yellow, sprintf(language[150], __WPL.CurrentWaypoint) .. "\n")
							handleLoadstringFailure(wp.Action, errmsg, filename)
						end
						actionchunk();
					end
				end
				__WPL:updateResume()
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

				if reason == WF_PULLBACK and #__WPL.Waypoints > 2 then
					__WPL:setWaypointIndex(__WPL:findPulledBeforeWaypoint())
				end

				if( reason == WF_STUCK or distBreakCount > 3 ) then
					-- Get ourselves unstuck, then!
					distBreakCount = 0;
					player:clearTarget();
					player.Success_waypoints = 0;	-- counter for successfull waypoints in row
					player.Unstick_counter = player.Unstick_counter + 1;	-- count our unstick tries

					-- Too many tries, logout
					if( settings.profile.options.MAX_UNSTICK_TRIALS > 0 and
						player.Unstick_counter > settings.profile.options.MAX_UNSTICK_TRIALS ) or
						(not isInGame()) then

						if isInGame() then
							cprintf(cli.yellow, language[55],
							  player.Unstick_counter,
							  settings.profile.options.MAX_UNSTICK_TRIALS );	-- max unstick reached
						else
							cprintf(cli.yellow, language[56]);	-- The game has been disconnected
						end

						-- check if onUnstickFailure event is used in profile
						if( type(settings.profile.events.onUnstickFailure) == "function" ) and
							player.Unstick_counter > settings.profile.options.MAX_UNSTICK_TRIALS then
							pcall(settings.profile.events.onUnstickFailure);

						elseif( settings.profile.options.LOGOUT_WHEN_STUCK ) then
							if settings.profile.options.CLOSE_WHEN_STUCK == false then
								player:logout() -- doesn't close client
							else
								player:logout(nil,true); -- closes client
							end
						else
						-- pause or stop ?
							player.Sleeping = true;		-- go to sleep
							--stopPE();	-- pause the bot
							-- we should play a sound !
							player.Unstick_counter = 0;
						end
					elseif( player.Sleeping ~= true) then	-- not when to much trial and we go to sleep
						-- unstick player und unstick message
						cprintf(cli.red, language[9], player.X, player.Z, 	-- unsticking player... at position
						   player.Unstick_counter, settings.profile.options.MAX_UNSTICK_TRIALS);
						player:unstick();
					end
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
	if settings.profile.options.RES_AUTOMATIC_AFTER_DEATH ~= nil then
	settings.profile.options.RES_AFTER_DEATH = settings.profile.options.RES_AUTOMATIC_AFTER_DEATH end -- backward compatability
	if( settings.profile.options.RES_AFTER_DEATH == false ) then
		cprintf(cli.yellow, language[103]); -- If you want to use automatic resurrection
	end

	if( settings.profile.options.RES_AFTER_DEATH == true ) then
		cprintf(cli.red, language[3]);			-- Died. Resurrecting player...

		cprintf(cli.green, language[104]);  -- try to resurrect in 5 seconds
		yrest(5000);

		-- Try to revive with macro
		if( not player.Alive ) then
			cprintf(cli.green, language[107]);  -- use the ingame resurrect macro
			RoMCode("UseSelfRevive();");	-- first try self revive
			yrest(500);
			RoMCode("BrithRevive();");
			waitForLoadingScreen(30)
			yrest(settings.profile.options.WAIT_TIME_AFTER_RES);
			player:update();
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

		if( player.Level > 9  and
		    player.Alive      ) then	-- no wait if resurrect at the place of death / priest / buff
			cprintf(cli.red, language[4]);		-- Returning to waypoints after 1 minute.

			-- check the first debuff that player has. (it has to be the weakness!)
			local debuff = RoMScript("GetPlayerBuffLeftTime(GetPlayerBuff(1,'HARMFUL'))");
			if(debuff == nil) then debuff = 0; end;
			debuff = tonumber(debuff);

			if (debuff == 0 and not settings.profile.options.PK_COUNTS_AS_DEATH) then
				print("This was a PK or no xp debt death.");
				player.Death_counter = player.Death_counter - 1;
			end

			player:rest(debuff,debuff+15); -- wait off the debuff before going about your path.
		end

	end

	player:updateAlive();
	-- pause if still death
	if( not player.Alive ) then
		pauseOnDeath();
	end

	-- use/compare return path if defined, if not use normal one and give a warning
	-- wen need to search the closest, hence we also accept resurrection at the death place
	player:rest(10); -- give some time to be really sure that loadscreen is gone
	-- if not it could result in loading NOT the returnpath, becaus we dont hat the new position
	player.Returning = nil;
	if( __RPL and __WPL.Mode ~= "wander" ) then
		-- compare closest waypoint with closest returnpath point
		__WPL:setWaypointIndex( __WPL:getNearestWaypoint(player.X, player.Z, player.Y ) );
		local hf_wp = __WPL:getNextWaypoint();
		local dist_to_wp = distance(player.X, player.Z, player.Y, hf_wp.X, hf_wp.Z, hf_wp.Y)

		__RPL:setWaypointIndex(__RPL:getNearestWaypoint(player.X, player.Z) );
		local hf_wp = __RPL:getNextWaypoint();
		local dist_to_rp = distance(player.X, player.Z, player.Y, hf_wp.X, hf_wp.Z, hf_wp.Y)

		if( dist_to_rp < dist_to_wp ) then	-- returnpoint is closer then next normal wayoiint
			player.Returning = true;	-- then use return path first
			cprintf(cli.yellow, language[12]);	-- Starting with return path
		end
	else
		cprintf(cli.yellow, language[111], __WPL:getFileName() ); -- don't have a defined return path
	end

	if( __RPL and __WPL.Mode == "wander" ) then
		__RPL:setWaypointIndex(1);
		player.Returning = true;
		cprintf(cli.yellow, language[12]);
	end

	-- not using returnpath, so we use the normal waypoint path
	if( player.Returning == nil) then
		player.Returning = false;
		__WPL:setWaypointIndex( __WPL:getNearestWaypoint(player.X, player.Z,player.Y ) );
		cprintf(cli.green, language[112], 	-- using normal waypoint file
		__WPL:getFileName() );
	end
end
startMacro(main,true);
