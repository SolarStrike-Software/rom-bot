if( settings == nil ) then
	include("settings.lua");
end

local charUpdatePattern = string.char(0x8B, 0x07, 0x8B, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF, 0x56, 0x50, 0xE8);
local charUpdateMask = "xxxx????xxx";
local charUpdateOffset = 4;

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
function selectGame()
	-- Get list of windows in an array
	local windowList = findWindowList("Runes of Magic", "Radiant Arcana");

	if( #windowList == 0 ) then
		print("You need to run rom first!");
		return 0;
	end

	charToUse = {};
	for i = 1, #windowList, 1 do
		local process, playerAddress, nameAddress;
	    -- open first window
		process = openProcess(findProcessByWindow(windowList[i]));
		-- read player address
		showWarnings(false);
		playerAddress = memoryReadIntPtr(process, addresses["staticbase_char"], addresses["charPtr_offset"]);
		-- read player name
		if( playerAddress ) then
			nameAddress = memoryReadUInt(process, playerAddress + addresses["pawnName_offset"]);
		end

		-- store the player name, with window number
		if nameAddress == nil then
		    charToUse[i] = "(RoM window "..i..")";
  		else
			charToUse[i] = memoryReadString(process, nameAddress);
		end
		showWarnings(true);
		closeProcess(process);
	end

	windowChoice = 1;
	-- wait until enter is released
    while keyPressed(key.VK_RETURN) do
    	yrest(200);
    end

    notShown = true;
	if (#windowList > 1) then  -- if theres more than 1 window, ask the player witch character to use
		while not keyPressedLocal(key.VK_RETURN) do
	    	if keyPressed(key.VK_UP) or keyPressed(key.VK_DOWN) or notShown then
	        	notShown = false;
	    		if keyPressed(key.VK_DOWN) then
	        		windowChoice = windowChoice + 1;
	        		if windowChoice > #charToUse then
	        	    	windowChoice = #charToUse;
					end
	    		end
	    		if keyPressed(key.VK_UP) then
	        		windowChoice = windowChoice - 1;
	        		if windowChoice < 1 then
	        	    	windowChoice = 1;
					end
	    		end

				if keyPressed(key.VK_UP) or keyPressed(key.VK_DOWN) then
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

function getWin()
	if( __WIN == nil ) then
  		__WIN = selectGame();
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
	if z2 == nil and y2 == nil then -- assume x1,z1,x2,z2 values (2 dimensional)
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

-- Used in pause/exit callbacks. Just releases hotkeys.
local function releaseKeys()
	if( settings.hotkeys.MOVE_FORWARD) then
		keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
	end

	if( settings.hotkeys.MOVE_BACKWARD ) then
		keyboardRelease(settings.hotkeys.MOVE_BACKWARD.key);
	end

	if( settings.hotkeys.ROTATE_LEFT ) then
		keyboardRelease(settings.hotkeys.ROTATE_LEFT.key);
	end

	if( settings.hotkeys.ROTATE_RIGHT) then
		keyboardRelease(settings.hotkeys.ROTATE_RIGHT.key);
	end

	if( settings.hotkeys.STRAFF_LEFT ) then
		keyboardRelease(settings.hotkeys.STRAFF_LEFT.key);
	end

	if( settings.hotkeys.STRAFF_RIGHT ) then
		keyboardRelease(settings.hotkeys.STRAFF_RIGHT.key);
	end
end

function pauseCallback()
	local msg = sprintf(language[46], getKeyName(getStartKey()));	--  to continue, (CTRL+L) exit ...

	-- If settings haven't been loaded...skip the cleanup.
	if( not settings ) then
		printf(msg);
		return;
	end;

	releaseKeys();
	printf(msg);
end
atPause(pauseCallback);

function exitCallback()
	-- If settings haven't been loaded...skip the cleanup.
	if( not settings ) then
		return;
	end;

	releaseKeys();
end
atExit(exitCallback);

function resumeCallback()
	printf("Resumed.\n");

	-- Make sure our player exists before trying to update it
	if( player ) then
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
	local displayname = string.sub(profile, 1, 4) .. "****";
	if( (player.X ~= LAST_PLAYER_X) or (player.Z ~= LAST_PLAYER_Z) ) then
		setWindowName(getHwnd(), sprintf(language[600],
		BOT_VERSION, displayname, player.X, player.Z, player.ExpPerMin, player.TimeTillLevel));

		LAST_PLAYER_X = player.X;
		LAST_PLAYER_Z = player.Z;
	end
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
		local foundpos = string.find(_wp_path,".",1,true);	-- filetype defined?
		if( foundpos ) then					-- filetype defined
			rp_default = string.sub(_wp_path,1,foundpos-1) .. settings.profile.options.RETURNPATH_SUFFIX .. ".xml";
		else							-- no filetype
			rp_default = _wp_path .. settings.profile.options.RETURNPATH_SUFFIX .. ".xml";
		end;
	end;

	if( _wp_path and not string.find(_wp_path,".", 1, true) and _wp_path ~= "wander" ) then
		_wp_path = _wp_path .. ".xml";
	end;
	if( _rp_path  and   not string.find(_rp_path,".", 1, true) ) then
		_rp_path = _rp_path .. ".xml";
	end;

	-- waypoint path is defined ... load it
	if( _wp_path and
		string.lower(_wp_path) ~= "wander" ) then
		local filename = getExecutionPath() .. "/waypoints/" .. _wp_path;
		if( not fileExists(filename) ) then
			local msg = sprintf(language[142], filename ); -- We can't find your waypoint file
			error(msg, 0);
		end;
		if( not __WPL ) then  		-- define object if not there
			__WPL = CWaypointList();
		end;
		__WPL:load(filename);
		cprintf(cli.green, language[0], __WPL:getFileName());	-- Loaded waypoint path

		if(__WPL.CurrentWaypoint ~= 1) then
			cprintf(cli.green, language[15], 					-- Waypoint #%d is closer then #1
			   __WPL.CurrentWaypoint, __WPL.CurrentWaypoint);
		end;
	end

	-- set wander for WP
	if( string.lower(_wp_path) == "wander" ) then
		__WPL = CWaypointListWander();
		__WPL:setRadius(settings.profile.options.WANDER_RADIUS);
		__WPL:setMode("wander");
		cprintf(cli.green, "We will wander arround in a radius of %d\n", settings.profile.options.WANDER_RADIUS);	-- Loaded waypoint path
	end

	-- look for default return path with suffix '_return'
	if( not _rp_path ) then
		if( fileExists(getExecutionPath() .. "/waypoints/" .. rp_default) ) then
			cprintf(cli.green, language[162], rp_default );	-- Return path found with default naming
			_rp_path = rp_default;	-- set default
		else
			cprintf(cli.yellow, language[163], rp_default );	-- No return path with default naming
		end;
	end

	-- return path defined or default found ... load it
	if( _rp_path ) then
		if( not __RPL ) then  		-- define object if not there
			__RPL = CWaypointList();
		end;
		local filename = getExecutionPath() .. "/waypoints/" .. _rp_path;
		if( not fileExists(filename) ) then
			local msg = sprintf(language[143], filename ); -- We can't find your returnpath file
			error(msg, 0);
		end;
		__RPL:load(filename);
		cprintf(cli.green, language[1], __RPL:getFileName());	-- Loaded return path
	else
		if( __RPL ) then  		-- clear old returnpath object
			__RPL = nil;
		end;
	end;

	-- check if on returnpath
	if( player.Returning == true  and
	    _rp_path ) then
		cprintf(cli.green, language[164], __RPL:getFileName());	-- We are coming from a return_path.
	else
		player.Returning = false;
		cprintf(cli.green, language[165], __WPL:getFileName() );-- We use the normal waypoint path %s now
	end
end

-- executing RoMScript and send a MM window message before
function sendMacro(_script)
	cprintf(cli.green, language[169], 		-- Executing RoMScript ...
	   "MACRO",
	   string.sub(_script, 1, 40) );

	return RoMScript(_script);

end


--- Run rom scripts, usage: RoMScript("BrithRevive();");
function RoMScript(script, default)

	--- Get the real offset of the address
	local macro_address = memoryReadUInt(getProc(), addresses.staticbase_macro);

	local scriptDef;

	if( settings.options.LANGUAGE == "spanish" ) then
		scriptDef = "/redactar";
	else
		scriptDef = "/script";
	end

	--- Macro length is max 255, and after we add the return code,
	--- we are left with about 155 character limit.

	local dataPart = 0 -- The part of the data to get
	local raw = ""     -- Combined raw data from 'R'
	repeat
		local text

		-- The command macro
		if dataPart == 0 then
			-- The initial command macro
			text = scriptDef.." R='' a={" .. script ..
			"} for i=1,#a do R=R..tostring(a[i])" ..
			"..'" .. string.char(9) .. "' end" ..
			" EditMacro("..resultMacro..",'"..RESULT_MACRO_NAME.."',7,R)";
		else
			-- command macro to get the rest of the data from 'R'
			text = scriptDef.." EditMacro("..resultMacro..",'"..
			RESULT_MACRO_NAME.."',7,string.sub(R,".. (1 + dataPart * 255) .."))";
		end

		-- Check to make sure length is within bounds
		local len = string.len(text);
		if( len > 254 ) then
			error("Macro text too long.", 2);
		end

		-- Write the command macro
		writeToMacro(commandMacro, text)

		-- Write something on the first address, to see when its over written
		memoryWriteByte(getProc(), macro_address + addresses.macroSize *(resultMacro - 1) + addresses.macroBody_offset , 6);

		--- Execute it
		if( settings.profile.hotkeys.MACRO ) then
			keyboardPress(settings.profile.hotkeys.MACRO.key);
		end

		-- A cheap version of a Mutex... wait till it is "released"
		-- Use high-res timers to find out when to time-out
		local startWaitTime = getTime();
		while( memoryReadByte(getProc(), macro_address + addresses.macroSize *(resultMacro - 1) + addresses.macroBody_offset) == 6 ) do
			if( deltaTime(getTime(), startWaitTime) > 800 ) then
				if( settings.options.DEBUGGING_MACRO ) then
					cprintf(cli.yellow, "[DEBUG] TIMEOUT in RoMScript ... \n");
				end;
				return default; -- Timed out
			end;
			rest(1);
		end

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
			if( string.find(readsz, "^%d+$") ) then readsz = tonumber(readsz);  end;
			if( readsz == "true" ) then readsz = true; end;
			if( readsz == "false" ) then readsz = false; end;

			table.insert(ret, readsz);
			cnt = cnt+1;
			readsz = "";
		else
			readsz = readsz .. string.char(byte);
		end
	end

	return unpack(ret);
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

	if( not _player_level) then _player_level = player.Level; end
	cprintf(cli.lightblue, language[170], _player_level );	-- Open and equipt giftbag for level

	-- open giftbag and equipt content
--	yrest(2000);	-- time for cooldowns to phase-out
	for i,v in pairs(database.giftbags)  do
		if( v.level == _player_level) then
			if( v.armor == armorMap[player.Class1]  or		-- only if items have the right armor
			    v.armor == nil ) then						-- or is armor independent
				local hf_return, hf_itemid, hf_name = inventory:useItem( v.itemid );	-- open bag or equipt item

				if ( hf_return ) then
					cprintf(cli.lightblue, language[171], hf_name );	-- Open/eqipt item:
				else
					cprintf(cli.yellow, language[174], v.name );		-- item not found
				end
				yrest(2000);					-- wait for using that item

				if( v.type == "bag" ) then		-- after opening bag update inventory
					yrest(4000);				-- some more time to open the bag
					inventory:update();			-- update slots
				end;
			end;
		end;

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
		sendMacro("SetSpellPoint("..skill_from_db.skilltab..","..skill_from_db.skillnum..");");
		hf_return = true;
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
								 [3] = { aslevel = 4, skillname="SCOUT_VAMPIRE_ARROWS" },},
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
								 [3] = { aslevel = 2, skillname="WARDEN_THORNY_VINE" },
								 [4] = { aslevel = 4, skillname="WARDEN_BRIAR_SHIELD" },
								 [5] = { aslevel = 8, skillname="WARDEN_POWER_OF_THE_WOOD_SPIRIT" } },
		[CLASS_DRUID]		= {  [1] = { aslevel = 1, skillname="DRUID_RECOVER" },
								 [2] = { aslevel = 1, skillname="DRUID_EARTH_ARROW" },
								 [3] = { aslevel = 2, skillname="DRUID_BRIAR_ENTWINEMENT" },
								 [4] = { aslevel = 6, skillname="DRUID_RESTORE_LIFE" } },
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
				tmp.hotkey = "MACRO";		-- use ROM API to use that skills
				tmp.Level = 1;
				table.insert(settings.profile.skills, tmp);
				cprintf(cli.lightblue, "We learned skill \'%s\' and will use it\n", v.skillname );	-- Open/eqipt item:
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

	-- special skill for SCOUT / not usable, just level it
	if(_loadonly ~= "loadonly") then
		if(player.Class1 == CLASS_SCOUT and
		   player.Level  == 6 ) then
			levelupSkill("SCOUT_RANGED_WEAPON_MASTERY", 6)
		elseif(player.Class1 == CLASS_SCOUT and
		   player.Level  > 6 ) then
		   levelupSkill("SCOUT_RANGED_WEAPON_MASTERY")
		end
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


