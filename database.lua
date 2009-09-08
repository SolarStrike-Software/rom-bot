database =  {
	skills = {},
	nodes = {},
	utf8_ascii = {},
	consumables = {},
	giftbags = {}	
};

function database.load()
	local root = xml.open(getExecutionPath() .. "/database/skills.xml");
	local elements = root:getElements();


	for i,v in pairs(elements) do
		local tmp = CSkill();
		local name, mana, rage, energy, concentration, range, minrange, casttime, cooldown, type, target;
		local toggleable, maxhpper, priority, manainc, level;

		name = v:getAttribute("name");
		mana = v:getAttribute("mana");
		rage = v:getAttribute("rage");
		energy = v:getAttribute("energy");
		concentration = v:getAttribute("concentration");
		range = v:getAttribute("range");
		minrange = v:getAttribute("minrange");
		casttime = v:getAttribute("casttime");
		cooldown = v:getAttribute("cooldown");
		type = v:getAttribute("type");
		target = v:getAttribute("target");
		toggleable = v:getAttribute("toggleable");
		maxhpper = v:getAttribute("maxhpper");
		manainc = v:getAttribute("manainc");
		level = v:getAttribute("level");
		priority = v:getAttribute("priority");

		if( level == nil ) then level = 1; end;
		if( level < 1 ) then level = 1; end;

		if( cooldown == 0 ) then
			cooldown = 1;
		end

		--[[
		if( not priority and type == "damage" ) then type = STYPE_DAMAGE; priority = 70; end;
		if( not priority and type == "hot" ) then type = STYPE_HOT; priority = 110; end;
		if( not priority and type == "heal" ) then type = STYPE_HEAL; priority = 100; end;
		if( not priority and type == "buff" ) then type = STYPE_BUFF; priority = 90; end;
		if( not priority and type == "dot" ) then type = STYPE_DOT; priority = 80; end;
		]]

		-- Automatically assign priority (if not given) based on type
		if( not priority ) then
			if( type == "damage" ) then
				priority = 70;
			elseif( type == "hot" ) then
				priority = 110;
			elseif( type == "heal" ) then
				priority = 100;
			elseif( type == "buff" ) then
				priority = 90;
			elseif( type == "dot" ) then
				priority = 80;
			end;
		end

		-- Re-assign type to an actual defined type (improves speed; reduces slow string compares)
		if( type == "damage" ) then
			type = STYPE_DAMAGE;
		elseif( type == "hot" ) then
			type = STYPE_HOT;
		elseif( type == "heal" ) then
			type = STYPE_HEAL;
		elseif( type == "buff" ) then
			type = STYPE_BUFF;
		elseif( type == "dot" ) then
			type = STYPE_DOT;
		end;



		if( target == "enemy" ) then target = STARGET_ENEMY; end;
		if( target == "self" ) then target = STARGET_SELF; end;
		if( target == "friendly" ) then target = STARGET_FRIENDLY; end;

		if(name) then tmp.Name = name; end;
		if(mana) then tmp.Mana = mana; end;
		if(rage) then tmp.Rage = rage; end;
		if(energy) then tmp.Energy = energy; end;
		if(concentration) then tmp.Concentration = concentration; end;
		if(range) then tmp.Range = range; end;
		if(minrange) then tmp.MinRange = minrange; end;
		if(casttime) then tmp.CastTime = casttime; end;
		if(cooldown) then tmp.Cooldown = cooldown; end;
		if(type) then tmp.Type = type; end;
		if(target) then tmp.Target = target; end;
		if(toggleable) then tmp.Toggleable = toggleable; end;
		if(maxhpper) then tmp.MaxHpPer = maxhpper; end;
		if(priority) then tmp.priority = priority; end;
		if(manainc) then tmp.ManaInc = manainc; end;
		if(level) then tmp.Level = level; end;

		database.skills[name] = tmp;
	end


	-- import nodes/ressouces 
	root = xml.open(getExecutionPath() .. "/database/nodes.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
		local name, id, type;
		local tmp = CNode();

		name = v:getAttribute("name");
		id = v:getAttribute("id");
		type = v:getAttribute("type");

		if( type == "WOOD" ) then
			type = NTYPE_WOOD;
		elseif( type == "ORE" ) then
			type = NTYPE_ORE;
		elseif( type == "HERB" ) then
			type = NTYPE_HERB;
		end;

		tmp.Name = name;
		tmp.Id = id;
		tmp.Type = type;

		database.nodes[id] = tmp;
	end

	-- UTF-8 -> ASCII translation
	root = xml.open(getExecutionPath() .. "/database/utf8_ascii.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
		local utf8_1, utf8_2, ascii, dos_replace;
		local tmp = CNode();

		utf8_1 = v:getAttribute("utf8_1");
		utf8_2 = v:getAttribute("utf8_2");
		ascii = v:getAttribute("ascii");
		dos_replace = v:getAttribute("dos_replace");

		tmp.Name = name;
		tmp.utf8_1 = utf8_1;
		tmp.utf8_2 = utf8_2;
		tmp.ascii = ascii;
		tmp.dos_replace = dos_replace;		

		database.utf8_ascii[ascii] = tmp;
	end
	
	-- import consumables (potions, arrows, stones, ...)
	root = xml.open(getExecutionPath() .. "/database/consumables.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
	    local type, name, level, id;
		local tmp = {};

		type = v:getAttribute("type");
		name = v:getAttribute("name");
		level = v:getAttribute("level");
		id = v:getAttribute("id");

		if (type) then tmp.Type = type; end;
		if (name) then tmp.Name = name; end;
		if (level) then tmp.Level = level; end;
		if (id) then tmp.Id = id; end;

		database.consumables[i] = tmp;
	end

	-- import giftbag contents
	root = xml.open(getExecutionPath() .. "/database/giftbags.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
	    local itemid, type, class, level, name;
		local tmp = {};

		itemid = v:getAttribute("itemid");
		type   = v:getAttribute("type");
		class  = v:getAttribute("class");		
		level  = v:getAttribute("level");
		name   = v:getAttribute("name");

		if (itemid) then tmp.itemid = itemid; end;
		if (type)   then tmp.type   = type;   end;
		if (class)  then tmp.class  = class;  end;
		if (level)  then tmp.level  = level;  end;
		if (name)   then tmp.name   = name;   end;

		database.giftbags[i] = tmp;
	end

end