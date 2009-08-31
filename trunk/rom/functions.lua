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
	charpatternstart_address, 1) == 0 ) then
		return false;
	end

	if( findPatternInProcess(getProc(), macroUpdatePattern, macroUpdateMask,
	macropatternstart_address, 1) == 0 ) then
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


function getWin()
	local skey = getStartKey();

	if( __WIN == nil ) then
		local winlist = findWindowList("Runes of Magic", "Radiant Arcana");

		if( #winlist == 0 ) then
			error(language[47], 0);	-- RoM window not found
		end

		if( #winlist > 1 ) then
			cprintf(cli.yellow, language[45],	-- Multiple RoM windows found
				getKeyName(skey));

			while( not keyPressed(skey) ) do
				yrest(10);
			end
			while( keyPressed(skey) ) do
				yrest(10);
			end

			__WIN = foregroundWindow();
		else
			__WIN = winlist[1];
		end
	else
		if( not windowValid(__WIN) ) then
			error(language[52], 0);
		end
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

function distance(x1, y1, x2, y2)
	if( x1 == nil or y1 == nil or x2 == nil or y2 == nil ) then
		error("Error: nil value passed to distance()", 2);
	end

	return math.sqrt( (y2-y1)*(y2-y1) + (x2-x1)*(x2-x1) );
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

	if( settings.profile.options.PATH_TYPE == "wander" ) then
		__WPL.OrigX = player.X;
		__WPL.OrigZ = player.Z;
	end

	-- Re-set our bot start time to now
	if( player ) then
		player.BotStartTime = os.time();

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
		setWindowName(getHwnd(), sprintf("RoM Bot %s [%s] (%d,%d)",
		BOT_VERSION, displayname, player.X, player.Z));

		LAST_PLAYER_X = player.X;
		LAST_PLAYER_Z = player.Z;
	end
end

function load_paths( _wp_path, _rp_path)
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
	if( _wp_path  and   not string.find(_wp_path,".",1,true) ) then _wp_path = _wp_path .. ".xml"; end;
	if( _rp_path  and   not string.find(_rp_path,".",1,true) ) then _rp_path = _rp_path .. ".xml"; end;

	-- waypoint path is defined ... load it
	if( _wp_path ) then
		local filename = getExecutionPath() .. "/waypoints/" .. _wp_path;
		if( not fileExists(filename) ) then 
			local msg = sprintf(language[142], filename ); -- We can't find your waypoint file
			error(msg, 0);
		end;
		__WPL:load(filename);
		cprintf(cli.green, language[0], __WPL:getFileName());	-- Loaded waypoint path
		__WPL:setWaypointIndex(__WPL:getNearestWaypoint(player.X, player.Z));
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

--- Run rom scripts, usage: RoMScript("AcceptResurrect();");
function RoMScript(script)
	--- Get the real offset of the address
	local macro_address = memoryReadUInt(getProc(), staticmacrobase_address);

	--- Macro length is max 255, and after we add the return code,
	--- we are left with 120 character limit.
	local text = "/script r='' a={" .. script ..
	"} for i=1,#a do if a[i] then r=r..a[i]" ..
	" end r=r..'" .. string.char(9) .. "' end" ..
	" EditMacro(2,'',7,r);";

	--- Write the macro
	for i = 0, 254, 1 do
		local byte = string.byte(text, i + 1);
		if( byte == null ) then
			memoryWriteByte(getProc(), macro_address + macro1_offset + i, 0);
			break;
		end
		memoryWriteByte(getProc(), macro_address + macro1_offset + i, byte);
	end

   -- Write something on the first address, to see when its over written
   memoryWriteByte(getProc(), macro_address + macro2_offset, 6);

	--- Execute it
	if( settings.profile.hotkeys.MACRO ) then
		keyboardPress(settings.profile.hotkeys.MACRO.key);
	end

	-- A cheap version of a Mutex... wait till it is "released"
	-- Use high-res timers to find out when to time-out
	local startWaitTime = getTime();
	while( memoryReadByte(getProc(), macro_address + macro2_offset) == 6 ) do
		if( deltaTime(getTime(), startWaitTime) > 100 ) then
			break; -- Timed out
		end;
		rest(1);
	end
   
	--- Read the outcome from macro 2
	readsz = "";
	ret = {};
	cnt = 0;
	for i = 0, 254, 1 do
		local byte = memoryReadByte(getProc(), macro_address + macro2_offset + i);

		if( byte == 0 ) then -- Break on NULL terminator
			break;
		elseif( byte == 9 ) then -- Use TAB to seperate
			-- Implicit casting
			if( readsz == "true" ) then readsz = true; end;
			if( readsz == "false" ) then readsz = false; end;
			if( string.find(readsz, "^[%-%+]?%d+%.?%d+$") ) then readsz = tonumber(readsz);  end;
			if( string.find(readsz, "^%d+$") ) then readsz = tonumber(readsz);  end;

			table.insert(ret, readsz);
			cnt = cnt+1;
			readsz = "";
		else
			readsz = readsz .. string.char(byte);
		end
	end

	return unpack(ret);
end