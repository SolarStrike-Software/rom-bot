settings_default = {
	hotkeys = {
		MOVE_FORWARD = {key = _G.key.VK_W, modifier = nil},
		MOVE_BACKWARD = {key = _G.key.VK_S, modifier = nil},
		ROTATE_LEFT = {key = _G.key.VK_A, modifier = nil},
		ROTATE_RIGHT = {key = _G.key.VK_D, modifier = nil},
		STRAFF_LEFT = {key = _G.key.VK_Q, modifier = nil},
		STRAFF_RIGHT = {key = _G.key.VK_E, modifier = nil},
		JUMP = {key = _G.key.VK_SPACE, modifier = nil},
		TARGET = {key = _G.key.VK_TAB, modifier = nil},
		START_BOT = {key = _G.key.VK_DELETE, modifier = nil},
		STOP_BOT = {key = _G.key.VK_END, modifier = nil}
	},
	options = {
		ENABLE_FIGHT_SLOW_TURN = false,
		MELEE_DISTANCE = 45,
		LANGUAGE = "english",
		DEBUG_ASSERT = false,
	},
	profile = {
		options = {
			-- common options
			HP_LOW = 85,
			MP_LOW_POTION = 50,
			HP_LOW_POTION = 40,
			COMBAT_TYPE = "melee",	
			COMBAT_DISTANCE = 200,
			ANTI_KS = true,
			WAYPOINTS = "myWaypoints.xml",
			RETURNPATH = nil,
			PATH_TYPE = "waypoints",
			WANDER_RADIUS = 500,
			WAYPOINT_DEVIATION = 0,
			LOOT = true,
			LOOT_TIME = 2000,
			LOOT_IN_COMBAT = true,
			LOOT_DISTANCE = nil,
			LOOT_PAUSE_AFTER = 10,	-- probability for short pause after loot to look more human
			POTION_COOLDOWN = 15,
			MAX_FIGHT_TIME = 12,
			DOT_PERCENT = 90,
			LOGOUT_TIME = 0,
			LOGOUT_SHUTDOWN = false,
			LOGOUT_WHEN_STUCK = true,
			MAX_UNSTICK_TRIALS = 10,
			TARGET_LEVELDIF_BELOW = 99,
			TARGET_LEVELDIF_ABOVE = 99,
			QUICK_TURN = false,
			MP_REST = 15,
			HP_REST = 15,
			RES_AUTOMATIC_AFTER_DEATH = false,	-- automatic resurrect after death true | false,

			
			-- expert options
			WAYPOINTS_REVERSE = false,	-- use the waypoint file in reverse order
			MAX_DEATHS = 10,		-- maximal death if automatic resurrect befor logout
			WAIT_TIME_AFTER_RES = 8000,	-- time to wait after resurrection, needs more on slow PCs
			RETURNPATH_SUFFIX = "_return",	-- suffix for default naming of returnpath
			HARVEST_SCAN_WIDTH = 10,	-- steps horizontal
			HARVEST_SCAN_HEIGHT = 8,	-- steps vertical
			HARVEST_SCAN_STEPSIZE = 35,	-- wide of every step
			HARVEST_SCAN_TOPDOWN = true,	-- true = top->down  false = botton->up
			HARVEST_SCAN_XMULTIPLIER = 1.0,	-- multiplier for scan width
			HARVEST_SCAN_YMULTIPLIER = 1.1,	-- multiplier for scan line height
			HARVEST_SCAN_YREST = 10,	-- scanspeed
			USE_SLEEP_AFTER_RESUME = false, -- enter sleep mode afer pressing pause key
			
		}, hotkeys = {}, skills = {}, friends = {},
		events = {
			onDeath = function () pauseOnDeath(); end,
			onLeaveCombat = nil,
			onSkillCast = nil,
		}
	},
};

settings = settings_default;


-- check if keys are double assigned or empty
check_keys = { };
function check_double_key_settings( _name, _key)

	for i,v in pairs(check_keys) do
		if( v.key == _key ) then
			cprintf(cli.yellow, "Error: You assigned the key \'%s\' double: for \'%s\' and for \'%s\'.\n",
			        v.key, v.name, _name);
			error("Please check your settings!", 0);
		if( _key == nil) then
			cprintf(cli.yellow, "Error: The key for \'%s\' is empty!\n", _name);
			error("Please check your settings!", 0);
		end

		end
	end;
	
	local tmp = {};
	tmp.name = _name;
	tmp.key  = _key;
	table.insert(check_keys, tmp);	

end

