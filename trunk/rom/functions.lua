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

	cprintf("Please use the renamed function \'loadPaths()\' instead of \'load_paths\'!\n");
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

-- executing RoMScript and send a MM window message before
function sendMacro(_script)

	cprintf(cli.green, language[169], 		-- Executing RoMScript ...
	   getKeyName(settings.profile.hotkeys.MACRO.key),
	   string.sub(_script, 1, 40) );

	RoMScript(_script);
	
end


--- Run rom scripts, usage: RoMScript("AcceptResurrect();");
function RoMScript(script)

	--- Get the real offset of the address
	local macro_address = memoryReadUInt(getProc(), staticmacrobase_address);

	--- Macro length is max 255, and after we add the return code,
	--- we are left with 120 character limit.
	local text = "/script r='' a={" .. script ..
	"} for i=1,#a do if a[i] then r=r..tostring(a[i])" ..
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
		if( deltaTime(getTime(), startWaitTime) > 500 ) then
			break; -- Timed out
		end;
		rest(1);
	end
   
	--- Read the outcome from macro 2
	readsz = "";
	ret = {};
	cnt = 0;
	for i = 0, 254, 1 do
		local byte = memoryReadUByte(getProc(), macro_address + macro2_offset + i);

		if( byte == 0 ) then -- Break on NULL terminator
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

	message = asciiToUtf8(message);	-- for ingame umlauts

	RoMScript("ChatFrame1:AddMessage(\""..message.."\")");
end

function replaceUtf8( _str, _ascii )
	local tmp = database.utf8_ascii[_ascii];
	_str = string.gsub(_str, string.char(tmp.utf8_1, tmp.utf8_2), string.char(_ascii) );
	return _str
end

function replaceAscii( _str, _ascii )
	local tmp = database.utf8_ascii[_ascii];
	_str = string.gsub(_str, string.char(_ascii), string.char(tmp.utf8_1, tmp.utf8_2) );
	return _str
end

-- we only replace umlaute, hence only that are importent for mob names
-- player names are at the moment not importent for the MM protocol
-- player names will be handled while loading the profile
function utf8ToAscii(_str)
	_str = replaceUtf8(_str, 132);		-- ä
	_str = replaceUtf8(_str, 142);		-- Ä
	_str = replaceUtf8(_str, 148);		-- ö
	_str = replaceUtf8(_str, 153);		-- Ö
	_str = replaceUtf8(_str, 129);		-- ü
	_str = replaceUtf8(_str, 154);		-- Ü
	_str = replaceUtf8(_str, 225);		-- ß
	return _str;
end

-- we only replace umlaute, hence only that are importent for
-- printing ingame messages
function asciiToUtf8(_str)
	_str = replaceAscii(_str, 132);		-- ä
	_str = replaceAscii(_str, 142);		-- Ä
	_str = replaceAscii(_str, 148);		-- ö
	_str = replaceAscii(_str, 153);		-- Ö
	_str = replaceAscii(_str, 129);		-- ü
	_str = replaceAscii(_str, 154);		-- Ü
	_str = replaceAscii(_str, 225);		-- ß
	return _str;
end

-- open giftbag (at the moment level 1-10)
function openGiftbag(_player_level, _maxslot)

	if( not _player_level) then _player_level = player.Level; end
	cprintf(cli.lightblue, language[170], _player_level );	-- Open and equipt giftbag for level 
	
	-- open giftbag and equipt content
	yrest(2000);	-- time for cooldowns to phase-out (prevents from missed opening tries)
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
					inventory:update(_maxslot);	-- update slots
				end;
			end;
		end;

	end

end

function levelupSkills1To10()
-- levelup skills

	-- e.g. 4 = third skill tab, 2 = second skill on the tab
	-- CAUTION: addressing a invalid skill will crash the RoM client
	local skillLevelupMap = {
		[CLASS_WARRIOR]		= {  [1] = { level = 1, skilltab = 2, skillnum = 2 } },	-- slash
		[CLASS_SCOUT]		= {  [1] = { level = 1, skilltab = 2, skillnum = 1 } },	-- shot
		[CLASS_ROGUE]		= {  [1] = { level = 1, skilltab = 2, skillnum = 1 } },	-- meucheln
		[CLASS_MAGE]		= {  [1] = { level = 1, skilltab = 4, skillnum = 2 },	-- flame
								 [2] = { level = 4, skilltab = 2, skillnum = 1 } },	-- fireball
		[CLASS_PRIEST]		= {  [1] = { level = 1, skilltab = 2, skillnum = 1 },	-- rising tide
								 [2] = { level = 1, skilltab = 2, skillnum = 2 } }, -- urgent heal
		[CLASS_KNIGHT]      = {  [1] = { level = 1, skilltab = 2, skillnum = 1 },	-- Bestrafung
								 [2] = { level = 1, skilltab = 2, skillnum = 2 } }, -- Heiliger Schlag
		[CLASS_RUNEDANCER] = "???",	-- ???
		[CLASS_DRUID]      = "???",	-- ???
		};

	local leveluptable = skillLevelupMap[player.Class1];
	for i,v in pairs(leveluptable)  do
		if( player.Level >= v.level ) then 
			sendMacro("SetSpellPoint("..v.skilltab..","..v.skillnum..");");
			yrest(1000);
			if(	player.Level == 2 ) then
				-- twice at lvl 2 for lvl 1 and lvl 2
				sendMacro("SetSpellPoint("..v.skilltab..","..v.skillnum..");");
				yrest(1000);
			end
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