if( settings == nil ) then
	include("settings.lua");
end

local charUpdatePattern = string.char(0x85, 0xED, 0x0F, 0x84, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x45, 0x00,
	0x8B, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF, 0x50, 0xE8);
local charUpdateMask = "xxxx????xxxxx????xx";
local charUpdateOffset = 13;

local macroUpdatePattern = string.char(0xFF, 0x15, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF, 0xE8);
local macroUpdateMask = "xx????xx????x";
local macroUpdateOffset = 8;

local romMouseRClickFlag = 0x8000;
local romMouseLClickFlag = 0x80;

function getCharUpdatePattern()
	return charUpdatePattern;
end

function getCharUpdateMask()
	return charUpdateMask;
end

function getCharUpdateOffset()
	return charUpdateOffset;
end

function getMacroUpdatePattern()
	return macroUpdatePattern;
end

function getMacroUpdateMask()
	return macroUpdateMask;
end

function getMacroUpdateOffset()
	return macroUpdateOffset;
end

function checkExecutableCompatible()
	if( findPatternInProcess(getProc(), charUpdatePattern, charUpdateMask,
	addresses.staticpattern_char, 1) == 0 ) then
		return false;
	end

	if( findPatternInProcess(getProc(), macroUpdatePattern, macroUpdateMask,
	addresses.staticpattern_macro, 1) == 0 ) then
		return false;
	end

	return true;
end

if(settings.options.DEBUGGING == nil ) then settings.options.DEBUGGING = false; end;
function debugAssert(args)
	if( settings.options.DEBUGGING ) then
		if( not args ) then
			error("Error in memory reading", 2);
		else
			return args;
		end
	else
		return args;
	end
end