function settings.load()
	local filename = getExecutionPath() .. "/settings.xml";
	local root = xml.open(filename);
	local elements = root:getElements();

	-- Specific to loading the hotkeys section of the file
	local loadHotkeys = function (node)
		local elements = node:getElements();
		for i,v in pairs(elements) do
			-- If the hotkey doesn't exist, create it.
			settings.hotkeys[ v:getAttribute("description") ] = { };
			settings.hotkeys[ v:getAttribute("description") ].key = key[v:getAttribute("key")];
			settings.hotkeys[ v:getAttribute("description") ].modifier = key[v:getAttribute("modifier")];

			if( key[v:getAttribute("key")] == nil ) then
				local err = sprintf("settings.xml error: %s does not have a valid hotkey!", v:getAttribute("description"));
				error(err, 0);
			end
			check_double_key_settings( v:getAttribute("description"), v:getAttribute("key") );
		end
	end

	local loadOptions = function (node)
		local elements = node:getElements();
		for i,v in pairs(elements) do
			settings.options[ v:getAttribute("name") ] = v:getAttribute("value");
		end
	end

	-- load RoM keyboard bindings.txt file
	local function load_RoM_bindings_txt()
		
		local filename, file;
		
		-- german windows installation
		filename = os.getenv("USERPROFILE").."\\Eigene Dateien"..
		   "\\Runes of Magic\\bindings.txt";
--		filename = "F:\\Privat\\Runes of Magic\\bindings.txt";
		file = io.open( filename,"r");

		-- english windows installation
		if( not file ) then
			filename = os.getenv("USERPROFILE").."\\My Documents"..
			   "\\Runes of Magic\\bindings.txt";
			file = io.open( filename,"r");
		end;

		-- french windows installation
		if( not file ) then
			filename = os.getenv("USERPROFILE").."\\Documents"..
			   "\\Runes of Magic\\bindings.txt";
			file = io.open( filename,"r");
		end;

		-- finish windows installation
		if( not file ) then
			filename = os.getenv("USERPROFILE").."\\Omat tiedostot"..
			   "\\Runes of Magic\\bindings.txt";
			file = io.open( filename,"r");
		end;

		-- no bindings.txt file found / no checks possible
		if( not file ) then
			return
		end;

		-- Load bindings.txt into own table structure
		bindings = { name = { } };
		-- read the lines in table 'lines'
		for line in file:lines() do
			for name, key1, key2 in string.gfind(line, "(%w*)%s([%w+]*)%s*([%w+]*)") do
				bindings[name] = {};
				bindings[name].key1 = key1;
				bindings[name].key2 = key2;

			end
		end
	end

	-- check ingame settings
	-- only if we can find the bindings.txt file
	local function check_ingame_settings( _name, _ingame_key)
		
		if( not bindings ) then		-- no bindings.txt file loaded
			return
		end;
		
		if( settings.hotkeys[_name].key ~= key["VK_"..bindings[_ingame_key].key1] and
		    settings.hotkeys[_name].key ~= key["VK_"..bindings[_ingame_key].key2] ) then
			cprintf(cli.yellow, "Your bot settings for hotkey \'%s\' in settings.xml "..
			   "don't match your RoM ingame keyboard settings.\n",
			        _name);
			error("Please check your settings!", 0);
		end
    	end


	function checkHotkeys(_name, _ingame_key)
		if( not settings.hotkeys[_name] ) then
			error("ERROR: Global hotkey not set: " .. _name, 0);
		end
		
		-- check if settings.lua hotkeys match the RoM ingame settings
		check_ingame_settings( _name, _ingame_key);
	end


	for i,v in pairs(elements) do
		local name = v:getName();

		if( string.lower(name) == "hotkeys" ) then
			loadHotkeys(v);
		elseif( string.lower(name) == "options" ) then
			loadOptions(v);
		end
	end


	load_RoM_bindings_txt();	-- read bindings.txt from RoM user folder
	
	-- Check to make sure everything important is set
	--           bot hotkey name   RoM ingame key name         
	checkHotkeys("MOVE_FORWARD",  "MOVEFORWARD");
	checkHotkeys("MOVE_BACKWARD", "MOVEBACKWARD");
	checkHotkeys("ROTATE_LEFT",   "TURNLEFT");
	checkHotkeys("ROTATE_RIGHT",  "TURNRIGHT");
	checkHotkeys("STRAFF_LEFT",   "STRAFELEFT");
	checkHotkeys("STRAFF_RIGHT",  "STRAFERIGHT");
	checkHotkeys("JUMP",          "JUMP");
	checkHotkeys("TARGET",        "TARGETNEARESTENEMY");
	
end


