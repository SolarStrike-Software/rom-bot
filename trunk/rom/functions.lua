if( settings == nil ) then
	include("settings.lua");
end

local charUpdatePattern = string.char(0x8B, 0x07, 0x8B, 0x0D, 0xFF, 0xFF, 0xFF, 0xFF, 0x56, 0x50, 0xE8);
local charUpdateMask = "xxxx????xxx";
local charUpdateOffset = 4;

local camUpdatePattern = string.char(0x83, 0x3D, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x53, 0x8B, 0x1D, 0xFF, 0xFF, 0xFF, 0xFF, 0x55);
local camUpdateMask = "xx????xxxx????x";
local camUpdateOffset = 2;

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

function getCamUpdatePattern()
	return camUpdatePattern;
end

function getCamUpdateMask()
	return camUpdateMask;
end

function getCamUpdateOffset()
	return camUpdateOffset;
end

function checkExecutableCompatible()
	if( findPatternInProcess(getProc(), charUpdatePattern, charUpdateMask,
	charpatternstart_address, 1) == 0 ) then
		return false;
	end

	if( findPatternInProcess(getProc(), camUpdatePattern, camUpdateMask,
	campatternstart_address, 1) == 0 ) then
		return false;
	end

	return true;
end

if(settings.options.DEBUG_ASSERT == nil ) then settings.options.DEBUG_ASSERT = false; end;
function debugAssert(args)
	if( settings.options.DEBUG_ASSERT ) then
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

	if( __WIN == nil or not windowValid(__WIN) ) then
		local winlist = findWindowList("Runes of Magic", "Radiant Arcana");

		if( #winlist == 0 ) then
			error("RoM window not found! RoM must be running first.", 0);
		end

		if( #winlist > 1 ) then
			cprintf(cli.yellow, "Multiple RoM windows found. Keep the RoM "
				.. "window to attach this bot to on top, and press %s.\n",
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
	local msg = sprintf("Paused. (%s) to continue, (CTRL+L) exit to shell, (CTRL+C) quit\n",
		getKeyName(getStartKey()));
		
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
		cprintf(cli.yellow, "We will go to sleep after fight finished / as soon as possible.\n");	-- Logout at %time%
		player.Sleeping = true;		-- activate sleep
	end
	
end
atResume(resumeCallback);


function pauseOnDeath()
	local sk = startKey;
	if( getVersion() >= 100 ) then sk = getStartKey(); end;
	cprintf(cli.red, "You have died... Sorry.\n");
	printf("Script paused until you revive yourself. Press %s when you\'re ready to continue.\n",
		getKeyName(sk))
	logMessage("Player died.\n");
	stopPE();
end

local LAST_PLAYER_X = 0;
local LAST_PLAYER_Z = 0;
function timedSetWindowName(profile)
	if( (player.X ~= LAST_PLAYER_X) or (player.Z ~= LAST_PLAYER_Z) ) then
		setWindowName(getHwnd(), sprintf("RoM Bot %s [%s] (%d,%d)",
		BOT_VERSION, profile, player.X, player.Z));

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
		cprintf(cli.yellow, "You have to specify either a waypoint path or a return path to use the function load_paths(). No paths loaded!\n");
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
		__WPL:load(getExecutionPath() .. "/waypoints/" .. _wp_path );
		cprintf(cli.green, language[0], __WPL:getFileName());	-- Loaded waypoint path
		__WPL:setWaypointIndex(__WPL:getNearestWaypoint(player.X, player.Z));
	end

	-- look for default return path with suffix '_return'
	if( not _rp_path ) then
		local file = io.open(getExecutionPath() .. "/waypoints/" .. rp_default , "r");
		if( file ) then	-- file exits
			file:close();
			cprintf(cli.green, "Return path found with default naming: %s\n", rp_default );	
			_rp_path = rp_default;	-- set default
		else
			cprintf(cli.yellow, "No return path with default naming %s found.\n", rp_default );
		end;
	end
	
	-- return path defined or default found ... load it
	if( _rp_path ) then
		if( not __RPL ) then  		-- define object if not there
			__RPL = CWaypointList(); 
		end;
		__RPL:load(getExecutionPath() .. "/waypoints/" .. _rp_path );
		cprintf(cli.green, language[1], __RPL:getFileName());	-- Loaded return path 		
	else
		if( __RPL ) then  		-- clear old returnpath object
			__RPL = nil; 
		end;
	end;

	-- check if on returnpath
	if( player.Returning == true  and
	    _rp_path ) then
		cprintf(cli.green, "We are coming from a return_path. So we will going on using the returnpath %s.\n", __RPL:getFileName());
	else
		player.Returning = false;
		cprintf(cli.green, "We use the normal waypoint path %s now.\n", __WPL:getFileName() );
	end


end