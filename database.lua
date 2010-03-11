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
		local name, mana, targetmaxhpper, targetmaxhp, maxhpper, maxmanaper, rage, energy, concentration;
		local range, minrange, casttime, cooldown, type, target;
		local toggleable, minmanaper, inbattle, priority, manainc, level, aslevel, skilltab, skillnum;
		local reqbufftype, reqbuffcount, reqbufftarget, reqbuffname;

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
		maxmanaper = v:getAttribute("maxmanaper");
		minmanaper = v:getAttribute("minmanaper");
		targetmaxhpper = v:getAttribute("targetmaxhpper");
		targetmaxhp = v:getAttribute("targetmaxhp");
		inbattle = v:getAttribute("inbattle");
		manainc = v:getAttribute("manainc");
		level = v:getAttribute("level");
		priority = v:getAttribute("priority");
		aslevel = v:getAttribute("aslevel");
		skilltab = v:getAttribute("skilltab");
		skillnum = v:getAttribute("skillnum");

		reqbufftype = string.lower(tostring(v:getAttribute("reqbufftype") or ""));
		reqbuffcount = tonumber(v:getAttribute("reqbuffcount") or 0);
		reqbufftarget = string.lower(tostring(v:getAttribute("reqbufftarget") or "player"));
		reqbuffname = tostring(v:getAttribute("reqbuffname") or "");

		if( level == nil ) then level = 1; end;
		if( level < 1 ) then level = 1; end;

		if( cooldown == 0 ) then
			cooldown = 1;
		end

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
			elseif( type == "summon" ) then
				priority = 95;
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
		elseif( type == "summon" ) then
			type = STYPE_SUMMON;
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
		if(targetmaxhp) then tmp.TargetMaxHp = targetmaxhp; end;
		if(targetmaxhpper) then tmp.TargetMaxHpPer = targetmaxhpper; end;
		if(maxhpper) then tmp.MaxHpPer = maxhpper; end;
		if(maxmanaper) then tmp.MaxManaPer = maxmanaper; end;
		if(minmanaper) then tmp.MinManaPer = minmanaper; end;
		if(inbattle ~= nil) then tmp.InBattle = inbattle; end;
		if(priority) then tmp.priority = priority; end;
		if(manainc) then tmp.ManaInc = manainc; end;
		if(level) then tmp.Level = level; end;
		if(aslevel) then tmp.aslevel = aslevel; end;	
		if(skilltab) then tmp.skilltab = skilltab; end;	
		if(skillnum) then tmp.skillnum = skillnum; end;		

		if(reqbufftype == "buff" or reqbufftype == "debuff" ) then tmp.ReqBuffType = reqbufftype; end;
		if(reqbuffcount > 0 ) then tmp.ReqBuffCount = reqbuffcount; end;
		if(reqbufftarget ~= "") then tmp.ReqBuffTarget = reqbufftarget; end;
		if(reqbuffname ~= "") then tmp.ReqBuffName = reqbuffname; end;

		database.skills[name] = tmp;
	end


	-- import local skill file
	-- used to use skills by name with RoMScript and CastSpellByName()
	cprintf(cli.red, "OPENING LOCAL SKILLS DB!\n");
	local root = xml.open(getExecutionPath() .. "/database/skills_local.xml");
	local elements = root:getElements();

	for i,v in pairs(elements) do
	  local skill_name = v:getName(); -- This is the TAG name; ie. MAGE_FIREBALL

	  -- Make sure the skill is in the database (and that the database is loaded)
	  if( database.skills[skill_name] ) then
		database.skills[skill_name].en = v:getAttribute("en");
		database.skills[skill_name].de = v:getAttribute("de");
		database.skills[skill_name].fr = v:getAttribute("fr");
		database.skills[skill_name].ru = v:getAttribute("ru");		
	  end
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
		local tmp = {};

		utf8_1 = v:getAttribute("utf8_1");
		utf8_2 = v:getAttribute("utf8_2");
		ascii = v:getAttribute("ascii");
		dos_replace = v:getAttribute("dos_replace");

--		tmp.Name = name;
		tmp.utf8_1 = utf8_1;
		tmp.utf8_2 = utf8_2;
		tmp.ascii = ascii;
		tmp.dos_replace = dos_replace;		

		local key = utf8_1*1000 + utf8_2;
		database.utf8_ascii[key] = tmp;
	end
	
	
	-- import consumables (potions, arrows, stones, ...)
	root = xml.open(getExecutionPath() .. "/database/consumables.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
	    local type, name, level, potency, id;
		local tmp = {};

		type = v:getAttribute("type");
		name = v:getAttribute("name");
		level = v:getAttribute("level");
		potency = v:getAttribute("potency");
		id = v:getAttribute("id");

		if (type) then tmp.Type = type; end;
		if (name) then tmp.Name = name; end;
		if (level) then tmp.Level = level; end;
		if (potency) then 
			tmp.Potency = potency; 
		else
			tmp.Potency = 0; 
		end;
		if (id) then tmp.Id = id; end;

		database.consumables[id] = tmp;
	end

	-- import giftbag contents
	root = xml.open(getExecutionPath() .. "/database/giftbags.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
	    local itemid, type, armor, level, name;
		local tmp = {};

		itemid = v:getAttribute("itemid");
		type   = v:getAttribute("type");
		armor  = v:getAttribute("armor");		
		level  = v:getAttribute("level");
		name   = v:getAttribute("name");

		if (itemid) then tmp.itemid = itemid; end;
		if (type)   then tmp.type   = type;   end;
		if (armor)  then tmp.armor  = armor;  end;
		if (level)  then tmp.level  = level;  end;
		if (name)   then tmp.name   = name;   end;

		database.giftbags[i] = tmp;
	end

end