function settings.loadProfile(_name)
	-- Delete old profile settings (if they even exist), restore defaults
	settings.profile = settings_default.profile;

	local filename = getExecutionPath() .. "/profiles/" .. _name .. ".xml";
	local root = xml.open(filename);
	local elements = root:getElements();

	local loadOptions = function(node)
		local elements = node:getElements();

		for i,v in pairs(elements) do
			settings.profile.options[v:getAttribute("name")] = v:getAttribute("value");
		end
	end

	local loadHotkeys = function(node)
		local elements = node:getElements();

		for i,v in pairs(elements) do
			settings.profile.hotkeys[v:getAttribute("name")] = {};
			settings.profile.hotkeys[v:getAttribute("name")].key = key[v:getAttribute("key")];
			settings.profile.hotkeys[v:getAttribute("name")].modifier = key[v:getAttribute("modifier")];

			if( key[v:getAttribute("key")] == nil ) then
				local err = sprintf("Profile error: Please set a valid key for hotkey %s in your profile file \'%s.xml\'.", tostring(v:getAttribute("name")), name );
				error(err, 0);
			end
			check_double_key_settings( v:getAttribute("name"), v:getAttribute("key") );
		end
	end

	local loadOnDeathEvent = function(node)
		local luaCode = tostring(node:getValue());

		if( string.len(luaCode) > 0 and string.find(luaCode, "%w") ) then
			settings.profile.events.onDeath = loadstring(luaCode);
			if( type(settings.profile.events.onDeath) ~= "function" ) then
				settings.profile.events.onDeath = nil;
			end;
		end
	end

	local loadOnLeaveCombatEvent = function(node)
		local luaCode = tostring(node:getValue());

		if( string.len(luaCode) > 0 and string.find(luaCode, "%w") ) then
			settings.profile.events.onLeaveCombat = loadstring(luaCode);
			if( type(settings.profile.events.onLeaveCombat) ~= "function" ) then
				settings.profile.events.onLeaveCombat = nil;
			end;
		end
	end

	local loadOnSkillCastEvent = function(node)
		local luaCode = tostring(node:getValue());

		if( string.len(luaCode) > 0 and string.find(luaCode, "%w") ) then
			settings.profile.events.onSkillCast = loadstring(luaCode);
			if( type(settings.profile.events.onSkillCast) ~= "function" ) then
				settings.profile.events.onSkillCast = nil;
			end;
		end
	end


	local skillSort = function(tab1, tab2)
		if( tab2.priority < tab1.priority ) then
			return true;
		end;

		return false;
	end

	local loadSkills = function(node)
		local elements = node:getElements();

		for i,v in pairs(elements) do
			local name, hotkey, modifier, level;
			name = v:getAttribute("name");
			hotkey = key[v:getAttribute("hotkey")];
			modifier = key[v:getAttribute("modifier")];
			level = v:getAttribute("level");

			check_double_key_settings( v:getAttribute("name"), v:getAttribute("hotkey") );

			-- Over-ride attributes
			local priority, maxhpper, inbattle
			priority = v:getAttribute("priority");
			maxhpper = tonumber(v:getAttribute("hpper"));
			inbattle = v:getAttribute("inbattle");

			-- check if 'wrong' options are set
			if( v:getAttribute("mana")      or
			    v:getAttribute("manainc")   or
			    v:getAttribute("rage")      or
			    v:getAttribute("energy")    or
			    v:getAttribute("concentration")      or
			    v:getAttribute("range")     or
			    v:getAttribute("cooldown")  or
			    v:getAttribute("minrange")  or
			    v:getAttribute("type")      or
			    v:getAttribute("target")    or
			    v:getAttribute("casttime") ) then
			    	cprintf(cli.yellow, "The options \'mana\', \'manainc\', \'rage\', "..
			    	   "\'energy\', \'concentration\', \'range\', "..
			    	   "\'cooldown\', \'minrange\', \'type\', \'target\' and \'casttime\' "..
			    	   "are no valid options for your skill \'%s\' in your profile \'%s.xml\'. "..
			    	   "Please delete them and restart!\n", name, _name);
			    	   error("Bot finished due of errors above.\n", 0);
			end;
			if( v:getAttribute("modifier") ) then
			    	cprintf(cli.yellow, "The options \'modifier\' "..
			    	  "for your skill \'%s\' in your profile \'%s.xml\' "..
			    	  "is not supported at the moment. "..
			    	  "Please delete it and restart!\n", name, _name);
				error("Bot finished due of errors above.\n", 0);
			end;

			if( name == nil) then
			    	cprintf(cli.yellow, "You defined an \'empty\' skill name in "..
			    	  "your profile \'%s.xml\'. Please delete or correct "..
			    	  "that line!\n", _name);
				error("Bot finished due of errors above.\n", 0);
			end;

			if( inbattle ~= nil ) then
				if( inbattle == "true" ) then
					inbattle = true;
				end;
				if( inbattle == "false" ) then
					inbattle = false;
				end;
			end

			if( level == nil or level < 1 ) then
				level = 1;
			end

			local baseskill = database.skills[name];
			if( not baseskill ) then
				local err = sprintf("ERROR: \'%s\' is not defined in the database!", name);
				error(err, 0);
			end

			local tmp = CSkill(database.skills[name]);
			tmp.hotkey = hotkey;
			tmp.modifier = modifier;
			tmp.Level = level;

			if( toggleable ) then tmp.Toggleable = toggleable; end;
			if( priority ) then tmp.priority = priority; end
			if( maxhpper ) then tmp.MaxHpPer = maxhpper; end;
			if( inbattle ~= nil ) then tmp.InBattle = inbattle; end;

			table.insert(settings.profile.skills, tmp);
		end

		table.sort(settings.profile.skills, skillSort);

	end

	local loadFriends = function(node)
		local elements = node:getElements();

		for i,v in pairs(elements) do
			local name = v:getAttribute("name");
			table.insert(settings.profile.friends, name);
		end
	end

	local hf_temp = name;	-- remember profile name shortly

	for i,v in pairs(elements) do
		local name = v:getName();

		if( string.lower(name) == "options" ) then
			loadOptions(v);
		elseif( string.lower(name) == "hotkeys" ) then
			loadHotkeys(v);
		elseif( string.lower(name) == "skills" ) then
			loadSkills(v);
		elseif( string.lower(name) == "friends" ) then
			loadFriends(v);
		elseif( string.lower(name) == "ondeath" ) then
			loadOnDeathEvent(v);
		elseif( string.lower(name) == "onleavecombat" ) then
			loadOnLeaveCombatEvent(v);
		elseif( string.lower(name) == "onskillcast" ) then
			loadOnSkillCastEvent(v);
		elseif( string.lower(name) == "skills_warrior"  and
		        player.Class1 == CLASS_WARRIOR ) then
			loadSkills(v);
		elseif( string.lower(name) == "skills_scout"  and
		        player.Class1 == CLASS_SCOUT ) then
			loadSkills(v);
		elseif( string.lower(name) == "skills_rogue"  and
		        player.Class1 == CLASS_ROGUE ) then
			loadSkills(v);
		elseif( string.lower(name) == "skills_mage"  and
		        player.Class1 == CLASS_MAGE ) then
			loadSkills(v);
		elseif( string.lower(name) == "skills_priest"  and
		        player.Class1 == CLASS_PRIEST ) then
			loadSkills(v);
		elseif( string.lower(name) == "skills_knight"  and
		        player.Class1 == CLASS_KNIGHT ) then
			loadSkills(v);
		elseif( string.lower(name) == "skills_runedancer"  and
		        player.Class1 == CLASS_RUNEDANCER ) then
			loadSkills(v);
		elseif( string.lower(name) == "skills_druid"  and
		        player.Class1 == CLASS_DRUID ) then
			loadSkills(v);
		else		-- warning for other stuff and misspellings
			if ( string.lower(name) ~= "skills_warrior"     and
			     string.lower(name) ~= "skills_scout"       and
		 	     string.lower(name) ~= "skills_rogue"       and
	 		     string.lower(name) ~= "skills_mage"        and
			     string.lower(name) ~= "skills_priest"      and
			     string.lower(name) ~= "skills_knight"      and
			     string.lower(name) ~= "skills_runedancer"  and
			     string.lower(name) ~= "skills_druid" )     then
				cprintf(cli.yellow, language[60], string.lower(name), hf_temp);
			end;
		end
	end


	function checkProfileHotkeys(name)
		if( not settings.profile.hotkeys[name] ) then
			error("ERROR: Hotkey not set for this profile: " ..name, 0);
		end
	end

	-- Check to make sure everything important is set
	checkProfileHotkeys("ATTACK");

	-- default combat type if not in profile defined
	if( settings.profile.options.COMBAT_TYPE ~= "ranged" and 
	    settings.profile.options.COMBAT_TYPE ~= "melee" ) then
		if( player.Class1 == CLASS_WARRIOR or
		    player.Class1 == CLASS_ROGUE   or
--		    player.Class1 == CLASS_RUNEDANCER  or
		    player.Class1 == CLASS_KNIGHT  ) then
			settings.profile.options.COMBAT_TYPE  = "melee";
		elseif(
		    player.Class1 == CLASS_PRIEST  or
		    player.Class1 == CLASS_SCOUT   or
--		    player.Class1 == CLASS_DRUID   or
		    player.Class1 == CLASS_MAGE    ) then
			settings.profile.options.COMBAT_TYPE  = "ranged";
		else
			error("undefined player.Class1 in settings.lua", 0);
		end;
	end

end