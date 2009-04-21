settings = {
	hotkeys = {},
	options = {},
	profile = {
		options = {}, hotkeys = {}, skills = {}, friends = {},
		events = {
			onDeath = nil,
			onLeaveCombat = nil,
			onSkillCast = nil,
		}
	},
};

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
	checkHotkeys("CLEAR_TARGET");
	checkHotkeys("TARGET");
end


function settings.loadProfile(name)
	-- Delete old profile settings (if they even exist), restore defaults
	settings.profile = {
		options = {}, hotkeys = {}, skills = {}, friends = {},
		events = {
			onDeath = nil,
			onLeaveCombat = nil,
			onSkillCast = nil,
		}
	}

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
				local err = sprintf("profile error: %s does not name a valid hotkey!", v:getAttribute("key"));
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

	-- Make sure they didn't use the same type of energy storage for both (hence breaking it)
	if( settings.profile.options.ENERGY_STORAGE_1 == settings.profile.options.ENERGY_STORAGE_2 ) then
		error("Do not use the same energy storage for primary and secondary!\nEdit your profile to fix this.", 0);
	end;
end