function convertProfileName(_profilename)

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
			local msg = sprintf(language[101], -- we can't use the character/profile name \'%s\' as a profile name
			        load_profile_name, new_profile_name);
			error(msg, 0);
		end;
	else
		-- check if profile exist
		if( not fileExists(getExecutionPath() .. "/profiles/" .. load_profile_name..".xml" ) ) then
			local msg = sprintf(language[102], load_profile_name ); -- We can't find your profile
			error(msg, 0);
		end
	end;

	return load_profile_name;
end


local lastDisplayBlocks = 0;
function displayProgressBar(percent, size)
	size = size or 10;
	local blocksFilled = math.floor(size*percent/100);
	local blocksUnfilled = size - blocksFilled;

	if( blocksFilled ~= lastDisplayBlocks ) then
		printf("\r%03d%% [", percent);
		cprintf(cli.turquoise, string.rep("*", blocksFilled));
		printf(string.rep("-", blocksUnfilled) .. "]");

		lastDisplayBlocks = blocksFilled;
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
		end
		if(_v == false) then
			_v = "<false>";
		end
		if( type(_v) == "table" ) then
			_v = "<table>";
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

function getQuestStatus(_questname)
	-- Used when you need to make 3 way decision, get quest, complete quest or gather quest items.
	if (bot.IgfAddon == false) then
		error(language[1004], 0)	-- Ingamefunctions addon (igf) is not installed
	end

	if type(_questname) == "number" then
		_questname = GetIdName(_questname)
	end

	if type(_questname) == "string" then
		return RoMScript("igf_questStatus(\"".._questname.."\")")
	end

	error("Invalid id sent to getQuestStatus()")
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
		prior = math.max(getPing() - 20, 25);
	else
		prior = settings.profile.options.SKILL_USE_PRIOR;
	end

	return prior;
end


-- Returns the point that is nearest to (X,Z) between segment (A,B) and (C,D)
function getNearestSegmentPoint(x, z, a, b, c, d)
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

function waitForLoadingScreen()
	-- wait for loading screen to appear
	if memoryReadBytePtr(getProc(), addresses.loadingScreenPtr, addresses.loadingScreen_offset) == 0 then
		repeat
			yrest(1000)
		until memoryReadBytePtr(getProc(), addresses.loadingScreenPtr, addresses.loadingScreen_offset) == 1
	end

	-- wait until loading screen is gone
	repeat
		yrest(1000)
	until memoryReadBytePtr(getProc(),addresses.loadingScreenPtr, addresses.loadingScreen_offset) == 0
	player:update()
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

