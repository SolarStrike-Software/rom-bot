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
	},
	profile = {
		options = {
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
			MAX_FIGHT_TIME = 15,
			DOT_PERCENT = 90,
			LOGOUT_TIME = 0,
			LOGOUT_SHUTDOWN = false,
			TARGET_LEVELDIF_BELOW = 99,
			TARGET_LEVELDIF_ABOVE = 99,
			QUICK_TURN = false,
			MP_REST = 15,
			HP_REST = 15,
			WAYPOINTS_REVERSE = false,
			MAX_DEATHS = 10,
			MAX_UNSTICK_TRIALS = 10,
			RETURNPATH_SUFFIX = "_return",	-- suffix for default naming of returnpath
			HARVEST_SCAN_WIDTH = 10,	-- steps horizontal
			HARVEST_SCAN_HEIGHT = 8,	-- steps vertical
			HARVEST_SCAN_STEPSIZE = 35,	-- wide of every step
			HARVEST_SCAN_TOPDOWN = true,	-- true = top->down  false = botton->up
			HARVEST_SCAN_YREST = 10,	-- scanspeed		
			
		}, hotkeys = {}, skills = {}, friends = {},
		events = {
			onDeath = function () pauseOnDeath(); end,
			onLeaveCombat = nil,
			onSkillCast = nil,
		}
	},
};

settings = settings_default;

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
				local err = sprintf("settings.xml error: %s does not name a valid hotkey!", v:getAttribute("key"));
				error(err, 0);
			end
		end
	end

	local loadOptions = function (node)
		local elements = node:getElements();
		for i,v in pairs(elements) do
			settings.options[ v:getAttribute("name") ] = v:getAttribute("value");
		end
	end

	for i,v in pairs(elements) do
		local name = v:getName();

		if( string.lower(name) == "hotkeys" ) then
			loadHotkeys(v);
		elseif( string.lower(name) == "options" ) then
			loadOptions(v);
		end
	end

	function checkHotkeys(name)
		if( not settings.hotkeys[name] ) then
			error("ERROR: Global hotkey not set: " .. name, 0);
		end
	end

	-- Check to make sure everything important is set
	checkHotkeys("MOVE_FORWARD");
	checkHotkeys("MOVE_BACKWARD");
	checkHotkeys("ROTATE_LEFT");
	checkHotkeys("ROTATE_RIGHT");
	checkHotkeys("STRAFF_LEFT");
	checkHotkeys("STRAFF_RIGHT");
	checkHotkeys("JUMP");
	checkHotkeys("TARGET");
end


function settings.loadProfile(name)
	-- Delete old profile settings (if they even exist), restore defaults
	settings.profile = settings_default.profile;

	local filename = getExecutionPath() .. "/profiles/" .. name .. ".xml";
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
				local err = sprintf("profile error: %s does not name a valid hotkey!", tostring(v:getAttribute("key")));
				error(err, 0);
			end
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

			-- Over-ride attributes
			local priority, maxhpper, inbattle
			priority = v:getAttribute("priority");
			maxhpper = tonumber(v:getAttribute("hpper"));
			inbattle = v:getAttribute("inbattle");

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
	if( settings.profile.options.COMBAT_TYPE ~= "ranged" and settings.profile.options.COMBAT_TYPE ~= "melee" ) then
		error("COMBAT_TYPE must be \"ranged\" or \"melee\"", 0);
	end

end