-- Ask witch character does the user want to be, from the open windows.
function selectGame(character)
	-- Get list of windows in an array
	local windowList = findWindowList("*", "Radiant Arcana");

	if( #windowList == 0 ) then
		print("You need to run rom first!");
		return 0;
	end

	charToUse = {};
	for i = 1, #windowList, 1 do
		local process, playerAddress, nameAddress;
	    -- open first window
		process = openProcess(findProcessByWindow(windowList[i]));
		local ver = getGameVersion(process)
		if ver ~= 0 then
			ver = " - " .. ver
		else
			ver = ""
		end
		-- read player address
		showWarnings(false);
		if addresses["staticbase_char"] and addresses["charPtr_offset"] and addresses["pawnName_offset"] then
			playerAddress = memoryReadUIntPtr(process, addresses["staticbase_char"], addresses["charPtr_offset"]);
			-- read player name
			if( playerAddress ) then
				nameAddress = memoryReadUInt(process, playerAddress + addresses["pawnName_offset"]);
			end
		end
		-- store the player name, with window number
		if nameAddress == nil then
		    charToUse[i] = "(RoM window "..i..")" .. ver;
  		else
			charToUse[i] = memoryReadString(process, nameAddress);
		end
		showWarnings(true);
		closeProcess(process);
	end

	if( character ) then
		for i,v in pairs(charToUse) do
			printf("[DEBUG] char: '%s', win: %s\n", tostring(v), tostring(windowList[i]));
			if( string.lower(v) == string.lower(character) ) then
				return windowList[i];
			end
		end
	end

	windowChoice = 1;
	-- wait until enter is released
    while keyPressedLocal(key.VK_RETURN) do
    	yrest(200);
    end

    notShown = true;
	if (#windowList > 1) then  -- if theres more than 1 window, ask the player witch character to use
		while not keyPressedLocal(key.VK_RETURN) do
	    	if keyPressedLocal(key.VK_UP) or keyPressedLocal(key.VK_DOWN) or notShown then
	        	notShown = false;
	    		if keyPressedLocal(key.VK_DOWN) then
	        		windowChoice = windowChoice + 1;
	        		if windowChoice > #charToUse then
	        	    	windowChoice = #charToUse;
					end
	    		end
	    		if keyPressedLocal(key.VK_UP) then
	        		windowChoice = windowChoice - 1;
	        		if windowChoice < 1 then
	        	    	windowChoice = 1;
					end
	    		end

				if keyPressedLocal(key.VK_UP) or keyPressedLocal(key.VK_DOWN) then
					print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
				end

				-- start message
	    		printf("Choose your character that you want to play on:\n");

	    		for i = 1, #charToUse, 1 do
	        		if i == windowChoice then
	    				cprintf(240, "\n"..charToUse[i]);
					else
	    				printf("\n"..charToUse[i]);
					end
				end
				printf("\n");
				yrest(200);
	    	end
	    	if keyPressedLocal(settings.hotkeys.STOP_BOT.key) then
	        	error("User quit");
			end
		end
		yrest(200)
	end

	return windowList[windowChoice];
end


function printPicture(pic, text, textColor)
	if not textColor then
	    textColor = 0;
	end

	local readfile = io.open(getExecutionPath() .. "/database/img/"..pic..".bmp", "r");
	if not readfile then
	    print(pic);
	    return 0;
	end

	file = readfile:read("*all");
	local height = string.byte(file, 23);
	local width = string.byte(file, 19);
	-- color data starts from 118 ends in -4
	--for i = 0, 200,1 do
	    --printf(i..":");
		--print(string.byte(file, i));
		--printf("\n");
	--end
	colorData = string.sub(file, 119, -4);
	dataLength = string.len(colorData);
	--colorData = string.reverse(colorData);
	color = {};
	for i = 1, dataLength, 1 do
		data = string.byte(colorData, i);
		first = math.floor(data/16);
		second = data - (first*16);

		position = (dataLength * 2) - (i * 2);
		color[position] = second;
		color[position + 1] = first;
	end
	i = 0;
	a = 1;
	newline = false;
	for y = 1, height, 1 do
		for x = 1, width, 1 do
		    nextchar = "€";
		    if not newline and not (a > string.len(text)) then
		    	nextchar = string.char(string.byte(text, a));
				a = a + 1;
			end

		    if nextchar == "\n" then
		        nextchar = "€";
		        newline = true;
			end

			pixel = i+width-x;
			col = color[pixel];

			-- repair colors from an unknown bug
			if col == 9 then
			    col = 12
      		elseif col == 12 then
      		    col = 9
      		elseif col == 1 then
      		    col = 4
      		elseif col == 4 then
      		    col = 1
      		elseif col == 3 then
      		    col = 6
      		elseif col == 6 then
      		    col = 3
      		elseif col == 7 then
      		    col = 8
      		elseif col == 8 then
      		    col = 7
      		elseif col == 11 then
      		    col = 14
      		elseif col == 14 then
      		    col = 11
			end

			if nextchar == "€" then
				cprintf(col*16+col, nextchar);
				--cprintf(col*16, col);
   			else
				cprintf(col*16+textColor, nextchar);
			end
			--printf(color[i]);
		end
		newline = false;
		i = i + 6 + width;
		printf("\n")
	end
end

-- get current directory (theres gotho be an easier way)
function currDir()
  os.execute("cd > cd.tmp")
  local f = io.open("cd.tmp", r)
  local cwd = f:read("*a")
  f:close()
  os.remove("cd.tmp")
  return cwd
end

function getWin(character)
	if( __WIN == nil ) then
  		__WIN = selectGame(character);
	end

	return __WIN;
end

function getProc()
	if( __PROC == nil or not windowValid(__WIN) ) then
		if( __PROC ) then closeProcess(__PROC) end;
		__PROC = openProcess( findProcessByWindow(getWin()) );
	end

	return __PROC;
end

function angleDifference(angle1, angle2)
  if( math.abs(angle2 - angle1) > math.pi ) then
    return (math.pi * 2) - math.abs(angle2 - angle1);
  else
    return math.abs(angle2 - angle1);
  end
end

function distance(x1, z1, y1, x2, z2, y2)
	if type(x1) == "table" and type(z1) == "table" then
        y2 = z1.Y or z1[3]
        z2 = z1.Z or z1[2]
        x2 = z1.X or z1[1]
        y1 = x1.Y or x1[3]
        z1 = x1.Z or x1[2]
        x1 = x1.X or x1[1]
    elseif z2 == nil and y2 == nil then -- assume x1,z1,x2,z2 values (2 dimensional)
		z2 = x2
		x2 = y1
		y1 = nil
	end

	if( x1 == nil or z1 == nil or x2 == nil or z2 == nil ) then
		error("Error: nil value passed to distance()", 2);
	end

	if y1 == nil or y2 == nil then -- 2 dimensional calculation
		return math.sqrt( (z2-z1)*(z2-z1) + (x2-x1)*(x2-x1) );
	else -- 3 dimensional calculation
		return math.sqrt( (z2-z1)*(z2-z1) + (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) );
	end
end

-- Used in pause/exit callbacks. Just releases movement keys.
function releaseKeys()
	if windowValid(__WIN) and __PROC then
		memoryWriteBytePtr(__PROC, addresses.staticbase_char ,addresses.moveKeysPressed_offset, 0 )
	end
end

function pauseCallback()
	local msg = sprintf(language[46], getKeyName(getStartKey()));	--  to continue, (CTRL+L) exit ...

	releaseKeys();
	printf(msg);
end
atPause(pauseCallback);

function exitCallback()
	releaseKeys();
end
atExit(exitCallback);

function errorCallback(script, line, message)
	local crashed, pid = isClientCrashed()
	if crashed then
		printf("Attached game client has crashed. Killing client (PID %d)\n", pid);
		warning(script .. ":" .. line .. ": " .. message);
		os.execute("TASKKILL /PID " .. pid .. " /F");
	else
		releaseKeys();

		printf("The game client did not crash.\n");
	end
end
atError(errorCallback);

function resumeCallback()
	printf("Resumed.\n");

	-- Make sure our player exists before trying to update it
	if( player and #settings.profile.skills ~= 0) then
		-- Make sure we aren't using potentially old data
		player:update();
	end

	if( settings.profile.options.PATH_TYPE == "wander" and __WPL ~= nil ) then
		__WPL.OrigX = player.X;
		__WPL.OrigZ = player.Z;
	end

	-- Re-set our bot start time to now
	if( player ) then
		player.BotStartTime = os.time();
		player.LastDistImprove = os.time();	-- reset unstick timer (dist improvement timer)

		if( settings.profile.options.LOGOUT_TIME > 0 ) then
			printf("Bot start time reset\n");
		end
	end

	-- check if using sleep function
	if( settings.profile.options.USE_SLEEP_AFTER_RESUME == true ) then
		cprintf(cli.yellow, language[148]);	-- LWe will go to sleep after fight finished
		player.Sleeping = true;		-- activate sleep
	end

end
atResume(resumeCallback);


function pauseOnDeath()
	local sk = startKey;
	if( getVersion() >= 100 ) then sk = getStartKey(); end;
	cprintf(cli.red, language[149]);	-- You have died
	printf(language[160],	-- Script paused until you revive yourself
		getKeyName(sk))
	logMessage("Player died.\n");
	stopPE();
end

local LAST_PLAYER_X = 0;
local LAST_PLAYER_Z = 0;
function timedSetWindowName(profile)
	-- Update our exp gain
	if isInGame() and ( os.difftime(os.time(), player.LastExpUpdateTime) > player.ExpUpdateInterval ) then
		player.Class1 = memoryReadRepeat("int", getProc(), player.Address + addresses.pawnClass1_offset) or player.Class1;
		player.Level = memoryReadRepeat("int", getProc(), addresses.charClassInfoBase + (addresses.charClassInfoSize* player.Class1 ) + addresses.charClassInfoLevel_offset) or player.Level
		player.XP = memoryReadRepeat("int", getProc(), addresses.charClassInfoBase + (addresses.charClassInfoSize* player.Class1 ) + addresses.charClassInfoXP_offset) or player.XP
		if player.XP == 0 or player.Level == 0 then return end

		local newExp = player.XP or 0;
		local maxExp = memoryReadRepeat("intptr", getProc(), addresses.charMaxExpTable_address, (player.Level-1) * 4) or 1;

		player.LastExpUpdateTime = os.time();					-- Reset timer

		if( type(newExp) ~= "number" ) then newExp = 0; end;
		if( type(maxExp) ~= "number" ) then maxExp = 1; end;

		-- If we have not begun tracking exp, start by gathering
		-- our current value, but do not count it as a gain
		if( player.ExpInsertPos == 0 ) then
			player.ExpInsertPos = 1;
			player.LastExp = newExp;
		else
			local gain = 0;
			local expGainSum = 0;
			local valueCount = 0;

			if( newExp > player.LastExp ) then
				gain = newExp - player.LastExp;
			elseif( newExp < player.LastExp ) then
				-- We probably just leveled up. Just get our current, new value and use that.
				gain = newExp;
			end

			player.LastExp = newExp;
			player.ExpTable[player.ExpInsertPos] = gain;
			player.ExpInsertPos = player.ExpInsertPos + 1;
			if( player.ExpInsertPos > player.ExpTableMaxSize ) then
				player.ExpInsertPos = 1;
			end;

			for i,v in pairs(player.ExpTable) do
				valueCount = valueCount + 1;
				expGainSum = expGainSum + v;
			end

			player.ExpPerMin = expGainSum / ( valueCount * player.ExpUpdateInterval / 60 );
			player.TimeTillLevel = (maxExp - newExp) / player.ExpPerMin;
			if( player.TimeTillLevel > 9999 ) then
				player.TimeTillLevel = 9999;
			elseif( player.TimeTillLevel < 0 ) then
				player.TimeTillLevel = 0
			end
		end
	end
	local displayname = player.Name
	if #displayname > 8 then
		displayname = string.sub(displayname, 1, 7) .. "*";
	end
	if( (player.X ~= LAST_PLAYER_X) or (player.Z ~= LAST_PLAYER_Z) ) then
		setWindowName(getHwnd(), sprintf(language[600],
		BOT_VERSION, displayname, player.X, player.Z, player.ExpPerMin, player.TimeTillLevel));

		LAST_PLAYER_X = player.X;
		LAST_PLAYER_Z = player.Z;
	end
end

-- returns full path if it exists, searching relative, local and global folders
-- To be found, _file path should be relative to 'rom' or 'romglobal' or the current waypoint file.
function findFile(_file)
	-- Check relative to current wp files location.
	if __WPL and __WPL.FileName then
		-- we strip "waypoints/" since we search relative to current waypoint location.
		local tmpFile = string.gsub(_file,"^/?waypoints/","")

		local currentWPLPath = string.match(__WPL.FileName,"(.+/)") or ""

		-- Simple nested folder
		if fileExists(getExecutionPath() .. "/waypoints/" .. currentWPLPath .. tmpFile) then
			return getExecutionPath() .. "/waypoints/" .. currentWPLPath .. tmpFile
		end

		-- Strip duplicate dirs
		local tmpPath = string.match(tmpFile, "^(.*%/).*%....")
		if tmpPath then
			repeat
				if string.match(currentWPLPath, tmpPath .. "$") then
					-- Match found, strip dirs
					currentWPLPath = string.match(currentWPLPath, "(.*)"..tmpPath.."$")
					if fileExists(getExecutionPath() .. "/waypoints/" .. currentWPLPath .. tmpFile) then
						return getExecutionPath() .. "/waypoints/" .. currentWPLPath .. tmpFile
					end
				end
				-- Take off a dir and try again
				tmpPath = string.match(tmpPath, "^(.-)[^%/]*%/$")
			until tmpPath == ""
		end
	end

	-- Then check local folder
	if fileExists(getExecutionPath() .. "/" .. _file) then
		return getExecutionPath() .. "/" .. _file
	end

	-- Then check global folder
	if fileExists(getExecutionPath() .. "/../romglobal/" .. _file) then
		return getExecutionPath() .. "/../romglobal/" .. _file
	end

	-- if neither exist return local as default
	return getExecutionPath() .. "/" .. _file
end

function load_paths( _wp_path, _rp_path)

	cprintf(cli.yellow, "Please use the renamed function \'loadPaths()\' instead of \'load_paths\'!\n");
	loadPaths( _wp_path, _rp_path);

end

function loadPaths( _wp_path, _rp_path)
-- load given waypoint path and return path file
-- if you don't specify a return path the function will look for
-- a default return path based on the waypoint path name and
-- the settings.profile.options.RETURNPATH_SUFFIX


	-- check if function is not called empty
	if( not _wp_path ) and ( not _rp_path ) then
		cprintf(cli.yellow, language[161]);	 -- have to specify either
		return;
	end;
	if( _wp_path == "" or _wp_path == " " ) then _wp_path = nil; end;

	-- check suffix and remember default return path name
	local rp_default;
	if(_wp_path ~= nil) then
		local foundpos = string.find(_wp_path,".xml",1,true);	-- filetype defined?
		if( foundpos ) then					-- filetype defined
			rp_default = string.sub(_wp_path,1,foundpos-1) .. settings.profile.options.RETURNPATH_SUFFIX .. ".xml";
		else							-- no filetype
			rp_default = _wp_path .. settings.profile.options.RETURNPATH_SUFFIX .. ".xml";
		end;
	end;

	if( _wp_path and not string.find(_wp_path,".xml", 1, true) and _wp_path ~= "wander" ) then
		_wp_path = _wp_path .. ".xml";
	end;
	if( _rp_path  and   not string.find(_rp_path,".xml", 1, true) ) then
		_rp_path = _rp_path .. ".xml";
	end;

	-- waypoint path is defined

	-- check if _wp_path exists
	local wpfilename
	if( _wp_path and
		string.lower(_wp_path) ~= "wander" ) then
		local filename = findFile("waypoints/" .. _wp_path )
		if not fileExists(filename) then
			local msg = sprintf(language[142], filename ); -- We can't find your waypoint file
			error(msg, 2);
		end
		__WPL = CWaypointList();
		wpfilename = filename
		cprintf(cli.yellow, language[0], _wp_path);	-- Loaded waypoint path
	end

	-- set wander for WP
	if( string.lower(_wp_path) == "wander" ) then
		__WPL = CWaypointListWander();
		__WPL:setRadius(settings.profile.options.WANDER_RADIUS);
		__WPL:setMode("wander");
		cprintf(cli.green, language[168], settings.profile.options.WANDER_RADIUS);	-- Loaded waypoint path
	end

	-- look for default return path with suffix '_return'
	if( not _rp_path ) then
		local filename = findFile("waypoints/" .. rp_default)
		if fileExists(filename) then
			cprintf(cli.green, language[162], rp_default );	-- Return path found with default naming
			_rp_path = rp_default;	-- set default
		else
			cprintf(cli.lightgray, language[163], rp_default );	-- No return path with default naming
		end;
	end

	-- check if _rp_path exists
	local rpfilename
	if( _rp_path ) then
		if( not __RPL ) then  		-- define object if not there
			__RPL = CWaypointList();
		end;
		local filename = findFile("waypoints/" .. _rp_path)
		if not fileExists(filename) then
			local msg = sprintf(language[143], _rp_path ); -- We can't find your returnpath file
			error(msg, 0);
		end;
		rpfilename = filename
		cprintf(cli.green, language[1], _rp_path);	-- Loaded return path
	end

	-- check if on returnpath
	if( player.Returning == true  and
	    _rp_path ) then
		cprintf(cli.green, language[164], _rp_path);	-- We are coming from a return_path.
	else
		player.Returning = false;
		cprintf(cli.green, language[165], _wp_path );-- We use the normal waypoint path %s now
	end

	-- waypoint path is defined ... load it
	if wpfilename then
		__WPL:load(wpfilename);

		if(__WPL.CurrentWaypoint ~= 1 ) then --and #__WPL.Waypoints > 0
			cprintf(cli.green, language[15], 					-- Waypoint #%d is closer then #1
			   __WPL.CurrentWaypoint, __WPL.CurrentWaypoint);
		end;
	end

	-- return path defined or default found ... load it
	if rpfilename then
		__RPL:load(rpfilename);
	else
		if( __RPL ) then  		-- clear old returnpath object
			__RPL = nil;
		end;
	end;
end

-- executing RoMScript and send a MM window message before
function sendMacro(_script)
	cprintf(cli.green, language[169], 		-- Executing RoMScript ...
	   "MACRO",
	   string.sub(_script, 1, 40) );

	return RoMScript(_script);

end

-- Execute a slash command
function SlashCommand(script)
	if commandMacro == 0 then
		-- setupMacros() hasn't run yet
		return
	end

	-- add slash if needed
	if string.match(script,"^.") ~= "/" then
		script = "/" .. script
	end

	-- write to macro
	writeToMacro(commandMacro, script)

	--- Execute it
	if( settings.profile.hotkeys.MACRO ) then
		keyboardPress(settings.profile.hotkeys.MACRO.key);
	end
end

--- Run rom scripts, usage: RoMScript("BrithRevive();");
function RoMScript(script)
	-- Check if in game
	if not isInGame() then
		-- Cannot execute RoMScript. Not in game.
		return
	end

	if commandMacro == 0 then
		-- setupMacros() hasn't run yet
		return
	else -- check if still valid
		local __, cName = readMacro(commandMacro)
		local __, rName = readMacro(resultMacro)
		if cName ~= COMMAND_MACRO_NAME or rName ~= RESULT_MACRO_NAME then -- macros moved
			setupMacros()
		end
	end

	--- Get the real offset of the address
	local macro_address = memoryReadUInt(getProc(), addresses.staticbase_macro);

--	local scriptDef;

--	if( settings.options.LANGUAGE == "spanish" ) then
--		scriptDef = "/redactar";
--	else
--		scriptDef = "/script";
--	end

	--- Macro length is max 255, and after we add the return code,
	--- we are left with about 155 character limit.

	local dataPart = 0 -- The part of the data to get
	local raw = ""     -- Combined raw data from 'R'
	repeat
		local text

		-- The command macro
		if dataPart == 0 then
			-- The initial command macro
--			text = scriptDef.." R='' a={" .. script ..
--			"} for i=1,#a do R=R..tostring(a[i])" ..
--			"..'" .. string.char(9) .. "' end" ..
--			" EditMacro("..resultMacro..",'"..RESULT_MACRO_NAME.."',7,R)";
			text = script
		else
			-- command macro to get the rest of the data from 'R'
--			text = scriptDef.." EditMacro("..resultMacro..",'"..
--			RESULT_MACRO_NAME.."',7,string.sub(R,".. (1 + dataPart * 255) .."))";
			text = "SendMore"
		end

		-- Check to make sure length is within bounds
		local len = string.len(text);
		if( len > 254 ) then
			error("Macro text too long by "..(len - 254), 2);
		end

		repeat
			-- Write the command macro
			writeToMacro(commandMacro, text)

			-- Write something on the first address, to see when its over written
			memoryWriteByte(getProc(), macro_address + addresses.macroSize *(resultMacro - 1) + addresses.macroBody_offset , 6);

			-- Execute it
			if( settings.profile.hotkeys.MACRO ) then
--				keyboardPress(settings.profile.hotkeys.MACRO.key);
				keyboardHold(settings.profile.hotkeys.MACRO.key);
				rest(100)
				keyboardRelease(settings.profile.hotkeys.MACRO.key);
			end

			local tryagain = false

			-- A cheap version of a Mutex... wait till it is "released"
			-- Use high-res timers to find out when to time-out
			local startWaitTime = getTime();
			while( memoryReadByte(getProc(), macro_address + addresses.macroSize *(resultMacro - 1) + addresses.macroBody_offset) == 6 ) do
				if( deltaTime(getTime(), startWaitTime) > 800 ) then
					if settings.options.DEBUGGING then
						printf("0x%X\n", addresses.editBoxHasFocus_address)
					end
					if memoryReadUInt(getProc(), addresses.editBoxHasFocus_address) == 0 then
						keyboardPress(settings.hotkeys.ESCAPE.key); yrest(500)
						if RoMScript("GameMenuFrame:IsVisible()") then
							-- Clear the game menu and reset editbox focus
							keyboardPress(settings.hotkeys.ESCAPE.key); yrest(300)
							RoMCode("z = GetKeyboardFocus(); if z then z:ClearFocus() end")
						end
					end


					tryagain = true
					break
				end;
				rest(1);
			end
		until tryagain == false

		--- Read the outcome from the result macro
		local rawPart = readMacro(resultMacro)

		raw = raw .. rawPart

		dataPart = dataPart + 1
	until string.len(rawPart) < 255

	readsz = "";
	ret = {};
	cnt = 0;
	for i = 1, string.len(raw), 1 do
		local byte = string.byte(raw, i);

		if( byte == 0 or byte == null) then -- Break on NULL terminator
			break;
		elseif( byte == 9 ) then -- Use TAB to seperate
			-- Implicit casting
			if( string.find(readsz, "^[%-%+]?%d+%.?%d+$") ) then readsz = tonumber(readsz);  end;
			if( string.find(readsz, "^[%-%+]?%d+$") ) then readsz = tonumber(readsz);  end;
			if( readsz == "true" ) then readsz = true; end;
			if( readsz == "false" ) then readsz = false; end;

			table.insert(ret, readsz);
			cnt = cnt+1;
			readsz = "";
		else
			readsz = readsz .. string.char(byte);
		end
	end

	local err = ret[1]
	if err == false then
		error("IGF:".."\\"..script.."\\ "..ret[2],0)
	elseif err == true then
		table.remove(ret,1)
	end

	return unpack(ret);
end

-- Executes code as apposed to returning a value. Can still return a value if assigned to variable 'a' in a table.
function RoMCode(code)
	if #code <  254-41 then
		return RoMScript("} "..code.." if type(a)~=\"table\" then a={a} end z={")
	else
		return RoMScript("} "..code.." z={")
	end
end

-- send message to the game
function addMessage(message)
	message = string.gsub(message, "\n", "\\n")
	message = string.gsub(message, "\"", "\\\"")

	-- language conversations
	if( bot.ClientLanguage == "RU" ) then
		message = oem2utf8_russian(message);
	else
		message = asciiToUtf8_umlauts(message);	-- for ingame umlauts
	end

	RoMScript("ChatFrame1:AddMessage(\""..message.."\")");
end


-- UTF8 -> DOS(OEM) Code page 866 conversation for the russian client
-- we use it for the player names & mob names conversion in pawn.lua
-- http://en.wikipedia.org/wiki/Code_page_866
function utf82oem_russian(txt)
  txt = string.gsub(txt, string.char(0xD0, 0x81), string.char(0xF0) );	-- 0xF0 / E with dots
  txt = string.gsub(txt, string.char(0xD1, 0x91), string.char(0xF1) );	-- 0xF1 / e with dots
  -- lower case
  local patt = string.char(0xD1) .. "([" .. string.char(0x80, 0x2D, 0x8F) .. "])";
  txt = string.gsub(txt, patt, function (s)
            return string.char(string.byte(s,1,1)+0x60);
          end
  );
  -- upper case
  patt = string.char(0xD0) .. "([" .. string.char(0x90, 0x2D, 0xBF) .. "])";
  txt = string.gsub(txt, patt, function (s)
            return string.char(string.byte(s,1,1)-0x10);
          end
  );
  return txt;
end


-- DOS(OEM) -> UTF8 conversation for the russian client
-- we use it within addMessage in functions.lua
function oem2utf8_russian(txt)
  local function translate(code)
         -- upper case and lower case part 1
          if(code>=0x80)and(code<=0xAF)then
              return string.char(0xD0, code+0x10);
          end
         -- lower case part 2
          if(code>=0xE0)and(code<=0xEF)then
              return string.char(0xD1, code-0x60);
          end
          if(code==0xF0)then
              return string.char(0xD0, 0x81); -- E with dots
          end
          if(code==0xF1)then
              return string.char(0xD1, 0x91); -- e with dots
          end
         return string.char(code);
  end

  local result = '';
  for i=1,string.len(txt) do
      result = result .. translate( string.byte(txt,i) );
  end
  return result;
end


-- convert the ingame UTF8 strings to ASCII
-- we use the complete utf8 table, that means for all languages we have
function convert_utf8_ascii( _str )

	-- local function to convert string (e.g. mob name / player name) from UTF-8 to ASCII
	local function convert_utf8_ascii_character( _str, _v )
		local found;
		_str, found = string.gsub(_str, string.char(_v.utf8_1, _v.utf8_2), string.char(_v.ascii) );
		return _str, found;
	end

	local found, found_all;
	found_all = 0;
	for i,v in pairs(database.utf8_ascii) do
--			_str, found = convert_utf8_ascii_character( _str, v.ascii  );	-- replace special characters
		_str, found = convert_utf8_ascii_character( _str, v  );	-- replace special characters
		found_all = found_all + found;									-- count replacements
	end

	if( found_all > 0) then
		return _str, true;
	else
		return _str, false;
	end
end


-- we only replace umlaute, hence only that are important for mob names
-- player names are at the moment not importent for the MM protocol
-- player names will be handled while loading the profile
function utf8ToAscii_umlauts(_str)

	-- convert one UTF8 character to his ASCII code
	-- key is the combined UTF8 code
	local function replaceUtf8( _str, _key )
		local tmp = database.utf8_ascii[_key];
		_str = string.gsub(_str, string.char(tmp.utf8_1, tmp.utf8_2), string.char(tmp.ascii) );
		return _str
	end

	_str = replaceUtf8(_str, 195164);		-- δ
	_str = replaceUtf8(_str, 195132);		-- Δ
	_str = replaceUtf8(_str, 195182);		-- φ
	_str = replaceUtf8(_str, 195150);		-- Φ
	_str = replaceUtf8(_str, 195188);		-- ό
	_str = replaceUtf8(_str, 195156);		-- ά
	_str = replaceUtf8(_str, 195159);		-- ί
	return _str;
end


-- we only replace umlaute, hence only that are important for
-- printing ingame messages
function asciiToUtf8_umlauts(_str)

	-- convert one ASCII code to his UTF8 character
	-- key is the combined UTF8 code
	local function replaceAscii( _str, _key )
		local tmp = database.utf8_ascii[_key];
		_str = string.gsub(_str, string.char(tmp.ascii), string.char(tmp.utf8_1, tmp.utf8_2) );
		return _str
	end

	_str = replaceAscii(_str, 195164);		-- δ
	_str = replaceAscii(_str, 195132);		-- Δ
	_str = replaceAscii(_str, 195182);		-- φ
	_str = replaceAscii(_str, 195150);		-- Φ
	_str = replaceAscii(_str, 195188);		-- ό
	_str = replaceAscii(_str, 195156);		-- ά
	_str = replaceAscii(_str, 195159);		-- ί
	return _str;
end


-- open giftbag (at the moment level 1-10)
function openGiftbags1To10(_player_level)
	player:updateMounted()
	local wasMounted = player.Mounted

	if( not _player_level) then _player_level = player.Level; end
	cprintf(cli.lightblue, language[170], _player_level );	-- Open and equipt giftbag for level

	-- open giftbag and equipt content
--	yrest(2000);	-- time for cooldowns to phase-out
	for i,v in pairs(database.giftbags)  do
		if( v.level == _player_level) then
			if v.type == "is" then
				local isitem = inventory:findItem( v.itemid, "bags" );	-- Find item shop item
				if isitem then
					isitem:moveTo("itemshop")
					cprintf(cli.lightblue, language[159], isitem.Name );	-- Moving to Item Shop bag:
				else
					cprintf(cli.yellow, language[174], GetIdName(v.itemid) );	-- item not found
				end
			elseif( v.armor == armorMap[player.Class1]  or		-- only if items have the right armor
			    v.armor == nil ) then						-- or is armor independent
				local hf_item = inventory:findItem( v.itemid );	-- Find item shop item

				if ( hf_item ) then
					cprintf(cli.lightblue, language[171], hf_item.Name );	-- Open/eqipt item:
					hf_item:use()
					yrest(2000);					-- wait for using that item

					if( v.type == "bag" ) then		-- after opening bag update inventory
						yrest(4000);				-- some more time to open the bag
						inventory:update();			-- update slots
					end;
				else
					cprintf(cli.yellow, language[174], GetIdName(v.itemid) );		-- item not found
				end

			end;
		end;

	end

	player:updateMounted()
	if wasMounted and not player.Mounted then
		player:mount()
	end
end


function levelupSkill(_skillname, _times)
-- _skillname = name of the skill in skills.xml
-- _times = how many levels do you want to levelup that skill

	if(player.Level == 1 ) then
		return false;
	end

	if(_times == nil or
	   _times == 0 ) then
		_times = 1;
	end

	local skill_from_db = database.skills[_skillname];	-- read skill parameters from database
	if skill_from_db == nil then
		skill_from_db = FindSkillBookSkill(_skillname) -- if real name or id is used
	end

	-- Check if skill found
	if not skill_from_db then
		cprintf(cli.yellow, "Invalid skill name %s.\n",
		   (_skillname or "nil") );
		return false;
	end

	-- check is skill has an aslevel in skills.xml
	if ( skill_from_db.aslevel ~= nil and
		 skill_from_db.aslevel > player.Level ) then
		cprintf(cli.yellow, "You need at least level %d to levelup skill %s. Your level is %d.\n",
		   skill_from_db.aslevel, _skillname, player.Level );
		return false;
	end

	-- check if skill parameters for automatic leveling are in skills.xml for that skill
	if ( skill_from_db.skilltab == nil or
		 skill_from_db.skillnum == nil ) then
		cprintf(cli.yellow, "Missing skill parameters in skills.xml to levelup skill %s\n", _skillname );
		return false;
	end

	local hf_return = false;
	for i = 1, _times do
		yrest(600);
		local name, _, icon, _, rank, type, upgradeCost, isSkillable, isAvailable = RoMScript("GetSkillDetail("..skill_from_db.skilltab..","..skill_from_db.skillnum..")")
		player:update()
		if upgradeCost ~= nil and player.TP >= upgradeCost then
			sendMacro("SetSpellPoint("..skill_from_db.skilltab..","..skill_from_db.skillnum..");");
			hf_return = true;
		else
			break
		end
	end

	if hf_return == true then
		settings.updateSkillsAvailability()
	end

	return hf_return;

end


function levelupSkills1To10(_loadonly)
-- level up the skill by using an internal leveling table
-- load the skills for using into the profile skill table

	-- e.g. 4 = third skill tab, 2 = second skill on the tab
	-- CAUTION: addressing a invalid skill will crash the RoM client
	local skillLevelupMap = {
		[CLASS_WARRIOR]		= {  [1] = { aslevel = 1, skillname="WARRIOR_SLASH" },
								 [2] = { aslevel = 2, skillname="WARRIOR_OPEN_FLANK" },
								 [3] = { aslevel = 2, skillname="WARRIOR_PROBING_ATTACK" },
								 [4] = { aslevel = 4, skillname="WARRIOR_ENRAGED" },
								 [5] = { aslevel = 6, skillname="WARRIOR_THUNDER" } },
		[CLASS_SCOUT]		= {  [1] = { aslevel = 1, skillname="SCOUT_SHOT" },
								 [2] = { aslevel = 2, skillname="SCOUT_WIND_ARROWS" },
								 [3] = { aslevel = 4, skillname="SCOUT_VAMPIRE_ARROWS" },
								 [4] = { aslevel = 6, skillname="490445" } }, -- passive Ranged Weapon Mastery
		[CLASS_ROGUE]		= {  [1] = { aslevel = 1, skillname="ROGUE_SHADOWSTAB" },
								 [2] = { aslevel = 2, skillname="ROGUE_LOW_BLOW" },
								 [3] = { aslevel = 6, skillname="ROGUE_WOUND_ATTACK" },
								 [4] = { aslevel = 8, skillname="ROGUE_BLIND_STAB" } },
		[CLASS_MAGE]		= {  [1] = { aslevel = 1, skillname="MAGE_FLAME" } },
		[CLASS_PRIEST]		= {  [1] = { aslevel = 1, skillname="PRIEST_RISING_TIDE" },
								 [2] = { aslevel = 1, skillname="PRIEST_URGENT_HEAL" },
--								 [3] = { aslevel = 2, skillname="PRIEST_WAVE_ARMOR" },	-- needs to much mana
								 [3] = { aslevel = 4, skillname="PRIEST_REGENERATE" } ,
								 [4] = { aslevel = 8, skillname="PRIEST_HOLY_AURA" } },
		[CLASS_KNIGHT]		= {  [1] = { aslevel = 1, skillname="KNIGHT_PUNISHMENT" },
								 [2] = { aslevel = 1, skillname="KNIGHT_HOLY_STRIKE" } },
		[CLASS_WARDEN]		= {  [1] = { aslevel = 1, skillname="WARDEN_CHARGED_CHOP" },
								 [2] = { aslevel = 1, skillname="WARDEN_ENERGY_ABSORB" },
								 [3] = { aslevel = 2, skillname="WARDEN_THORNY_VINES" },
								 [4] = { aslevel = 4, skillname="WARDEN_BRIAR_SHIELD" },
								 [5] = { aslevel = 8, skillname="WARDEN_POWER_OF_THE_WOOD_SPIRIT" } },
		[CLASS_DRUID]		= {  [1] = { aslevel = 1, skillname="DRUID_RECOVER" },
								 [2] = { aslevel = 1, skillname="DRUID_EARTH_ARROW" },
								 [3] = { aslevel = 2, skillname="DRUID_BRIAR_ENTWINEMENT" },
								 [4] = { aslevel = 6, skillname="DRUID_RESTORE_LIFE" } },
		[CLASS_WARLOCK]		= {  [1] = { aslevel = 1, skillname="WARLOCK_PSYCHIC_ARROWS" },
								 [2] = { aslevel = 4, skillname="WARLOCK_WARP_CHARGE" },
								 [3] = { aslevel = 6, skillname="WARLOCK_PERCEPTION_EXTRACTION" },
								 [4] = { aslevel = 8, skillname="497961" } }, -- passive Pure Soul
		[CLASS_CHAMPION]	= {  [1] = { aslevel = 1, skillname="CHAMPION_ELECTROCUTION" },
								 [2] = { aslevel = 1, skillname="CHAMPION_HEAVY_BASH" },
								 [3] = { aslevel = 6, skillname="CHAMPION_ENERGY_INFLUX_STRIKE" },
								 [4] = { aslevel = 8, skillname="498525" } }, -- passive Finishing Hammer
		};


	local leveluptable = skillLevelupMap[player.Class1];
	for i,v in pairs(leveluptable)  do

		if (_loadonly ~= "loadonly") then
			-- levelup the skill ingame
			-- TODO: maxlevel skills vs. new skill with only one level
			if( player.Level == v.aslevel ) then		-- maxlevel the new skill
					levelupSkill(v.skillname, v.aslevel);
			elseif( player.Level == 2 and
					v.aslevel == 1) then			-- 2x aft level 2
					levelupSkill(v.skillname, 2);
			elseif( player.Level > v.aslevel ) then  	-- levelup 1 level
					levelupSkill(v.skillname);
			end
		end;

		-- add skill to profile skilltable
--		if( player.Level == v.aslevel ) then
		-- we will also reload skills into skilltable if we restart the bot
		-- TODO: but only at the levelup event
		if( player.Level >= v.aslevel ) then

			local hf_found;
			for i,profile_skills in pairs(settings.profile.skills)  do
				if( profile_skills.Name == v.skillname ) then
					hf_found = true;		-- skill allready in the table
				end
			end
			if( not hf_found ) then			-- skill not there, insert it
				local tmp = database.skills[v.skillname];
				if tmp then
					tmp.hotkey = "MACRO";		-- use ROM API to use that skills
					tmp.Level = 1;
					table.insert(settings.profile.skills, tmp);
					cprintf(cli.lightblue, "We learned skill \'%s\' and will use it\n", v.skillname );	-- Open/eqipt item:
				end
			end
		end

		-- sort the skill table
		local skillSort = function(tab1, tab2)
			if( tab2.priority < tab1.priority ) then
				return true;
			end;
			return false;
		end
		table.sort(settings.profile.skills, skillSort);

	end
end

-- change profile options and print values in MM protocol
function changeProfileOption(_option, _value)

	if( settings.profile.options[_option] == nil ) then
		cprintf(cli.green, language[173], _option );	-- Unknown profile option
		return;
	end

	local hf_old_value = settings.profile.options[_option];
	settings.profile.options[_option] = _value;

	cprintf(cli.lightblue, language[172], _option, hf_old_value, _value );	-- We change the option

end

-- change profile skill value and print values in MM protocol
function changeProfileSkill(_skill, _option, _value)

	local skill = nil
	for k,v in pairs(settings.profile.skills) do
		if v.Name == _skill then
			skill = v
			break
		end
	end

	if skill == nil then
		cprintf(cli.green, language[184], _skill );	-- Unknown profile skill
		return;
	end

	local hf_old_value = skill[_option]
	if hf_old_value == nil then hf_old_value = "nil" end
	skill[_option] = _value;

	cprintf(cli.lightblue, language[185], _option, _skill, hf_old_value, _value );	-- We change the option

	-- Resort skills if priority is changed
	if _option == "priority" then
		table.sort(settings.profile.skills, function(a,b) return a.priority > b.priority end)
	end
end

function convertProfileName(_profilename)
	--local usingPlayerName = false
	--if _profilename == player.Name then
	--	usingPlayerName = true
	--end

	local function check_for_userdefault_profile()
		if _profilename == player.Name then
			return ( fileExists(getExecutionPath() .. "/profiles/userdefault.xml") )
		else
			return false
		end
	end

	-- local functions to replace special ASCII characters (e.g. in player name)
	local function replace_special_ascii_character( _str, _v )
		local found;
--		local tmp = database.utf8_ascii[_ascii];
		_str, found = string.gsub(_str, string.char(_v.ascii), _v.dos_replace );
		return _str, found;
	end

	local function replace_special_ascii( _str )
		local found, found_all;
		found_all = 0;
		for i,v in pairs(database.utf8_ascii) do
			_str, found = replace_special_ascii_character( _str, v );	-- replace special characters
			found_all = found_all + found;			-- count replacements
		end

		if( found_all > 0) then
			return _str, true;
		else
			return _str, false;
		end
	end

	local load_profile_name, new_profile_name;	-- name of profile to load

	-- convert player/profile name from UTF-8 to ASCII
	load_profile_name = convert_utf8_ascii(_profilename);

	-- replace special ASCII characters like φόδϊ / hence open.XML() can't handle them
	new_profile_name , hf_convert = replace_special_ascii(load_profile_name);	-- replace characters

	if( hf_convert ) then		-- we replace some special characters

		-- check if profile with replaced characters allready there
		if( fileExists(getExecutionPath() .. "/profiles/" .. new_profile_name..".xml") ) then
			load_profile_name = new_profile_name;
		else
			-- check if userdefault profile exists
			if check_for_userdefault_profile() then
				load_profile_name = "userdefault"
			else
				local msg = sprintf(language[101], -- we can't use the character/profile name \'%s\' as a profile name
						load_profile_name, new_profile_name);
				error(msg, 0);
			end
		end;
	else
		-- check if profile exist
		if( not fileExists(getExecutionPath() .. "/profiles/" .. load_profile_name..".xml" ) ) then
			-- check if userdefault profile exists
			if check_for_userdefault_profile() then
				load_profile_name = "userdefault"
			else
				local msg = sprintf(language[102], load_profile_name ); -- We can't find your profile
				error(msg, 0);
			end
		end
	end;

	return load_profile_name;
end


local lastDisplayBlocks = nil;
function displayProgressBar(percent, size)
	size = size or 10;
	local blocksFilled = math.floor(size*percent/100);
	local blocksUnfilled = size - blocksFilled;

	if( blocksFilled ~= lastDisplayBlocks ) then
		printf("\r%03d%% [", percent);
		cprintf(cli.turquoise, string.rep("*", blocksFilled));
		printf(string.rep("-", blocksUnfilled) .. "]");

		lastDisplayBlocks = blocksFilled;
		if blocksFilled == size then printf("\n") end
	end
end

function trim(_s)
	return (string.gsub(_s, "^%s*(.-)%s*$", "%1"))
end

function debugMsg(_debug, _reason, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6 )

	-- return if debugging / detail  is disabled
	if( _debug ~= true ) then return; end

	local function make_printable(_v)
		if(_v == true) then
			_v = "<true>";
		elseif(_v == false) then
			_v = "<false>";
		elseif( type(_v) == "table" ) then
			_v = "<table>";
		elseif( type(_v) == "string" ) then
			_v = convert_utf8_ascii(_v)
		end
--		if( type(_v) == "number" ) then
--			_v = sprintf("%d", _v);
--		end
		return _v
	end

	local hf_arg1, hf_arg2, hf_arg3, hf_arg4, hf_arg5, hf_arg6 = "", "", "", "", "", "";
	if(_arg1) then hf_arg1 = make_printable(_arg1); end;
	if(_arg2) then hf_arg2 = make_printable(_arg2); end;
	if(_arg3) then hf_arg3 = make_printable(_arg3); end;
	if(_arg4) then hf_arg4 = make_printable(_arg4); end;
	if(_arg5) then hf_arg5 = make_printable(_arg5); end;
	if(_arg6) then hf_arg6 = make_printable(_arg6); end;


	local msg = sprintf("[DEBUG] %s %s %s %s %s %s %s\n", _reason, hf_arg1, hf_arg2, hf_arg3, hf_arg4, hf_arg5, hf_arg6 ) ;
	msg = string.gsub(msg, "%%", "%%%%");
	cprintf(cli.yellow, msg);

end

function getQuestStatus(_questnameorid)
	-- Used when you need to make 3 way decision, get quest, complete quest or gather quest items.
	if (bot.IgfAddon == false) then
		error(language[1004], 0)	-- Ingamefunctions addon (igf) is not installed
	end

	if type(tonumber(_questnameorid)) == "number" then
		return RoMScript("igf_questStatus(".._questnameorid..")")
	elseif type(_questnameorid) == "string" then
		return RoMScript("igf_questStatus(\""..NormaliseString(_questnameorid).."\")")
	end

	error("Invalid argument used with getQuestStatus(): Expected type 'number' or 'string'")
end

-- Read the ping variable from the client
function getPing()
	return memoryReadIntPtr(getProc(), addresses.staticbase_char, addresses.ping_offset);
end

-- Returns the proper SKILL_USE_PRIOR value (whether manual or auto, and adjusted)
function getSkillUsePrior()
	local prior = 0;
	if( settings.profile.options.SKILL_USE_PRIOR == "auto" ) then
		-- assume ping - 20
		--prior = math.max(getPing() - 20, 25);
		prior = getPing()
	else
		prior = settings.profile.options.SKILL_USE_PRIOR;
	end

	return prior;
end


-- Returns the point that is nearest to (X,Z) between segment (A,B) and (C,D)
function getNearestSegmentPoint(x, z, a, b, c, d)

	if a == c and b == d then
		return CWaypoint(a, b)
	end

	local dx1 = x - a;
	local dz1 = z - b;
	local dx2 = c - a;
	local dz2 = d - b;

	local dot = dx1 * dx2 + dz1 * dz2;
	local len_sq = dx2 * dx2 + dz2 * dz2;
	local param = dot / len_sq;

	local nx, nz;

	if( param < 0 ) then
		nx = a;
		nz = b;
	elseif( param > 1 ) then
		nx = c;
		nz = d;
	else
		nx = a + param * dx2;
		nz = b + param * dz2;
	end

	return CWaypoint(nx, nz);
end

function waitForLoadingScreen(_maxWaitTime)
	local oldAddress = player.Address

	local startTime = os.time()
	-- wait for player address to change
	repeat
		if (_maxWaitTime ~= nil and os.difftime(os.time(),startTime) > _maxWaitTime ) then
			-- Loading screen didn't appear, we return false so waypoint file can try and take alternate action to recover
			cprintf(cli.yellow,"The loading screen didn't appear...\n")
			return false
		end
		rest(1000)
		local newAddress = memoryReadRepeat("uintptr", getProc(), addresses.staticbase_char, addresses.charPtr_offset)
	until (newAddress ~= oldAddress and newAddress ~= 0) or memoryReadBytePtr(getProc(),addresses.loadingScreenPtr, addresses.loadingScreen_offset) ~= 0
	-- wait until loading screen is gone
	repeat
		rest(1000)
	until memoryReadBytePtr(getProc(),addresses.loadingScreenPtr, addresses.loadingScreen_offset) == 0

	rest(2000)
	player:update()
	return true
end

function isInGame()
	-- Note: if not in game, addresses.isInGame + 0xBF4 is 1 when at the character selection screen.
	if memoryReadBytePtr(getProc(),addresses.loadingScreenPtr, addresses.loadingScreen_offset) == 0 and
	   memoryReadInt(getProc(), addresses.isInGame) == 1 then
		return true
	else
		return false
	end
end

-- Parse from |Hitem:33BF1|h|cff0000ff[eeppine ase]|r|h
-- hmm, i whonder if we could get more information out of it than id, color and name.
function parseItemLink(itemLink)
	if itemLink == "" or itemLink == nil then
		return;
 	end

	local s,e, id, color, name = string.find(itemLink, "|Hitem:(%x+).*|h|c(%x+)%[(.+)%]|r|h");
	id = id or "000000"; color = color or "000000";
	id    = tonumber(tostring(id), 16) or 0;
	color = tonumber(tostring(color), 16) or 0;
	name = name or "<invalid>";

	return id, color, name;
end


function GetPartyMemberName(_number)

	if type(_number) ~= "number" or _number < 1 then
		print("GetPartyMemberName(number): incorrect value for 'number'.")
		return
	end

	local listAddress = memoryReadRepeat("uintptr", getProc(), addresses.partyMemberList_address, addresses.partyMemberList_offset )
	local memberAddress = listAddress + (_number - 1) * 0x60

	-- Check if that number exists
	if memoryReadRepeat("byte", getProc(), memberAddress) ~= 1 then
		return nil
	end
	if memoryReadRepeat("byte", getProc(), memberAddress + 0x1C) == 31 then
		memberAddress = memoryReadRepeat("uint", getProc(), memberAddress + 8 )
		local name = memoryReadString(getProc(), memberAddress)
			if( bot.ClientLanguage == "RU" ) then
				name = utf82oem_russian(name);
			else
				name = utf8ToAscii_umlauts(name);   -- only convert umlauts
			end
		return name
	else
		local name = memoryReadString(getProc(), memberAddress + 8)
			if( bot.ClientLanguage == "RU" ) then
				name = utf82oem_russian(name);
			else
				name = utf8ToAscii_umlauts(name);   -- only convert umlauts
			end
		return name
	end
end

function GetPartyMemberAddress(_number)
	local name = GetPartyMemberName(_number)
	if name then
		return player:findNearestNameOrId(name)
	end
end

function EventMonitorStart(monitorName, event, filter)
	-- 'monitorName' (string) - A unique name to identify the monitor.
	-- 'event' (string) - The event to register and monitor.
	-- 'filter' (table) - A table of values to compare with the returned arguments from a triggered event.
	--		eg. {nil,nil,nil,"random"} will only save events that have the word "random" in the 4th argument.

	-- warning if igf events addon is missing
	if bot.IgfEventAddon == false then
		cprintf(cli.yellow, language[183])	-- Ingamefunctions event addon is not installed or igf needs updating.
		return false
	end

	if filter then
		RoMScript("igf_events:StartMonitor(\'"..monitorName.."\',\'" ..event.."\',\'"..filter.."\')")
	else
		RoMScript("igf_events:StartMonitor(\'"..monitorName.."\',\'" ..event.."\')")
	end
end

function EventMonitorStop(monitorName)
	-- warning if igf events addon is missing
	if bot.IgfEventAddon == false then
		cprintf(cli.yellow, language[183])	-- Ingamefunctions event addon is not installed or igf needs updating.
		return false
	end

	RoMScript("igf_events:StopMonitor(\'"..monitorName.."\')")
end

function EventMonitorPause(monitorName)
	-- warning if igf events addon is missing
	if bot.IgfEventAddon == false then
		cprintf(cli.yellow, language[183])	-- Ingamefunctions event addon is not installed or igf needs updating.
		return false
	end

	RoMScript("igf_events:PauseMonitor(\'"..monitorName.."\')")
end

function EventMonitorResume(monitorName)
	-- warning if igf events addon is missing
	if bot.IgfEventAddon == false then
		cprintf(cli.yellow, language[183])	-- Ingamefunctions event addon is not installed or igf needs updating.
		return false
	end

	RoMScript("igf_events:ResumeMonitor(\'"..monitorName.."\')")
end

function EventMonitorCheck(monitorName, returnFilter, lastEntryOnly)
	-- 'monitorName' (string) - The name of the monitor you want to get the event data from.
	-- 'returnFilter' (string) - A comma separated string of numbers representing the arguments you wish to get.
	--		eg. '1,4' will return the 1st and 4th argument from the event.
	-- 'lastEntryOnly' (string) - Will only return the latest logged triggered event ignoring older ones.

	-- warning if igf events addon is missing
	if bot.IgfEventAddon == false then
		cprintf(cli.yellow, language[183])	-- Ingamefunctions event addon is not installed or igf needs updating.
		return false
	end

	if returnFilter then
		returnFilter = ",\'" .. returnFilter .. "\'"
	else
		returnFilter = ", nil"
	end

	if lastEntryOnly ~= nil then
		lastEntryOnly = "," .. tostring(lastEntryOnly)
	else
		lastEntryOnly = ", nil"
	end

	return RoMScript("igf_events:GetLogEvent(\'" .. monitorName .. "\'" .. returnFilter .. lastEntryOnly .. ")")
end

function CallPartner(nameOrId)
	-- Seach each tab
	for tab = 1, 2 do
		-- Get number of pets/mounts
		local count = RoMScript("PartnerFrame_GetPartnerCount("..tab..")")
		-- Check each
		for i = 1, count do
			local _, id, name = RoMScript("PartnerFrame_GetPartnerInfo(".. tab ..",".. i ..")")
			if id == nameOrId or name == nameOrId then -- found
				RoMScript("PartnerFrame_CallPartner(".. tab ..",".. i ..")")
				yrest(500)
				repeat player:updateCasting() yrest(1000) until not player.Casting
				return
			end
		end
	end

	printf("Partner %s not found.\n",nameOrId)
end

function AddPartner(nameOrId)
	local partner = inventory:findItem(nameOrId, "all")
	if partner then
		RoMScript("PartnerFrame_AddPartner(".. partner.BagId ..")")
	end
end

function Attack()
	if settings.profile.hotkeys.AttackType == nil then
		setupAttackKey()
	end

	local tmpTargetPtr = memoryReadRepeat("uint", getProc(), player.Address + addresses.pawnTargetPtr_offset) or 0

	if tmpTargetPtr == 0 and player.TargetPtr == 0 then
		-- Nothing to attack
		return
	end

	if tmpTargetPtr ~= 0 then
		player.TargetPtr = tmpTargetPtr
		if settings.profile.hotkeys.AttackType == "macro" then
			RoMScript("UseSkill(1,1)")
		else
			keyboardPress(settings.profile.hotkeys.AttackType)
		end
		return
	end

	if player.TargetPtr ~= 0 then
		-- update TargetPtr
		player:updateTargetPtr()
		if player.TargetPtr ~= 0 then -- still valid target

			if( memoryWriteString == nil ) then
				error("Update your copy of MicroMacro to version 1.02!");
			end

			-- freeze TargetPtr
			memoryWriteString(getProc(), addresses.functionTargetPatchAddr, string.rep(string.char(0x90),#addresses.functionTargetBytes));

			-- Target it
			memoryWriteInt(getProc(), player.Address + addresses.pawnTargetPtr_offset, player.TargetPtr);

			-- 'Click'
			if settings.profile.hotkeys.AttackType == "macro" then
				RoMScript("UseSkill(1,1)")
			else
				keyboardPress(settings.profile.hotkeys.AttackType)
			end
			yrest(100)

			-- unfreeze TargetPtr
			memoryWriteString(getProc(), addresses.functionTargetPatchAddr, string.char(unpack(addresses.functionTargetBytes)));

		end
	end
end

function getZoneId()
	local zonechannel = memoryReadRepeat("int", getProc(), addresses.zoneId)
	if zonechannel ~= nil then
		local zone = zonechannel%1000
		return zone, (zonechannel-zone)/1000 + 1 -- zone and channel
	else
		printf("Failed to get zone id\n")
	end
end

function bankItemBySlot(SlotNumber)
	-- moneyPtr + 0x8 = bank Address = 0x9DDDCC in 4.0.4.2456
	-- SlotNumber is 1 to 40
	if SlotNumber >= 1 and 40 >= SlotNumber then
		local baseaddress = (addresses.moneyPtr + 0x8)
		local Address = baseaddress + ( (SlotNumber - 1) * 68 );
		local Id = memoryReadInt( getProc(), Address ) or 0;
		local Name
		if ( Id ~= nil and Id ~= 0 ) then
			local BaseItemAddress = GetItemAddress( Id );
			if ( BaseItemAddress == nil or BaseItemAddress == 0 ) then
				cprintf( cli.yellow, "Wrong value returned in update of item id: %d\n", Id );
				logMessage(sprintf("Wrong value returned in update of item id: %d", Id));
				return;
			end;
			local MaxDurability = memoryReadByte( getProc(), Address + addresses.maxDurabilityOffset );
			local RequiredLvl = memoryReadInt( getProc(), Address + addresses.requiredLevelOffset );
			local ItemCount = memoryReadInt( getProc(), Address + addresses.itemCountOffset );
			local nameAddress = memoryReadUInt( getProc(), BaseItemAddress + addresses.nameOffset );
			if( nameAddress == nil or nameAddress == 0 ) then
				Name = "<EMPTY>";
			else
				Name = memoryReadString(getProc(), nameAddress);
				return Name, Id, ItemCount, SlotNumber, RequiredLvl, MaxDurability   -- this is the important part
			end;
		end
	else
		print("Incorrect Slot number stated\n")
	end
end

-- This function for users is to simplify changing profile after changing character.
function loadProfile(forcedProfile)
   -- convert player name to profile name and check if profile exist
   local load_profile_name;   -- name of profile to load
   if( forcedProfile ) then
      load_profile_name = convertProfileName(forcedProfile);
   else
      load_profile_name = convertProfileName(player.Name);
   end
   player = CPlayer.new();
   settings.load();
   settings.loadProfile(load_profile_name)
   player:update()

   -- Profile onLoad event
   if( type(settings.profile.events.onLoad) == "function" ) then
      local status,err = pcall(settings.profile.events.onLoad);
      if( status == false ) then
         local msg = sprintf("onLoad error: %s", err);
         error(msg);
      end
   end
end

-- Thanks to JackBlonder for his work on the QuestByName functions
function AcceptQuestByName(_nameorid, _questgroup)
	local DEBUG = false
	if settings.options.DEBUGGING == true then DEBUG = true end

	-- Check for valid _nameorid
	local questToAccept
	if _nameorid == nil then
		questToAccept = "all"
	elseif type(_nameorid) == "number" then
		questToAccept = GetIdName(_nameorid)
	else
		questToAccept = _nameorid
	end

	if type(questToAccept) ~= "string" then
		error("Invalid name or id used in AcceptQuestByName")
	end
				if DEBUG then
					printf("questToAccept: %s\n",questToAccept)
				end

	-- Check for valid _questgroup
	if _questgroup ~= nil then
		if type(_questgroup) == "string" then
			_questgroup = string.lower(_questgroup)
			_questgroup = string.gsub(_questgroup,"s$","") -- remove 's' at end if user used plural
		end
		if _questgroup == "normal" then _questgroup = 0
		elseif _questgroup == "daily" then _questgroup = 2
		elseif _questgroup == "public" then _questgroup = 3
		else _questgroup = nil
		end
	end

	-- If no _questgroup specified and Id used, get quest group from memory.
	if _questgroup == nil and type(_nameorid) == "number" then
		local baseaddress = GetItemAddress(_nameorid)
		if baseaddress then
			_questgroup = memoryReadInt(getProc(), baseaddress + addresses.questGroup_offset)
		end
	end

	-- Check if we have target
	player:updateTargetPtr()
	yrest(100)
	if (player.TargetPtr == 0 or player.TargetPtr == nil) then
		print("No target! Target NPC before using AcceptQuestByName")
		return
	end

	-- Target NPC again to get updated questlist
	Attack()
	yrest(500)

	local questOnBoard
	local availableQuests = RoMScript("GetNumQuest(1)") -- Get number of available quests
				if DEBUG then
					printf("Number of available quests: %d\n",availableQuests)
				end

	local matchFound = false
	-- For each quest
	for i=1,availableQuests do
		-- Check to see if we have room to accept quests
		if (30 > RoMScript("GetNumQuestBookButton_QuestBook()"))  then
			-- Get quest name
			questOnBoard, daily, qgroup = RoMScript("GetQuestNameByIndex(1, "..i..")")
						if DEBUG then
							printf("questOnBoard: %s \n",questOnBoard)
						end
			if ((questToAccept == "" or questToAccept == "all") or -- Accept all
			  FindNormalisedString(questOnBoard,questToAccept)) and -- Or match name
			  (_questgroup == nil or _questgroup == qgroup) then -- And match quest group
				matchFound = true
				repeat
					RoMScript("OnClick_QuestListButton(1,"..i..")") -- Clicks the quest
					yrest(100)
					RoMScript("AcceptQuest()") -- Accepts the quest
					yrest(100)
				until (getQuestStatus(questOnBoard)=="incomplete" or getQuestStatus(questOnBoard)=="complete") -- Try again if accepting didn't work
				printf("Quest accepted: %s\n",questOnBoard)

				-- break if name matched
				if (questToAccept ~= "" and questToAccept ~= "all") then
					break
				end
				yrest(200)
			elseif questToAccept ~= "" and questToAccept ~= "all" and i==availableQuests then
				-- Didn't find name match
				printf("Questname not found: %s\n",questToAccept) -- Quest not found
			end
		else
			print("Maxim number of quests in questbook!")
		end
	end
	RoMScript("SpeakFrame:Hide()")
	yrest(750)
	return matchFound
end

function CompleteQuestByName(_nameorid, _rewardnumberorname, _questgroup)
	local DEBUG = false
	if settings.options.DEBUGGING == true then DEBUG = true end

	-- Check for valid _nameorid
	local questToComplete
	if _nameorid == nil then
		questToComplete = "all"
	elseif type(_nameorid) == "number" then
		questToComplete = GetIdName(_nameorid)
	else
		questToComplete = _nameorid
	end

	if type(questToComplete) ~= "string" then
		error("Invalid name or id used in CompleteQuestByName")
	end
				if DEBUG then
					printf("questToComplete: %s\n",questToComplete)
				end

	-- Check if user put questgroup in second argument
	if type(_rewardnumberorname) == "string" and
	   (string.lower(_rewardnumberorname) == "normal" or string.lower(_rewardnumberorname) == "daily" or string.lower(_rewardnumberorname) == "public") then
		_questgroup = _rewardnumberorname
		_rewardnumberorname = nil
	end

	-- Check for valid _questgroup
	if _questgroup ~= nil then
		if type(_questgroup) == "string" then
			_questgroup = string.lower(_questgroup)
			_questgroup = string.gsub(_questgroup,"s$","") -- remove 's' at end if user used plural
		end
		if _questgroup == "normal" then _questgroup = 0
		elseif _questgroup == "daily" then _questgroup = 2
		elseif _questgroup == "public" then _questgroup = 3
		else _questgroup = nil
		end
	end

	-- If no _questgroup specified and Id used, get quest group from memory.
	if _questgroup == nil and type(_nameorid) == "number" then
		local baseaddress = GetItemAddress(_nameorid)
		if baseaddress then
			_questgroup = memoryReadInt(getProc(), baseaddress + addresses.questGroup_offset)
		end
	end

	-- Check if we have target
	player:updateTargetPtr()
	yrest(100)
	if (player.TargetPtr == 0 or player.TargetPtr == nil) then
		print("No target! Target NPC before using CompleteQuestByName")
		return
	end

	-- Target NPC again to get updated questlist
	Attack()
	yrest(500)

	local questOnBoard = ""
	local availableQuests = RoMScript("GetNumQuest(3)")
				if DEBUG then
					printf("Number of available quests: %d\n",availableQuests)
				end

	-- For each quest
	for i=1,availableQuests do
		-- Get quest name
		questOnBoard, daily, qgroup = RoMScript("GetQuestNameByIndex(3, "..i..")")
				if DEBUG then
					printf("questOnBoard / Index: %s \t %d\n",questOnBoard,i)
				end

		if ((questToComplete == "" or questToComplete == "all") or -- Complete all
		  FindNormalisedString(questOnBoard,questToComplete)) and -- Or match name
		  (_questgroup == nil or _questgroup == qgroup) then -- And match quest group
			local _counttime = os.time()
			repeat
				RoMScript("OnClick_QuestListButton(3, "..i..")") -- Clicks the quest
				yrest(100)

				if _rewardnumberorname then
							if DEBUG then
								printf("_rewardnumberorname: %s \n",_rewardnumberorname)
							end
					if type(_rewardnumberorname) == "number" then
						RoMScript("SpeakFrame_ClickQuestReward(SpeakQuestReward1_Item".._rewardnumberorname..")")
						yrest(100)
					elseif type(_rewardnumberorname) == "string" then
						-- Search for reward name
						local found = false
						for rewardNum = 1, RoMScript("SpeakQuestReward1.itemcount") do
							-- rewardID = RoMScript("SpeakQuestReward1_Item"..rewardNum..".ID")
							-- rewardType = RoMScript("SpeakQuestReward1_Item"..rewardNum..".Type")
							-- set Tooltip
							-- RoMScript("GameTooltip:SetQuestItem("..rewardType..","..rewardID..")")
							-- get Tooltip data
							local rewardName = RoMScript("SpeakQuestReward1_Item"..rewardNum.."_Desc:GetText()")
							if FindNormalisedString(rewardName, _rewardnumberorname) then
								found = true
								RoMScript("SpeakFrame_ClickQuestReward(SpeakQuestReward1_Item"..rewardNum..")")
								yrest(100)
								break
							end
						end
						if not found then
							printf("Invalid reward name or number, \"%s\"\n", _rewardnumberorname)
							return
						end
					else
						printf("Invalid reward type specified. Expected \"number\" or \"string\", got \""..type(_rewardnumberorname).."\".\n")
						return
					end
				elseif (os.time() - _counttime) >= 2 then -- quest still there because of reward item needs choosing
					RoMScript("SpeakFrame_ClickQuestReward(SpeakQuestReward1_Item1)")
					yrest(100)
				end
				RoMScript("CompleteQuest()") -- Completes the quest
				yrest(100)
			until (getQuestStatus(_nameorid)~="complete")
			printf("Quest completed: %s\n",questOnBoard)

			-- break if name matched
			if (questToComplete ~= "" and questToComplete ~= "all") then
				break
			end
			yrest(200)
		elseif questToComplete ~= "" and questToComplete ~= "all" and i==availableQuests then
			printf("Questname not found: %s\n",questToComplete)
		end
	end
	RoMScript("SpeakFrame:Hide()")
	yrest(750)
end

function AcceptAllQuests(_questgroup)
	AcceptQuestByName("all", _questgroup)
end

function CompleteAllQuests(_questgroup)
	CompleteQuestByName("all", nil, _questgroup)
end

function CancelQuest(nameorid)
	local index = 1
	local questId = RoMScript("GetQuestId(1)")
	while questId ~= nil do
		if questId == nameorid or string.find(GetIdName(questId), nameorid, 1, true) then
			-- match found, delete
			RoMCode("g_SelectedQuest = "..index)
			RoMScript("ViewQuest_QuestBook( g_SelectedQuest )")
			yrest(500)
			RoMScript("DeleteQuest()")
			yrest(1000)
			return
		else
			index = index + 1
			questId = RoMScript("GetQuestId("..index..")")
		end
	end
end

function AcceptPopup(popupName)
   -- Get the correct popup frame
   local popup
   if popupName == nil then -- look for first visible popup
      for i = 1,4 do
         if RoMScript("StaticPopup"..i..":IsVisible()") then
            popup = "StaticPopup"..i
            break
         end
      end
   else -- look for the named popup
      popup = RoMScript("StaticPopup_Visible('"..popupName.."')")
   end

   -- Accept the popup
   if popup then
      print("Accepting popup "..RoMScript(popup..".which"))
      RoMScript("StaticPopup_EnterPressed("..popup..");") yrest(1000)
      RoMScript(popup..":Hide()")
   else
      print("Popup not found "..(popupName or ""))
   end
end

-- normalises a string so it can be used in searches such as "string.find" and "string.match" without error.
function NormaliseString(_str)
	_str = string.gsub(_str, "%"..string.char(94), ".")	-- Delete "^" in string
	_str = string.gsub(_str, "%"..string.char(36), ".")	-- Delete "$" in string
	_str = string.gsub(_str, "%"..string.char(40), ".")	-- Delete "(" in string
	_str = string.gsub(_str, "%"..string.char(41), ".")	-- Delete ")" in string
	_str = string.gsub(_str, "%"..string.char(37), ".")	-- Delete "%" in string
	_str = string.gsub(_str, "%"..string.char(91), ".")	-- Delete "[" in string
	_str = string.gsub(_str, "%"..string.char(93), ".")	-- Delete "]" in string
	_str = string.gsub(_str, "%"..string.char(42), ".")	-- Delete "*" in string
	_str = string.gsub(_str, "%"..string.char(43), ".")	-- Delete "+" in string
	_str = string.gsub(_str, "%"..string.char(45), ".")	-- Delete "-" in string
	_str = string.gsub(_str, "%"..string.char(63), ".")	-- Delete "?" in string
	_str = string.gsub(_str, string.char(34), ".")	-- Delete """ in string
	_str = string.lower(_str) -- Lower case
	return _str
end

-- Finds a string in another string, normalising it first.
function FindNormalisedString(_name, _string)
	_name = string.lower(_name)
	_string = NormaliseString(_string)

	if string.find(_name,_string) then
		return true
	else
		return false
	end
end

function ChoiceOptionByName(optiontext)
------------------------------------------------
-- Select Option By Name
-- optiontext = option text or part of
-- NPC option dialog should already be open
------------------------------------------------
	if not RoMScript("SpeakFrame:IsVisible()") then
		printf("Please open a dialog before using \"ChoiceOptionByName\".\n")
		return
	end

    local counter = 1
	local option
    repeat
		option = RoMScript("GetSpeakOption("..counter..")")
		if option and FindNormalisedString(option,optiontext) then
			-- First try "ChoiceOption"
            RoMScript("ChoiceOption("..counter..");"); yrest(1000);

			-- If SpeakFrame is still open and option is still there then try "SpeakFrame_ListDialogOption"
			option = RoMScript("GetSpeakOption("..counter..")")
			if option and FindNormalisedString(option,optiontext) and RoMScript("SpeakFrame:IsVisible()") then
				RoMScript("SpeakFrame_ListDialogOption(1,"..counter..");"); yrest(1000);
			end
            return true
        end
        counter = counter + 1
    until not option
	printf("Option \"%s\" not found.\n",optiontext)
    return false
end

function PointInPoly(vertices, testx, testz )
-- Tells you if a point (testx,testz) is within a polygon represented by a table of points in 'vertices'
	if type(vertices) == "string" then
		if not string.find(vertices,".xml", 1, true) then
			vertices = vertices .. ".xml"
		end
		local filename = getExecutionPath() .. "/waypoints/" .. vertices
		if not fileExists(filename) then
			filename = getExecutionPath() .. "/../romglobal/waypoints/" .. vertices
		end
		local file, err = io.open(filename, "r");
		if file then
			file:close();
			local tmpWPL = CWaypointList();
			tmpWPL:load(filename);
			vertices = table.copy(tmpWPL.Waypoints)
		else
			error("PointInPoly: invalid file name.",0)
		end
	end

	local nvert = #vertices
	local j = nvert
	local c = false
	for i = 1, nvert do
		if ( ((vertices[i].Z > testz) ~= (vertices[j].Z > testz)) and (testx < (vertices[j].X - vertices[i].X) * (testz - vertices[i].Z) / (vertices[j].Z - vertices[i].Z) + vertices[i].X) ) then
			c = not c
		end
		j = i
	end
	return c
end

function GetSkillBookData(_tabs)
	if type(_tabs) == "table" then
		-- do nothing
	elseif type(tonumber(_tabs)) == "number" then
		_tabs = {tonumber(_tabs)}
	else
		_tabs = {1,2,3,4,5}
	end

	local proc = getProc()
	local skillsTableTabSize = 0x10
	local skillSize = 0x4c

	local function GetSkillInfo (address)
		local tmp = {}
		tmp.Address = address
		tmp.Id = tonumber(memoryReadRepeat("int", proc, address))
		tmp.Name = GetIdName(tmp.Id)
		tmp.TPToLevel = memoryReadRepeat("int", proc, address + addresses.skillTPToLevel_offset)
		tmp.Level = memoryReadRepeat("int", proc, address + addresses.skillLevel_offset)
		tmp.aslevel = memoryReadRepeat("int", proc, address + addresses.skillAsLevel_offset)
		tmp.BaseItemAddress = GetItemAddress(tmp.Id)
		-- Get power and consumables
		for count = 0, 1 do
			local uses = memoryReadRepeat("int", proc, tmp.BaseItemAddress + (8 * count) + addresses.skillUsesBase_offset)
			if uses == 0 then
				break
			end
			local usesnum = memoryReadRepeat("int", proc, tmp.BaseItemAddress + (8 * count) + addresses.skillUsesBase_offset + 4)
			if uses == SKILLUSES_MANA then
				if tmp.Level > 49 then
					tmp.Mana = usesnum * (5.8 + (tmp.Level - 49)*0.2)
				elseif tmp.Level > 1 then
					tmp.Mana = usesnum * (1 + (tmp.Level - 1)*0.1)
				else
					tmp.Mana = usesnum
				end
			elseif uses == SKILLUSES_RAGE then
				tmp.Rage = usesnum
			elseif uses == SKILLUSES_FOCUS then
				tmp.Focus = usesnum
			elseif uses == SKILLUSES_ENERGY then
				tmp.Energy = usesnum
			elseif uses == SKILLUSES_ITEM then
				tmp.Consumable = "item"
				tmp.ConsumableNumber = usesnum
			elseif uses == SKILLUSES_PROJECTILE then
				tmp.Consumable = "projectile"
				tmp.ConsumableNumber = usesnum
			elseif uses == SKILLUSES_ARROW then
				tmp.Consumable = "arrow"
				tmp.ConsumableNumber = usesnum
			elseif uses == SKILLUSES_PSI then
				tmp.Psi = usesnum
			elseif uses ~= 3 and uses ~= 4 then -- known unused 'uses' values.
				printf("Skill %s 'uses' unknown type %d, 'usesnum' %d. Please report to bot devs. We might be able to use it.\n",tmp.Name, uses, usesnum)
			end
		end

		return tmp
	end

	-- Collect tab skill info
	local tabData = {}

	for __, tab in pairs(_tabs) do
		local tabBaseAddress = memoryReadRepeat("uint", proc, addresses.skillsTableBase + skillsTableTabSize*(tab-1) + addresses.skillsTableTabStartAddress_offset)
		local tabEndAddress = memoryReadRepeat("uint", proc, addresses.skillsTableBase + skillsTableTabSize*(tab-1) + addresses.skillsTableTabEndAddress_offset)

		if tabBaseAddress ~= 0 and tabEndAddress ~= 0 then
			for num = 1, (tabEndAddress - tabBaseAddress) / skillSize do
				local skilladdress = tabBaseAddress + (num - 1) * skillSize
				tmpData = GetSkillInfo(skilladdress)
				if tmpData.Name ~= nil and tmpData.Name ~= "" then
					tabData[tmpData.Name] = {
						Address = tmpData.Address,
						Id = tmpData.Id,
						TPToLevel = tmpData.TPToLevel,
						Level = tmpData.Level,
						aslevel = tmpData.aslevel,
						Mana = tmpData.Mana,
						Rage = tmpData.Rage,
						Focus = tmpData.Focus,
						Energy = tmpData.Energy,
						Consumable = tmpData.Consumable,
						ConsumableNumber = tmpData.ConsumableNumber,
						Psi = tmpData.Psi,
						skilltab = tab,
						skillnum = num,
						BaseItemAddress = tmpData.BaseItemAddress,
					}
				end
			end
		end
	end

	return tabData
end

function FindSkillBookSkill(_nameorid, _tabs)
	local tabData = GetSkillBookData(_tabs)
	for name, data in pairs(tabData) do
		if data.Id == tonumber(_nameorid) or string.find(name, _nameorid, 1, true) then
			data.Name = name
			return data
		end
	end

	return false
end

function ItemQueueCount()
	-- Returns the number of items in the ItemQueue. That's the queue of items going into the backpack.
	return memoryReadInt(getProc(), addresses.itemQueueCount)
end

local originalkeyboardHold = keyboardHold
local originalkeyboardRelease = keyboardRelease

function keyboardHold(key)
	local keybit, oppbit -- The bit for the key and the bit for the opposite key
	if key == settings.hotkeys.MOVE_FORWARD.key then
		keybit = 1
		oppbit = 2
	elseif key == settings.hotkeys.MOVE_BACKWARD.key then
		keybit = 2
		oppbit = 1
	elseif key == settings.hotkeys.STRAFF_RIGHT.key then
		keybit = 4
		oppbit = 8
	elseif key == settings.hotkeys.STRAFF_LEFT.key then
		keybit = 8
		oppbit = 4
	elseif key == settings.hotkeys.ROTATE_RIGHT.key then
		keybit = 16
		oppbit = 32
	elseif key == settings.hotkeys.ROTATE_LEFT.key then
		keybit = 32
		oppbit = 16
	else
		return originalkeyboardHold(key) -- Not a move key. Fall back to original function.
	end

	-- Get current move keys pressed
	local keyspressed = memoryReadBytePtr(getProc(),addresses.staticbase_char ,addresses.moveKeysPressed_offset )

	-- Set 'key' pressed
	if keyspressed and not bitAnd(keyspressed, keybit) then
		keyspressed = keyspressed + keybit

		-- Unset opposite key
		if bitAnd(keyspressed, oppbit) then
			keyspressed = keyspressed - oppbit
		end

		-- Write result to memory
		memoryWriteBytePtr(getProc(),addresses.staticbase_char ,addresses.moveKeysPressed_offset, keyspressed )
	end
end

function keyboardRelease(key)
	local keybit -- The bit for the key
	if key == settings.hotkeys.MOVE_FORWARD.key then
		keybit = 1
	elseif key == settings.hotkeys.MOVE_BACKWARD.key then
		keybit = 2
	elseif key == settings.hotkeys.STRAFF_RIGHT.key then
		keybit = 4
	elseif key == settings.hotkeys.STRAFF_LEFT.key then
		keybit = 8
	elseif key == settings.hotkeys.ROTATE_RIGHT.key then
		keybit = 16
	elseif key == settings.hotkeys.ROTATE_LEFT.key then
		keybit = 32
	else
		return originalkeyboardRelease(key) -- Not a move key. Fall back to original function.
	end

	-- Get current move keys pressed
	local keyspressed = memoryReadBytePtr(getProc(),addresses.staticbase_char ,addresses.moveKeysPressed_offset )

	-- Set 'key' released
	if keyspressed and bitAnd(keyspressed, keybit) then
		keyspressed = keyspressed - keybit
		memoryWriteBytePtr(getProc(),addresses.staticbase_char ,addresses.moveKeysPressed_offset, keyspressed )
	end
end

function getGameTime()
	return memoryReadRepeat("uint",getProc(),addresses.gameTimeAddress)/1000
end

function getTEXT(text)
	local function memoryGetTEXT(str)
		local addressPtrsBase = memoryReadInt(getProc(), addresses.getTEXT)
		local startloc = memoryReadInt(getProc(), addressPtrsBase + 0x268)
		local endloc = memoryReadInt(getProc(), addressPtrsBase + 0x26C)
		local quarter = math.floor((endloc-startloc) / 4)

		local tmpStart = endloc
		local tmpEnd = endloc
		-- Find which quarter of memory holds string to speed up search
		for count = 1,3 do
			tmpStart = tmpStart - quarter
			local found = findPatternInProcess(getProc(), string.char(0).."Sys", "xxx", tmpStart, tmpEnd);
			local tmpText = memoryReadString(getProc(), found + 1)
			if tmpText <= str then
				startloc = tmpStart
				break
			else
				endloc = tmpStart
			end
		end
		local searchlen = endloc - startloc

		local pattern = string.char(0x00) .. str .. string.char(0x00)
		local mask = string.rep("x", #pattern)
		local offset = #pattern
		local found = findPatternInProcess(getProc(), pattern, mask, startloc, searchlen);

		if found ~= 0 then
			return memoryReadString(getProc(), found + offset)
		else
			return str
		end
	end

	if not text or type(text) ~= "string" then return end
	local resultTEXT = memoryGetTEXT(text)
	for subTEXT in string.gmatch(resultTEXT,"%[(.-)%]") do
		local translatedSubTEXT
		if tonumber(subTEXT) then -- Must be id
			translatedSubTEXT = GetIdName(tonumber(subTEXT))
		else
			translatedSubTEXT = memoryGetTEXT(subTEXT)
		end
		if translatedSubTEXT ~= nil and translatedSubTEXT ~= subTEXT then
			resultTEXT = string.gsub(resultTEXT, "%["..subTEXT.."%]", translatedSubTEXT)
		end
	end

	return resultTEXT
end

function getGameVersion(proc)
	-- Check 'proc'
	if proc == nil then
		proc = getProc()
	end

	-- Look for pattern in 64 bit memory area first
	local foundAddress = findPatternInProcess(proc, string.char(0xBD, 0x04, 0xEF, 0xFE), "xxxx", 0x186000, 0xA000)

	-- If it fails then look in 32 bit memory area
	if foundAddress == nil or foundAddress == 0 then
		foundAddress = findPatternInProcess(proc, string.char(0xBD, 0x04, 0xEF, 0xFE), "xxxx", 0x126000, 0xA000)
	end

	if foundAddress == nil or foundAddress == 0 then
		return 0
	end

	-- Add the offset to the address
	foundAddress = foundAddress + 0xC

	-- Read the version numbers which are 4 shorts in reverse order
	local ver = ""
	for i = 6, 0, -2 do
		ver = ver .. (memoryReadShort(proc, foundAddress + i) or 0)
		if i ~= 0 then ver = ver .. "." end
	end

	return ver
end

function getLastWarning(message, age)
	if type(message) ~= "string" then
		print("Must specify message string when calling 'getLastWarning()'.")
		return
	end

	if age then
		return RoMScript("igf_events:getLastEventMessage('WARNING_MESSAGE',[[" .. message .. "]]," .. age .. ")")
	else
		return RoMScript("igf_events:getLastEventMessage('WARNING_MESSAGE',[[" .. message .. "]])")
	end
end

function getLastAlert(message, age)
	if type(message) ~= "string" then
		print("Must specify message string when calling 'getLastAlert()'.")
		return
	end

	if age then
		return RoMScript("igf_events:getLastEventMessage('ALERT_MESSAGE',[[" .. message .. "]],".. age .. ")")
	else
		return RoMScript("igf_events:getLastEventMessage('ALERT_MESSAGE',[[" .. message .. "]])")
	end
end

function getCurrency(name)
	name = string.lower(name) -- Make lower case
	local noSname = string.match(name,"^(.-)s?$") -- Take off ending 's'

	local group, index
	if noSname == "shell" or name == string.lower(getTEXT("SYS_MONEY_TYPE_11")) then
		group, index = 1,1
	elseif noSname == "energy" or noSname == "eoj" or name == string.lower(getTEXT("SYS_MONEY_TYPE_12")) then
		group, index = 1,2
	elseif noSname == "dreamland" or noSname == "pioneer sigil" or noSname == "sigil" or name == string.lower(getTEXT("SYS_MONEY_TYPE_10")) then
		group, index = 1,3
	elseif noSname == "mem" or noSname == "mento" or noSname == "memento" or name == string.lower(getTEXT("SYS_MONEY_TYPE_9")) then
		group, index = 2,1
	elseif noSname == "proof" or noSname == "pom" or name == string.lower(getTEXT("SYS_MONEY_TYPE_13")) then
		group, index = 2,2
	elseif noSname == "honor" or name == string.lower(getTEXT("SYS_MONEY_TYPE_4")) then
		group, index = 3,1
	elseif noSname == "trial" or noSname == "bott" or name == string.lower(getTEXT("SYS_MONEY_TYPE_8")) then
		group, index = 3,2
	elseif noSname == "warrior" or noSname == "botw" or name == string.lower(getTEXT("SYS_MONEY_TYPE_14")) then
		group, index = 3,3
	else
		print("Invalid currency type. Please use 'shell', 'eoj', 'sigil', 'mem', 'proof', 'honor', 'trial' or 'warrior'.")
		return 0,0
	end
	local amount, limit = RoMScript("GetPlayerPointInfo("..group..","..index..",\"\")")

	return amount, limit-amount
end

function isClientCrashed()
	local crashwins = findWindowList("Crash Report", "#32770");

	if( #crashwins == 0 ) then
		return false
	end

	local crashparent
	for i = 1, #crashwins, 1 do
		crashparent = getWindowParent(crashwins[i])
		if crashparent and crashparent == getWin() then
			-- Looks like the paired game client crashed.
			local pid = findProcessByWindow(crashwins[i]);
			return true, pid
		end
	end

	return false
end
