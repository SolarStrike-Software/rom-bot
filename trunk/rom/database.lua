database =  {
	skills = {};
};

function database.load()
	local root = xml.open(getExecutionPath() .. "/database/skills.xml");
	local elements = root:getElements();


	for i,v in pairs(elements) do
		local tmp = CSkill();
		local name, mana, rage, energy, concentration, range, minrange, casttime, cooldown, type, target;
		local maxhpper, priority, manainc, level;

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
		maxhpper = v:getAttribute("maxhpper");
		manainc = v:getAttribute("manainc");
		level = v:getAttribute("level");
		priority = v:getAttribute("priority");

		if( level == nil ) then level = 1; end;
		if( level < 1 ) then level = 1; end;

		if( cooldown == 0 ) then
			cooldown = 1;
		end

		if( not priority and type == "damage" ) then type = STYPE_DAMAGE; priority = 70; end;
		if( not priority and type == "hot" ) then type = STYPE_HOT; priority = 110; end;
		if( not priority and type == "heal" ) then type = STYPE_HEAL; priority = 100; end;
		if( not priority and type == "buff" ) then type = STYPE_BUFF; priority = 90; end;
		if( not priority and type == "dot" ) then type = STYPE_DOT; priority = 80; end;

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
		if(maxhpper) then tmp.MaxHpPer = maxhpper; end;
		if(priority) then tmp.priority = priority; end;
		if(manainc) then tmp.ManaInc = manainc; end;
		if(level) then tmp.Level = level; end;

		database.skills[name] = tmp;
	end

end